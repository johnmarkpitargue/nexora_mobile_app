class RiderChatMessage {
  final String id;
  final String orderId;
  final String sender; // 'rider', 'customer', 'system'
  final String text;
  final DateTime time;
  final bool isMe;

  const RiderChatMessage({
    required this.id,
    required this.orderId,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
  });
}
