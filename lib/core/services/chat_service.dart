import 'package:flutter/material.dart';

class ChatMessageModel {
  final String sender; // 'user' or 'other'
  final String text;
  final String time;

  ChatMessageModel({
    required this.sender,
    required this.text,
    required this.time,
  });
}

class ChatConversationModel {
  final String id;
  final String category;
  final String title;
  String subtitle;
  final String? brandTag;
  final String? itemTag;
  final String? botTag;
  final String? resolvedTag;
  String time;
  int unread;
  final bool isDoubleCheck;
  final bool isCheck;
  final IconData avatarIcon;
  final Color avatarBg;
  final List<ChatMessageModel> messages;

  ChatConversationModel({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    this.brandTag,
    this.itemTag,
    this.botTag,
    this.resolvedTag,
    required this.time,
    this.unread = 0,
    this.isDoubleCheck = false,
    this.isCheck = false,
    required this.avatarIcon,
    required this.avatarBg,
    required this.messages,
  });
}

class ChatService extends ChangeNotifier {
  static final ChatService instance = ChatService._internal();

  ChatService._internal() {
    _initConversations();
  }

  final List<ChatConversationModel> _conversations = [];

  List<ChatConversationModel> get conversations => List.unmodifiable(_conversations);

  int get totalUnreadCount => _conversations.fold(0, (sum, c) => sum + c.unread);

  void _initConversations() {
    _conversations.addAll([
      ChatConversationModel(
        id: 'nexora_store',
        category: 'Official Stores',
        title: 'Nexora Official Store',
        subtitle: 'Your warranty for Nexora Studio Pro W...',
        brandTag: 'BRAND',
        itemTag: '🎧 Nexora Studio Pro',
        time: '2:10 PM',
        unread: 0,
        isDoubleCheck: true,
        avatarIcon: Icons.verified_user_rounded,
        avatarBg: const Color(0xFF0075FF),
        messages: [
          ChatMessageModel(
            sender: 'other',
            text: 'Hello Alex! Thank you for purchasing Nexora Studio Pro Wireless.',
            time: '2:00 PM',
          ),
          ChatMessageModel(
            sender: 'other',
            text: 'Your warranty for Nexora Studio Pro Wireless is now active for 1 year.',
            time: '2:10 PM',
          ),
        ],
      ),
      ChatConversationModel(
        id: 'aura_studios',
        category: 'Official Stores',
        title: 'Aura Studios Official',
        subtitle: 'Hi Alex! The Warm Stone Hoodie in Siz...',
        itemTag: '👗 Stone Hoodie (L)',
        time: 'Yesterday',
        unread: 0,
        isCheck: true,
        avatarIcon: Icons.checkroom_rounded,
        avatarBg: const Color(0xFFFCA5A5),
        messages: [
          ChatMessageModel(
            sender: 'user',
            text: 'Hi, is the Warm Stone Hoodie in Size L in stock?',
            time: 'Yesterday 4:30 PM',
          ),
          ChatMessageModel(
            sender: 'other',
            text: 'Hi Alex! The Warm Stone Hoodie in Size L has been dispatched with your order!',
            time: 'Yesterday 4:35 PM',
          ),
        ],
      ),
      ChatConversationModel(
        id: 'ai_support',
        category: 'Support',
        title: 'Nexora AI Support',
        subtitle: 'Ticket #SUP-4491 closed: Refund for...',
        botTag: 'BOT',
        resolvedTag: 'Case Resolved',
        time: 'Nov 15',
        unread: 0,
        avatarIcon: Icons.smart_toy_rounded,
        avatarBg: const Color(0xFF00B4D8),
        messages: [
          ChatMessageModel(
            sender: 'other',
            text: 'Ticket #SUP-4491 closed: Refund for item process completed.',
            time: 'Nov 15 10:00 AM',
          ),
        ],
      ),
      ChatConversationModel(
        id: 'logitech_store',
        category: 'Official Stores',
        title: 'LogiTech Hub Store',
        subtitle: 'Thanks for purchasing with us! Let us k...',
        itemTag: 'MX Mechanical Mini',
        time: 'Nov 05',
        unread: 0,
        isCheck: true,
        avatarIcon: Icons.keyboard_rounded,
        avatarBg: const Color(0xFF94A3B8),
        messages: [
          ChatMessageModel(
            sender: 'other',
            text: 'Thanks for purchasing with us! Let us know if you need driver software setup.',
            time: 'Nov 05 3:20 PM',
          ),
        ],
      ),
    ]);
  }

  void markAsRead(String conversationId) {
    final conv = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => _conversations.first,
    );
    if (conv.unread > 0) {
      conv.unread = 0;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool hasUnread = false;
    for (final c in _conversations) {
      if (c.unread > 0) {
        c.unread = 0;
        hasUnread = true;
      }
    }
    if (hasUnread) notifyListeners();
  }

  void receiveIncomingMessage({
    required String conversationId,
    required String text,
    String? senderName,
  }) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    if (index >= 0) {
      final conv = _conversations[index];
      conv.messages.add(ChatMessageModel(
        sender: 'other',
        text: text,
        time: timeStr,
      ));
      conv.subtitle = text;
      conv.time = timeStr;
      conv.unread += 1;
      // Move conversation to top
      final updated = _conversations.removeAt(index);
      _conversations.insert(0, updated);
      notifyListeners();
    } else {
      // Create new conversation
      _conversations.insert(
        0,
        ChatConversationModel(
          id: conversationId,
          category: 'Official Stores',
          title: senderName ?? 'Store Support',
          subtitle: text,
          time: timeStr,
          unread: 1,
          avatarIcon: Icons.storefront_rounded,
          avatarBg: const Color(0xFF00C1D4),
          messages: [
            ChatMessageModel(
              sender: 'other',
              text: text,
              time: timeStr,
            ),
          ],
        ),
      );
      notifyListeners();
    }
  }

  void sendUserMessage(String conversationId, String text) {
    final conv = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => _conversations.first,
    );
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    conv.messages.add(ChatMessageModel(
      sender: 'user',
      text: text,
      time: timeStr,
    ));
    conv.subtitle = text;
    conv.time = timeStr;
    notifyListeners();
  }
}
