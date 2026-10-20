import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';

class ShippedOrderDetailsPage extends StatelessWidget {
  final OrderItemModel? order;

  const ShippedOrderDetailsPage({
    super.key,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    final currentOrder = order;
    // Fallback data if navigated without arguments (matching the reference design)
    final orderId = currentOrder?.orderId ?? 'NX-20240809-771890';
    final items = currentOrder?.items ?? [
      CartItemModel(
        id: '1',
        title: '10pcs Universal Cable Clips',
        variant: 'Cable Clip 28*10mm',
        price: 37.0,
        originalPrice: 199.0,
        imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=200&q=80',
        quantity: 1,
        storeName: 'PixiePH',
        storeBadge: 'MALL',
      ),
      CartItemModel(
        id: '2',
        title: '3MP CCTV Camera Pro HD',
        variant: 'Q6 Pro 3MP + SD 32GB',
        price: 969.0,
        originalPrice: 2999.0,
        imageUrl: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?auto=format&fit=crop&w=200&q=80',
        quantity: 1,
        storeName: 'PixiePH',
        storeBadge: 'MALL',
      ),
    ];

    final storeName = items.isNotEmpty ? items.first.storeName : 'PixiePH';
    final storeBadge = items.isNotEmpty ? items.first.storeBadge : 'MALL';
    final totalOrderPrice = currentOrder?.totalPrice ?? 926.0;
    final totalItemsCount = items.length;

    final userProfile = ProfileService.instance;
    final recipientName = (currentOrder != null && currentOrder.recipientName.isNotEmpty)
        ? currentOrder.recipientName
        : (userProfile.name.isNotEmpty ? userProfile.name : 'Alex Rivera');
    final recipientPhone = (currentOrder != null && currentOrder.recipientPhone.isNotEmpty)
        ? currentOrder.recipientPhone
        : (userProfile.phone.isNotEmpty ? userProfile.phone : '(+63) 917 123 4567');
    final recipientAddress = (currentOrder != null && currentOrder.shippingAddress.isNotEmpty)
        ? currentOrder.shippingAddress
        : (userProfile.address.isNotEmpty
            ? userProfile.address
            : 'Unit 402, Lumina Heights Tower 2, Makati, Metro Manila');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Header Banner
            _buildDeliveryEstimateBanner(currentOrder),

            // Guaranteed On-Time Delivery Card
            _buildGuaranteedDeliveryCard(),

            // Shipping Information Card
            _buildShippingInfoCard(context, currentOrder),

            // Delivery Information Card
            _buildDeliveryInfoCard(recipientName, recipientPhone, recipientAddress),

            // Product & Store Card
            _buildProductSectionCard(storeBadge, storeName, items, totalItemsCount, totalOrderPrice),

            // Payment & Order Details Card
            _buildPaymentAndOrderDetailsCard(currentOrder, orderId),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context, currentOrder, orderId),
    );
  }

  Widget _buildDeliveryEstimateBanner(OrderItemModel? order) {
    final current = order;
    final etaText = (current != null && current.etaTime.isNotEmpty)
        ? current.etaTime
        : '09 Aug – 12 Aug';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E2E), // Deep dark navy
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated delivery date: $etaText',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order?.etaText ?? 'Seller will arrange your order shortly',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteedDeliveryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time, color: Color(0xFF00C1D4), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
                    children: [
                      TextSpan(
                        text: 'Guaranteed On-Time Delivery: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'Get a ₱50 voucher if no delivery was attempted by 12-08-2024.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'View More',
                  style: TextStyle(
                    color: Color(0xFF00C1D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoCard(BuildContext context, OrderItemModel? order) {
    final shippingOption = order?.shippingOption ?? 'Standard Local Delivery';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHIPPING INFORMATION',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF475569), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nexora Express – SPX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shippingOption,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.orderTracking,
                    arguments: order,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('Track', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Miniature 4-Step Stepper
          _buildMiniStepper(context, order),
        ],
      ),
    );
  }

  Widget _buildMiniStepper(BuildContext context, OrderItemModel? order) {
    final status = order?.statusText.toLowerCase() ?? 'to receive';
    int currentStep = 2;
    if (status.contains('complete') || status.contains('delivered')) {
      currentStep = 3;
    } else if (status.contains('receive') ||
        status.contains('delivery') ||
        status.contains('transit') ||
        status.contains('shipping') ||
        status.contains('shipped')) {
      currentStep = 2;
    } else if (status.contains('ship') || status.contains('process')) {
      currentStep = 1;
    } else if (status.contains('pay')) {
      currentStep = 0;
    }

    final steps = [
      {'title': 'Placed', 'icon': Icons.check},
      {'title': 'Packed', 'icon': Icons.inventory_2_outlined},
      {'title': 'Out for Delivery', 'icon': Icons.two_wheeler_rounded},
      {'title': 'Delivered', 'icon': Icons.done_all_rounded},
    ];

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.orderTracking,
          arguments: order,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Row(
              children: List.generate(steps.length * 2 - 1, (index) {
                if (index.isOdd) {
                  final lineIndex = index ~/ 2;
                  final isPassed = currentStep > lineIndex;
                  return Expanded(
                    child: Container(
                      height: 2.5,
                      color: isPassed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    ),
                  );
                }

                final stepIndex = index ~/ 2;
                final isPassed = currentStep > stepIndex;
                final isCurrent = currentStep == stepIndex;

                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFF10B981)
                        : (isCurrent ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF0066FF)
                          : (isPassed ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isPassed
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : (isCurrent
                            ? const Icon(Icons.two_wheeler, size: 12, color: Colors.white)
                            : Text(
                                '${stepIndex + 1}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                              )),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.map((s) {
                final idx = steps.indexOf(s);
                final isCurrent = currentStep == idx;
                return SizedBox(
                  width: 68,
                  child: Text(
                    s['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? const Color(0xFF0066FF) : const Color(0xFF64748B),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Tap to view live GPS & Courier tracking',
                  style: TextStyle(
                    color: Color(0xFF00C1D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF00C1D4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard(String recipientName, String recipientPhone, String recipientAddress) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY INFORMATION',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F8FC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined, color: Color(0xFF00C1D4), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        children: [
                          TextSpan(
                            text: '$recipientName ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '| $recipientPhone',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipientAddress,
                      style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSectionCard(
    String storeBadge,
    String storeName,
    List<CartItemModel> items,
    int totalCount,
    double totalPrice,
  ) {
    // Group items by storeName so each merchant has its own section
    final Map<String, List<CartItemModel>> storeMap = {};
    for (final item in items) {
      final key = item.storeName.isNotEmpty ? item.storeName : storeName;
      storeMap.putIfAbsent(key, () => []).add(item);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                // Store Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: currentStoreBadge.toUpperCase() == 'MALL'
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF00C1D4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentStoreBadge.isNotEmpty ? currentStoreBadge : 'MALL',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentStoreName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
                  ],
                ),
                const SizedBox(height: 12),

                // Items list
                ...currentStoreItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              image: DecorationImage(
                                image: NetworkImage(item.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.variant,
                                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F8FC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: const Text(
                                    'Change of Mind Returns',
                                    style: TextStyle(color: Color(0xFF0090A8), fontSize: 9, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (item.originalPrice != null && item.originalPrice! > item.price) ...[
                                      Text(
                                        '₱${item.originalPrice!.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.black38,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      '₱${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            );
          }),

          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // Order Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total ($totalCount items)',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                '₱${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndOrderDetailsCard(OrderItemModel? order, String orderId) {
    final paymentMethod = order?.paymentMethod ?? 'Cash on Delivery';
    final placedDate = order?.orderDateTimeText ?? 'Today';
    final subtotal = order?.subtotal ?? (order?.totalPrice ?? 926.0);
    final shippingFee = order?.shippingFee ?? 38.0;
    final discount = order?.discount ?? 0.0;
    final total = order?.totalPrice ?? (subtotal + shippingFee - discount);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT & ORDER DETAILS',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Payment Method
          Row(
            children: [
              const Icon(Icons.payment_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text('Payment Method', style: TextStyle(color: Colors.black54, fontSize: 12)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paymentMethod,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order ID
          Row(
            children: [
              const Icon(Icons.copy_all_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text('Order ID', style: TextStyle(color: Colors.black54, fontSize: 12)),
              const Spacer(),
              Text(
                orderId,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F8FC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('COPY', style: TextStyle(color: Color(0xFF00C1D4), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Placed
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text('Order Placed', style: TextStyle(color: Colors.black54, fontSize: 12)),
              const Spacer(),
              Text(
                placedDate,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Financial Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Merchandise Subtotal', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('₱${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shipping Fee', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('₱${shippingFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Voucher Discount', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text('-₱${discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF00C1D4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, OrderItemModel? order, String orderId) {
    final isToReceive = order?.statusText == 'To Receive' || order?.statusText == 'OUT FOR DELIVERY';

    return Container(
      padding: const EdgeInsets.all(14),
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
                  if (isToReceive) {
                    Navigator.pushNamed(context, AppRoutes.chat);
                  } else {
                    OrderService.instance.cancelOrder(orderId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order Cancelled')),
                    );
                    Navigator.pop(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isToReceive ? 'Contact Courier' : 'Cancel Order',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (isToReceive) {
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
                              OrderService.instance.receiveOrder(orderId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order marked as received! Moved to Completed.'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                              Navigator.pop(context);
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
                  } else {
                    Navigator.pushNamed(context, AppRoutes.chat);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C1D4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isToReceive) ...[
                      const Icon(Icons.check_circle_outline, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isToReceive ? 'Order Received' : 'Contact Seller',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
}
