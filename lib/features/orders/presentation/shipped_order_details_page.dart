import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShippedOrderDetailsPage extends StatefulWidget {
  final OrderItemModel? order;

  const ShippedOrderDetailsPage({
    super.key,
    this.order,
  });

  @override
  State<ShippedOrderDetailsPage> createState() => _ShippedOrderDetailsPageState();
}

class _ShippedOrderDetailsPageState extends State<ShippedOrderDetailsPage> {
  OrderItemModel? _currentOrder;
  StreamSubscription? _orderStreamSub;
  bool _initializedArgs = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    OrderService.instance.addListener(_onOrderServiceChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is OrderItemModel) {
        _currentOrder = args;
      }
      _findLatestFromOrderService();
      _initSupabaseStream();
      OrderService.instance.refreshOrdersFromSupabase();
    }
  }

  @override
  void dispose() {
    OrderService.instance.removeListener(_onOrderServiceChanged);
    _orderStreamSub?.cancel();
    super.dispose();
  }

  void _findLatestFromOrderService() {
    final orderId = _currentOrder?.orderId.replaceAll('#', '').trim().toLowerCase();
    if (orderId == null || orderId.isEmpty) {
      final latest = OrderService.instance.latestActiveOrder ??
          (OrderService.instance.activeOrders.isNotEmpty ? OrderService.instance.activeOrders.first : null) ??
          (OrderService.instance.pastOrders.isNotEmpty ? OrderService.instance.pastOrders.first : null);
      if (latest != null && mounted) {
        setState(() {
          _currentOrder = latest;
        });
      }
      return;
    }

    final inActive = OrderService.instance.activeOrders.where(
      (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == orderId,
    );
    if (inActive.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currentOrder = inActive.first;
        });
      }
      return;
    }

    final inPast = OrderService.instance.pastOrders.where(
      (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == orderId,
    );
    if (inPast.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currentOrder = inPast.first;
        });
      }
      return;
    }
  }

  void _onOrderServiceChanged() {
    if (!mounted) return;
    _findLatestFromOrderService();
  }

  void _initSupabaseStream() {
    final rawId = _currentOrder?.orderId.replaceAll('#', '').trim();
    if (rawId == null || rawId.isEmpty) return;

    try {
      _orderStreamSub?.cancel();
      final isNumeric = int.tryParse(rawId) != null;
      final query = Supabase.instance.client.from('orders').stream(primaryKey: ['id']);
      _orderStreamSub = (isNumeric ? query.eq('id', int.parse(rawId)) : query.eq('order_id', rawId))
          .listen(
        (rows) {
          if (!mounted || rows.isEmpty) return;
          final row = rows.first;
          final status = (row['status'] ?? '').toString().toLowerCase().trim();
          _applyStatusUpdate(status);
        },
        onError: (err, stack) {
          debugPrint('📡 ShippedOrderDetails Supabase stream notice (offline/reconnecting): $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('⚠️ ShippedOrderDetails Supabase stream note: $e');
    }
  }

  void _applyStatusUpdate(String rawStatus) {
    if (_currentOrder == null || !mounted) return;
    final status = OrderService.normalizeRemoteStatus(rawStatus);
    OrderService.instance.syncOrderFromRemoteStatus(
      _currentOrder!.orderId,
      status,
    );
    _findLatestFromOrderService();
  }

  int _calculateStep(OrderItemModel? order) {
    if (order == null) return 0;
    final status = order.statusText.toLowerCase().trim();
    final eta = order.etaText.toLowerCase().trim();
    if (status.contains('complete') || status.contains('delivered') || order.progress >= 1.0) {
      return 3;
    }
    if (status.contains('receive') ||
        status.contains('delivery') ||
        status.contains('to_deliver') ||
        status.contains('road') ||
        status.contains('transit') ||
        status.contains('out for delivery') ||
        eta.contains('picked up') ||
        eta.contains('out for delivery') ||
        order.progress >= 0.7) {
      return 2;
    }
    if (order.isRiderAccepted ||
        order.progress >= 0.45 ||
        eta.contains('accepted') ||
        eta.contains('arrived at') ||
        eta.contains('scanning') ||
        eta.contains('packing')) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    OrderItemModel? currentOrder = _currentOrder;
    currentOrder ??= OrderService.instance.latestActiveOrder ??
        (OrderService.instance.activeOrders.isNotEmpty ? OrderService.instance.activeOrders.first : null) ??
        (OrderService.instance.pastOrders.isNotEmpty ? OrderService.instance.pastOrders.first : null);

    final rawOrderId = currentOrder?.orderId ?? 'NX-48786';
    final orderId = rawOrderId.startsWith('#') ? rawOrderId : '#$rawOrderId';

    final items = (currentOrder != null && currentOrder.items.isNotEmpty)
        ? currentOrder.items
        : [
            CartItemModel(
              id: '1',
              title: 'Nexora Pro Heavy Duty Suspension Boom Arm',
              variant: 'Standard Edition',
              price: 311.0,
              originalPrice: 450.0,
              imageUrl:
                  'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=300&q=80',
              quantity: 1,
              storeName: 'Nexora Official Flagship',
              storeBadge: 'MALL',
            ),
          ];

    final storeName = items.isNotEmpty ? items.first.storeName : 'Nexora Official Flagship';
    final storeBadge = items.isNotEmpty ? items.first.storeBadge : 'MALL';
    final totalOrderPrice = currentOrder?.totalPrice ?? 311.0;
    final totalItemsCount = items.fold<int>(0, (sum, it) => sum + it.quantity);

    final userProfile = ProfileService.instance;
    final recipientName = (currentOrder != null && currentOrder.recipientName.isNotEmpty)
        ? currentOrder.recipientName
        : (userProfile.name.isNotEmpty ? userProfile.name : 'John Mark Pitargue');
    final recipientPhone = (currentOrder != null && currentOrder.recipientPhone.isNotEmpty)
        ? currentOrder.recipientPhone
        : (userProfile.phone.isNotEmpty ? userProfile.phone : '(+63) 9759632035');
    final recipientAddress = (currentOrder != null && currentOrder.shippingAddress.isNotEmpty)
        ? currentOrder.shippingAddress
        : (userProfile.address.isNotEmpty
            ? userProfile.address
            : '192, Tuy-Baanan, Liliw, 4004');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Top Estimated Delivery Banner (Dark Navy)
            _buildEstimatedDeliveryBanner(currentOrder),

            // 2. Guaranteed On-Time Delivery Card
            _buildGuaranteedDeliveryCard(context),

            // 3. Shipping Information Card (Rider Info + Stepper + Live GPS)
            _buildShippingInfoCard(context, currentOrder),

            // 4. Delivery Information Card
            _buildDeliveryInfoCard(recipientName, recipientPhone, recipientAddress),

            // 5. Product & Store Card
            _buildProductSectionCard(context, storeBadge, storeName, items, totalItemsCount, totalOrderPrice),

            // 6. Payment & Order Details Card
            _buildPaymentAndOrderDetailsCard(context, currentOrder, orderId),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context, currentOrder, orderId),
    );
  }

  Widget _buildEstimatedDeliveryBanner(OrderItemModel? order) {
    final step = _calculateStep(order);
    final status = order?.statusText.toLowerCase() ?? '';
    final isCancelled = status.contains('cancel');
    final isDelivered = step >= 3 || status.contains('delivered') || status.contains('complete');
    final isOutForDelivery = step == 2 || status.contains('out for delivery') || status.contains('receive');

    String title;
    String subtitle;
    Color bgColor = const Color(0xFF0F172A);

    if (isCancelled) {
      title = 'Order Cancelled';
      subtitle = 'This order was cancelled';
      bgColor = const Color(0xFF7F1D1D);
    } else if (isDelivered) {
      title = 'Delivered Successfully';
      subtitle = 'Package was received safely by recipient';
      bgColor = const Color(0xFF064E3B);
    } else if (isOutForDelivery) {
      title = 'Out for Delivery • Expected: Today';
      subtitle = 'SPX Express courier is on the road with your package';
      bgColor = const Color(0xFF0F1E2E);
    } else {
      final etaText = (order != null && order.etaTime.isNotEmpty) ? order.etaTime : 'Tomorrow';
      title = 'Estimated delivery date: $etaText';
      subtitle = (order?.etaText.isNotEmpty == true)
          ? order!.etaText
          : 'Order Placed • Merchant is preparing your package';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCancelled) ...[
                const Icon(Icons.cancel_rounded, color: Color(0xFFF87171), size: 20),
                const SizedBox(width: 8),
              ] else if (isDelivered) ...[
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
              ] else if (isOutForDelivery) ...[
                const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0066FF), size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteedDeliveryCard(BuildContext context) {
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
          const Icon(Icons.access_time_rounded, color: Color(0xFF0066FF), size: 20),
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
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nexora Guaranteed On-Time Delivery: ₱50 credit if delayed.')),
                    );
                  },
                  child: const Text(
                    'View More',
                    style: TextStyle(
                      color: Color(0xFF0066FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
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
    final courierName = (order?.courierName.isNotEmpty == true) ? order!.courierName : 'Pedro Jose Garcia';
    final step = _calculateStep(order);
    final isRiderAccepted = order?.isRiderAccepted == true || step >= 1;

    final steps = [
      {'title': 'Placed', 'icon': Icons.check},
      {'title': 'Packed', 'icon': Icons.inventory_2_outlined},
      {'title': 'Out for\nDelivery', 'icon': Icons.two_wheeler_rounded},
      {'title': 'Delivered', 'icon': Icons.done_all_rounded},
    ];

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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Rider: $courierName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text(
                                OrderService.instance
                                    .getLiveCourierRating(
                                      courierName,
                                      fallback: order?.courierRating ?? 4.96,
                                    )
                                    .toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isRiderAccepted
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isRiderAccepted
                                ? '✓ Rider Accepted'
                                : 'Awaiting Rider Acceptance',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isRiderAccepted
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            shippingOption,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 13),
                label: const Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0066FF),
                  side: const BorderSide(color: Color(0xFF0066FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
              ),
              const SizedBox(width: 6),
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
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Track', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Stepper
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineIndex = index ~/ 2;
                final isPassed = step > lineIndex;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    color: isPassed ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isPassed = step > stepIndex;
              final isCurrent = step == stepIndex;

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (isPassed || isCurrent)
                      ? const Color(0xFF0066FF)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isPassed || isCurrent)
                        ? const Color(0xFF0066FF)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : (isCurrent
                          ? Icon(steps[stepIndex]['icon'] as IconData, size: 14, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.map((s) {
              final idx = steps.indexOf(s);
              final isCurrent = step == idx;
              final isPassed = step > idx;
              return SizedBox(
                width: 68,
                child: Text(
                  s['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: (isCurrent || isPassed) ? FontWeight.w800 : FontWeight.w600,
                    color: (isCurrent || isPassed)
                        ? const Color(0xFF0066FF)
                        : const Color(0xFF64748B),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.orderTracking,
                arguments: order,
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Tap to view live GPS & Courier tracking',
                    style: TextStyle(
                      color: Color(0xFF0066FF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF0066FF)),
                ],
              ),
            ),
          ),
        ],
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
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined, color: Color(0xFF0066FF), size: 20),
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
    BuildContext context,
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
                        color: const Color(0xFF0066FF),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 64,
                              height: 64,
                              color: const Color(0xFFF8FAFC),
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(
                                    Icons.headset_rounded,
                                    color: Color(0xFF0F172A),
                                    size: 32,
                                  ),
                                ),
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
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: const Text(
                                    'Change of Mind Returns',
                                    style: TextStyle(color: Color(0xFF0066FF), fontSize: 9, fontWeight: FontWeight.w600),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndOrderDetailsCard(BuildContext context, OrderItemModel? order, String orderId) {
    final paymentMethod = order?.paymentMethod ?? 'Cash on Delivery';
    final placedDate = (order?.orderDateTimeText.isNotEmpty == true) ? order!.orderDateTimeText : 'Today, 18:57';
    final subtotal = order?.subtotal ?? (order?.totalPrice ?? 311.0);
    final shippingFee = order?.shippingFee ?? 0.0;
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
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: orderId.replaceAll('#', '')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order ID copied to clipboard')),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('COPY', style: TextStyle(color: Color(0xFF0066FF), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
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
              Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, OrderItemModel? order, String orderId) {
    final step = _calculateStep(order);
    final isCancelled = (order?.statusText.toLowerCase().contains('cancel') ?? false);
    final isDelivered = step >= 3 || (order?.statusText.toLowerCase().contains('complete') ?? false) || (order?.statusText.toLowerCase().contains('delivered') ?? false);
    final isOutForDelivery = !isCancelled && (step == 2 || (order?.statusText.toLowerCase().contains('out for delivery') ?? false));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  if (isCancelled || isDelivered) {
                    Navigator.pushNamed(context, AppRoutes.home);
                  } else if (isOutForDelivery) {
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
                  (isCancelled || isDelivered) ? 'Buy Again' : (isOutForDelivery ? 'Contact Courier' : 'Cancel Order'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (isCancelled) {
                    Navigator.pushNamed(context, AppRoutes.chat);
                  } else if (isDelivered) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.rateProduct,
                      arguments: order,
                    );
                  } else if (isOutForDelivery) {
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
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
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
                  backgroundColor: isDelivered ? const Color(0xFF10B981) : const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCancelled) ...[
                      const Text(
                        'Contact Support',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ] else if (isDelivered) ...[
                      const Icon(Icons.star_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        order?.isRated == true
                            ? 'Rated (${order?.buyerDriverRating ?? 5}★)'
                            : 'Rate',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ] else if (isOutForDelivery) ...[
                      const Icon(Icons.check_circle_outline, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Order Received',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      const Text(
                        'Contact Seller',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
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
