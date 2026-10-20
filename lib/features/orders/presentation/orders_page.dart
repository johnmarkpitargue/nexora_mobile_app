import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  bool _initializedTab = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedTab) {
      _initializedTab = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('initialIndex')) {
        final idx = args['initialIndex'] as int;
        if (idx >= 0 && idx < _tabController.length) {
          _tabController.index = idx;
        }
      } else if (args is int && args >= 0 && args < _tabController.length) {
        _tabController.index = args;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OrderService.instance,
      builder: (context, child) {
        int toPayCount = OrderService.instance.activeOrders.where((o) => o.statusText == 'To Pay' || o.statusText == 'PENDING').length;
        int toShipCount = OrderService.instance.activeOrders.where((o) => o.statusText == 'To Ship' || o.statusText == 'PROCESSING').length;
        int toReceiveCount = OrderService.instance.activeOrders.where((o) => o.statusText == 'OUT FOR DELIVERY' || o.statusText == 'To Receive' || o.statusText == 'In Transit').length;
        int cancelledCount = OrderService.instance.activeOrders.where((o) => o.statusText == 'Cancelled').length;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                }
              },
            ),
            title: const Text(
              'My Orders',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black87, size: 22),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.insert_comment_outlined, color: Colors.black87, size: 22),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorColor: const Color(0xFF00C1D4),
                  indicatorWeight: 2,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF00C1D4),
                  unselectedLabelColor: Colors.black54,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: [
                    const Tab(text: 'All'),
                    _buildTabWithBadge('To Pay', toPayCount),
                    _buildTabWithBadge('To Ship', toShipCount),
                    _buildTabWithBadge('To Receive', toReceiveCount),
                    const Tab(text: 'Completed'),
                    const Tab(text: 'Return/Refund'),
                    _buildTabWithBadge('Cancelled', cancelledCount),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAllOrdersTab(),
              _buildToPayTab(),
              _buildToShipTab(),
              _buildToReceiveTab(),
              _buildCompletedTab(),
              _buildReturnRefundTab(),
              _buildCancelledTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabWithBadge(String text, int count) {
    if (count == 0) return Tab(text: text);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF00C1D4),
              shape: BoxShape.circle,
            ),
            child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF00C1D4).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF00C1D4)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C1D4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text('Discover Products', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOrdersTab() {
    final dynamicActive = OrderService.instance.activeOrders.map((o) => _buildDynamicOrderCard(o)).toList();
    final dynamicPast = OrderService.instance.pastOrders.map((o) => _buildDynamicOrderCard(o)).toList();
    final hasPendingPay = OrderService.instance.activeOrders.any((o) => o.statusText == 'To Pay' || o.statusText == 'PENDING');

    if (dynamicActive.isEmpty && dynamicPast.isEmpty) {
      return _buildEmptyOrdersState('No Orders Yet', 'Start discovering products and place your first order!', Icons.shopping_bag_outlined);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (hasPendingPay) _buildUrgentNotice(),
        ...dynamicActive,
        ...dynamicPast,
        _buildYouMayAlsoLike(),
      ],
    );
  }

  Widget _buildToPayTab() {
    final toPay = OrderService.instance.activeOrders
        .where((o) => o.statusText == 'To Pay' || o.statusText == 'PENDING')
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (toPay.isEmpty) {
      return _buildEmptyOrdersState('No Pending Payments', 'All of your orders have been paid for.', Icons.credit_score_outlined);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildUrgentNotice(),
        ...toPay,
        _buildYouMayAlsoLike(),
      ],
    );
  }

  Widget _buildToShipTab() {
    final toShip = OrderService.instance.activeOrders
        .where((o) => o.statusText == 'To Ship' || o.statusText == 'PROCESSING')
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (toShip.isEmpty) {
      return _buildEmptyOrdersState('No Orders To Ship', 'Items will appear here once orders are confirmed and preparing.', Icons.local_shipping_outlined);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ...toShip,
        _buildYouMayAlsoLike(),
      ],
    );
  }

  Widget _buildToReceiveTab() {
    final toReceive = OrderService.instance.activeOrders
        .where((o) => o.statusText == 'OUT FOR DELIVERY' || o.statusText == 'To Receive' || o.statusText == 'In Transit')
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (toReceive.isEmpty) {
      return _buildEmptyOrdersState('No Orders To Receive', 'Tracking updates will appear here once parcels are in transit.', Icons.inventory_2_outlined);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ...toReceive,
        _buildYouMayAlsoLike(),
      ],
    );
  }

  Widget _buildCompletedTab() {
    final completed = OrderService.instance.pastOrders
        .where((o) => o.statusText == 'Delivered' || o.statusText == 'Completed')
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (completed.isEmpty) {
      return _buildEmptyOrdersState('No Completed Orders', 'Delivered and received orders will appear here.', Icons.check_circle_outline);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ...completed,
        _buildYouMayAlsoLike(),
      ],
    );
  }

  Widget _buildReturnGuaranteeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Color(0xFF1E3A8A), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Return & Refund Guarantee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              ),
              const Text('Guidelines ', style: TextStyle(color: Color(0xFF0066FF), fontSize: 11, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right, size: 14, color: Color(0xFF0066FF)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Nexora Mall items are eligible for 15 days free easy return. Safe packaging ensures speedy resolution.', style: TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReturnApprovedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F8FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF00C1D4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text('Return Approved • Drop Off', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
          const Spacer(),
          const Text('#RF-982103984', style: TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStepTrackerAndCopyBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, color: Colors.black12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Step 2 of 3: Drop off Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0066FF))),
            Text('Due by 12 Oct', style: TextStyle(color: Color(0xFFE11D48), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
            Container(height: 4, width: 200, decoration: BoxDecoration(color: const Color(0xFF00C1D4), borderRadius: BorderRadius.circular(2))),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Hand over parcel at nearest SPX Express or J&T Express hub.', style: TextStyle(color: Colors.black54, fontSize: 11)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Drop-off Tracking No.', style: TextStyle(color: Colors.black54, fontSize: 11)),
                  SizedBox(height: 2),
                  Text('SPX-RET-0948271', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.copy, size: 12, color: Colors.black54),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Cancel Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                // Not passing context down here easily, but we can just use a Builder or pass a callback.
                // It's better to pass context or callbacks, but since this is a private method inside State, context is available!
                Navigator.pushNamed(context, '/chat');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Contact Seller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/order-details');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C1D4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Drop-off Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefundCompletedBanner() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF00C1D4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('P1,420.00 credited to GCash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                    SizedBox(height: 2),
                    Text('Resolved on 28 Sep 2024', style: TextStyle(color: Colors.black54, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chat');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Contact Seller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/order-details');
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9), // Light grey
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Refund Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReturnOrderCard({
    required String tag,
    required String storeName,
    required Widget statusWidget,
    Widget? topBanner,
    required String image,
    required String title,
    required String variant,
    required int qty,
    required double refundAmount,
    Widget? customBottomWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tag.toUpperCase() == 'MALL' ? const Color(0xFF1E3A8A) : const Color(0xFF5B6C8C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(storeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
              const SizedBox(width: 8),
              statusWidget,
            ],
          ),
          if (topBanner != null) ...[
            const SizedBox(height: 12),
            topBanner,
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                  image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(variant, style: const TextStyle(color: Colors.black54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Qty: $qty', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                        Row(
                          children: [
                            const Text('Refund Amount: ', style: TextStyle(color: Colors.black54, fontSize: 11)),
                            Text('P${refundAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (customBottomWidget != null) ...[
            const SizedBox(height: 12),
            customBottomWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildReturnRefundTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildReturnGuaranteeBanner(),
        _buildReturnOrderCard(
          tag: 'Mall',
          storeName: 'AudioTech Official',
          statusWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD6EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Drop Off Needed', style: TextStyle(color: Color(0xFF0066FF), fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          topBanner: _buildReturnApprovedBanner(),
          image: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?auto=format&fit=crop&w=200&q=80',
          title: 'Nexora Ergonomic Precision Mouse',
          variant: 'Light Grey, Bluetooth 5.2',
          qty: 1,
          refundAmount: 890.00,
          customBottomWidget: _buildStepTrackerAndCopyBlock(),
        ),
        _buildReturnOrderCard(
          tag: 'Preferred',
          storeName: 'Urban Minimalist ...',
          statusWidget: Row(
            children: const [
              Icon(Icons.check_circle, size: 14, color: Color(0xFF008060)),
              SizedBox(width: 4),
              Text('Refund Completed', style: TextStyle(color: Color(0xFF008060), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          image: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=200&q=80',
          title: 'Minimalist Canvas Commuter Tote...',
          variant: 'Sandstone Beige • 15L Capacity',
          qty: 1,
          refundAmount: 1420.00,
          customBottomWidget: _buildRefundCompletedBanner(),
        ),
        _buildYouMayAlsoLike(),
      ],
    );
  }

  Widget _buildCancelledTab() {
    final dynamicCancelled = OrderService.instance.activeOrders
        .where((o) => o.statusText == 'Cancelled')
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (dynamicCancelled.isEmpty) {
      return _buildEmptyOrdersState(
        'No Cancelled Orders',
        'You have no cancelled orders at this time.',
        Icons.check_circle_outline,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ...dynamicCancelled,
        _buildMissedSomethingBanner(),
        _buildYouMayAlsoLike(),
      ],
    );
  }



  Widget _buildMissedSomethingBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFBAE6FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0284C7), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Missed something\ngood?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                SizedBox(height: 2),
                Text(
                  'Explore top picks tailored ...',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0369A1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Discover', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }


  Widget _buildDynamicOrderCard(OrderItemModel order) {
    if (order.items.isEmpty) return const SizedBox();
    final firstItem = order.items.first;
    final tag = firstItem.storeBadge.isNotEmpty ? firstItem.storeBadge : 'MALL';
    final storeName = firstItem.storeName;
    final isCancelled = order.statusText == 'Cancelled';
    final isToPay = order.statusText == 'To Pay' || order.statusText == 'PENDING';
    final isToShip = order.statusText == 'To Ship' || order.statusText == 'PROCESSING';
    final isDelivered = order.statusText == 'Delivered' || order.statusText == 'Completed';

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (isToShip || order.statusText == 'To Receive' || order.statusText == 'OUT FOR DELIVERY') {
              Navigator.pushNamed(context, AppRoutes.shippedOrderDetails, arguments: order);
            } else {
              Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: order);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tag.toUpperCase() == 'MALL' ? const Color(0xFF1E3A8A) : const Color(0xFF00C1D4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        storeName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
                    const SizedBox(width: 8),
                    Text(
                      order.statusText,
                      style: TextStyle(color: order.statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order Items (Renders all products in this order)
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                            image: DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.variant,
                                style: const TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Qty: x${item.quantity}', style: const TextStyle(color: Colors.black38, fontSize: 12)),
                                  Row(
                                    children: [
                                      if (item.originalPrice != null && item.originalPrice! > item.price) ...[
                                        Text(
                                          'P${item.originalPrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.black38,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        'P${item.price.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (!isCancelled) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: order),
                    child: _buildTrackingBanner(order.etaText, order.etaTime, isCyanBg: true),
                  ),
                ],

                const Divider(height: 24, color: Color(0xFFF1F5F9)),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderId,
                      style: const TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    Row(
                      children: [
                        Text(
                          'Total ${order.items.length} ${order.items.length == 1 ? "item" : "items"}: ',
                          style: const TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                        Text(
                          'P${order.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCancelled ? const Color(0xFFE11D48) : const Color(0xFF00C1D4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isCancelled) ...[
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Cancellation Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.productDetails),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C1D4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Buy Again', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ] else if (isToPay) ...[
                      OutlinedButton(
                        onPressed: () {
                          OrderService.instance.cancelOrder(order.orderId);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Cancelled')));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Cancel Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          OrderService.instance.payOrder(order.orderId);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful! Order is now preparing.')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C1D4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Row(
                          children: const [
                            Text('Pay Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14),
                          ],
                        ),
                      ),
                    ] else if (order.statusText == 'To Receive' || order.statusText == 'OUT FOR DELIVERY') ...[
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Track Parcel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Confirm Order Received?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              content: const Text(
                                'Have you received all items in good condition? Confirming will complete the order and move it to your Completed tab where you can rate the product.',
                                style: TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text('Not Yet', style: TextStyle(color: Colors.black54)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    OrderService.instance.receiveOrder(order.orderId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order marked as received! Moved to Completed.'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C1D4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Yes, Received'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C1D4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_outline, size: 14),
                            SizedBox(width: 4),
                            Text('Order Received', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ] else ...[
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Contact Seller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isDelivered
                            ? () => Navigator.pushNamed(context, AppRoutes.rateProduct)
                            : (isToShip
                                ? () => Navigator.pushNamed(context, AppRoutes.shippedOrderDetails, arguments: order)
                                : () => Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: order)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C1D4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isDelivered ? 'Rate' : isToShip ? 'Order Details' : 'Track Order',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isDelivered ? Icons.star_border : Icons.arrow_forward,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, color: Color(0xFF5A728A), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Urgent Payment Notice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87)),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    children: [
                      TextSpan(text: 'Please pay within '),
                      TextSpan(text: '23h 45m', style: TextStyle(color: Color(0xFF0066FF), fontWeight: FontWeight.bold)),
                      TextSpan(text: ' or your orders will ca...'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 16),
        ],
      ),
    );
  }



  Widget _buildTrackingBanner(String title, String subtitle, {IconData icon = Icons.access_time, bool isCyanBg = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isCyanBg ? const Color(0xFFF2FCFE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isCyanBg ? const Color(0xFF00C1D4) : const Color(0xFF008060)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isCyanBg ? const Color(0xFF00C1D4) : const Color(0xFF008060))),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                ]
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _buildYouMayAlsoLike() {
    return Column(
      children: [
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 1, width: 48, color: Colors.black12),
            const SizedBox(width: 16),
            const Icon(Icons.bolt, color: Color(0xFF00C1D4), size: 18),
            const SizedBox(width: 4),
            const Text('You May Also Like', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(width: 16),
            Container(height: 1, width: 48, color: Colors.black12),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Based on your recent cart activity', style: TextStyle(color: Colors.black45, fontSize: 11)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.65,
            children: [
              _buildProductCard(
                image: 'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?auto=format&fit=crop&w=300&q=80',
                topRedTag: '-55%',
                tag: 'Mall',
                title: 'Vention Screen Bar USB Screen Clip Eye Protection Reading Lamp',
                sold: '3.2k sold',
                originalPrice: 1840,
                currentPrice: 827,
                bottomRightText: 'Free Shipping',
              ),
              _buildProductCard(
                image: 'https://images.unsplash.com/photo-1473968512647-3e447244af8f?auto=format&fit=crop&w=300&q=80',
                topRedTag: '-15%',
                tag: 'Mall',
                title: 'DJI Aerial Mini 3 Lightweight 249g 4K HDR Camera Drone',
                rating: 4.9,
                showRatingBadge: true,
                sold: '1.8k sold',
                originalPrice: 24500,
                currentPrice: 20690,
                bottomRightText: '0% Installment',
                bottomRightTextColor: const Color(0xFF00C1D4),
              ),
              _buildProductCard(
                image: 'https://images.unsplash.com/photo-1595225476474-87563907a212?auto=format&fit=crop&w=300&q=80',
                topRedTag: '-30%',
                tag: 'Preferred',
                title: 'OBSBOT Tiny 2 AI AI-Powered 4K PTZ Streaming Webcam',
                sold: '950 sold',
                originalPrice: 7850,
                currentPrice: 5499,
                bottomRightText: 'P200 Voucher',
                bottomRightTextColor: const Color(0xFF00C1D4),
              ),
              _buildProductCard(
                image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=300&q=80',
                topRedTag: '-22%',
                tag: 'Mall',
                title: 'Acoustic Pro NC9 Hybrid ANC Studio Wireless Headphones',
                rating: 5.0,
                showRatingBadge: true,
                sold: '2.4k sold',
                originalPrice: 4100,
                currentPrice: 3190,
                bottomRightText: 'Free Return',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard({
    required String image,
    String? topRedTag,
    String? topCyanTag,
    required String tag,
    required String title,
    double? rating,
    required String sold,
    double? originalPrice,
    required double currentPrice,
    bool showRatingBadge = false,
    String? bottomRightText,
    Color? bottomRightTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(image, height: 140, width: double.infinity, fit: BoxFit.cover),
              if (topRedTag != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(topRedTag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (topCyanTag != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C1D4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(topCyanTag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (showRatingBadge && rating != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 10, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text('$rating', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: tag.toUpperCase() == 'MALL' ? const Color(0xFF1E3A8A) : const Color(0xFF5B6C8C),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TextSpan(
                        text: title,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'P${currentPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE11D48)),
                    ),
                    if (originalPrice != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        'P${originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black38, fontSize: 9),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sold, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                    if (bottomRightText != null)
                      Text(bottomRightText, style: TextStyle(color: bottomRightTextColor ?? const Color(0xFF008060), fontSize: 10, fontWeight: FontWeight.bold)),
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
