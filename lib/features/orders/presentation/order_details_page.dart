import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:nexora_flutter_app/features/chat/presentation/chat_detail_page.dart';

class OrderDetailsPage extends StatelessWidget {
  final OrderItemModel? order;

  const OrderDetailsPage({
    super.key,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OrderService.instance,
      builder: (context, _) {
        // Resolve latest order state from OrderService if available
        OrderItemModel? activeOrder = order;
        if (activeOrder != null) {
          final cleanId = activeOrder.orderId.replaceAll('#', '').trim().toLowerCase();
          final allOrders = [
            ...OrderService.instance.activeOrders,
            ...OrderService.instance.pastOrders,
          ];
          for (final o in allOrders) {
            if (o.orderId.replaceAll('#', '').trim().toLowerCase() == cleanId) {
              activeOrder = o;
              break;
            }
          }
        }
        final orderId = activeOrder?.orderId ?? 'NX-2602170F1KMYAD';
        final statusText = activeOrder?.statusText ?? 'Cancelled';
        final isCancelled = statusText.toLowerCase() == 'cancelled';
        final isToPay = statusText.toLowerCase() == 'to pay' || statusText.toLowerCase() == 'pending';
        final isToShip = statusText.toLowerCase() == 'to ship' || statusText.toLowerCase() == 'processing';

        final items = (activeOrder?.items.isNotEmpty ?? false)
            ? activeOrder!.items
            : [
                CartItemModel(
                  id: 'def_item',
                  storeName: 'blk cosmetics',
                  storeBadge: 'Mall',
                  title: 'blk cosmetics face stacks',
                  variant: 'Variant: getaway car • Qty: 1',
                  price: 449.00,
                  originalPrice: 499.00,
                  imageUrl:
                      'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=300&q=80',
                  quantity: 1,
                ),
              ];

        final firstItem = items.first;
        final storeName = firstItem.storeName;
        final storeBadge = firstItem.storeBadge.isNotEmpty ? firstItem.storeBadge : 'Mall';
        final totalPayment = activeOrder?.totalPrice ?? 458.00;
        final paymentMethod = activeOrder?.paymentMethod ?? 'Cash on Delivery';

        final userProfile = ProfileService.instance;
        final recipientName = (activeOrder != null && activeOrder.recipientName.isNotEmpty)
            ? activeOrder.recipientName
            : (userProfile.name.isNotEmpty ? userProfile.name : 'Maria Sofia');
        final recipientPhone = (activeOrder != null && activeOrder.recipientPhone.isNotEmpty)
            ? activeOrder.recipientPhone
            : (userProfile.phone.isNotEmpty ? userProfile.phone : '(+63) 953 732 3290');
        final recipientAddress = (activeOrder != null && activeOrder.shippingAddress.isNotEmpty)
            ? activeOrder.shippingAddress
            : (userProfile.address.isNotEmpty
                ? userProfile.address
                : '355 Sta Catalina, Holy Spirit, Quezon City, Metro Manila 1127');

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Order Details',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.black87),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nexora Customer Care & Resolution Center')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildDynamicStatusBanner(isToPay, isCancelled, isToShip, activeOrder),
                _buildShippingInfo(isToPay, isCancelled, isToShip, activeOrder),
                _buildDeliveryInfo(recipientName, recipientPhone, recipientAddress),
                _buildProductSection(context, storeBadge, storeName, items, totalPayment),
                _buildSupportCenter(context),
                _buildOrderInfo(orderId, paymentMethod, activeOrder, isCancelled),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, orderId, isToPay, isCancelled, activeOrder),
        );
      },
    );
  }

  Widget _buildDynamicStatusBanner(
      bool isToPay, bool isCancelled, bool isToShip, OrderItemModel? order) {
    if (isToPay) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F1E2E), Color(0xFF1E3A8A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.access_time_filled, color: Color(0xFF0066FF), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'To Pay • Awaiting Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please settle your payment within 23h 45m so the seller can start preparing your order.',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.credit_card_outlined, color: Colors.white54, size: 28),
          ],
        ),
      );
    }

    if (isCancelled) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF475569), Color(0xFF64748B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order != null ? 'Order Cancelled (${order.dateText})' : 'Order Cancelled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cancelled by buyer • Refund processed or order closed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.receipt_long, color: Colors.white54, size: 30),
          ],
        ),
      );
    }

    // Default / To Ship / Other Status
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052FF), Color(0xFF0066FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order?.statusText ?? 'Order Confirmed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order?.etaText ?? 'Seller is preparing your order for courier drop-off',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.inventory_2_outlined, color: Colors.white54, size: 28),
        ],
      ),
    );
  }

  Widget _buildShippingInfo(
      bool isToPay, bool isCancelled, bool isToShip, OrderItemModel? order) {
    String stepTitle = isToPay
        ? 'Awaiting payment confirmation before dispatch'
        : isCancelled
            ? 'Order was cancelled before shipment'
            : (order?.etaText ?? 'Sender is preparing to ship your parcel');

    String stepTime = order?.dateText ?? 'Today';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: const [
                  Text('Details',
                      style: TextStyle(
                          color: Color(0xFF0066FF), fontSize: 12, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: Color(0xFF0066FF), size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('SPX EXPRESS',
                    style: TextStyle(
                        color: Color(0xFF008060), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Text(order?.orderId.replaceAll('#', '') ?? 'NX268291558799U',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const Spacer(),
                const Text('Copy',
                    style: TextStyle(
                        color: Color(0xFF0066FF), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isToPay
                      ? const Color(0xFFFEF3C7)
                      : isCancelled
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFE5F8FC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isToPay
                      ? Icons.payment_outlined
                      : isCancelled
                          ? Icons.close_rounded
                          : Icons.local_shipping_outlined,
                  color: isToPay
                      ? const Color(0xFFD97706)
                      : isCancelled
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF008060),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isToPay
                            ? const Color(0xFFD97706)
                            : isCancelled
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF008060),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(stepTime,
                        style: const TextStyle(color: Colors.black45, fontSize: 12)),
                    if (order != null && !isCancelled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler_rounded, size: 15, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Assigned Rider: ${order.courierName} (★ ${OrderService.instance.getLiveCourierRating(order.courierName, fallback: order.courierRating).toStringAsFixed(2)})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                          ),
                          if (order.isRated)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'You rated ${order.buyerDriverRating ?? 5}★',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(String recipientName, String phone, String address) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF5B6C8C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    children: [
                      TextSpan(
                          text: '$recipientName ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: phone, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(
    BuildContext context,
    String storeBadge,
    String storeName,
    List<CartItemModel> items,
    double totalPayment,
  ) {
    final Map<String, List<CartItemModel>> storeMap = {};
    for (final item in items) {
      final key = item.storeName.isNotEmpty ? item.storeName : storeName;
      storeMap.putIfAbsent(key, () => []).add(item);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ...storeMap.entries.map((entry) {
            final currentStoreName = entry.key;
            final currentStoreItems = entry.value;
            final currentStoreBadge = currentStoreItems.first.storeBadge.isNotEmpty
                ? currentStoreItems.first.storeBadge
                : storeBadge;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentStoreBadge,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentStoreName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _openStoreChat(context, currentStoreName, currentStoreBadge),
                      child: Row(
                        children: const [
                          Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF0066FF)),
                          SizedBox(width: 4),
                          Text('Chat',
                              style: TextStyle(
                                  color: Color(0xFF0066FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...currentStoreItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(item.imageUrl),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.variant,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: NexoraTheme.price),
                                  ),
                                  Text('x${item.quantity}',
                                      style: const TextStyle(color: Colors.black38, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payment (${items.length} ${items.length == 1 ? 'item' : 'items'}):',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Row(
                children: [
                  Text(
                    '₱${totalPayment.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: NexoraTheme.price),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black87),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCenter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Support Center',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          ),
          ListTile(
            onTap: () => _openStoreChat(
              context,
              _getOrderStoreName(order),
              _getOrderStoreBadge(order),
            ),
            leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF5B6C8C)),
            title: const Text('Contact Seller',
                style: TextStyle(fontSize: 14, color: Colors.black87)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          ListTile(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Help Center & Resolution Hub...')),
              );
            },
            leading: const Icon(Icons.help_outline, color: Color(0xFF5B6C8C)),
            title: const Text('Help Center & FAQ',
                style: TextStyle(fontSize: 14, color: Colors.black87)),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black45),
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(
      String orderId, String paymentMethod, OrderItemModel? order, bool isCancelled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Order ID', orderId, showCopy: true),
          const SizedBox(height: 12),
          _buildInfoRow('Payment Method', paymentMethod),
          const SizedBox(height: 12),
          _buildInfoRow('Order Date', order?.orderDateTimeText ?? order?.dateText ?? 'Today'),
          if (order != null && order.shippingOption.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Shipping Option', order.shippingOption),
          ],
          if (isCancelled) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Status', 'Order Cancelled'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool showCopy = false}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showCopy) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('COPY',
                      style: TextStyle(
                          color: Color(0xFF0066FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    String orderId,
    bool isToPay,
    bool isCancelled,
    OrderItemModel? order,
  ) {
    if (isToPay) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    OrderService.instance.cancelOrderRemote(orderId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order Cancelled')),
                    );
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel Order',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    OrderService.instance.payOrder(orderId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Payment Successful! Order moved to "To Ship".'),
                          ],
                        ),
                        backgroundColor: Color(0xFF0066FF),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Pay Now',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refund of purchase has completed.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Refund Details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Buy Again',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isCompleted = order != null &&
        (order.statusText.toLowerCase() == 'completed' ||
            order.statusText.toLowerCase() == 'delivered');

    // Other status
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (isCompleted) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.shippedOrderDetails,
                      arguments: order,
                    );
                  } else {
                    _openStoreChat(
                      context,
                      _getOrderStoreName(order),
                      _getOrderStoreBadge(order),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isCompleted ? 'Delivery Details' : 'Contact Seller',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (isCompleted) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.rateProduct,
                      arguments: order,
                    );
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.shippedOrderDetails,
                      arguments: order,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted && order.isRated
                      ? const Color(0xFF059669)
                      : const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCompleted) ...[
                      Icon(
                        order.isRated ? Icons.star_rounded : Icons.star_border,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isCompleted
                          ? (order.isRated
                              ? 'Rated (${order.buyerDriverRating ?? 5}★)'
                              : 'Rate')
                          : 'Track Parcel',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOrderStoreName(OrderItemModel? order) {
    if (order != null && order.items.isNotEmpty) {
      return order.items.first.storeName;
    }
    return 'Nexora Official Store';
  }

  String _getOrderStoreBadge(OrderItemModel? order) {
    if (order != null && order.items.isNotEmpty && order.items.first.storeBadge.isNotEmpty) {
      return order.items.first.storeBadge;
    }
    return 'MALL';
  }

  void _openStoreChat(BuildContext context, String storeName, String badge) {
    final conv = ChatService.instance.getOrCreateShopConversation(
      shopId: storeName.toLowerCase().replaceAll(' ', '_'),
      shopName: storeName,
      shopBadge: badge,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          conversationId: conv.id,
          title: conv.title,
          subtitle: badge,
          avatarIcon: conv.avatarIcon,
          avatarBgColor: conv.avatarBg,
          initialMessages: conv.messages.map((m) => m.toMap()).toList(),
        ),
      ),
    );
  }
}
