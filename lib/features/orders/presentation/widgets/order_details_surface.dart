import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';

import 'order_components.dart';

class OrderDetailsSurface extends StatelessWidget {
  const OrderDetailsSurface({
    super.key,
    required this.order,
    this.liveDelivery = false,
  });

  final OrderItemModel? order;
  final bool liveDelivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = order;
    if (current == null) {
      return Scaffold(
        appBar: const NexoraAppBar(
          titleText: 'Order details',
          fallbackRoute: AppRoutes.orders,
        ),
        body: OrderEmptyState(
          title: 'Order unavailable',
          message: 'This order could not be loaded. Return to your orders and try again.',
          icon: Icons.receipt_long_outlined,
          actionLabel: 'Back to orders',
          onAction: () => Navigator.maybePop(context),
        ),
      );
    }

    return Scaffold(
      appBar: NexoraAppBar(
        titleText: 'Order details',
        fallbackRoute: AppRoutes.orders,
        actions: [
          IconButton(
            tooltip: 'Contact support',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
            icon: const Icon(Icons.support_agent_outlined),
          ),
          const SizedBox(width: NexoraSpacing.xs),
        ],
      ),
      body: ListView(
        key: const ValueKey('order-details-scroll-view'),
        padding: const EdgeInsets.fromLTRB(
          NexoraSpacing.md,
          NexoraSpacing.xs,
          NexoraSpacing.md,
          NexoraSpacing.xxl,
        ),
        children: [
          _buildStatusHeader(context, current),
          const SizedBox(height: NexoraSpacing.md),
          _buildProgress(context, current),
          const SizedBox(height: NexoraSpacing.md),
          _OrderSection(
            title: 'Delivery',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.recipientName, style: theme.textTheme.bodyMedium),
                const SizedBox(height: NexoraSpacing.xxs),
                Text(current.recipientPhone, style: theme.textTheme.bodySmall),
                const SizedBox(height: NexoraSpacing.xs),
                Text(
                  current.shippingAddress,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: NexoraSpacing.md),
          _OrderSection(
            title: current.items.isEmpty
                ? 'Items'
                : current.items.first.storeName,
            icon: Icons.storefront_outlined,
            child: current.items.isEmpty
                ? Text(
                    'No product details available.',
                    style: theme.textTheme.bodySmall,
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < current.items.length;
                        index++
                      ) ...[
                        if (index > 0) const Divider(height: NexoraSpacing.xl),
                        _OrderItemRow(item: current.items[index]),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: NexoraSpacing.md),
          _OrderSection(
            title: 'Payment summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _DetailsRow(
                  label: 'Merchandise',
                  value: '₱${current.subtotal.toStringAsFixed(2)}',
                ),
                _DetailsRow(
                  label: 'Shipping',
                  value: current.shippingFee == 0
                      ? 'FREE'
                      : '₱${current.shippingFee.toStringAsFixed(2)}',
                ),
                if (current.discount > 0)
                  _DetailsRow(
                    label: 'Discount',
                    value: '-₱${current.discount.toStringAsFixed(2)}',
                    valueColor: theme.colorScheme.primary,
                  ),
                const Divider(height: NexoraSpacing.xl),
                _DetailsRow(
                  label: 'Total payment',
                  value: '₱${current.totalPrice.toStringAsFixed(2)}',
                  emphasized: true,
                ),
                const SizedBox(height: NexoraSpacing.sm),
                _DetailsRow(
                  label: 'Payment method',
                  value: current.paymentMethod,
                ),
                _DetailsRow(label: 'Order number', value: current.orderId),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActions(context, current),
    );
  }

  Widget _buildStatusHeader(BuildContext context, OrderItemModel order) {
    final theme = Theme.of(context);
    return Material(
      color: NexoraTheme.darkNavy,
      borderRadius: BorderRadius.circular(NexoraRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(NexoraSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrderStatusBadge(label: order.statusText),
            const SizedBox(height: NexoraSpacing.md),
            Text(
              _statusTitle(order),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: NexoraSpacing.xs),
            Text(
              order.etaTime.isEmpty ? order.etaText : order.etaTime,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFCBD5E1),
                height: 1.4,
              ),
            ),
            const SizedBox(height: NexoraSpacing.md),
            Text(
              '${order.orderId} • ${order.orderDateTimeText}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusTitle(OrderItemModel order) {
    final status = order.statusText.toLowerCase();
    if (status.contains('cancel')) return 'This order was cancelled';
    if (status.contains('complete') || status.contains('deliver')) {
      return 'Delivered successfully';
    }
    if (status.contains('receive') || status.contains('transit')) {
      return 'Your parcel is on the way';
    }
    if (status.contains('pay') || status.contains('pending')) {
      return 'Payment is still required';
    }
    return 'The seller is preparing your order';
  }

  Widget _buildProgress(BuildContext context, OrderItemModel order) {
    final status = order.statusText.toLowerCase();
    if (status.contains('cancel')) return const SizedBox.shrink();
    return _OrderSection(
      title: liveDelivery ? 'Delivery progress' : 'Order progress',
      icon: Icons.route_outlined,
      trailing:
          liveDelivery &&
              (status.contains('receive') || status.contains('transit'))
          ? TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.orderTracking,
                arguments: order,
              ),
              child: const Text('Live map'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderProgressLine(progress: order.progress, label: order.etaText),
          const SizedBox(height: NexoraSpacing.md),
          Wrap(
            spacing: NexoraSpacing.sm,
            runSpacing: NexoraSpacing.xs,
            children: const [
              _Milestone(label: 'Placed'),
              _Milestone(label: 'Preparing'),
              _Milestone(label: 'In transit'),
              _Milestone(label: 'Delivered'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, OrderItemModel order) {
    final theme = Theme.of(context);
    final status = order.statusText.toLowerCase();
    final toPay = status == 'to pay' || status == 'pending';
    final toShip = status == 'to ship' || status == 'processing';
    final inTransit =
        status.contains('receive') ||
        status.contains('transit') ||
        status.contains('delivery');
    final completed = status.contains('complete') || status.contains('deliver');
    final cancelled = status.contains('cancel');

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(NexoraSpacing.md),
          child: Wrap(
            spacing: NexoraSpacing.xs,
            runSpacing: NexoraSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Get help'),
              ),
              if (toPay || toShip)
                OutlinedButton(
                  onPressed: () {
                    OrderService.instance.cancelOrder(order.orderId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order cancelled.')),
                    );
                  },
                  child: const Text('Cancel order'),
                ),
              if (toPay)
                FilledButton(
                  onPressed: () {
                    OrderService.instance.payOrder(order.orderId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment successful.')),
                    );
                  },
                  child: const Text('Pay now'),
                )
              else if (inTransit)
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.orderTracking,
                    arguments: order,
                  ),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Track parcel'),
                )
              else if (completed)
                FilledButton(
                  onPressed: order.isRated
                      ? () => Navigator.pushNamed(
                          context,
                          AppRoutes.productDetails,
                        )
                      : () => Navigator.pushNamed(
                          context,
                          AppRoutes.rateProduct,
                          arguments: order,
                        ),
                  child: Text(order.isRated ? 'Buy again' : 'Rate order'),
                )
              else if (cancelled)
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.productDetails),
                  child: const Text('Buy again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSection extends StatelessWidget {
  const _OrderSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return NexoraCard.section(
      title: Text(title),
      icon: Icon(icon),
      trailing: trailing,
      child: child,
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.45;
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
                  Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: NexoraSpacing.xs),
            Text(item.variant, style: theme.textTheme.bodySmall),
            const SizedBox(height: NexoraSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text('×${item.quantity}', style: theme.textTheme.labelLarge),
              ],
            ),
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
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NexoraSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: NexoraSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: style?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.circle, size: 10),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
