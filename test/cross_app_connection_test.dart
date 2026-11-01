// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _CrossAppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _CrossAppHttpOverrides();

  group('Cross-App Connection & Synchronization Test Suite', () {
    late SupabaseClient buyerClient;
    late SupabaseClient riderClient;
    late String testOrderId;
    late String cleanId;

    setUp(() {
      testOrderId = 'NX-CROSS-APP-${DateTime.now().millisecondsSinceEpoch}';
      cleanId = testOrderId.replaceAll('#', '').trim().toLowerCase();

      // Client simulating the Buyer APK (nexora_flutter_app)
      buyerClient = SupabaseClient(
        SupabaseConstants.url,
        SupabaseConstants.anonKey,
      );

      // Client simulating the Rider APK (nexora_rider_app)
      riderClient = SupabaseClient(
        SupabaseConstants.url,
        SupabaseConstants.anonKey,
      );
    });

    tearDown(() async {
      await buyerClient.dispose();
      await riderClient.dispose();
    });

    test('1. Backend Connectivity & Health Check: Both apps can reach shared Supabase instance', () async {
      expect(SupabaseConstants.url, isNotEmpty);
      expect(SupabaseConstants.anonKey, isNotEmpty);

      // Test database connectivity
      final response = await buyerClient
          .from('orders')
          .select('order_id')
          .limit(1);

      expect(response, isNotNull);
      print('✅ Both apps successfully connected to backend: ${SupabaseConstants.url}');
    });

    test('2. Bidirectional Live Chat Channel: Buyer and Rider exchange messages over WebSocket', () async {
      final channelName = 'rider_chat_$cleanId';
      final buyerReceivedCompleter = Completer<Map<String, dynamic>>();
      final riderReceivedCompleter = Completer<Map<String, dynamic>>();

      final buyerChannel = buyerClient.channel(channelName);
      final riderChannel = riderClient.channel(channelName);

      buyerChannel.onBroadcast(
        event: 'chat_message',
        callback: (payload) {
          if (!buyerReceivedCompleter.isCompleted) {
            buyerReceivedCompleter.complete(Map<String, dynamic>.from(payload));
          }
        },
      );

      riderChannel.onBroadcast(
        event: 'chat_message',
        callback: (payload) {
          if (!riderReceivedCompleter.isCompleted) {
            riderReceivedCompleter.complete(Map<String, dynamic>.from(payload));
          }
        },
      );

      final buyerSub = Completer<void>();
      final riderSub = Completer<void>();

      buyerChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed && !buyerSub.isCompleted) {
          buyerSub.complete();
        }
      });

      riderChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed && !riderSub.isCompleted) {
          riderSub.complete();
        }
      });

      await Future.wait([buyerSub.future, riderSub.future])
          .timeout(const Duration(seconds: 10));

      await Future.delayed(const Duration(milliseconds: 300));

      // Buyer sends message to Rider
      const buyerText = 'Hi Rider! Can you please ring the doorbell upon arrival?';
      await buyerChannel.sendBroadcastMessage(
        event: 'chat_message',
        payload: {
          'id': 'buyer_msg_001',
          'orderId': cleanId,
          'sender': 'customer',
          'senderName': 'Alex Rivera (Customer)',
          'text': buyerText,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final receivedByRider = await riderReceivedCompleter.future
          .timeout(const Duration(seconds: 8));
      expect(receivedByRider['text'], equals(buyerText));
      expect(receivedByRider['sender'], equals('customer'));
      print('✅ Rider App received message from Buyer App');

      // Rider replies to Buyer
      const riderReply = 'Understood! I am 5 minutes away with your parcel.';
      await riderChannel.sendBroadcastMessage(
        event: 'chat_message',
        payload: {
          'id': 'rider_msg_001',
          'orderId': cleanId,
          'sender': 'rider',
          'senderName': 'Pedro Jose Garcia (Courier)',
          'text': riderReply,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final receivedByBuyer = await buyerReceivedCompleter.future
          .timeout(const Duration(seconds: 8));
      expect(receivedByBuyer['text'], equals(riderReply));
      expect(receivedByBuyer['sender'], equals('rider'));
      print('✅ Buyer App received reply from Rider App');

      await buyerChannel.unsubscribe();
      await riderChannel.unsubscribe();
    });

    test('3. Real-Time GPS Tracking Telemetry: Rider broadcasts live location, Buyer receives update', () async {
      final trackingChannelName = 'rider_tracking_$cleanId';
      final buyerLocationCompleter = Completer<Map<String, dynamic>>();

      final buyerChannel = buyerClient.channel(trackingChannelName);
      final riderChannel = riderClient.channel(trackingChannelName);

      buyerChannel.onBroadcast(
        event: 'location_update',
        callback: (payload) {
          if (!buyerLocationCompleter.isCompleted) {
            buyerLocationCompleter.complete(Map<String, dynamic>.from(payload));
          }
        },
      );

      final buyerSub = Completer<void>();
      final riderSub = Completer<void>();

      buyerChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed && !buyerSub.isCompleted) {
          buyerSub.complete();
        }
      });

      riderChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed && !riderSub.isCompleted) {
          riderSub.complete();
        }
      });

      await Future.wait([buyerSub.future, riderSub.future])
          .timeout(const Duration(seconds: 10));

      await Future.delayed(const Duration(milliseconds: 300));

      // Rider broadcasts GPS position
      const liveLat = 14.2250;
      const liveLng = 121.1610;
      const liveSpeed = 42.5;

      await riderChannel.sendBroadcastMessage(
        event: 'location_update',
        payload: {
          'order_id': cleanId,
          'latitude': liveLat,
          'longitude': liveLng,
          'speed_kmh': liveSpeed,
          'status': 'in_transit',
          'bearing': 85.0,
          'eta_minutes': 7,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final locationReceived = await buyerLocationCompleter.future
          .timeout(const Duration(seconds: 8));

      expect(locationReceived['latitude'], equals(liveLat));
      expect(locationReceived['longitude'], equals(liveLng));
      expect(locationReceived['speed_kmh'], equals(liveSpeed));
      expect(locationReceived['status'], equals('in_transit'));
      print('✅ Buyer App successfully received real-time Rider GPS telemetry ($liveLat, $liveLng at $liveSpeed km/h)');

      await buyerChannel.unsubscribe();
      await riderChannel.unsubscribe();
    });

    test('4. Global Dispatch Notification Bus: Cross-app notifications for incoming messages', () async {
      const dispatchChannelName = 'rider_dispatch_chat';
      final riderDispatchCompleter = Completer<Map<String, dynamic>>();

      final buyerChannel = buyerClient.channel(dispatchChannelName);
      final riderChannel = riderClient.channel(dispatchChannelName);

      riderChannel.onBroadcast(
        event: 'new_customer_message',
        callback: (payload) {
          if (!riderDispatchCompleter.isCompleted) {
            riderDispatchCompleter.complete(Map<String, dynamic>.from(payload));
          }
        },
      );

      final buyerSub = Completer<void>();
      final riderSub = Completer<void>();

      buyerChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed && !buyerSub.isCompleted) {
          buyerSub.complete();
        }
      });

      riderChannel.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed && !riderSub.isCompleted) {
          riderSub.complete();
        }
      });

      await Future.wait([buyerSub.future, riderSub.future])
          .timeout(const Duration(seconds: 10));

      await Future.delayed(const Duration(milliseconds: 300));

      // Buyer notifies global dispatch channel
      await buyerChannel.sendBroadcastMessage(
        event: 'new_customer_message',
        payload: {
          'order_id': cleanId,
          'sender': 'customer',
          'sender_name': 'Alex Rivera',
          'text': 'I am waiting by the gate',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final dispatchNotice = await riderDispatchCompleter.future
          .timeout(const Duration(seconds: 8));

      expect(dispatchNotice['order_id'], equals(cleanId));
      expect(dispatchNotice['text'], equals('I am waiting by the gate'));
      print('✅ Global dispatch broadcast received across app boundaries');

      await buyerChannel.unsubscribe();
      await riderChannel.unsubscribe();
    });

    test('5. Database State Synchronization: Persistent order chat storage across both apps', () async {
      const dbOrderId = 'TEST-123';

      // 1. Rider writes message into Supabase orders table
      final initialFetch = await riderClient
          .from('orders')
          .select()
          .eq('order_id', dbOrderId)
          .single();

      final existingDetails = (initialFetch['item_details'] ?? '').toString();
      String baseTitle = 'Test Item';
      List<Map<String, dynamic>> chatList = [];

      if (existingDetails.startsWith('{') && existingDetails.endsWith('}')) {
        try {
          final parsed = jsonDecode(existingDetails) as Map<String, dynamic>;
          baseTitle = (parsed['title'] ?? 'Test Item').toString();
          if (parsed['chat'] is List) {
            chatList = (parsed['chat'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } catch (_) {}
      }

      final testRiderMsg = {
        'id': 'msg_sync_${DateTime.now().millisecondsSinceEpoch}',
        'orderId': dbOrderId,
        'sender': 'rider',
        'senderName': 'Pedro Jose Garcia',
        'text': 'Package ready for delivery',
        'timestamp': DateTime.now().toIso8601String(),
      };

      chatList.add(testRiderMsg);

      await riderClient
          .from('orders')
          .update({
            'item_details': jsonEncode({
              'title': baseTitle,
              'chat': chatList,
            }),
          })
          .eq('order_id', dbOrderId);

      // 2. Buyer reads from Supabase orders table
      final buyerFetch = await buyerClient
          .from('orders')
          .select('item_details')
          .eq('order_id', dbOrderId)
          .single();

      final buyerParsed = jsonDecode(buyerFetch['item_details']) as Map<String, dynamic>;
      final buyerChat = (buyerParsed['chat'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      expect(buyerChat.any((m) => m['id'] == testRiderMsg['id']), isTrue);
      print('✅ Database persistent synchronization verified: Buyer fetched Rider message from shared database');
    });
  });
}
