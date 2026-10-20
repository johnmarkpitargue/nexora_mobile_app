import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class RiderChatService extends ChangeNotifier {
  static final RiderChatService instance = RiderChatService._();
  RiderChatService._() {
    _initSampleMessages();
  }

  final Map<String, List<RiderChatMessage>> _orderChats = {};

  List<RiderChatMessage> getMessages(String orderId) {
    return _orderChats[orderId] ?? [];
  }

  void _initSampleMessages() {
    _orderChats['NX-8942-ORD'] = [
      RiderChatMessage(
        id: 'msg-1',
        orderId: 'NX-8942-ORD',
        sender: 'customer',
        text: 'Hi rider! Please let me know once you arrive at Lumina Tower.',
        time: DateTime.now().subtract(const Duration(minutes: 8)),
        isMe: false,
      ),
      RiderChatMessage(
        id: 'msg-2',
        orderId: 'NX-8942-ORD',
        sender: 'rider',
        text: 'Noted Alex! I am currently heading to the Nexora BGC store to pick up your items.',
        time: DateTime.now().subtract(const Duration(minutes: 6)),
        isMe: true,
      ),
      RiderChatMessage(
        id: 'msg-3',
        orderId: 'NX-8942-ORD',
        sender: 'customer',
        text: 'Awesome, thanks! Take care on the road.',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        isMe: false,
      ),
    ];
  }

  void sendMessage(String orderId, String text) {
    if (text.trim().isEmpty) return;

    final msg = RiderChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      sender: 'rider',
      text: text.trim(),
      time: DateTime.now(),
      isMe: true,
    );

    if (!_orderChats.containsKey(orderId)) {
      _orderChats[orderId] = [];
    }
    _orderChats[orderId]!.add(msg);
    notifyListeners();

    // Simulated quick customer response after 2 seconds
    if (text.toLowerCase().contains('arrived') || text.toLowerCase().contains('lobby')) {
      Future.delayed(const Duration(seconds: 2), () {
        final reply = RiderChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          orderId: orderId,
          sender: 'customer',
          text: 'Got it! Coming down to the lobby now with the security pass.',
          time: DateTime.now(),
          isMe: false,
        );
        _orderChats[orderId]?.add(reply);
        notifyListeners();
      });
    }
  }
}
