import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class ChatMessageModel {
  final String sender; // 'user' or 'other'
  final String text;
  final String time;

  ChatMessageModel({
    required this.sender,
    required this.text,
    required this.time,
  });

  factory ChatMessageModel.fromApiJson(Map<String, dynamic> json) {
    final isMine = json['is_mine'] == true || json['sender_type'] == 'buyer';
    return ChatMessageModel(
      sender: isMine ? 'user' : 'other',
      text: json['message'] as String? ?? '',
      time: json['created_at'] != null ? json['created_at'].toString().split(' ').last : 'Now',
    );
  }

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

  factory ChatConversationModel.fromApiJson(Map<String, dynamic> json) {
    final seller = json['seller'] as Map<String, dynamic>? ?? {};
    final storeName = seller['store_name'] as String? ?? 'Seller';
    final lastMsg = json['last_message'] as Map<String, dynamic>?;
    final lastMsgText = lastMsg?['message'] as String? ?? 'No messages yet';
    final timeStr = lastMsg?['created_at'] != null
        ? lastMsg!['created_at'].toString().split(' ').last
        : 'Now';

    return ChatConversationModel(
      id: json['id'].toString(),
      category: 'Sellers',
      title: storeName,
      subtitle: lastMsgText,
      brandTag: 'BRAND',
      time: timeStr,
      avatarIcon: Icons.storefront_rounded,
      avatarBg: const Color(0xFF0066FF),
      messages: [],
    );
  }
}

class ChatService extends ChangeNotifier {
  static final ChatService instance = ChatService._internal();

  ChatService._internal() {
    _initConversations();
  }

  /// Fetch buyer chat conversations from Laravel backend API
  Future<List<ChatConversationModel>> fetchConversationsRemote() async {
    if (!ApiClient.instance.hasToken) return conversations;
    try {
      final res = await ApiClient.instance.get(ApiConstants.buyerChat);
      final data = res['data'];
      final List list = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
      final parsed = list.map((c) => ChatConversationModel.fromApiJson(c as Map<String, dynamic>)).toList();
      if (parsed.isNotEmpty) {
        _conversations.removeWhere((c) => parsed.any((p) => p.id == c.id));
        _conversations.insertAll(0, parsed);
        notifyListeners();
      }
      return conversations;
    } catch (e) {
      debugPrint('fetchConversationsRemote error: $e');
      return conversations;
    }
  }

  /// Fetch messages for conversation from Laravel backend API
  Future<List<ChatMessageModel>> fetchMessagesRemote(String conversationId) async {
    final existing = getConversationById(conversationId)?.messages ?? [];
    if (!ApiClient.instance.hasToken) return existing;
    try {
      final res = await ApiClient.instance.get(ApiConstants.buyerChatConversation(conversationId));
      if (res['data'] is Map<String, dynamic>) {
        final messages = res['data']['messages'];
        if (messages is List) {
          final list = messages.map((m) => ChatMessageModel.fromApiJson(m as Map<String, dynamic>)).toList();
          final conv = getConversationById(conversationId);
          if (conv != null) {
            conv.messages.clear();
            conv.messages.addAll(list);
            notifyListeners();
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint('fetchMessagesRemote error: $e');
    }
    return getConversationById(conversationId)?.messages ?? [];
  }

  /// Start a chat with a seller on Laravel backend API
  Future<ChatConversationModel?> startConversationRemote(int sellerId) async {
    if (!ApiClient.instance.hasToken) return null;
    try {
      final res = await ApiClient.instance.post(
        ApiConstants.buyerChatStart,
        body: {'seller_id': sellerId},
      );
      if (res['data'] is Map<String, dynamic>) {
        final conv = ChatConversationModel.fromApiJson(res['data'] as Map<String, dynamic>);
        _conversations.removeWhere((c) => c.id == conv.id);
        _conversations.insert(0, conv);
        notifyListeners();
        return conv;
      }
    } catch (e) {
      debugPrint('startConversationRemote error: $e');
    }
    return null;
  }

  /// Send message in conversation via Laravel backend API
  Future<ChatMessageModel?> sendMessageRemote(String conversationId, String text) async {
    sendUserMessage(conversationId, text);
    if (!ApiClient.instance.hasToken) return null;
    try {
      final res = await ApiClient.instance.post(
        ApiConstants.buyerChatMessage(conversationId),
        body: {'message': text},
      );
      if (res['data'] is Map<String, dynamic>) {
        return ChatMessageModel.fromApiJson(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('sendMessageRemote error: $e');
    }
    return null;
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
