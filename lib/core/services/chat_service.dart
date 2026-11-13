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

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'time': time,
    };
  }
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
  final String? avatarUrl;
  final List<ChatMessageModel> messages;
  bool isHidden;
  bool isDeleted;

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
    this.avatarUrl,
    required this.messages,
    this.isHidden = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'brandTag': brandTag,
      'itemTag': itemTag,
      'botTag': botTag,
      'resolvedTag': resolvedTag,
      'time': time,
      'unread': unread,
      'isDoubleCheck': isDoubleCheck,
      'isCheck': isCheck,
      'avatarIcon': avatarIcon,
      'avatarBg': avatarBg,
      'avatarUrl': avatarUrl ?? '',
      'isHidden': isHidden,
      'isDeleted': isDeleted,
      'initialMessages': messages.map((m) => m.toMap()).toList(),
    };
  }
}

class ChatService extends ChangeNotifier {
  static final ChatService instance = ChatService._internal();

  ChatService._internal() {
    _initConversations();
  }

  final List<ChatConversationModel> _conversations = [];

  List<ChatConversationModel> get conversations =>
      _conversations.where((c) => !c.isDeleted && !c.isHidden).toList();

  List<ChatConversationModel> get hiddenConversations =>
      _conversations.where((c) => !c.isDeleted && c.isHidden).toList();

  List<ChatConversationModel> get allConversations =>
      _conversations.where((c) => !c.isDeleted).toList();

  int get totalUnreadCount =>
      _conversations.where((c) => !c.isDeleted && !c.isHidden).fold(0, (sum, c) => sum + c.unread);

  void _initConversations() {
    // Initialized empty so it is clean and ready for live web / API integration
    _conversations.clear();
  }

  /// Removes any legacy mock conversations from memory (useful across hot reloads)
  void purgeMockConversations() {
    _conversations.removeWhere((c) =>
        c.id == 'nexora_store' ||
        c.id == 'aura_studios' ||
        c.id == 'ai_support' ||
        c.id == 'logitech_store');
    notifyListeners();
  }

  /// Hook for web/backend integration: set conversations fetched from the web server/API.
  void setConversations(List<ChatConversationModel> conversations) {
    _conversations.clear();
    _conversations.addAll(conversations);
    notifyListeners();
  }

  /// Clears all conversations for account sign-out or session resets.
  void clearConversations() {
    _conversations.clear();
    notifyListeners();
  }

  ChatConversationModel? getConversationById(String id) {
    try {
      return _conversations.firstWhere(
        (c) => c.id == id && !c.isDeleted,
      );
    } catch (_) {
      return null;
    }
  }

  void hideConversation(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      _conversations[index].isHidden = true;
      notifyListeners();
    }
  }

  void unhideConversation(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      _conversations[index].isHidden = false;
      notifyListeners();
    }
  }

  void deleteConversation(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      _conversations[index].isDeleted = true;
      notifyListeners();
    }
  }

  ChatConversationModel getOrCreateShopConversation({
    required String shopId,
    required String shopName,
    String? shopBadge,
    String? avatarUrl,
    Color? avatarBg,
    String? initialProductSnippet,
  }) {
    final normalizedId = shopId.toLowerCase().replaceAll(' ', '_');
    // Check if matching conversation already exists
    final index = _conversations.indexWhere(
      (c) =>
          c.id == shopId ||
          c.id == 'shop_$normalizedId' ||
          c.title.toLowerCase() == shopName.toLowerCase(),
    );

    if (index >= 0) {
      final existing = _conversations[index];
      // Restore if deleted or hidden
      existing.isHidden = false;
      existing.isDeleted = false;
      // If product snippet provided and not set, update tag
      if (initialProductSnippet != null && (existing.itemTag == null || existing.itemTag!.isEmpty)) {
        // We can keep it or leave existing
      }
      notifyListeners();
      return existing;
    }

    // Otherwise create brand new conversation
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    final welcomeMessage = ChatMessageModel(
      sender: 'other',
      text: 'Hello! Welcome to $shopName. How can we help you with your order or questions today?',
      time: timeStr,
    );

    final newConv = ChatConversationModel(
      id: 'shop_$normalizedId',
      category: 'Official Stores',
      title: shopName,
      subtitle: welcomeMessage.text,
      brandTag: (shopBadge == 'NEXORA MALL' || shopBadge == 'OFFICIAL STORE' || shopBadge == 'TOP SELLER')
          ? 'BRAND'
          : null,
      itemTag: initialProductSnippet,
      time: timeStr,
      unread: 0,
      avatarIcon: Icons.storefront_rounded,
      avatarBg: avatarBg ?? const Color(0xFF0075FF),
      avatarUrl: avatarUrl,
      messages: [welcomeMessage],
    );

    _conversations.insert(0, newConv);
    notifyListeners();
    return newConv;
  }

  void addSupportTicket({required String text}) {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    final id = 'ticket_${DateTime.now().millisecondsSinceEpoch}';
    final title = 'Support Ticket #${id.substring(7)}';

    final conv = ChatConversationModel(
      id: id,
      category: 'Support',
      title: title,
      subtitle: text,
      botTag: 'LIVE',
      time: timeStr,
      unread: 0,
      isDoubleCheck: true,
      avatarIcon: Icons.support_agent_rounded,
      avatarBg: const Color(0xFF0284C7),
      messages: [
        ChatMessageModel(
          sender: 'user',
          text: text,
          time: timeStr,
        ),
        ChatMessageModel(
          sender: 'other',
          text: 'Thank you for reaching out! A customer support representative has received your ticket.',
          time: timeStr,
        ),
      ],
    );

    _conversations.insert(0, conv);
    notifyListeners();
  }

  void markAsRead(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0 && _conversations[index].unread > 0) {
      _conversations[index].unread = 0;
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
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
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
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    if (index >= 0) {
      final conv = _conversations[index];
      conv.messages.add(ChatMessageModel(
        sender: 'user',
        text: text,
        time: timeStr,
      ));
      conv.subtitle = text;
      conv.time = timeStr;
      // Move conversation to top
      final updated = _conversations.removeAt(index);
      _conversations.insert(0, updated);
      notifyListeners();
    } else {
      // Create if needed
      _conversations.insert(
        0,
        ChatConversationModel(
          id: conversationId,
          category: 'Official Stores',
          title: 'Store',
          subtitle: text,
          time: timeStr,
          avatarIcon: Icons.storefront_rounded,
          avatarBg: const Color(0xFF0075FF),
          messages: [
            ChatMessageModel(
              sender: 'user',
              text: text,
              time: timeStr,
            ),
          ],
        ),
      );
      notifyListeners();
    }
  }
}
