// ignore_for_file: depend_on_referenced_packages, deprecated_member_use
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/constants/supabase_constants.dart';
import 'package:nexora_flutter_app/core/services/order_chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  HttpOverrides.global = _RealHttpOverrides();

  test('Bidirectional Real-Time Chat between Rider App and Buyer App via Supabase Broadcast', () async {
    // 1. Initialize Buyer Client via Supabase singleton
    try {
      await Supabase.initialize(
        url: SupabaseConstants.url,
        anonKey: SupabaseConstants.anonKey,
      );
    } catch (_) {}

    // 2. Initialize separate Rider Client simulating Rider App
    final riderClient = SupabaseClient(
      SupabaseConstants.url,
      SupabaseConstants.anonKey,
    );

    final testOrderId = 'NX-REALTIME-${DateTime.now().millisecondsSinceEpoch}';
    final cleanId = testOrderId.replaceAll('#', '').trim().toLowerCase();
    final channelName = 'rider_chat_$cleanId';

    // 3. Buyer subscribes via OrderChatService
    final buyerService = OrderChatService.instance;
    buyerService.subscribeToOrder(testOrderId);

    // 4. Rider subscribes on separate client
    final riderMsgCompleter = Completer<Map<String, dynamic>>();
    final riderTypingCompleter = Completer<bool>();

    final riderChannel = riderClient.channel(
      channelName,
      opts: const RealtimeChannelConfig(self: false),
    );

    riderChannel.onBroadcast(
      event: 'chat_message',
      callback: (payload) {
        if (!riderMsgCompleter.isCompleted) {
          riderMsgCompleter.complete(Map<String, dynamic>.from(payload));
        }
      },
    ).onBroadcast(
      event: 'typing',
      callback: (payload) {
        if (payload['is_typing'] == true && !riderTypingCompleter.isCompleted) {
          riderTypingCompleter.complete(true);
        }
      },
    );

    final riderSubCompleter = Completer<void>();
    riderChannel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed && !riderSubCompleter.isCompleted) {
        riderSubCompleter.complete();
      }
    });

    await riderSubCompleter.future.timeout(const Duration(seconds: 8));

    // Wait a brief moment for both WebSocket connections to establish
    await Future.delayed(const Duration(milliseconds: 600));

    // 5. Test 1: Rider sends message -> Buyer receives it
    final buyerMsgCompleter = Completer<Map<String, dynamic>>();
    buyerService.onNewMessageReceived = (msg) {
      if (!buyerMsgCompleter.isCompleted) {
        buyerMsgCompleter.complete(msg);
      }
    };

    await riderChannel.sendBroadcastMessage(
      event: 'chat_message',
      payload: {
        'id': 'msg_r_test_101',
        'order_id': cleanId,
        'sender': 'rider',
        'sender_name': 'Pedro Jose Garcia (Courier)',
        'text': 'Good day Alex! I have arrived at your building lobby.',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    final receivedByBuyer = await buyerMsgCompleter.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => {},
    );

    expect(receivedByBuyer.isNotEmpty, isTrue, reason: 'Buyer should receive rider message');
    expect(receivedByBuyer['text'], 'Good day Alex! I have arrived at your building lobby.');
    expect(receivedByBuyer['sender'], 'other');
    expect(buyerService.getUnreadCount(testOrderId), greaterThan(0));

    // 6. Test 2: Buyer sends message -> Rider receives it
    await buyerService.sendMessage(
      testOrderId,
      'Thanks Mark! Coming down to the front desk with COD cash.',
      customerName: 'Alex Rivera',
    );

    final receivedByRider = await riderMsgCompleter.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => {},
    );

    expect(receivedByRider.isNotEmpty, isTrue, reason: 'Rider should receive buyer message');
    expect(receivedByRider['sender'], 'customer');
    expect(receivedByRider['text'], 'Thanks Mark! Coming down to the front desk with COD cash.');

    // 7. Test 3: Buyer typing status -> Rider receives it
    await buyerService.sendTyping(testOrderId, true);

    final isTypingReceived = await riderTypingCompleter.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );

    expect(isTypingReceived, isTrue, reason: 'Rider should receive buyer typing indicator');

    // 8. Cleanup
    await riderClient.removeChannel(riderChannel);
    await buyerService.unsubscribeFromOrder(testOrderId);
  });
}
