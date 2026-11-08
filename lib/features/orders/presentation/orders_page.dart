import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/order_service.dart';
import 'widgets/order_action_dialogs.dart';

class OrdersPage extends StatefulWidget {
  final bool isActiveTab;

  const OrdersPage({super.key, this.isActiveTab = true});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _initializedTab = false;

  static const List<String> _tabKeys = [
    'all',
    'to_ship',
    'to_receive',
    'completed',
    'return_refund',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: _tabKeys.length, vsync: this);
    if (widget.isActiveTab && ApiClient.instance.hasToken) {
      OrderService.instance.fetchOrdersRemote();
    }
    _syncPollingState();
  }

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab && !oldWidget.isActiveTab) {
      if (ApiClient.instance.hasToken) {
        OrderService.instance.fetchOrdersRemote();
      }
    }
    if (widget.isActiveTab != oldWidget.isActiveTab) {
      _syncPollingState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncPollingState();
  }

  void _syncPollingState() {
    if (widget.isActiveTab &&
        _lifecycleState == AppLifecycleState.resumed &&
        ApiClient.instance.hasToken) {
      OrderService.instance.startPolling();
    } else {
      OrderService.instance.stopPolling();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedTab) {
      _initializedTab = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final initialTab = args['initialTab']?.toString();
        if (initialTab != null && _tabKeys.contains(initialTab)) {
          _tabController.index = _tabKeys.indexOf(initialTab);
        } else if (args.containsKey('initialIndex') &&
            args['initialIndex'] is int) {
          final idx = args['initialIndex'] as int;
          _tabController.index = idx.clamp(0, _tabKeys.length - 1);
        }
      } else if (args is String && _tabKeys.contains(args)) {
        _tabController.index = _tabKeys.indexOf(args);
      } else if (args is int) {
        _tabController.index = args.clamp(0, _tabKeys.length - 1);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OrderService.instance.stopPolling();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (!ApiClient.instance.hasToken) return;
    await OrderService.instance.fetchOrdersRemote();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        OrderService.instance,
        BuyerAccountService.instance,
      ]),
      builder: (context, child) {
        final counts = OrderService.instance.tabCounts;
        final isAuthenticated = ApiClient.instance.hasToken;

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
              if (isAuthenticated)
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.black87,
                    size: 22,
                  ),
                  tooltip: 'Refresh Orders',
                  onPressed: _onRefresh,
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
                  indicatorColor: const Color(0xFF0066FF),
                  indicatorWeight: 2,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF0066FF),
                  unselectedLabelColor: Colors.black54,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: [
                    _buildTabWithBadge('All', counts.all, showZero: false),
                    _buildTabWithBadge('To Ship', counts.toShip),
                    _buildTabWithBadge('To Receive', counts.toReceive),
                    _buildTabWithBadge(
                      'Completed',
                      counts.completed,
                      showBadge: false,
                    ),
                    _buildTabWithBadge('Return/Refund', counts.returnRefund),
                    _buildTabWithBadge(
                      'Cancelled',
                      counts.cancelled,
                      showBadge: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: !isAuthenticated
              ? _buildUnauthenticatedState()
              : _buildAuthenticatedBody(),
        );
      },
    );
  }

  Widget _buildUnauthenticatedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 34,
                color: Color(0xFF0066FF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign In to View Orders',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to track your parcel status, hub transfers, and receipts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedBody() {
    final service = OrderService.instance;
    if (service.isLoading && service.allOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (service.ordersError != null && service.allOrders.isEmpty) {
      return _buildErrorState(service.ordersError!);
    }

    return Column(
      children: [
        if (service.ordersError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.ordersError!,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _onRefresh,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersTabList(
                tabKey: 'all',
                emptyTitle: 'No Orders Yet',
                emptySubtitle: 'When you place orders, they will appear here with real-time hub tracking.',
                emptyIcon: Icons.shopping_bag_outlined,
                showGuaranteeFooter: true,
              ),
              _buildOrdersTabList(
                tabKey: 'to_ship',
                emptyTitle: 'No Orders To Ship',
                emptySubtitle: 'Items will appear here once placed and while sellers prepare your parcel.',
                emptyIcon: Icons.inventory_2_outlined,
              ),
              _buildOrdersTabList(
                tabKey: 'to_receive',
                emptyTitle: 'No Orders To Receive',
                emptySubtitle: 'Hub transit, pickup, and delivery updates will appear here once dispatched.',
                emptyIcon: Icons.local_shipping_outlined,
              ),
              _buildOrdersTabList(
                tabKey: 'completed',
                emptyTitle: 'No Completed Orders',
                emptySubtitle:
                    'Delivered and confirmed orders will appear here.',
                emptyIcon: Icons.check_circle_outline,
              ),
              _buildOrdersTabList(
                tabKey: 'return_refund',
                emptyTitle: 'No Return or Refund Requests',
                emptySubtitle: 'You do not have any return or refund requests at this time.',
                emptyIcon: Icons.assignment_return_outlined,
                showReturnBanner: true,
              ),
              _buildOrdersTabList(
                tabKey: 'cancelled',
                emptyTitle: 'No Cancelled Orders',
                emptySubtitle: 'You have no cancelled orders at this time.',
                emptyIcon: Icons.cancel_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to Load Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabWithBadge(
    String text,
    int count, {
    bool showZero = false,
    bool showBadge = true,
  }) {
    if (!showBadge || (!showZero && count == 0)) return Tab(text: text);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: const BoxDecoration(
              color: Color(0xFF0066FF),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTabList({
    required String tabKey,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    bool showGuaranteeFooter = false,
    bool showReturnBanner = false,
  }) {
    final orders = OrderService.instance.ordersForTab(tabKey);

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (showReturnBanner) _buildReturnGuaranteeBanner(),
            _buildEmptyOrdersState(emptyTitle, emptySubtitle, emptyIcon),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (showReturnBanner) _buildReturnGuaranteeBanner(),
          ...orders.map(_buildDynamicOrderCard),
          if (showGuaranteeFooter) _buildNexoraGuaranteeFooter(),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: const Color(0xFF0066FF)),
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
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Discover Products',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNexoraGuaranteeFooter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0066FF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0066FF).withValues(alpha: 0.15),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFF0066FF), size: 16),
          SizedBox(width: 8),
          Text(
            'All orders are covered by Nexora COD & Return policy',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF1E3A8A),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Return & Refund Guarantee',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Delivered items are eligible for return/refund within 7 days with 1–5 proof photos or videos.',
            style: TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _openOrderDetails(OrderItemModel order) {
    final useShippedView =
        order.matchesTab('to_receive') ||
        order.rawStatus == 'delivered' ||
        order.rawStatus == 'completed';
    Navigator.pushNamed(
      context,
      useShippedView ? AppRoutes.shippedOrderDetails : AppRoutes.orderDetails,
      arguments: order,
    );
  }

  Widget _buildDynamicOrderCard(OrderItemModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final storeName = order.storeName.isNotEmpty
        ? order.storeName
        : (firstItem?.storeName.isNotEmpty == true
              ? firstItem!.storeName
              : 'Seller');
    final canConfirmReceipt =
        order.rawStatus == 'out_for_delivery' || order.rawStatus == 'delivered';
    final firstProductId = firstItem?.productId;

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _openOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store & Order Number Header
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: Color(0xFF0066FF),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: order.sellerId != null
                            ? () => Navigator.pushNamed(
                                context,
                                AppRoutes.shop,
                                arguments: order.sellerId.toString(),
                              )
                            : null,
                        child: Text(
                          storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: order.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.statusText,
                        style: TextStyle(
                          color: order.statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (order.currentHubName != null) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      Flexible(
                        child: Text(
                          order.currentHubName!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                if (order.rawStatus == 'out_for_delivery' &&
                    order.deliveryOtp.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin_outlined,
                          size: 16,
                          color: Color(0xFF0066FF),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Delivery Verification OTP',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        Text(
                          order.deliveryOtp,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Order Items
                if (order.items.isEmpty)
                  Text(
                    order.etaText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  )
                else
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFF94A3B8),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.variant,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Qty: x${item.quantity}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '₱${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                      ),
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

                const Divider(height: 18, color: Color(0xFFF1F5F9)),

                // Order Total
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total (${order.items.length} ${order.items.length == 1 ? "item" : "items"}): ',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '₱${order.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Server-driven Action Buttons
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (order.canBeCancelled)
                      OutlinedButton(
                        onPressed: () =>
                            OrderActionDialogs.showCancelOrderDialog(
                              context,
                              order,
                            ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE11D48),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (order.canBeReturned)
                      OutlinedButton(
                        onPressed: () =>
                            OrderActionDialogs.showReturnRequestDialog(
                              context,
                              order,
                            ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(color: Color(0xFFDDD6FE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text(
                          'Return / Refund',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (canConfirmReceipt)
                      ElevatedButton.icon(
                        onPressed: () =>
                            OrderActionDialogs.showConfirmReceiptDialog(
                              context,
                              order,
                            ),
                        icon: const Icon(Icons.check_circle_outline, size: 15),
                        label: const Text(
                          'Order Received',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 34),
                        ),
                      ),
                    if (order.canBeReviewed &&
                        (order.review == null || order.review!.canBeEdited))
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.rateProduct,
                          arguments: order,
                        ),
                        icon: const Icon(Icons.star_rounded, size: 15),
                        label: Text(
                          order.review != null
                              ? 'Edit Review'
                              : 'Rate & Review',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 34),
                        ),
                      ),
                    if (firstProductId != null &&
                        (order.rawStatus == 'cancelled' ||
                            order.rawStatus == 'completed' ||
                            order.rawStatus == 'delivered'))
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.productDetails,
                          arguments: firstProductId,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text(
                          'Buy Again',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    OutlinedButton(
                      onPressed: () => _openOrderDetails(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066FF),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 34),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
