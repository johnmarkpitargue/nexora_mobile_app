import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/order_chat_service.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _allRead = false;

  @override
  void initState() {
    super.initState();
    ChatService.instance.addListener(_onChatServiceChanged);
    OrderChatService.instance.addListener(_onChatServiceChanged);
    final activeOrders = OrderService.instance.activeOrders;
    final orderId = activeOrders.isNotEmpty ? activeOrders.first.orderId : 'NX-8942-ORD';
    OrderChatService.instance.subscribeToOrder(orderId);
  }

  @override
  void dispose() {
    ChatService.instance.removeListener(_onChatServiceChanged);
    OrderChatService.instance.removeListener(_onChatServiceChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onChatServiceChanged() {
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> get _filters {
    final active = ChatService.instance.conversations;
    final hidden = ChatService.instance.hiddenConversations;
    final officialCount = active.where((c) => c.category == 'Official Stores').length;
    final supportCount = active.where((c) => c.category == 'Support').length;

    return [
      {'label': 'All Chats', 'count': active.length},
      {'label': 'Couriers', 'count': 1, 'dotColor': const Color(0xFF06B6D4)},
      {'label': 'Official Stores', 'count': officialCount},
      {'label': 'Support', 'count': supportCount},
      {'label': 'Hidden', 'count': hidden.length, 'icon': Icons.visibility_off_outlined},
    ];
  }

  void _markAllAsRead() {
    ChatService.instance.markAllAsRead();
    setState(() {
      _allRead = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All messages marked as read!'),
        backgroundColor: Color(0xFF0284C7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<ChatConversationModel> get _filteredConversations {
    final bool isHiddenTab = _selectedFilterIndex == 4;
    final sourceList = isHiddenTab
        ? ChatService.instance.hiddenConversations
        : ChatService.instance.conversations;

    return sourceList.where((item) {
      // Category filter
      if (!isHiddenTab) {
        if (_selectedFilterIndex == 1) {
          return false; // Couriers tab shows live dispatch card
        }
        if (_selectedFilterIndex == 2 && item.category != 'Official Stores') {
          return false;
        }
        if (_selectedFilterIndex == 3 && item.category != 'Support') {
          return false;
        }
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = item.title.toLowerCase();
        final subtitle = item.subtitle.toLowerCase();
        final itemTag = (item.itemTag ?? '').toLowerCase();
        return title.contains(query) || subtitle.contains(query) || itemTag.contains(query);
      }
      return true;
    }).toList();
  }

  void _hideConversation(ChatConversationModel chat) {
    ChatService.instance.hideConversation(chat.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conversation with "${chat.title}" hidden'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF00C1D4),
          onPressed: () {
            ChatService.instance.unhideConversation(chat.id);
          },
        ),
      ),
    );
  }

  void _unhideConversation(ChatConversationModel chat) {
    ChatService.instance.unhideConversation(chat.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conversation with "${chat.title}" restored'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDeleteConversation(ChatConversationModel chat) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Conversation?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your conversation with "${chat.title}"? This conversation and its messages will be permanently removed.',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ChatService.instance.deleteConversation(chat.id);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Conversation with "${chat.title}" deleted'),
                  backgroundColor: const Color(0xFF0F172A),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Top Navigation Bar (← Messages, Search, Filter, Settings)
                  _buildTopAppBar(context),
                  const SizedBox(height: 16),

                  // Title Bar & Read All Button
                  _buildTitleRow(),
                  const SizedBox(height: 14),

                  // Search Input Bar
                  _buildSearchBar(),
                  const SizedBox(height: 14),

                  // Category Filter Chips
                  _buildFilterPills(),
                  const SizedBox(height: 20),

                  // Live Dispatch Connected Card (Pedro Jose Garcia Courier)
                  if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
                    _buildLiveDispatchCard(context),
                    const SizedBox(height: 22),
                  ],

                  // Conversations List Section
                  if (_selectedFilterIndex != 1) ...[
                    _buildConversationsSection(context),
                    const SizedBox(height: 22),
                  ],

                  // Need Immediate Help? Card
                  _buildImmediateHelpCard(context),

                  // Clearance for bottom floating nav dock
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Row(
      children: [
        if (canPop) ...[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
        ],
        const Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            _searchFocusNode.requestFocus();
          },
          icon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF0F172A),
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        IconButton(
          onPressed: () {
            _showFilterOptionsModal(context);
          },
          icon: const Icon(
            Icons.tune_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        IconButton(
          onPressed: () {
            _showSettingsModal(context);
          },
          icon: const Icon(
            Icons.settings_outlined,
            color: Color(0xFF0F172A),
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  /// Subheader Title & Read All Pill Button
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Conversations',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Real-time driver updates and store inquiries',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ✓ Read All Button (Matching Screenshot light ice-blue background)
        InkWell(
          onTap: _markAllAsRead,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: _allRead ? Colors.grey.shade600 : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 3),
                Text(
                  'Read All',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _allRead ? Colors.grey.shade600 : const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Search Bar with outlined rounded pill layout
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search messages, orders, or stores...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade500,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: Colors.grey.shade600,
              size: 18,
            ),
            onPressed: () => _showFilterOptionsModal(context),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Filter Pills Matching Design (All Chats [4], Couriers [1], Official Stores [2], Support [1])
  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final filter = _filters[index];
          final isSelected = _selectedFilterIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0075FF) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0075FF)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (filter.containsKey('icon')) ...[
                      Icon(
                        filter['icon'] as IconData,
                        size: 14,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                    ] else if (filter.containsKey('dotColor') && !isSelected) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: filter['dotColor'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      filter['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filter['count']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Live Dispatch Connected Card (Active Courier Section)
  Widget _buildLiveDispatchCard(BuildContext context) {
    final activeOrders = OrderService.instance.activeOrders;
    final activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;
    final orderId = activeOrder?.orderId.replaceAll('#', '').trim() ?? 'NX-8942-ORD';
    final courierName = (activeOrder?.courierName.isNotEmpty == true && !activeOrder!.courierName.contains('Mark'))
        ? activeOrder.courierName
        : 'Pedro Jose Garcia';
    final messages = OrderChatService.instance.getMessages(orderId);
    final lastMsg = messages.isNotEmpty ? messages.last : null;
    final previewText = lastMsg != null
        ? (lastMsg['text'] ?? '')
        : 'Good day! I have picked up your order and am on my way.';
    final previewTime = lastMsg != null ? (lastMsg['time'] ?? 'Just now') : 'Live';
    final courierUnread = OrderChatService.instance.getUnreadCount(orderId);
    final showUnread = courierUnread > 0 || (ChatService.instance.totalUnreadCount > 0 && !_allRead);

    return Column(
      children: [
        // Live Dispatch Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF06B6D4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE DISPATCH CONNECTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF06B6D4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              'Order in transit',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Active Courier Card Container
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  orderId: orderId,
                  title: courierName,
                  subtitle: 'Courier • Active on route',
                  orderRef: '#$orderId',
                  avatarBgColor: const Color(0xFF00B4D8),
                  avatarIcon: Icons.two_wheeler_rounded,
                  initialMessages: messages.isNotEmpty ? messages : const [],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags Row (On the way ETA 4:30 PM & #NX-89240)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFFAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.directions_bike_rounded,
                              size: 13, color: Color(0xFF0891B2)),
                          SizedBox(width: 4),
                          Text(
                            'On the way (ETA 4:30 PM)',
                            style: TextStyle(
                              color: Color(0xFF0891B2),
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$orderId',
                        style: const TextStyle(
                          color: Color(0xFF0075FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Driver Avatar & Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Courier Avatar
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00B4D8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_motorsports_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        courierName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• Courier',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                previewTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0075FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            previewText,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Footer Actions Row (Phone button, Location pin button, Carrier name, Chevron)
                Row(
                  children: [
                    _buildSmallIconButton(
                      icon: Icons.phone_outlined,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calling Pedro Jose Garcia (+63 917 123 4567)...'),
                            backgroundColor: Color(0xFF0284C7),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildSmallIconButton(
                      icon: Icons.location_on_outlined,
                      onPressed: () {
                        _showLocationModal(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Speedy Logistics',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (showUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0075FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2FE),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: const Color(0xFF0284C7)),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Conversations Card Container List
  Widget _buildConversationsSection(BuildContext context) {
    final list = _filteredConversations;
    final isHiddenTab = _selectedFilterIndex == 4;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isHiddenTab ? 'HIDDEN CONVERSATIONS' : 'CONVERSATIONS',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              isHiddenTab
                  ? '${list.length} hidden'
                  : '${list.length} recent stores',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHiddenTab
                        ? Icons.visibility_off_outlined
                        : Icons.chat_bubble_outline_rounded,
                    size: 28,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isHiddenTab
                      ? 'No Hidden Conversations'
                      : 'No conversations found',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHiddenTab
                      ? 'Slide any conversation to the left and tap "Hide" to move it here.'
                      : 'Start messaging a store or clear your search filter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final chat = list[index];
                final isFirst = index == 0;
                final isLast = index == list.length - 1;
                final borderRadius = BorderRadius.vertical(
                  top: isFirst ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                );

                return SlidableConversationCard(
                  key: ValueKey(chat.id),
                  chat: chat,
                  isHiddenMode: isHiddenTab,
                  borderRadius: borderRadius,
                  onTap: () {
                    ChatService.instance.markAsRead(chat.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          conversationId: chat.id,
                          title: chat.title,
                          subtitle: chat.category,
                          avatarIcon: chat.avatarIcon,
                          avatarBgColor: chat.avatarBg,
                          orderRef: chat.itemTag ?? '',
                          initialMessages:
                              chat.messages.map((m) => m.toMap()).toList(),
                        ),
                      ),
                    );
                  },
                  onHide: () {
                    if (isHiddenTab) {
                      _unhideConversation(chat);
                    } else {
                      _hideConversation(chat);
                    }
                  },
                  onDelete: () {
                    _confirmDeleteConversation(chat);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  /// "Need Immediate Help?" Bottom Card
  Widget _buildImmediateHelpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Immediate Help?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live agents ready 24/7',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AVG: 2m',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: + Start Ticket & ? Help Center FAQ
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showStartTicketDialog(context);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text(
                    'Start Ticket',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showFAQModal(context);
                  },
                  icon: const Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: Color(0xFF0284C7),
                  ),
                  label: const Text(
                    'Help Center FAQ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStartTicketDialog(BuildContext context) {
    final ticketController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.confirmation_number_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Create Support Ticket'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your issue or order inquiry:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ticketController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type details here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = ticketController.text.trim();
              Navigator.pop(context);
              if (text.isNotEmpty) {
                ChatService.instance.addSupportTicket(text: text);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support ticket created successfully! Connected with live agent.'),
                  backgroundColor: Color(0xFF0284C7),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }

  void _showFAQModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help Center FAQ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF0284C7)),
                title: const Text('Where is my package?'),
                subtitle: const Text('Track your live delivery status in real-time'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Showing live tracking details...'), backgroundColor: Color(0xFF0284C7)),
                  );
                },
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.assignment_return_outlined, color: Color(0xFF0284C7)),
                title: const Text('30-Day Hassle-Free Return Policy'),
                subtitle: const Text('Learn how to request a return or refund'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Return policy guide...'), backgroundColor: Color(0xFF0284C7)),
                  );
                },
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.payment_rounded, color: Color(0xFF0284C7)),
                title: const Text('Payment & Invoice Queries'),
                subtitle: const Text('NexoraPay and invoice downloads'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Payment & Invoice guide...'), backgroundColor: Color(0xFF0284C7)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Conversations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_filters.length, (index) {
                final isSelected = _selectedFilterIndex == index;
                return ChoiceChip(
                  label: Text(_filters[index]['label']),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0284C7),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Message Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Live Dispatch Push Notifications'),
              subtitle: const Text('Receive driver ETA updates'),
              value: true,
              activeThumbColor: const Color(0xFF0284C7),
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text('Store Inquiry Auto-Replies'),
              subtitle: const Text('Instant support summaries'),
              value: true,
              activeThumbColor: const Color(0xFF0284C7),
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationModal(BuildContext context) {
    final activeOrder = OrderService.instance.latestActiveOrder;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Delivery Location'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 60, color: Color(0xFF0284C7)),
            SizedBox(height: 12),
            Text(
              'Pedro Jose Garcia (Courier) is 1.2 km away.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Destination: Front Desk / Receptionist Desk, Tower A',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.orderTracking,
                arguments: activeOrder,
              );
            },
            icon: const Icon(Icons.my_location_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            label: const Text('Track Live on Map'),
          ),
        ],
      ),
    );
  }
}

/// Interactive Slidable Conversation Card with Hide & Delete Actions
class SlidableConversationCard extends StatefulWidget {
  final ChatConversationModel chat;
  final bool isHiddenMode;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final VoidCallback onHide;
  final VoidCallback onDelete;

  const SlidableConversationCard({
    super.key,
    required this.chat,
    required this.isHiddenMode,
    required this.borderRadius,
    required this.onTap,
    required this.onHide,
    required this.onDelete,
  });

  @override
  State<SlidableConversationCard> createState() => _SlidableConversationCardState();
}

class _SlidableConversationCardState extends State<SlidableConversationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  double _dragExtent = 0.0;
  static const double _maxSlideExtent = 148.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: -_maxSlideExtent).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snapOpen() {
    _controller.animateTo(1.0);
    HapticFeedback.selectionClick();
  }

  void _snapClose() {
    _controller.animateTo(0.0);
    _dragExtent = 0.0;
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.chat.avatarBg,
                    radius: 18,
                    child: Icon(widget.chat.avatarIcon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.chat.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isHiddenMode
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isHiddenMode
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: widget.isHiddenMode
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                title: Text(
                  widget.isHiddenMode ? 'Unhide Conversation' : 'Hide Conversation',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  widget.isHiddenMode
                      ? 'Restore back to your active inbox'
                      : 'Move conversation to hidden archives',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                onTap: () {
                  Navigator.pop(modalCtx);
                  widget.onHide();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Delete Conversation',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
                subtitle: Text(
                  'Permanently remove conversation and messages',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                onTap: () {
                  Navigator.pop(modalCtx);
                  widget.onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          // Background Action Buttons Slider
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Hide / Unhide Action Button
                GestureDetector(
                  onTap: () {
                    _snapClose();
                    widget.onHide();
                  },
                  child: Container(
                    width: 74,
                    color: widget.isHiddenMode
                        ? const Color(0xFF10B981)
                        : const Color(0xFF475569),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isHiddenMode
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isHiddenMode ? 'Unhide' : 'Hide',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Delete Action Button
                GestureDetector(
                  onTap: () {
                    _snapClose();
                    widget.onDelete();
                  },
                  child: Container(
                    width: 74,
                    color: const Color(0xFFEF4444),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sliding Foreground Card
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = _controller.isAnimating
                  ? _slideAnimation.value
                  : _dragExtent;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragExtent = (_dragExtent + (details.primaryDelta ?? 0.0))
                      .clamp(-_maxSlideExtent, 0.0);
                  _controller.value = (-_dragExtent) / _maxSlideExtent;
                });
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -250) {
                  _snapOpen();
                } else if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 250) {
                  _snapClose();
                } else if (_dragExtent < -(_maxSlideExtent / 2)) {
                  _snapOpen();
                } else {
                  _snapClose();
                }
              },
              child: Material(
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    if (_controller.value > 0.05) {
                      _snapClose();
                    } else {
                      widget.onTap();
                    }
                  },
                  onLongPress: () => _showContextMenu(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Icon with Badge Overlay
                        Stack(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: widget.chat.avatarBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.chat.avatarIcon,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            if (widget.chat.brandTag != null)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0075FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.chat.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        if (widget.chat.brandTag != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD1E9FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              widget.chat.brandTag!,
                                              style: const TextStyle(
                                                color: Color(0xFF0075FF),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (widget.chat.botTag != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFCFFAFE),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              widget.chat.botTag!,
                                              style: const TextStyle(
                                                color: Color(0xFF0891B2),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (widget.isHiddenMode) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'HIDDEN',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.chat.time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),

                              Text(
                                widget.chat.subtitle,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  if (widget.chat.itemTag != null &&
                                      widget.chat.itemTag!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        widget.chat.itemTag!,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  if (widget.chat.resolvedTag != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE4E6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.shield_outlined,
                                              size: 11, color: Color(0xFFE11D48)),
                                          const SizedBox(width: 3),
                                          Text(
                                            widget.chat.resolvedTag!,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE11D48),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  if (widget.chat.isDoubleCheck)
                                    const Icon(Icons.done_all_rounded,
                                        size: 16, color: Color(0xFF0075FF))
                                  else if (widget.chat.isCheck)
                                    Icon(Icons.done_rounded,
                                        size: 16, color: Colors.grey.shade400),
                                  const SizedBox(width: 6),
                                  // Subtle slider swipe hint icon
                                  Icon(
                                    Icons.chevron_left_rounded,
                                    size: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
