// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Two separate Supabase Realtime clients can exchange chat messages bidirectionally', () async {
    const testOrderId = 'test_two_clients_sync';
    final channelName = 'rider_chat_$testOrderId';

    // ignore: deprecated_member_use
    final buyerClient = SupabaseClient(
      SupabaseConstants.url,
      SupabaseConstants.anonKey,
    );

    // ignore: deprecated_member_use
    final riderClient = SupabaseClient(
      SupabaseConstants.url,
      SupabaseConstants.anonKey,
    );

    final buyerReceivedCompleter = Completer<Map<String, dynamic>>();
    final riderReceivedCompleter = Completer<Map<String, dynamic>>();

    final buyerChannel = buyerClient.channel(channelName);
    final riderChannel = riderClient.channel(channelName);

    buyerChannel.onBroadcast(
      event: 'chat_message',
      callback: (payload) {
        if (!buyerReceivedCompleter.isCompleted) {
          buyerReceivedCompleter.complete(payload);
        }
      },
    );

    riderChannel.onBroadcast(
      event: 'chat_message',
      callback: (payload) {
        if (!riderReceivedCompleter.isCompleted) {
          riderReceivedCompleter.complete(payload);
        }
      },
    );

    final buyerSubscribed = Completer<bool>();
    final riderSubscribed = Completer<bool>();

    buyerChannel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed && !buyerSubscribed.isCompleted) {
        buyerSubscribed.complete(true);
      }
    });

    riderChannel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed && !riderSubscribed.isCompleted) {
        riderSubscribed.complete(true);
      }
    });

    await Future.wait([buyerSubscribed.future, riderSubscribed.future])
        .timeout(const Duration(seconds: 15));

    // Buyer sends to Rider
    await buyerChannel.sendBroadcastMessage(
      event: 'chat_message',
      payload: {
        'id': 'buyer-msg-1',
        'orderId': testOrderId,
        'senderId': 'buyer_test',
        'senderName': 'Buyer Customer',
        'text': 'Hello Rider, please leave at door',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    final riderReceived = await riderReceivedCompleter.future
        .timeout(const Duration(seconds: 10));
    expect(riderReceived['text'], equals('Hello Rider, please leave at door'));

    // Rider sends reply to Buyer
    await riderChannel.sendBroadcastMessage(
      event: 'chat_message',
      payload: {
        'id': 'rider-msg-1',
        'orderId': testOrderId,
        'senderId': 'rider_test',
        'senderName': 'Rider Courier',
        'text': 'Got it! On my way.',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    final buyerReceived = await buyerReceivedCompleter.future
        .timeout(const Duration(seconds: 10));
    expect(buyerReceived['text'], equals('Got it! On my way.'));

    // Cleanup resources
    await buyerChannel.unsubscribe();
    await riderChannel.unsubscribe();
    await buyerClient.dispose();
    await riderClient.dispose();
  });
}
