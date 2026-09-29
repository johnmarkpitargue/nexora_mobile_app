import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../home/presentation/widgets/floating_nav_dock.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
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
      'subtitle': 'Your warranty for Nexora Studio Pro Wi...',
      'brandTag': 'BRAND',
      'itemTag': '🎧 Nexora Studio Pro',
      'time': '2:10 PM',
      'unread': 0,
      'isDoubleCheck': true,
      'avatarIcon': Icons.verified_user_rounded,
      'avatarBg': const Color(0xFF5038ED),
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
      'subtitle': 'Hi Alex! The Warm Stone Hoodie in Size...',
      'itemTag': '👔 Stone Hoodie (L)',
      'time': 'Yesterday',
      'unread': 0,
      'isDoubleCheck': true,
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
      'avatarBg': const Color(0xFF818CF8),
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
      'itemTag': '⌨️ MX Mechanical Mini',
      'time': 'Nov 05',
      'unread': 0,
      'isCheck': true,
      'avatarIcon': Icons.keyboard_rounded,
      'avatarBg': const Color(0xFF93C5FD),
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
    super.dispose();
  }

  void _markAllAsRead() {
    setState(() {
      _allRead = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All messages marked as read!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredConversations {
    return _conversations.where((item) {
      // Category filter
      if (_selectedFilterIndex == 1) {
        return false; // Couriers has live card section
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
        return title.contains(query) || subtitle.contains(query);
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
                  const SizedBox(height: 12),
                  // App Bar Header
                  _buildHeaderAppBar(context),
                  const SizedBox(height: 20),

                  // Title Bar & Read All Button
                  _buildTitleRow(),
                  const SizedBox(height: 16),

                  // Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  // Filter Pills
                  _buildFilterPills(),
                  const SizedBox(height: 20),

                  // Live Dispatch Card (Mark Ronald Courier)
                  if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
                    _buildLiveDispatchCard(context),
                    const SizedBox(height: 24),
                  ],

                  // Conversations List Section
                  if (_selectedFilterIndex != 1) ...[
                    _buildConversationsSection(context),
                    const SizedBox(height: 24),
                  ],

                  // Need Immediate Help Card
                  _buildImmediateHelpCard(context),

                  // Bottom padding clearance for floating navigation dock
                  const SizedBox(height: 110),
                ],
              ),
            ),

            // Floating Nav Dock
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingNavDock(
                currentIndex: 2, // Chat tab active
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  } else if (index == 1) {
                    Navigator.pushReplacementNamed(context, AppRoutes.orders);
                  } else if (index == 3) {
                    Navigator.pushReplacementNamed(context, AppRoutes.profile);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAppBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF5038ED),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5038ED).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nexora',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            Text(
              'Chat Hub',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildCircleIconButton(icon: Icons.search, onPressed: () {}),
        const SizedBox(width: 8),
        Stack(
          children: [
            _buildCircleIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: () {},
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Stack(
          children: [
            _buildCircleIconButton(
              icon: Icons.shopping_bag_outlined,
              onPressed: () {},
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFF5038ED),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF5038ED),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 19, color: const Color(0xFF1E293B)),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages & Support',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
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
        // Read All Pill Button
        InkWell(
          onTap: _markAllAsRead,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEEECFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.done_all_rounded,
                  size: 15,
                  color: Color(0xFF5038ED),
                ),
                SizedBox(width: 4),
                Text(
                  'Read All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5038ED),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: const TextStyle(fontSize: 14),
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
          suffixIcon: Icon(
            Icons.tune_rounded,
            color: Colors.grey.shade600,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final filter = _filters[index];
          final isSelected = _selectedFilterIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5038ED) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF5038ED).withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: isSelected ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
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
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFF1F3F9),
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

  Widget _buildLiveDispatchCard(BuildContext context) {
    final unreadCount = _allRead ? 0 : 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D9488),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE DISPATCH CONNECTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D9488),
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
                  subtitle: 'Nexora Express Courier',
                  orderRef: '#NX-89240',
                  initialMessages: [
                    {
                      'sender': 'user',
                      'text': 'Hi Mark, can you drop it off at the lobby?',
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
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0F9FF), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags row
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
                          color: Color(0xFF5038ED),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Driver Info & Last Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22D3EE),
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
                                  color: Color(0xFF5038ED),
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

                // Bottom Buttons row
                Row(
                  children: [
                    _buildSmallIconButton(
                      icon: Icons.call_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling Mark Ronald...')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildSmallIconButton(
                      icon: Icons.location_on_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tracking live location...')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Speedy Logistics',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5038ED),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFEEECFF),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 15, color: const Color(0xFF5038ED)),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
              indent: 70,
            ),
            itemBuilder: (context, index) {
              final chat = list[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(
                        title: chat['title'],
                        subtitle: chat['category'] ?? 'Store Inquiry',
                        avatarIcon: chat['avatarIcon'],
                        avatarBgColor: chat['avatarBg'] ?? const Color(0xFF5038ED),
                        initialMessages: List<Map<String, dynamic>>.from(
                            chat['initialMessages'] ?? []),
                      ),
                    ),
                  );
                },
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(20))
                    : index == list.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(20))
                        : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: chat['avatarBg'] ?? const Color(0xFF5038ED),
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
                                  color: const Color(0xFF5038ED),
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
                                          color: const Color(0xFFEEECFF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          chat['brandTag'],
                                          style: const TextStyle(
                                            color: Color(0xFF5038ED),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                if (chat['isDoubleCheck'] == true)
                                  const Icon(Icons.done_all_rounded,
                                      size: 16, color: Color(0xFF5038ED)),
                                if (chat['isCheck'] == true)
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

  Widget _buildImmediateHelpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0EEFF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF5038ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
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
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AVG: 2m',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5038ED),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons
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
                    backgroundColor: const Color(0xFF5038ED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                    color: Color(0xFF0F172A),
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
                    side: const BorderSide(color: Colors.transparent),
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
            Icon(Icons.confirmation_number_rounded, color: Color(0xFF5038ED)),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support ticket created successfully! Response ETA: 2 mins.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5038ED),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF5038ED)),
                title: const Text('Where is my package?'),
                subtitle: const Text('Track your live delivery status in real-time'),
                onTap: () => Navigator.pop(context),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.assignment_return_outlined, color: Color(0xFF5038ED)),
                title: const Text('30-Day Hassle-Free Return Policy'),
                subtitle: const Text('Learn how to request a return or refund'),
                onTap: () => Navigator.pop(context),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.payment_rounded, color: Color(0xFF5038ED)),
                title: const Text('Payment & Invoice Queries'),
                subtitle: const Text('NexoraPay and invoice downloads'),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
