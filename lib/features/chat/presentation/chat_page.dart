import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import '../../../app/routes/app_routes.dart';
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

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All Chats', 'count': 4},
    {'label': 'Couriers', 'count': 1, 'dotColor': const Color(0xFF06B6D4)},
    {'label': 'Official Stores', 'count': 2},
    {'label': 'Support', 'count': 1},
  ];

  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 'nexora_store',
      'category': 'Official Stores',
      'title': 'Nexora Official Store',
      'subtitle': 'Your warranty for Nexora Studio Pro W...',
      'brandTag': 'BRAND',
      'itemTag': '🎧 Nexora Studio Pro',
      'time': '2:10 PM',
      'unread': 0,
      'isDoubleCheck': true,
      'avatarIcon': Icons.verified_user_rounded,
      'avatarBg': const Color(0xFF0075FF),
      'initialMessages': [
        {
          'sender': 'other',
          'text': 'Hello Alex! Thank you for purchasing Nexora Studio Pro Wireless.',
          'time': '2:00 PM'
        },
        {
          'sender': 'other',
          'text': 'Your warranty for Nexora Studio Pro Wireless is now active for 1 year.',
          'time': '2:10 PM'
        },
      ]
    },
    {
      'id': 'aura_studios',
      'category': 'Official Stores',
      'title': 'Aura Studios Official',
      'subtitle': 'Hi Alex! The Warm Stone Hoodie in Siz...',
      'itemTag': '👗 Stone Hoodie (L)',
      'time': 'Yesterday',
      'unread': 0,
      'isCheck': true,
      'avatarIcon': Icons.checkroom_rounded,
      'avatarBg': const Color(0xFFFCA5A5),
      'initialMessages': [
        {
          'sender': 'user',
          'text': 'Hi, is the Warm Stone Hoodie in Size L in stock?',
          'time': 'Yesterday 4:30 PM'
        },
        {
          'sender': 'other',
          'text': 'Hi Alex! The Warm Stone Hoodie in Size L has been dispatched with your order!',
          'time': 'Yesterday 4:35 PM'
        },
      ]
    },
    {
      'id': 'ai_support',
      'category': 'Support',
      'title': 'Nexora AI Support',
      'subtitle': 'Ticket #SUP-4491 closed: Refund for...',
      'botTag': 'BOT',
      'resolvedTag': 'Case Resolved',
      'time': 'Nov 15',
      'unread': 0,
      'avatarIcon': Icons.smart_toy_rounded,
      'avatarBg': const Color(0xFF00B4D8),
      'initialMessages': [
        {
          'sender': 'other',
          'text': 'Ticket #SUP-4491 closed: Refund for item process completed.',
          'time': 'Nov 15 10:00 AM'
        },
      ]
    },
    {
      'id': 'logitech_store',
      'category': 'Official Stores',
      'title': 'LogiTech Hub Store',
      'subtitle': 'Thanks for purchasing with us! Let us k...',
      'itemTag': 'MX Mechanical Mini',
      'time': 'Nov 05',
      'unread': 0,
      'isCheck': true,
      'avatarIcon': Icons.keyboard_rounded,
      'avatarBg': const Color(0xFF94A3B8),
      'initialMessages': [
        {
          'sender': 'other',
          'text': 'Thanks for purchasing with us! Let us know if you need driver software setup.',
          'time': 'Nov 05 3:20 PM'
        },
      ]
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get _filteredConversations {
    return _conversations.where((item) {
      // Category filter
      if (_selectedFilterIndex == 1) {
        return false; // Couriers tab shows live dispatch card
      }
      if (_selectedFilterIndex == 2 && item['category'] != 'Official Stores') {
        return false;
      }
      if (_selectedFilterIndex == 3 && item['category'] != 'Support') {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = (item['title'] as String).toLowerCase();
        final subtitle = (item['subtitle'] as String).toLowerCase();
        final itemTag = (item['itemTag'] ?? '').toString().toLowerCase();
        return title.contains(query) || subtitle.contains(query) || itemTag.contains(query);
      }
      return true;
    }).toList();
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

                  // Live Dispatch Connected Card (Mark Ronald Courier)
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top App Bar matching screenshot: ← Messages [Search] [Filter] [Settings]
  Widget _buildTopAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF0F172A),
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
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
                    if (filter.containsKey('dotColor') && !isSelected) ...[
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
    final showUnread = ChatService.instance.totalUnreadCount > 0 && !_allRead;

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
                builder: (context) => const ChatDetailPage(
                  title: 'Mark Ronald',
                  subtitle: 'Courier',
                  orderRef: '#NX-89240',
                  avatarBgColor: Color(0xFF00B4D8),
                  initialMessages: [
                    {
                      'sender': 'user',
                      'text': 'Hi Mark, can you drop it off at the front desk?',
                      'time': '4:00 PM'
                    },
                    {
                      'sender': 'other',
                      'text':
                          'Noted po! Will leave it with the front desk receptionist and ask for a claim receipt.',
                      'time': '4:05 PM'
                    },
                  ],
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
                      child: const Text(
                        '#NX-89240 (2 items)',
                        style: TextStyle(
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
                              Row(
                                children: [
                                  const Text(
                                    'Mark Ronald',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5,
                                      color: Color(0xFF0F172A),
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
                              const Text(
                                '4:05 PM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0075FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"Noted po! Will leave it with the front desk receptionist and ask for a claim...',
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
                            content: Text('Calling Mark Ronald (+63 917 123 4567)...'),
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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CONVERSATIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${list.length} recent stores',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

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

              return InkWell(
                onTap: () {
                  ChatService.instance.markAsRead(chat['id'] ?? '');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(
                        title: chat['title'],
                        subtitle: chat['category'] ?? 'Store Inquiry',
                        avatarIcon: chat['avatarIcon'],
                        avatarBgColor: chat['avatarBg'] ?? const Color(0xFF0075FF),
                        initialMessages: List<Map<String, dynamic>>.from(
                            chat['initialMessages'] ?? []),
                      ),
                    ),
                  );
                },
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == list.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
                              color: chat['avatarBg'] ?? const Color(0xFF0075FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              chat['avatarIcon'] ?? Icons.storefront_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (chat.containsKey('brandTag'))
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
                                Row(
                                  children: [
                                    Text(
                                      chat['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (chat.containsKey('brandTag')) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1E9FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          chat['brandTag'],
                                          style: const TextStyle(
                                            color: Color(0xFF0075FF),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (chat.containsKey('botTag')) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCFFAFE),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          chat['botTag'],
                                          style: const TextStyle(
                                            color: Color(0xFF0891B2),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  chat['time'],
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
                              chat['subtitle'],
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
                                if (chat.containsKey('itemTag'))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      chat['itemTag'],
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                if (chat.containsKey('resolvedTag'))
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
                                          chat['resolvedTag'],
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
                                if (_allRead || chat['isDoubleCheck'] == true)
                                  const Icon(Icons.done_all_rounded,
                                      size: 16, color: Color(0xFF0075FF))
                                else if (chat['isCheck'] == true)
                                  Icon(Icons.done_rounded,
                                      size: 16, color: Colors.grey.shade400),
                                if (chat.containsKey('resolvedTag'))
                                  Text(
                                    'Automated',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                setState(() {
                  _conversations.insert(0, {
                    'id': 'ticket_${DateTime.now().millisecondsSinceEpoch}',
                    'category': 'Support',
                    'title': 'Support Ticket #${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    'subtitle': text,
                    'botTag': 'LIVE',
                    'time': 'Just now',
                    'unread': 0,
                    'isDoubleCheck': true,
                    'avatarIcon': Icons.support_agent_rounded,
                    'avatarBg': const Color(0xFF0284C7),
                    'initialMessages': [
                      {
                        'sender': 'user',
                        'text': text,
                        'time': 'Just now',
                      },
                      {
                        'sender': 'other',
                        'text': 'A support specialist has been assigned to your ticket! Average response time is under 2 minutes.',
                        'time': 'Just now',
                      }
                    ],
                  });
                });
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
              'Mark Ronald (Courier) is 1.2 km away.',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
