import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/models/shop_models.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/shop_service.dart';
import '../../chat/presentation/chat_detail_page.dart';
import '../../home/presentation/widgets/product_card.dart';

class ShopPage extends StatefulWidget {
  final ShopModel? initialShop;
  final String? shopId;

  const ShopPage({
    super.key,
    this.initialShop,
    this.shopId,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with TickerProviderStateMixin {
  late ShopModel _shop;
  late TabController _tabController;
  final ShopService _shopService = ShopService.instance;

  // Animation controllers for Follow & Chat buttons
  late AnimationController _followAnimController;
  late Animation<double> _followScaleAnim;
  late AnimationController _chatAnimController;
  late Animation<double> _chatScaleAnim;

  // Flash deals countdown timer (04 : 35 : 57)
  late Timer _countdownTimer;
  int _secondsLeft = 4 * 3600 + 35 * 60 + 57;

  // Active filter for "Products" tab
  String _selectedProductFilter = 'Popular';

  // Hover state map for Category cards
  final Map<String, bool> _categoryHoverStates = {};

  // Claiming animation tracking
  final Set<String> _claimingVouchers = {};

  @override
  void initState() {
    super.initState();
    _shop = widget.initialShop ??
        _shopService.getShopById(widget.shopId ?? '1');

    _tabController = TabController(length: 3, vsync: this);

    // Follow button spring scale animation
    _followAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _followScaleAnim = CurvedAnimation(
      parent: _followAnimController,
      curve: Curves.easeOutBack,
    );

    // Chat button spring scale animation
    _chatAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _chatScaleAnim = CurvedAnimation(
      parent: _chatAnimController,
      curve: Curves.easeOutBack,
    );

    // Countdown ticker
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
          }
        });
      }
    });

    _shopService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ShopModel) {
      _shop = args;
    } else if (args is String) {
      _shop = _shopService.getShopById(args);
    }
    final targetShopId = _shop.id;
    if (targetShopId.isNotEmpty) {
      _shopService.fetchStoreRemote(targetShopId).then((remoteShop) {
        if (remoteShop != null && mounted) {
          setState(() {
            _shop = remoteShop;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _followAnimController.dispose();
    _chatAnimController.dispose();
    _countdownTimer.cancel();
    _shopService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  String get _hoursStr => _formatTwoDigits(_secondsLeft ~/ 3600);
  String get _minutesStr => _formatTwoDigits((_secondsLeft % 3600) ~/ 60);
  String get _secondsStr => _formatTwoDigits(_secondsLeft % 60);

  void _handleFollowTap() async {
    await _followAnimController.reverse();
    await _followAnimController.forward();
    await _shopService.toggleFollowRemote(_shop.id);

    final isNowFollowing = _shopService.isFollowing(_shop.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNowFollowing ? Icons.check_circle : Icons.person_remove,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isNowFollowing
                  ? 'You are now following ${_shop.name}!'
                  : 'Unfollowed ${_shop.name}',
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleChatTap() async {
    await _chatAnimController.reverse();
    await _chatAnimController.forward();
    if (!mounted) return;
    final conv = ChatService.instance.getOrCreateShopConversation(
      shopId: _shop.id,
      shopName: _shop.name,
      shopBadge: _shop.badge,
      avatarBg: _shop.avatarBg,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          conversationId: conv.id,
          title: conv.title,
          subtitle: _shop.badge,
          avatarIcon: conv.avatarIcon,
          avatarBgColor: conv.avatarBg,
          initialMessages: conv.messages.map((m) => m.toMap()).toList(),
        ),
      ),
    );
  }

  void _handleClaimVoucher(ShopVoucherModel voucher) async {
    if (_shopService.isVoucherClaimed(voucher.id)) return;

    setState(() {
      _claimingVouchers.add(voucher.id);
    });

    await Future.delayed(const Duration(milliseconds: 350));
    _shopService.claimVoucher(voucher.id);

    if (!mounted) return;
    setState(() {
      _claimingVouchers.remove(voucher.id);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎉 Voucher Claimed! (${voucher.discountTitle})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Saved to your account • ${voucher.minSpend}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF050B28),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _shop.products.isNotEmpty
        ? _shop.products
        : _shopService.getProductsByShop(_shop.id);
    final isFollowing = _shopService.isFollowing(_shop.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Dark Navy Gradient Store Header
            SliverToBoxAdapter(
              child: _buildShopHeader(isFollowing),
            ),
            // Sticky Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _ShopTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0066FF),
                  indicatorWeight: 3.5,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF0066FF),
                  unselectedLabelColor: const Color(0xFF475569),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Shop'),
                    Tab(text: 'Products'),
                    Tab(text: 'Categories'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildShopTab(products),
            _buildProductsTab(products),
            _buildCategoriesTab(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STORE HEADER
  // =========================================================================
  Widget _buildShopHeader(bool isFollowing) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 14,
        right: 14,
        bottom: 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF020617),
            Color(0xFF070E28),
            Color(0xFF0B173D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Search & Navigation Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Search in Nexora...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 21),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_shop.name} link copied to clipboard!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 21),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Shop Profile Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Store Logo
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _shop.avatarBg,
                  border: Border.all(color: const Color(0xFF0066FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _shop.avatarUrl != null && _shop.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _shop.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              _shop.initials,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _shop.initials,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            height: 1.1,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Title, Badge, Rating & Followers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _shop.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _shop.badge,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w900,
                          fontSize: 9.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${_shop.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            '  |  ${_shop.followers} Followers',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Follow & Chat Action Buttons (With Spring Animation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Follow Button
                  ScaleTransition(
                    scale: _followScaleAnim,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleFollowTap,
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          width: 96,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF07153B).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFollowing
                                  ? const Color(0xFF0066FF)
                                  : const Color(0xFF0075FF),
                              width: 1.3,
                            ),
                            boxShadow: [
                              if (!isFollowing)
                                BoxShadow(
                                  color: const Color(0xFF0075FF).withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isFollowing ? Icons.check : Icons.add,
                                color: isFollowing ? const Color(0xFF0066FF) : const Color(0xFF00B4D8),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isFollowing ? 'Following' : 'Follow',
                                style: TextStyle(
                                  color: isFollowing
                                      ? const Color(0xFF0066FF)
                                      : const Color(0xFF00B4D8),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Chat Button
                  ScaleTransition(
                    scale: _chatScaleAnim,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleChatTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 96,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF07153B).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.8),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF00B4D8),
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SHOP (Vouchers, Flash Deals, Popular Products)
  // =========================================================================
  Widget _buildShopTab(List<ProductModel> products) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      children: [
        // VOUCHERS CAROUSEL / ROW
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _shop.vouchers.map((voucher) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildVoucherTicketCard(voucher),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 22),

        // MALL FLASH DEALS HEADER
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF0066FF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'MALL FLASH DEALS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
                color: Color(0xFF0F172A),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),

            // Countdown timer boxes: [04] : [35] : [57]
            _buildTimerBadge(_hoursStr),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            _buildTimerBadge(_minutesStr),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(':', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            _buildTimerBadge(_secondsStr),

            const Spacer(),
            InkWell(
              onTap: () {
                _tabController.animateTo(1);
              },
              child: const Row(
                children: [
                  Text(
                    'See More',
                    style: TextStyle(
                      color: Color(0xFF0066FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF0066FF)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // FLASH DEALS CARDS ROW (StreamMic D20, Voice Master Amp)
        Row(
          children: [
            if (products.isNotEmpty)
              Expanded(
                child: _buildFlashDealProductCard(
                  products[0],
                  discountBadge: '-48%',
                  progressValue: 0.72,
                ),
              ),
            const SizedBox(width: 12),
            if (products.length > 1)
              Expanded(
                child: _buildFlashDealProductCard(
                  products[1],
                  discountBadge: '-54%',
                  progressValue: 0.85,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // POPULAR PRODUCTS HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'POPULAR PRODUCTS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${products.length * 15 + 4} Items',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2-COLUMN POPULAR PRODUCTS GRID
        _buildProductGrid(products),
        const SizedBox(height: 20),
      ],
    );
  }

  // =========================================================================
  // TAB 2: PRODUCTS (Filters: Popular, Latest, Top Sales, Price ⇅)
  // =========================================================================
  Widget _buildProductsTab(List<ProductModel> products) {
    // Sort products based on filter
    List<ProductModel> sorted = List.from(products);
    if (_selectedProductFilter == 'Latest') {
      sorted = sorted.reversed.toList();
    } else if (_selectedProductFilter == 'Top Sales') {
      sorted.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    } else if (_selectedProductFilter == 'Price ⇅') {
      sorted.sort((a, b) {
        final pa = double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        final pb = double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        return pa.compareTo(pb);
      });
    }

    final filters = ['Popular', 'Latest', 'Top Sales', 'Price ⇅'];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // Filter pills bar
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: filters.map((f) {
                    final isSel = _selectedProductFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedProductFilter = f;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFF0FDF4).withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF0066FF)
                                  : const Color(0xFFE2E8F0),
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: isSel
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF64748B),
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Text(
              '${products.length * 15 + 4} ITEMS',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Product Grid
        _buildProductGrid(sorted),
        const SizedBox(height: 24),

        // End of Products footer
        const Center(
          child: Text(
            '— End of Products —',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =========================================================================
  // TAB 3: CATEGORIES (Hover Animations on Collection Cards)
  // =========================================================================
  Widget _buildCategoriesTab() {
    final categories = _shop.categories;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      children: [
        // Category Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 15,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _shop.categoryGroupTitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${categories.length} Collections',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2-COLUMN CATEGORIES GRID WITH HOVER ANIMATION
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _buildCategoryCollectionCard(cat);
          },
        ),
        const SizedBox(height: 22),

        // Authentic Guarantee Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, color: Color(0xFF0066FF), size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _shop.guaranteeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // End of Categories footer
        const Center(
          child: Text(
            '— End of Categories —',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =========================================================================
  // COMPONENT: VOUCHER TICKET (With authentic notches & claim feedback)
  // =========================================================================
  Widget _buildVoucherTicketCard(ShopVoucherModel voucher) {
    final isClaimed = _shopService.isVoucherClaimed(voucher.id);
    final isClaiming = _claimingVouchers.contains(voucher.id);

    return Container(
      width: 196,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClaimed ? const Color(0xFFCBD5E1) : const Color(0xFF38BDF8),
          width: 1.2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  voucher.discountTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    color: Color(0xFF0284C7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  voucher.tag,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            voucher.minSpend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          Text(
            voucher.expiry,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),

          // CLAIM BUTTON WITH CELEBRATION FEEDBACK
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: (isClaimed || isClaiming) ? null : () => _handleClaimVoucher(voucher),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClaimed
                    ? const Color(0xFFF1F5F9)
                    : voucher.buttonColor,
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isClaimed ? const Color(0xFFCBD5E1) : Colors.transparent,
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
              child: isClaiming
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isClaimed) ...[
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isClaimed ? 'CLAIMED' : 'CLAIM',
                          style: TextStyle(
                            color: isClaimed ? const Color(0xFF64748B) : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
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

  // =========================================================================
  // COMPONENT: TIMER BADGE (For Flash Deals)
  // =========================================================================
  Widget _buildTimerBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // =========================================================================
  // COMPONENT: FLASH DEAL PRODUCT CARD
  // =========================================================================
  Widget _buildFlashDealProductCard(
    ProductModel product, {
    required String discountBadge,
    required double progressValue,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Stack(
              children: [
                SizedBox(
                  height: 125,
                  width: double.infinity,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.mic, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      discountBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        product.price,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (product.originalPrice != null)
                        Text(
                          product.originalPrice!,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Cyan progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SELLING FAST',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // COMPONENT: CATEGORY CARD (With Smooth Hover Animation)
  // =========================================================================
  Widget _buildCategoryCollectionCard(ShopCategoryModel cat) {
    final isHovered = _categoryHoverStates[cat.id] ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _categoryHoverStates[cat.id] = true;
        });
      },
      onExit: (_) {
        setState(() {
          _categoryHoverStates[cat.id] = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          // Switch to Products tab or notify user
          _tabController.animateTo(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing items in "${cat.title}"'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: isHovered
              ? (Matrix4.translationValues(0.0, -4.0, 0.0)..scaleByDouble(1.03, 1.03, 1.0, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFF0066FF)
                  : const Color(0xFFE2E8F0),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? const Color(0xFF0066FF).withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isHovered ? 14 : 6,
                offset: Offset(0, isHovered ? 6 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: Image.network(
                    cat.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.headphones,
                      size: 40,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),

              // Title, items count & chevron
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: isHovered
                            ? const Color(0xFF0066FF)
                            : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cat.itemCount} items',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 15,
                          color: isHovered
                              ? const Color(0xFF0066FF)
                              : const Color(0xFF94A3B8),
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
    );
  }

  // =========================================================================
  // COMPONENT: 2-COLUMN PRODUCT GRID
  // =========================================================================
  Widget _buildProductGrid(List<ProductModel> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.53,
      ),
      itemBuilder: (context, index) {
        final p = products[index];
        return ProductCard(product: p);
      },
    );
  }
}

// ===========================================================================
// SLIVER PERSISTENT HEADER DELEGATE FOR TAB BAR
// ===========================================================================
class _ShopTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _ShopTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_ShopTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}
