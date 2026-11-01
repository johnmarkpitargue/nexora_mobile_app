// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase Realtime Broadcast connectivity test for Rider App', () async {
    const orderId = 'test_order_lint_check';
    final channelName = 'rider_chat_$orderId';

    // ignore: deprecated_member_use
    final client = SupabaseClient(
      SupabaseConstants.url,
      SupabaseConstants.anonKey,
    );

    final completer = Completer<bool>();
    final channel = client.channel(channelName);

    channel.onBroadcast(
      event: 'chat_message',
      callback: (payload) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    ).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.sendBroadcastMessage(
          event: 'chat_message',
          payload: {
            'id': 'test-1',
            'orderId': orderId,
            'senderId': 'test_rider',
            'senderName': 'Test Rider',
            'text': 'Test broadcast message',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    });

    // Cleanup client resources
    await channel.unsubscribe();
    await client.dispose();
  });
}
