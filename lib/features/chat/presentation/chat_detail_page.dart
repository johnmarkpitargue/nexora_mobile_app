import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/order_chat_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/profanity_filter_service.dart';
import '../../../core/services/in_app_notification_service.dart';

class ChatDetailPage extends StatefulWidget {
  final String? conversationId;
  final String? orderId;
  final String title;
  final String subtitle;
  final String avatarUrl;
  final IconData? avatarIcon;
  final Color avatarBgColor;
  final String orderRef;
  final List<Map<String, dynamic>> initialMessages;

  const ChatDetailPage({
    super.key,
    this.conversationId,
    this.orderId,
    required this.title,
    required this.subtitle,
    this.avatarUrl = '',
    this.avatarIcon,
    this.avatarBgColor = const Color(0xFF0284C7),
    this.orderRef = '',
    required this.initialMessages,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> with WidgetsBindingObserver {
  late List<Map<String, dynamic>> _messages;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  Map<String, dynamic>? _editingMessage;
  bool _isSimulatedTyping = false;
  bool _isCourierChat = false;
  String _effectiveOrderId = '';
  late String _effectiveTitle;
  Timer? _typingDebounce;
  bool _isLocallyTyping = false;

  String get _cleanTitle {
    final title = _effectiveTitle.isNotEmpty ? _effectiveTitle : widget.title;
    return title
        .replaceAll(RegExp(r'\s*\((Courier|Rider)\)', caseSensitive: false), '')
        .trim();
  }

  final List<String> _quickReplies = [
    'Where are you now?',
    'Please leave with front desk / guard',
    'I will meet you at the lobby',
    'Thank you so much!',
    'Exact cash is ready',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _effectiveOrderId = (widget.orderId != null && widget.orderId!.isNotEmpty)
        ? widget.orderId!.replaceAll('#', '').trim()
        : (widget.orderRef.isNotEmpty ? widget.orderRef.replaceAll('#', '').trim() : '');

    final rawTitle = widget.title
        .replaceAll(RegExp(r'\s*\((Courier|Rider)\)', caseSensitive: false), '')
        .trim();
    _effectiveTitle = rawTitle.contains('Mark Ronald')
        ? rawTitle.replaceAll('Mark Ronald', 'Pedro Jose Garcia')
        : rawTitle;

    final isCourierKeyword = widget.avatarIcon == Icons.two_wheeler_rounded ||
        widget.subtitle.toLowerCase().contains('courier') ||
        widget.subtitle.toLowerCase().contains('route') ||
        widget.subtitle.toLowerCase().contains('rider') ||
        widget.subtitle.toLowerCase().contains('delivery') ||
        widget.title.toLowerCase().contains('courier') ||
        widget.title.toLowerCase().contains('rider') ||
        widget.title.toLowerCase().contains('pedro') ||
        widget.title.toLowerCase().contains('mark') ||
        (widget.conversationId != null && widget.conversationId!.startsWith('courier_'));

    if (_effectiveOrderId.isEmpty && isCourierKeyword) {
      _effectiveOrderId = 'NX-8942-ORD';
    }

    _isCourierChat = _effectiveOrderId.isNotEmpty || isCourierKeyword;

    if (_isCourierChat) {
      _setupOrderChatListener();
      OrderChatService.instance.addListener(_onOrderChatServiceUpdated);
      _messageController.addListener(_onBuyerTextChanged);
    } else {
      if (widget.conversationId != null) {
        final conv = ChatService.instance.getConversationById(widget.conversationId!);
        if (conv != null && conv.messages.isNotEmpty) {
          _messages = conv.messages.map((m) => m.toMap()).toList();
          return;
        }
      }
      _messages = List.from(widget.initialMessages);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  void _setupOrderChatListener() {
    final cleanId = OrderChatService.instance.normalizeOrderId(_effectiveOrderId);
    OrderChatService.instance.subscribeToOrder(_effectiveOrderId);
    OrderChatService.instance.activeScreenOrderId = cleanId;
    OrderChatService.instance.markAsRead(_effectiveOrderId);
    OrderChatService.instance.syncRemoteMessages(_effectiveOrderId);

    final existing = OrderChatService.instance.getMessages(_effectiveOrderId);
    if (existing.isNotEmpty) {
      _messages = List.from(existing);
    } else {
      _messages = List.from(widget.initialMessages);
      for (final m in widget.initialMessages) {
        OrderChatService.instance.getMessages(_effectiveOrderId).add(Map<String, dynamic>.from(m));
      }
    }

    OrderChatService.instance.onNewMessageReceived = (msg) {
      if (!mounted) return;
      final cleanId = OrderChatService.instance.normalizeOrderId((msg['orderId'] ?? '').toString());
      final currentClean = OrderChatService.instance.normalizeOrderId(_effectiveOrderId);
      if (cleanId != currentClean) {
        final rawSender = (msg['senderName'] ?? 'Pedro Jose Garcia').toString();
        final sender = rawSender.contains('Mark') ? 'Pedro Jose Garcia' : rawSender;
        InAppNotificationService.instance.showNotification(
          senderName: sender,
          message: (msg['text'] ?? '').toString(),
          orderId: cleanId,
          icon: Icons.two_wheeler_rounded,
          accentColor: const Color(0xFF00B4D8),
          onReply: () {
            _switchToOrder(
              (msg['orderId'] ?? '').toString(),
              sender,
            );
          },
        );
      }
    };
  }

  void _switchToOrder(String newOrderId, [String? newSenderName]) {
    final clean = OrderChatService.instance.normalizeOrderId(newOrderId);
    if (clean == OrderChatService.instance.normalizeOrderId(_effectiveOrderId)) return;

    if (_isLocallyTyping) {
      OrderChatService.instance.sendTyping(_effectiveOrderId, false);
      _isLocallyTyping = false;
    }
    _typingDebounce?.cancel();

    setState(() {
      _effectiveOrderId = newOrderId.replaceAll('#', '').trim();
      if (newSenderName != null && newSenderName.isNotEmpty) {
        _effectiveTitle = newSenderName
            .replaceAll(RegExp(r'\s*\((Courier|Rider)\)', caseSensitive: false), '')
            .trim();
      }
    });

    _setupOrderChatListener();
    OrderChatService.instance.syncRemoteMessages(_effectiveOrderId);
    final updated = OrderChatService.instance.getMessages(_effectiveOrderId);
    setState(() {
      _messages = List.from(updated);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
  }

  void _showOrderSwitchModal() {
    final activeOrders = OrderService.instance.activeOrders;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Switch Courier Chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select an order to chat with its assigned courier',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              if (activeOrders.isEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0066FF),
                    child: Icon(Icons.two_wheeler_rounded, color: Colors.white),
                  ),
                  title: const Text('Default Courier (#NX-8942-ORD)'),
                  subtitle: const Text('Pedro Jose Garcia • Active on route'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _switchToOrder('NX-8942-ORD', 'Pedro Jose Garcia');
                  },
                )
              else
                ...activeOrders.map((o) {
                  final isCurrent = OrderChatService.instance.normalizeOrderId(o.orderId) ==
                      OrderChatService.instance.normalizeOrderId(_effectiveOrderId);
                  final unread = OrderChatService.instance.getUnreadCount(o.orderId);
                  final name = o.courierName.isNotEmpty ? o.courierName : 'Pedro Jose Garcia';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
                      child: Icon(
                        isCurrent ? Icons.check : Icons.two_wheeler_rounded,
                        color: isCurrent ? Colors.white : const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '$name (${o.orderId})',
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        color: isCurrent ? const Color(0xFF0066FF) : const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      '${o.items.isNotEmpty ? o.items.first.title : "Order Item"} • ${o.statusText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: unread > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _switchToOrder(o.orderId, name);
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _onOrderChatServiceUpdated() {
    if (!mounted || !_isCourierChat) return;
    final updated = OrderChatService.instance.getMessages(_effectiveOrderId);
    if (updated.isNotEmpty) {
      final lastRiderMsg = updated.lastWhere(
        (m) => m['sender'] == 'other' && (m['senderName'] as String?)?.isNotEmpty == true,
        orElse: () => {},
      );
      if (lastRiderMsg.isNotEmpty) {
        final name = (lastRiderMsg['senderName'] as String)
            .replaceAll(RegExp(r'\s*\((Courier|Rider)\)', caseSensitive: false), '')
            .trim();
        _effectiveTitle = name;
      }
    }
    setState(() {
      _messages = List.from(updated);
    });
    _scrollToBottom(animate: true);
  }

  void _onBuyerTextChanged() {
    if (!_isCourierChat) return;
    final text = _messageController.text;
    final isTypingNow = text.trim().isNotEmpty;

    if (isTypingNow != _isLocallyTyping) {
      _isLocallyTyping = isTypingNow;
      OrderChatService.instance.sendTyping(_effectiveOrderId, isTypingNow);
    }

    _typingDebounce?.cancel();
    if (isTypingNow) {
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        if (mounted && _isLocallyTyping) {
          _isLocallyTyping = false;
          OrderChatService.instance.sendTyping(_effectiveOrderId, false);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCourierChat) {
      OrderChatService.instance.syncRemoteMessages(_effectiveOrderId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingDebounce?.cancel();
    if (_isCourierChat) {
      if (_isLocallyTyping) {
        OrderChatService.instance.sendTyping(_effectiveOrderId, false);
      }
      OrderChatService.instance.activeScreenOrderId = null;
      OrderChatService.instance.removeListener(_onOrderChatServiceUpdated);
      _messageController.removeListener(_onBuyerTextChanged);
    }
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

  void _pickAttachment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Upload Photo or File (Max 5MB)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0075FF)),
                ),
                title: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Take a photo to send to rider', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleImagePick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF9333EA)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Select photo or screenshot (up to 5MB)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleImagePick(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;
      const int max5Mb = 5 * 1024 * 1024; // 5MB

      if (fileSize > max5Mb) {
        if (!mounted) return;
        _showFileSizeLimitDialog(fileSize);
        return;
      }

      final base64Str = base64Encode(bytes);
      final fileName = file.name.isNotEmpty ? file.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final textToSend = _messageController.text.trim();

      if (_isCourierChat) {
        await OrderChatService.instance.sendMessage(
          _effectiveOrderId,
          textToSend,
          customerName: 'Alex Rivera',
          attachmentData: base64Str,
          attachmentName: fileName,
          attachmentSize: fileSize,
          attachmentType: 'image',
        );
      } else {
        setState(() {
          _messages.add({
            'sender': 'user',
            'text': textToSend,
            'time': _getCurrentTime(),
            'attachmentData': base64Str,
            'attachmentName': fileName,
            'attachmentSize': fileSize,
            'attachmentType': 'image',
          });
        });
      }

      _messageController.clear();
      _scrollToBottom(animate: true);
    } catch (e) {
      debugPrint('⚠️ Error picking image: $e');
    }
  }

  void _showFileSizeLimitDialog(int sizeBytes) {
    final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('File Exceeds 5MB Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'The selected file is $mb MB. In active order chat, uploads are restricted to a maximum of 5MB only.\n\nPlease select an image or file within 5.0 MB.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0075FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(String base64Str, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  base64Decode(base64Str),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final trimmed = text.trim();
    if (ProfanityFilterService.instance.hasProfanity(trimmed)) {
      _showProfanityAlert('Inappropriate language detected. Please maintain respectful and courteous communication.');
      return;
    }

    HapticFeedback.lightImpact();

    if (_isCourierChat) {
      // Real-time Supabase Broadcast communication with the rider
      OrderChatService.instance.sendMessage(_effectiveOrderId, trimmed);
      _messageController.clear();
      _isLocallyTyping = false;
      _typingDebounce?.cancel();
      _scrollToBottom(animate: true);
      return;
    }

    // Default fallback for shop and AI support conversations
    final userMessage = {
      'sender': 'user',
      'text': trimmed,
      'time': _getCurrentTime(),
    };

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isSimulatedTyping = true;
    });

    if (widget.conversationId != null) {
      ChatService.instance.sendUserMessage(widget.conversationId!, trimmed);
    }

    _scrollToBottom();

    // Simulate auto reply from support / store
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      String autoReplyText =
          'Hello! Thanks for messaging ${widget.title}. We have received your message and will assist you shortly.';
      if (widget.title.contains('AI Support') || widget.title.contains('Support')) {
        autoReplyText =
            'Thank you for reaching out to Nexora Support! Your query has been logged.';
      } else if (widget.title.contains('Official Store') ||
          widget.title.contains('Store') ||
          widget.title.contains('Studios')) {
        autoReplyText =
            'Hello! Thanks for contacting ${widget.title}. All items include verified warranty. How may we assist you today?';
      }

      setState(() {
        _isSimulatedTyping = false;
        _messages.add({
          'sender': 'other',
          'text': autoReplyText,
          'time': _getCurrentTime(),
        });
      });

      if (widget.conversationId != null) {
        ChatService.instance.receiveIncomingMessage(
          conversationId: widget.conversationId!,
          text: autoReplyText,
          senderName: widget.title,
        );
      }

      _scrollToBottom();
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isRiderTyping = _isCourierChat && OrderChatService.instance.isRiderTyping(_effectiveOrderId);
    final showTyping = _isCourierChat ? isRiderTyping : _isSimulatedTyping;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.avatarBgColor,
                    shape: BoxShape.circle,
                    image: widget.avatarUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.avatarUrl.isEmpty
                      ? Icon(
                          widget.avatarIcon ?? Icons.person,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _isCourierChat ? _showOrderSwitchModal : null,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanTitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isCourierChat
                              ? 'Order #${_effectiveOrderId.replaceAll('#', '').toUpperCase()} • Live'
                              : widget.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_isCourierChat) ...[
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 16,
                            color: Color(0xFF0075FF),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_isCourierChat)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0075FF)),
              tooltip: 'Switch Order',
              onPressed: _showOrderSwitchModal,
            ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Color(0xFF0075FF), size: 20),
            tooltip: 'Call Courier',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $_cleanTitle (+63 917 123 4567)...')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (showTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (showTyping && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ChatTypingIndicator(
                        senderName: _cleanTitle,
                        dotColor: const Color(0xFF0075FF),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];

                // Render system security notice pill
                if (msg['sender'] == 'system') {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF475569)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              msg['text'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final isUser = (msg['sender'] == 'user') || (msg['isMe'] == true);
                final isUnsent = msg['isUnsent'] == true;
                final isEdited = msg['isEdited'] == true;

                final rawSenderName = (msg['senderName'] as String?) ?? '';
                final senderName = rawSenderName.isNotEmpty
                    ? rawSenderName.replaceAll(RegExp(r'\s*\((Courier|Rider)\)', caseSensitive: false), '').trim()
                    : _cleanTitle;

                if (isUnsent) {
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_circle_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Text(
                            isUser ? 'You unsent a message' : 'This message was unsent',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final attachData = (msg['attachmentData'] ?? msg['attachment_data'])?.toString();
                final attachName = (msg['attachmentName'] ?? msg['attachment_name'])?.toString();
                final attachSize = (msg['attachmentSize'] ?? msg['attachment_size']) as int?;
                final attachType = (msg['attachmentType'] ?? msg['attachment_type'])?.toString() ?? 'image';
                final isImage = attachType == 'image' ||
                    attachName?.endsWith('.jpg') == true ||
                    attachName?.endsWith('.jpeg') == true ||
                    attachName?.endsWith('.png') == true ||
                    attachName?.endsWith('.webp') == true ||
                    (attachData != null && attachData.startsWith('data:image'));

                String formatSize(int? bytes) {
                  if (bytes == null || bytes == 0) return '';
                  final kb = bytes / 1024;
                  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
                  final mb = kb / 1024;
                  return '${mb.toStringAsFixed(2)} MB';
                }

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: isUser ? () => _showMessageOptions(msg) : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF0075FF) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isUser && senderName.isNotEmpty) ...[
                            Text(
                              senderName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0075FF),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (attachData != null && attachData.isNotEmpty) ...[
                            if (isImage)
                              GestureDetector(
                                onTap: () => _openImageViewer(attachData, attachName ?? 'Photo'),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Image.memory(
                                          base64Decode(attachData),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                          ),
                                        ),
                                        if (attachSize != null && attachSize > 0)
                                          Container(
                                            margin: const EdgeInsets.all(6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.65),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              formatSize(attachSize),
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isUser ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.insert_drive_file_rounded, size: 24, color: isUser ? Colors.white : const Color(0xFF0075FF)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            attachName ?? 'File Attachment',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isUser ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (attachSize != null)
                                            Text(
                                              formatSize(attachSize),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isUser ? Colors.white70 : const Color(0xFF64748B),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          if ((msg['text'] ?? '').toString().isNotEmpty)
                            Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isUser ? Colors.white : const Color(0xFF0F172A),
                                height: 1.35,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg['time'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUser
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : Colors.grey.shade500,
                                ),
                              ),
                              if (isEdited) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(edited)',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontStyle: FontStyle.italic,
                                    color: isUser
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : const Color(0xFF0284C7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (isUser) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),


          // Quick Replies Carousel
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: _quickReplies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      reply,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => _sendMessage(reply),
                  ),
                );
              }).toList(),
            ),
          ),

          // Messenger-Style Editing Message Banner
          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F9FF),
                border: Border(
                  top: BorderSide(color: Color(0xFFBAE6FD)),
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Editing message',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _editingMessage!['text'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Cancel Edit',
                    onPressed: _cancelEditingMessage,
                  ),
                ],
              ),
            ),

          // Bottom Input Bar wrapped in SafeArea for Android system nav
          SafeArea(
            top: false,
            bottom: true,
            child: Container(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded,
                        color: Color(0xFF0075FF), size: 24),
                    tooltip: 'Send Photo / File (Max 5MB)',
                    onPressed: _pickAttachment,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: InputDecoration(
                          hintText: _editingMessage != null
                              ? 'Edit your message...'
                              : (_isCourierChat
                                  ? 'Message $_cleanTitle...'
                                  : 'Type a message...'),
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) {
                          if (_editingMessage != null) {
                            _submitEditMessage();
                          } else {
                            _sendMessage(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_editingMessage != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0075FF),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        tooltip: 'Save Edit',
                        onPressed: _submitEditMessage,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Color(0xFF0075FF), size: 22),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startEditingMessage(Map<String, dynamic> msg) {
    setState(() {
      _editingMessage = msg;
      _messageController.text = (msg['text'] ?? '').toString();
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _messageFocusNode.requestFocus();
    });
  }

  void _cancelEditingMessage() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
    _messageFocusNode.unfocus();
  }

  void _submitEditMessage() {
    if (_editingMessage == null) return;
    final newText = _messageController.text.trim();
    if (newText.isEmpty) return;

    if (ProfanityFilterService.instance.hasProfanity(newText)) {
      _showProfanityAlert('Inappropriate language detected. Please maintain respectful and courteous communication.');
      return;
    }

    HapticFeedback.lightImpact();
    final msgId = (_editingMessage!['id'] ?? '').toString();

    if (_isCourierChat) {
      OrderChatService.instance.editMessage(_effectiveOrderId, msgId, newText);
    } else {
      final idx = _messages.indexWhere((m) => m['id'] == msgId);
      if (idx != -1) {
        setState(() {
          _messages[idx]['text'] = newText;
          _messages[idx]['isEdited'] = true;
          _messages[idx]['editedAt'] = DateTime.now().toIso8601String();
        });
      }
    }

    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
    _messageFocusNode.unfocus();
  }

  void _showMessageOptions(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true || msg['sender'] == 'user';
    final isUnsent = msg['isUnsent'] == true;
    if (isUnsent) return;

    final canEdit = isMe && OrderChatService.instance.canEditMessage(msg);
    final remainingMinutes = OrderChatService.instance.getRemainingEditMinutes(msg);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Message Options',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 8),
              if (isMe) ...[
                ListTile(
                  leading: Icon(
                    Icons.edit_rounded,
                    color: canEdit ? const Color(0xFF0075FF) : Colors.grey.shade400,
                  ),
                  title: Text(
                    'Edit Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: canEdit ? const Color(0xFF0F172A) : Colors.grey.shade400,
                    ),
                  ),
                  subtitle: Text(
                    canEdit
                        ? '$remainingMinutes min left to edit (< 10 min window)'
                        : 'Edit window expired (can only edit within 10 mins)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: canEdit ? const Color(0xFF0284C7) : Colors.grey.shade400,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (canEdit) {
                      _startEditingMessage(msg);
                    } else {
                      _showProfanityAlert('Messages can only be edited within 10 minutes of sending.');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.undo_rounded, color: Color(0xFFEF4444)),
                  title: const Text(
                    'Unsend Message',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                  ),
                  subtitle: const Text(
                    'Removes message for everyone in this chat',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmUnsend(msg);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Color(0xFF64748B)),
                title: const Text('Copy Text', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Text copied to clipboard'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmUnsend(Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.undo_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Unsend Message?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Are you sure you want to unsend this message? It will be removed for everyone in the conversation.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final msgId = (msg['id'] ?? '').toString();
              if (_isCourierChat) {
                OrderChatService.instance.unsendMessage(_effectiveOrderId, msgId);
              } else {
                setState(() {
                  msg['text'] = 'You unsent a message';
                  msg['isUnsent'] = true;
                });
              }
            },
            child: const Text('Unsend'),
          ),
        ],
      ),
    );
  }

  void _showProfanityAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 26),
            SizedBox(width: 8),
            Text('Warning', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}

class ChatTypingIndicator extends StatefulWidget {
  final String senderName;
  final Color dotColor;
  final Widget? leadingAvatar;

  const ChatTypingIndicator({
    super.key,
    required this.senderName,
    this.dotColor = const Color(0xFF0075FF),
    this.leadingAvatar,
  });

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildBouncingDot(int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final delay = index * 0.18;
        final t = (_animController.value - delay) % 1.0;
        final wave = math.sin(t * 2 * math.pi);
        final offsetY = wave < 0 ? wave * 4.5 : 0.0;
        final scale = 0.85 + (0.25 * ((wave + 1) / 2));
        final opacity = 0.4 + (0.6 * ((wave + 1) / 2));

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity.clamp(0.35, 1.0),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: widget.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.leadingAvatar != null) ...[
            widget.leadingAvatar!,
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.senderName.isNotEmpty) ...[
                  Text(
                    '${widget.senderName} is typing',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBouncingDot(0),
                    _buildBouncingDot(1),
                    _buildBouncingDot(2),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
