import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';

import 'widgets/order_components.dart';

class OrdersPage extends StatefulWidget {
  final bool isActiveTab;

  const OrdersPage({super.key, this.isActiveTab = true});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  static const bool _useLegacyOrders = bool.fromEnvironment(
    'NEXORA_LEGACY_ORDERS',
  );
  late TabController _tabController;
  int _selectedView = 0;
  bool _searchVisible = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    OrderService.instance.refreshOrdersFromSupabase();
    if (ApiClient.instance.hasToken) {
      OrderService.instance.fetchOrdersRemote();
    }
  }

  bool _initializedTab = false;
  bool _voucherClaimed = false;

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
          _selectedView = idx;
        }
      } else if (args is int && args >= 0 && args < _tabController.length) {
        _tabController.index = args;
        _selectedView = args;
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
    if (_useLegacyOrders) return _buildLegacyOrders(context);
    return _buildRefinedOrders(context);
  }

  Widget _buildRefinedOrders(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        OrderService.instance,
        BuyerAccountService.instance,
        AddressService.instance,
      ]),
      builder: (context, _) {
        final counts = _orderCounts();
        return Scaffold(
          appBar: NexoraAppBar(
            titleText: 'My Orders',
            actions: [
              IconButton(
                key: const ValueKey('orders-search-action'),
                tooltip: _searchVisible
                    ? 'Close order search'
                    : 'Search orders',
                onPressed: () => setState(() {
                  _searchVisible = !_searchVisible;
                  if (!_searchVisible) _searchQuery = '';
                }),
                icon: Icon(
                  _searchVisible ? Icons.close_rounded : Icons.search_rounded,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (_searchVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NexoraSpacing.md,
                    NexoraSpacing.xs,
                    NexoraSpacing.md,
                    0,
                  ),
                  child: TextField(
                    key: const ValueKey('orders-search-field'),
                    autofocus: true,
                    onChanged: (value) => setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    }),
                    decoration: const InputDecoration(
                      hintText: 'Search order number, store, or product',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              _buildRefinedFilters(counts),
              Expanded(
                child: AnimatedSwitcher(
                  duration: NexoraMotion.resolve(context),
                  switchInCurve: NexoraMotion.standardCurve,
                  child: KeyedSubtree(
                    key: ValueKey('orders-view-$_selectedView-$_searchQuery'),
                    child: _buildRefinedOrderView(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<int, int> _orderCounts() {
    final active = OrderService.instance.activeOrders;
    final past = OrderService.instance.pastOrders;
    bool has(OrderItemModel order, Iterable<String> statuses) => statuses.any(
      (status) => order.statusText.toLowerCase() == status.toLowerCase(),
    );
    return {
      0: active.length + past.length,
      1: active.where((order) => has(order, ['To Pay', 'PENDING'])).length,
      2: active.where((order) => has(order, ['To Ship', 'PROCESSING'])).length,
      3: active
          .where(
            (order) =>
                has(order, ['OUT FOR DELIVERY', 'To Receive', 'In Transit']),
          )
          .length,
      4: past.where((order) => has(order, ['Delivered', 'Completed'])).length,
      5: [...active, ...past]
          .where(
            (order) =>
                order.statusText.toLowerCase().contains('return') ||
                order.statusText.toLowerCase().contains('refund'),
          )
          .length,
      6: [
        ...active,
        ...past,
      ].where((order) => order.statusText.toLowerCase() == 'cancelled').length,
    };
  }

  Widget _buildRefinedFilters(Map<int, int> counts) {
    final theme = Theme.of(context);
    final mainFilters = <(int, String)>[
      (0, 'All'),
      (1, 'To Pay'),
      (2, 'To Ship'),
      (3, 'To Receive'),
      (4, 'Completed'),
      (5, 'Return / Refund'),
      (6, 'Cancelled'),
    ];
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NexoraSpacing.xs),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: NexoraSpacing.md),
          child: Row(
            children: [
              for (final filter in mainFilters) ...[
                ChoiceChip(
                  key: ValueKey('orders-filter-${filter.$1}'),
                  selected: _selectedView == filter.$1,
                  label: Text(
                    counts[filter.$1] == 0
                        ? filter.$2
                        : '${filter.$2} ${counts[filter.$1]}',
                  ),
                  onSelected: (_) => setState(() {
                    _selectedView = filter.$1;
                  }),
                ),
                const SizedBox(width: NexoraSpacing.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefinedOrderView() {
    final service = OrderService.instance;
    final buyer = BuyerAccountService.instance.currentBuyer;
    final all = [...service.activeOrders, ...service.pastOrders];
    if (_selectedView == 5) return _buildRefinedReturns(all);

    Iterable<OrderItemModel> filtered = switch (_selectedView) {
      1 => service.activeOrders.where(
        (order) =>
            order.statusText == 'To Pay' || order.statusText == 'PENDING',
      ),
      2 => service.activeOrders.where(
        (order) =>
            order.statusText == 'To Ship' || order.statusText == 'PROCESSING',
      ),
      3 => service.activeOrders.where(
        (order) => const [
          'OUT FOR DELIVERY',
          'To Receive',
          'In Transit',
        ].contains(order.statusText),
      ),
      4 => service.pastOrders.where(
        (order) => const ['Delivered', 'Completed'].contains(order.statusText),
      ),
      6 => all.where((order) => order.statusText.toLowerCase() == 'cancelled'),
      _ => all,
    };

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final searchable = [
          order.orderId,
          order.statusText,
          ...order.items.expand(
            (item) => [item.title, item.storeName, item.variant],
          ),
        ].join(' ').toLowerCase();
        return searchable.contains(_searchQuery);
      });
    }
    final orders = filtered.toList();

    if (orders.isEmpty && _selectedView == 0 && _searchQuery.isEmpty) {
      if (buyer != null) return _buildRefinedNewcomerHub(buyer);
      return _buildRefinedEmpty(
        title: 'No orders yet',
        message: 'Your purchases and delivery updates will appear here.',
        icon: Icons.shopping_bag_outlined,
      );
    }
    if (orders.isEmpty) {
      final empty = switch (_selectedView) {
        1 => (
          'No pending payments',
          'Paid orders move to preparation automatically.',
          Icons.credit_score_outlined,
        ),
        2 => (
          'Nothing preparing',
          'Confirmed orders will appear here while sellers prepare them.',
          Icons.inventory_2_outlined,
        ),
        3 => (
          'No parcels in transit',
          'Live delivery updates appear here after courier pickup.',
          Icons.local_shipping_outlined,
        ),
        4 => (
          'No completed orders',
          'Delivered purchases will remain available here.',
          Icons.check_circle_outline,
        ),
        6 => (
          'No cancelled orders',
          'Cancelled purchases and their details will appear here.',
          Icons.cancel_outlined,
        ),
        _ => (
          'No matching orders',
          'Try another order number, store, or product name.',
          Icons.search_off_rounded,
        ),
      };
      return _buildRefinedEmpty(
        title: empty.$1,
        message: empty.$2,
        icon: empty.$3,
        showAction: _searchQuery.isEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: OrderService.instance.refreshOrdersFromSupabase,
      child: ListView.separated(
        key: const ValueKey('orders-results-list'),
        padding: const EdgeInsets.fromLTRB(
          NexoraSpacing.md,
          NexoraSpacing.sm,
          NexoraSpacing.md,
          NexoraSpacing.xxl,
        ),
        itemCount: orders.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: NexoraSpacing.md),
        itemBuilder: (context, index) {
          if (index == orders.length) return _buildRefinedGuarantee();
          return _buildRefinedOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildRefinedEmpty({
    required String title,
    required String message,
    required IconData icon,
    bool showAction = true,
  }) {
    return OrderEmptyState(
      title: title,
      message: message,
      icon: icon,
      actionLabel: showAction ? 'Discover products' : null,
      onAction: showAction
          ? () => Navigator.pushReplacementNamed(context, AppRoutes.home)
          : null,
    );
  }

  Widget _buildRefinedNewcomerHub(dynamic buyer) {
    final theme = Theme.of(context);
    final firstName = (buyer.firstName as String? ?? '').isNotEmpty
        ? buyer.firstName
        : 'Shopper';
    return ListView(
      key: const ValueKey('orders-newcomer-hub'),
      padding: const EdgeInsets.fromLTRB(
        NexoraSpacing.md,
        NexoraSpacing.sm,
        NexoraSpacing.md,
        NexoraSpacing.xxl,
      ),
      children: [
        Text(
          'Welcome to Nexora, $firstName!',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: NexoraSpacing.xs),
        Text(
          'Your orders will appear here. Start with your welcome benefit and delivery details.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: NexoraSpacing.xl),
        NexoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: NexoraSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₱150 Welcome Voucher',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: NexoraSpacing.xxs),
                        Text(
                          'Valid on any first order • Code: NEXORAFIRST',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NexoraSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _voucherClaimed
                      ? null
                      : () => setState(() => _voucherClaimed = true),
                  icon: Icon(
                    _voucherClaimed
                        ? Icons.check_rounded
                        : Icons.redeem_outlined,
                  ),
                  label: Text(_voucherClaimed ? 'Claimed' : 'Claim voucher'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NexoraSpacing.xl),
        Text('Next steps', style: theme.textTheme.titleMedium),
        const SizedBox(height: NexoraSpacing.sm),
        _buildRefinedChecklistItem(
          Icons.location_on_outlined,
          'Add a delivery address',
        ),
        _buildRefinedChecklistItem(
          Icons.shopping_bag_outlined,
          'Explore products and use your voucher at checkout',
        ),
      ],
    );
  }

  Widget _buildRefinedChecklistItem(IconData icon, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NexoraSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: NexoraSpacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildRefinedReturns(List<OrderItemModel> allOrders) {
    final returns = allOrders
        .where(
          (order) =>
              order.statusText.toLowerCase().contains('return') ||
              order.statusText.toLowerCase().contains('refund'),
        )
        .toList();
    return ListView(
      key: const ValueKey('returns-refunds-view'),
      padding: const EdgeInsets.fromLTRB(
        NexoraSpacing.md,
        NexoraSpacing.sm,
        NexoraSpacing.md,
        NexoraSpacing.xxl,
      ),
      children: [
        _buildRefinedReturnGuarantee(),
        const SizedBox(height: NexoraSpacing.md),
        if (returns.isEmpty)
          const OrderEmptyState(
            title: 'No Return or Refund Requests',
            message: 'You do not have any return or refund requests. Eligible purchases remain protected by the Nexora 15-day guarantee.',
            icon: Icons.assignment_return_outlined,
          )
        else
          ...returns.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: NexoraSpacing.md),
              child: _buildRefinedOrderCard(order),
            ),
          ),
      ],
    );
  }

  Widget _buildRefinedReturnGuarantee() {
    final theme = Theme.of(context);
    return NexoraCard(
      variant: NexoraCardVariant.primaryTint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: NexoraSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Return & Refund Guarantee',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: NexoraSpacing.xxs),
                Text(
                  'Eligible Nexora Mall items include 15-day returns with protected resolution.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedGuarantee() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NexoraSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: NexoraSpacing.xs),
          Flexible(
            child: Text(
              'Orders are protected by Nexora Guarantee',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedOrderCard(OrderItemModel order) {
    final theme = Theme.of(context);
    final items = order.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final firstItem = items.first;
    final isActive = !const [
      'Cancelled',
      'Completed',
      'Delivered',
    ].contains(order.statusText);

    return NexoraCard(
      key: ValueKey('order-card-${order.orderId}'),
      onTap: () => _openOrderDetails(order),
      semanticLabel: 'Order ${order.orderId}, ${order.statusText}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: NexoraSpacing.sm,
            runSpacing: NexoraSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(firstItem.storeName, style: theme.textTheme.titleMedium),
              OrderStatusBadge(label: order.statusText),
            ],
          ),
          const SizedBox(height: NexoraSpacing.xs),
          Text(
            '${order.orderId} • ${order.dateText}',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: NexoraSpacing.xl),
          _buildRefinedOrderItem(firstItem, items.length),
          if (isActive) ...[
            const SizedBox(height: NexoraSpacing.md),
            OrderProgressLine(
              progress: order.progress,
              label: order.etaText.isEmpty ? order.etaTime : order.etaText,
            ),
          ],
          const Divider(height: NexoraSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${items.fold<int>(0, (sum, item) => sum + item.quantity)} items',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                '₱${order.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: NexoraSpacing.md),
          _buildRefinedOrderActions(order),
        ],
      ),
    );
  }

  Widget _buildRefinedOrderItem(CartItemModel item, int itemCount) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stacked = constraints.maxWidth < 310 || textScale > 1.45;
        final image = ClipRRect(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: theme.colorScheme.surfaceContainer,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: stacked ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: NexoraSpacing.xs),
            Text(item.variant, style: theme.textTheme.bodySmall),
            if (itemCount > 1) ...[
              const SizedBox(height: NexoraSpacing.xs),
              Text(
                '+${itemCount - 1} more item${itemCount == 2 ? '' : 's'}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ],
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(height: NexoraSpacing.sm),
              details,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            const SizedBox(width: NexoraSpacing.sm),
            Expanded(child: details),
          ],
        );
      },
    );
  }

  Widget _buildRefinedOrderActions(OrderItemModel order) {
    final status = order.statusText.toLowerCase();
    final toPay = status == 'to pay' || status == 'pending';
    final toShip = status == 'to ship' || status == 'processing';
    final toReceive =
        status.contains('receive') ||
        status.contains('transit') ||
        status.contains('delivery');
    final completed = status.contains('complete') || status.contains('deliver');
    final cancelled = status.contains('cancel');

    final actions = <Widget>[
      if (toPay || toShip)
        OutlinedButton(
          onPressed: () => _cancelOrder(order),
          child: const Text('Cancel Order'),
        ),
      if (toPay)
        FilledButton(
          onPressed: () {
            OrderService.instance.payOrder(order.orderId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment successful. Your order is now preparing.',
                ),
              ),
            );
          },
          child: const Text('Pay Now'),
        )
      else if (toReceive)
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.orderTracking,
            arguments: order,
          ),
          icon: const Icon(Icons.location_on_outlined),
          label: const Text('Track Parcel'),
        )
      else if (completed)
        FilledButton(
          onPressed: order.isRated
              ? () => Navigator.pushNamed(context, AppRoutes.productDetails)
              : () => Navigator.pushNamed(
                  context,
                  AppRoutes.rateProduct,
                  arguments: order,
                ),
          child: Text(order.isRated ? 'Buy Again' : 'Rate Order'),
        )
      else if (cancelled)
        FilledButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.productDetails),
          child: const Text('Buy Again'),
        )
      else
        FilledButton(
          onPressed: () => _openOrderDetails(order),
          child: const Text('Order Details'),
        ),
    ];
    return Wrap(
      spacing: NexoraSpacing.xs,
      runSpacing: NexoraSpacing.xs,
      alignment: WrapAlignment.end,
      children: actions,
    );
  }

  void _openOrderDetails(OrderItemModel order) {
    final status = order.statusText.toLowerCase();
    final shipped =
        status.contains('ship') ||
        status.contains('receive') ||
        status.contains('transit') ||
        status.contains('delivery') ||
        status.contains('complete');
    Navigator.pushNamed(
      context,
      shipped ? AppRoutes.shippedOrderDetails : AppRoutes.orderDetails,
      arguments: order,
    );
  }

  void _cancelOrder(OrderItemModel order) {
    OrderService.instance.cancelOrder(order.orderId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Order cancelled.')));
  }

  Widget _buildLegacyOrders(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        OrderService.instance,
        BuyerAccountService.instance,
        AddressService.instance,
      ]),
      builder: (context, child) {
        int toPayCount = OrderService.instance.activeOrders
            .where((o) => o.statusText == 'To Pay' || o.statusText == 'PENDING')
            .length;
        int toShipCount = OrderService.instance.activeOrders
            .where(
              (o) => o.statusText == 'To Ship' || o.statusText == 'PROCESSING',
            )
            .length;
        int toReceiveCount = OrderService.instance.activeOrders
            .where(
              (o) =>
                  o.statusText == 'OUT FOR DELIVERY' ||
                  o.statusText == 'To Receive' ||
                  o.statusText == 'In Transit',
            )
            .length;
        int cancelledCount =
            OrderService.instance.activeOrders
                .where((o) => o.statusText.toLowerCase() == 'cancelled')
                .length +
            OrderService.instance.pastOrders
                .where((o) => o.statusText.toLowerCase() == 'cancelled')
                .length;

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
                icon: const Icon(
                  Icons.insert_comment_outlined,
                  color: Colors.black87,
                  size: 22,
                ),
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
              color: Color(0xFF0066FF),
              shape: BoxShape.circle,
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

  Widget _buildNewcomerHub(dynamic buyer) {
    final firstName = (buyer.firstName as String? ?? '').isNotEmpty
        ? buyer.firstName
        : 'Shopper';
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0066FF).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0066FF).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NEWCOMER PRIVILEGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to Nexora, $firstName!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'As a new member, enjoy an exclusive welcome voucher on your first order.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Color(0xFF0066FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₱150 Welcome Voucher',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Valid on any first order • Code: NEXORAFIRST',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _voucherClaimed = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _voucherClaimed
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  _voucherClaimed ? 'Claimed ✓' : 'Claim Voucher',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'What should you do next?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _buildChecklistItem(
          Icons.check_circle_outline,
          'Claim your ₱150 Welcome Voucher',
        ),
        _buildChecklistItem(
          Icons.location_on_outlined,
          'Set up your Delivery Address',
        ),
        _buildChecklistItem(
          Icons.shopping_bag_outlined,
          'Start Shopping with ₱150 OFF',
        ),
      ],
    );
  }

  Widget _buildChecklistItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0066FF)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllOrdersTab() {
    final dynamicActive = OrderService.instance.activeOrders
        .map((o) => _buildDynamicOrderCard(o))
        .toList();
    final dynamicPast = OrderService.instance.pastOrders
        .map((o) => _buildDynamicOrderCard(o))
        .toList();
    final hasPendingPay = OrderService.instance.activeOrders.any(
      (o) => o.statusText == 'To Pay' || o.statusText == 'PENDING',
    );

    final buyer = BuyerAccountService.instance.currentBuyer;
    if (dynamicActive.isEmpty && dynamicPast.isEmpty) {
      if (buyer != null) {
        return _buildNewcomerHub(buyer);
      }
      return _buildEmptyOrdersState(
        'No Orders Yet',
        'When you place orders, they will appear here.',
        Icons.shopping_bag_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (hasPendingPay) _buildUrgentNotice(),
        ...dynamicActive,
        ...dynamicPast,
        _buildNexoraGuaranteeFooter(),
      ],
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
            'All orders are protected by Nexora Guarantee',
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

  Widget _buildToPayTab() {
    final toPay = OrderService.instance.activeOrders
        .where((o) => o.statusText == 'To Pay' || o.statusText == 'PENDING')
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (toPay.isEmpty) {
      return _buildEmptyOrdersState(
        'No Pending Payments',
        'All of your orders have been paid for.',
        Icons.credit_score_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [_buildUrgentNotice(), ...toPay],
    );
  }

  Widget _buildToShipTab() {
    final toShip = OrderService.instance.activeOrders
        .where((o) => o.statusText == 'To Ship' || o.statusText == 'PROCESSING')
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (toShip.isEmpty) {
      return _buildEmptyOrdersState(
        'No Orders To Ship',
        'Items will appear here once orders are confirmed and preparing.',
        Icons.local_shipping_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: toShip,
    );
  }

  Widget _buildToReceiveTab() {
    final toReceive = OrderService.instance.activeOrders
        .where(
          (o) =>
              o.statusText == 'OUT FOR DELIVERY' ||
              o.statusText == 'To Receive' ||
              o.statusText == 'In Transit',
        )
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (toReceive.isEmpty) {
      return _buildEmptyOrdersState(
        'No Orders To Receive',
        'Tracking updates will appear here once parcels are in transit.',
        Icons.inventory_2_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: toReceive,
    );
  }

  Widget _buildCompletedTab() {
    final completed = OrderService.instance.pastOrders
        .where(
          (o) => o.statusText == 'Delivered' || o.statusText == 'Completed',
        )
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    if (completed.isEmpty) {
      return _buildEmptyOrdersState(
        'No Completed Orders',
        'Delivered and received orders will appear here.',
        Icons.check_circle_outline,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: completed,
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
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF1E3A8A),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Return & Refund Guarantee',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Text(
                'Guidelines ',
                style: TextStyle(
                  color: Color(0xFF0066FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: Color(0xFF0066FF),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Nexora Mall items are eligible for 15 days free easy return. Safe packaging ensures speedy resolution.',
            style: TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnRefundTab() {
    final returnOrders = OrderService.instance.activeOrders
        .where(
          (o) =>
              o.statusText.toLowerCase().contains('return') ||
              o.statusText.toLowerCase().contains('refund'),
        )
        .map((o) => _buildDynamicOrderCard(o))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildReturnGuaranteeBanner(),
        if (returnOrders.isNotEmpty)
          ...returnOrders
        else ...[
          const SizedBox(height: 16),
          _buildEmptyOrdersState(
            'No Return or Refund Requests',
            'You do not have any return or refund requests. All your purchases are protected by Nexora 15-day Guarantee.',
            Icons.assignment_return_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildCancelledTab() {
    final dynamicCancelled = [
      ...OrderService.instance.activeOrders.where(
        (o) => o.statusText.toLowerCase() == 'cancelled',
      ),
      ...OrderService.instance.pastOrders.where(
        (o) => o.statusText.toLowerCase() == 'cancelled',
      ),
    ].map((o) => _buildDynamicOrderCard(o)).toList();

    if (dynamicCancelled.isEmpty) {
      return _buildEmptyOrdersState(
        'No Cancelled Orders',
        'You have no cancelled orders at this time.',
        Icons.check_circle_outline,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: dynamicCancelled,
    );
  }

  Widget _buildDynamicOrderCard(OrderItemModel order) {
    if (order.items.isEmpty) return const SizedBox();
    final firstItem = order.items.first;
    final tag = firstItem.storeBadge.isNotEmpty ? firstItem.storeBadge : 'MALL';
    final storeName = firstItem.storeName;
    final isCancelled = order.statusText == 'Cancelled';
    final isToPay =
        order.statusText == 'To Pay' || order.statusText == 'PENDING';
    final isToShip =
        order.statusText == 'To Ship' || order.statusText == 'PROCESSING';
    final isDelivered =
        order.statusText == 'Delivered' || order.statusText == 'Completed';

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
            if (isToShip ||
                order.statusText == 'To Receive' ||
                order.statusText == 'OUT FOR DELIVERY' ||
                isDelivered) {
              Navigator.pushNamed(
                context,
                AppRoutes.shippedOrderDetails,
                arguments: order,
              );
            } else {
              Navigator.pushNamed(
                context,
                AppRoutes.orderDetails,
                arguments: order,
              );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
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
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.statusText,
                      style: TextStyle(
                        color: isCancelled
                            ? const Color(0xFFEF4444)
                            : (isDelivered
                                  ? const Color(0xFF00A896)
                                  : const Color(0xFF0066FF)),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            image: DecorationImage(
                              image: NetworkImage(item.imageUrl),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                  fontWeight: FontWeight.w500,
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
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                  Row(
                                    children: [
                                      if (item.originalPrice != null &&
                                          item.originalPrice! > item.price) ...[
                                        Text(
                                          '₱${item.originalPrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 20, color: Color(0xFFF1F5F9)),

                // Footer Row 1 (The Math): Right-aligned item count & total price
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total ${order.items.length} ${order.items.length == 1 ? "item" : "items"}: ',
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

                // Footer Row 2 (The CTAs): Action buttons aligned to the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isCancelled) ...[
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.orderDetails,
                          arguments: order,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Cancellation Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.productDetails,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Buy Again',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (isToPay) ...[
                      OutlinedButton(
                        onPressed: () {
                          OrderService.instance.cancelOrder(order.orderId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order Cancelled')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          OrderService.instance.payOrder(order.orderId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment Successful! Order is now preparing.',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14),
                          ],
                        ),
                      ),
                    ] else if (order.statusText == 'To Receive' ||
                        order.statusText == 'OUT FOR DELIVERY') ...[
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.orderTracking,
                          arguments: order,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Track Parcel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Confirm Order Received?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              content: const Text(
                                'Have you received all items in good condition? Confirming will complete the order and move it to your Completed tab where you can rate the product.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text(
                                    'Not Yet',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    OrderService.instance.receiveOrder(
                                      order.orderId,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Order marked as received! You can now rate the product & delivery rider.',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                        action: SnackBarAction(
                                          label: 'RATE RIDER',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.rateProduct,
                                              arguments: order,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Yes, Received'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle_outline, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Order Received',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isToShip) ...[
                      OutlinedButton(
                        onPressed: () {
                          OrderService.instance.cancelOrder(order.orderId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order Cancelled')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.shippedOrderDetails,
                          arguments: order,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              'Order Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 14),
                          ],
                        ),
                      ),
                    ] else ...[
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.chat),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Contact Seller',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isDelivered
                            ? (order.isRated
                                  ? () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.productDetails,
                                    )
                                  : () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.rateProduct,
                                      arguments: order,
                                    ))
                            : () => Navigator.pushNamed(
                                context,
                                AppRoutes.orderTracking,
                                arguments: order,
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isDelivered
                                  ? (order.isRated ? 'Buy Again' : 'Rate')
                                  : 'Track Order',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isDelivered && !order.isRated) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 14),
                            ] else if (!isDelivered) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 14),
                            ],
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
          const Icon(
            Icons.access_time_filled,
            color: Color(0xFF5A728A),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urgent Payment Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    children: [
                      TextSpan(text: 'Please pay within '),
                      TextSpan(
                        text: '23h 45m',
                        style: TextStyle(
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
