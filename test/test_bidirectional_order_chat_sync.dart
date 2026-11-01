// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test bidirectional chat sync via Supabase orders table', () async {
    // ignore: deprecated_member_use
    final client = SupabaseClient(
      SupabaseConstants.url,
      SupabaseConstants.anonKey,
    );

    const testOrderId = 'TEST-123';

    // 1. Fetch current order row
    final row = await client
        .from('orders')
        .select()
        .eq('order_id', testOrderId)
        .single();
    expect(row, isNotNull);

    // 2. Rider app sends message
    final riderMsg = {
      'id': 'msg_r_test_1',
      'orderId': testOrderId,
      'sender': 'rider',
      'senderName': 'Pedro Jose Garcia',
      'text': "I'm heading to the store now",
      'time': '4:55 AM',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Serialize messages inside item_details
    final existingDetails = (row['item_details'] ?? '').toString();
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

    chatList.removeWhere((m) => m['id'] == riderMsg['id']);
    chatList.add(riderMsg);

    final updatedDetails1 = jsonEncode({
      'title': baseTitle,
      'chat': chatList,
    });

    await client
        .from('orders')
        .update({'item_details': updatedDetails1})
        .eq('order_id', testOrderId);

    // 3. Buyer app loads messages (simulating opening Buyer APK 2 mins later)
    final buyerFetch = await client
        .from('orders')
        .select('item_details')
        .eq('order_id', testOrderId)
        .single();

    final buyerParsed = jsonDecode(buyerFetch['item_details']) as Map<String, dynamic>;
    final buyerChat = (buyerParsed['chat'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    expect(buyerChat.any((m) => m['text'] == "I'm heading to the store now"), isTrue);
    print('✅ Buyer successfully loaded Rider message sent earlier!');

    // 4. Buyer sends reply: "hi"
    final buyerMsg = {
      'id': 'msg_c_test_2',
      'orderId': testOrderId,
      'sender': 'customer',
      'senderName': 'Alex Rivera',
      'text': 'hi',
      'time': '4:57 AM',
      'timestamp': DateTime.now().toIso8601String(),
    };

    buyerChat.removeWhere((m) => m['id'] == buyerMsg['id']);
    buyerChat.add(buyerMsg);

    final updatedDetails2 = jsonEncode({
      'title': baseTitle,
      'chat': buyerChat,
    });

    await client
        .from('orders')
        .update({'item_details': updatedDetails2})
        .eq('order_id', testOrderId);

    // 5. Rider app resumes and pulls latest messages
    final riderFetch = await client
        .from('orders')
        .select('item_details')
        .eq('order_id', testOrderId)
        .single();

    final riderParsed = jsonDecode(riderFetch['item_details']) as Map<String, dynamic>;
    final riderChat = (riderParsed['chat'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    expect(riderChat.any((m) => m['text'] == 'hi'), isTrue);
    print('✅ Rider successfully loaded Buyer message upon resume!');

    await client.dispose();
  });
}
