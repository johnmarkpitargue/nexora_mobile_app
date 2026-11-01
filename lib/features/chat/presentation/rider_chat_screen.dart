import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/profanity_filter_service.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../courier/services/courier_service.dart';

class RiderChatScreen extends StatefulWidget {
  final String orderId;
  final String customerName;

  const RiderChatScreen({
    super.key,
    required this.orderId,
    required this.customerName,
  });

  @override
  State<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends State<RiderChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  RiderChatMessage? _editingMessage;
  Timer? _typingDebounce;
  bool _isLocallyTyping = false;
  late String _currentOrderId;
  late String _currentCustomerName;

  final List<String> _quickReplies = [
    "I'm heading to the store now",
    "Waiting for store to pack items",
    "On my way to your location!",
    "I have arrived at your building lobby",
    "Please prepare exact COD cash amount",
    "I am outside your gate / entrance",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentOrderId = widget.orderId.replaceAll('#', '').trim();
    _currentCustomerName = widget.customerName;

    _setupChatListener();
    _controller.addListener(_onTextChanged);
    RiderChatService.instance.syncRemoteMessages(_currentOrderId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      RiderChatService.instance.syncRemoteMessages(_currentOrderId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingDebounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_isLocallyTyping) {
      RiderChatService.instance.sendTyping(_currentOrderId, false);
    }
    RiderChatService.instance.activeScreenOrderId = null;
    RiderChatService.instance.onNewMessageReceived = null;
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupChatListener() {
    final cleanId = RiderChatService.instance.normalizeOrderId(_currentOrderId);
    RiderChatService.instance.subscribeToOrder(
      _currentOrderId,
      customerName: _currentCustomerName,
    );
    RiderChatService.instance.activeScreenOrderId = cleanId;
    RiderChatService.instance.markAsRead(_currentOrderId);

    RiderChatService.instance.onNewMessageReceived = (msg) {
      if (!mounted) return;
      final msgClean = RiderChatService.instance.normalizeOrderId(msg.orderId);
      final activeClean = RiderChatService.instance.normalizeOrderId(_currentOrderId);
      if (msgClean != activeClean) {
        InAppNotificationService.instance.showNotification(
          senderName: msg.senderName.isNotEmpty ? msg.senderName : 'Customer',
          message: msg.text,
          orderId: msgClean,
          icon: Icons.person_pin_circle_rounded,
          accentColor: const Color(0xFF0066FF),
          onReply: () => _switchToOrder(msg.orderId, msg.senderName),
        );
      }
    };
  }

  void _switchToOrder(String newOrderId, [String? newCustomerName]) {
    final clean = RiderChatService.instance.normalizeOrderId(newOrderId);
    if (clean == RiderChatService.instance.normalizeOrderId(_currentOrderId)) return;

    if (_isLocallyTyping) {
      RiderChatService.instance.sendTyping(_currentOrderId, false);
      _isLocallyTyping = false;
    }
    _typingDebounce?.cancel();

    setState(() {
      _currentOrderId = newOrderId.replaceAll('#', '').trim();
      if (newCustomerName != null && newCustomerName.isNotEmpty) {
        _currentCustomerName = newCustomerName;
      }
    });

    _setupChatListener();
    RiderChatService.instance.syncRemoteMessages(_currentOrderId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  void _onTextChanged() {
    final text = _controller.text;
    final isTypingNow = text.trim().isNotEmpty;

    if (isTypingNow != _isLocallyTyping) {
      _isLocallyTyping = isTypingNow;
      RiderChatService.instance.sendTyping(_currentOrderId, isTypingNow);
    }

    _typingDebounce?.cancel();
    if (isTypingNow) {
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        if (mounted && _isLocallyTyping) {
          _isLocallyTyping = false;
          RiderChatService.instance.sendTyping(_currentOrderId, false);
        }
      });
    }
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (ProfanityFilterService.instance.hasProfanity(text)) {
      _showProfanityAlert('Inappropriate language detected. Please maintain professional and respectful communication on Nexora.');
      return;
    }

    HapticFeedback.lightImpact();
    RiderChatService.instance.sendMessage(
      _currentOrderId,
      text,
      customerName: _currentCustomerName,
    );
    _controller.clear();
    _isLocallyTyping = false;
    _typingDebounce?.cancel();

    _scrollToBottom(animate: true);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
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
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0066FF)),
                ),
                title: const Text('Take Photo (Camera)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Snap parcel, landmark, or gate photo', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                subtitle: const Text('Select existing picture (up to 5MB)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
      final textToSend = _controller.text.trim();

      await RiderChatService.instance.sendMessage(
        _currentOrderId,
        textToSend,
        customerName: _currentCustomerName,
        attachmentData: base64Str,
        attachmentName: fileName,
        attachmentSize: fileSize,
        attachmentType: 'image',
      );

      _controller.clear();
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
              backgroundColor: RiderTheme.primary,
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

  void _showOrderSwitchModal() {
    final active = DeliveryService.instance.activeOrder;
    final available = DeliveryService.instance.availableOrders;
    final allOrders = <DeliveryOrder>[
      ?active,
      ...available,
    ];
    final seenIds = <String>{
      for (final o in allOrders) RiderChatService.instance.normalizeOrderId(o.id),
    };
    for (final p in CourierService.instance.parcels) {
      final norm = RiderChatService.instance.normalizeOrderId(p.id);
      if (!seenIds.contains(norm)) {
        seenIds.add(norm);
        allOrders.add(CourierService.instance.toDeliveryOrder(p));
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.72,
          ),
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
                  'Switch Order / Parcel Chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: RiderTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select an active rider order or courier parcel to chat with the buyer',
                  style: TextStyle(fontSize: 13, color: RiderTheme.textMuted),
                ),
                const SizedBox(height: 14),
                if (allOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No orders found')),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: allOrders.map((o) {
                        final isCurrent = RiderChatService.instance.normalizeOrderId(o.id) ==
                            RiderChatService.instance.normalizeOrderId(_currentOrderId);
                        final unread = RiderChatService.instance.getUnreadCount(o.id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isCurrent ? RiderTheme.primary : const Color(0xFFF1F5F9),
                            child: Icon(
                              isCurrent ? Icons.check : Icons.receipt_long_rounded,
                              color: isCurrent ? Colors.white : RiderTheme.textDark,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '${o.customerName} (${o.id})',
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: isCurrent ? RiderTheme.primary : RiderTheme.textDark,
                            ),
                          ),
                          subtitle: Text(
                            '${o.items.isNotEmpty ? o.items.first.name : "Order Item"} • ${o.status.name.toUpperCase()}',
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
                            _switchToOrder(o.id, o.customerName);
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCallModal() {
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
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0066FF), size: 36),
              const SizedBox(height: 12),
              Text(
                'Call ${widget.customerName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'VoIP numbers are masked for data privacy. Calls are free of cellular charge over mobile data / Wi-Fi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📞 Connecting secure VoIP call to ${widget.customerName}...'),
                        backgroundColor: const Color(0xFF0066FF),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Connect Masked Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RiderTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: RiderTheme.primaryContainer,
                  child: Text(
                    _currentCustomerName.isNotEmpty ? _currentCustomerName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: RiderTheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
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
                onTap: _showOrderSwitchModal,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentCustomerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: RiderTheme.textDark,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Order $_currentOrderId • Live',
                          style: const TextStyle(
                            fontSize: 11,
                            color: RiderTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: RiderTheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: RiderTheme.primary),
            tooltip: 'Switch Order',
            onPressed: _showOrderSwitchModal,
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: RiderTheme.primary),
            tooltip: 'Call Customer',
            onPressed: _showCallModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: AnimatedBuilder(
              animation: RiderChatService.instance,
              builder: (context, _) {
                final messages = RiderChatService.instance.getMessages(
                  _currentOrderId,
                  customerName: _currentCustomerName,
                );
                final isTyping = RiderChatService.instance.isCustomerTyping(_currentOrderId);

                // Auto scroll if new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients &&
                      _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 140) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: RiderTheme.primaryContainer.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: RiderTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Direct Chat with $_currentCustomerName',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: RiderTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Real-time messages sent here are delivered instantly to the customer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: RiderTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isTyping && index == messages.length) {
                      return _buildTypingIndicator();
                    }

                    final msg = messages[index];

                    // System notice pill
                    if (msg.sender == 'system') {
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
                                  msg.text,
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

                    final isMe = msg.isMe;
                    final isUnsent = msg.isUnsent;
                    final isEdited = msg.isEdited;

                    if (isUnsent) {
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                                isMe ? 'You unsent a message' : 'This message was unsent',
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

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isMe ? () => _showMessageOptions(msg) : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? RiderTheme.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
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
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe && msg.senderName.isNotEmpty) ...[
                                Text(
                                  msg.senderName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: RiderTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              if (msg.hasAttachment) ...[
                                if (msg.isImageAttachment)
                                  GestureDetector(
                                    onTap: () => _openImageViewer(msg.attachmentData!, msg.attachmentName ?? 'Photo'),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            Image.memory(
                                              base64Decode(msg.attachmentData!),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) => const Center(
                                                child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                              ),
                                            ),
                                            if (msg.formattedAttachmentSize.isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.all(6),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.65),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  msg.formattedAttachmentSize,
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
                                      color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.insert_drive_file_rounded, size: 24, color: isMe ? Colors.white : const Color(0xFF0066FF)),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                msg.attachmentName ?? 'File Attachment',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isMe ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (msg.formattedAttachmentSize.isNotEmpty)
                                                Text(
                                                  msg.formattedAttachmentSize,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isMe ? Colors.white70 : const Color(0xFF64748B),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              if (msg.text.isNotEmpty)
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isMe ? Colors.white : RiderTheme.textDark,
                                    height: 1.35,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    msg.formattedTime,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white.withValues(alpha: 0.75) : RiderTheme.textMuted,
                                    ),
                                  ),
                                  if (isEdited) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(edited)',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: isMe ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF0066FF),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all_rounded,
                                      size: 13,
                                      color: Colors.white.withValues(alpha: 0.85),
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
                );
              },
            ),
          ),

          // Quick Reply Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ActionChip(
                  label: Text(
                    _quickReplies[i],
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: RiderTheme.primary,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: RiderTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => _sendMessage(_quickReplies[i]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

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
                      color: RiderTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, size: 14, color: RiderTheme.primary),
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
                            color: RiderTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _editingMessage!.text,
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
                left: 14,
                right: 14,
                top: 8,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: RiderTheme.cardBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded,
                        color: Color(0xFF0066FF), size: 24),
                    tooltip: 'Send Photo / File (Max 5MB)',
                    onPressed: _pickAttachment,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: RiderTheme.cardBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (_editingMessage != null) {
                            _submitEditMessage();
                          } else {
                            _sendMessage();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: _editingMessage != null
                              ? 'Edit your message...'
                              : 'Message $_currentCustomerName...',
                          hintStyle: const TextStyle(fontSize: 13, color: RiderTheme.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_editingMessage != null)
                    IconButton.filled(
                      onPressed: () => _submitEditMessage(),
                      icon: const Icon(Icons.check_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: RiderTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    IconButton.filled(
                      onPressed: () => _sendMessage(),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: RiderTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startEditingMessage(RiderChatMessage msg) {
    setState(() {
      _editingMessage = msg;
      _controller.text = msg.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _cancelEditingMessage() {
    setState(() {
      _editingMessage = null;
      _controller.clear();
    });
    _focusNode.unfocus();
  }

  void _submitEditMessage() {
    if (_editingMessage == null) return;
    final newText = _controller.text.trim();
    if (newText.isEmpty) return;

    if (ProfanityFilterService.instance.hasProfanity(newText)) {
      _showProfanityAlert('Inappropriate language detected. Please maintain professional and respectful communication on Nexora.');
      return;
    }

    HapticFeedback.lightImpact();
    RiderChatService.instance.editMessage(_currentOrderId, _editingMessage!.id, newText);

    setState(() {
      _editingMessage = null;
      _controller.clear();
    });
    _focusNode.unfocus();
  }

  Widget _buildTypingIndicator() {
    return ChatTypingIndicator(
      senderName: _currentCustomerName,
      dotColor: RiderTheme.primary,
      leadingAvatar: CircleAvatar(
        radius: 14,
        backgroundColor: RiderTheme.primaryContainer,
        child: Text(
          _currentCustomerName.isNotEmpty ? _currentCustomerName[0].toUpperCase() : 'C',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: RiderTheme.primary,
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(RiderChatMessage msg) {
    if (msg.isUnsent) return;

    final canEdit = msg.canEdit;
    final remainingMinutes = msg.remainingEditMinutes;

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
              if (msg.isMe) ...[
                ListTile(
                  leading: Icon(
                    Icons.edit_rounded,
                    color: canEdit ? RiderTheme.primary : Colors.grey.shade400,
                  ),
                  title: Text(
                    'Edit Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: canEdit ? RiderTheme.textDark : Colors.grey.shade400,
                    ),
                  ),
                  subtitle: Text(
                    canEdit
                        ? '$remainingMinutes min left to edit (< 10 min window)'
                        : 'Edit window expired (can only edit within 10 mins)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: canEdit ? RiderTheme.primary : Colors.grey.shade400,
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
                  Clipboard.setData(ClipboardData(text: msg.text));
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

  void _confirmUnsend(RiderChatMessage msg) {
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
              RiderChatService.instance.unsendMessage(_currentOrderId, msg.id);
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
    this.dotColor = const Color(0xFF0066FF),
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
