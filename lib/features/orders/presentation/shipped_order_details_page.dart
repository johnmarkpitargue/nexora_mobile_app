import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/order_service.dart';
import 'widgets/order_action_dialogs.dart';

class ShippedOrderDetailsPage extends StatefulWidget {
  final OrderItemModel? order;

  const ShippedOrderDetailsPage({
    super.key,
    this.order,
  });

  @override
  State<ShippedOrderDetailsPage> createState() =>
      _ShippedOrderDetailsPageState();
}

class _ShippedOrderDetailsPageState extends State<ShippedOrderDetailsPage> {
  OrderItemModel? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
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
      _resolveLatestOrder();
      _loadOrderDetail();
    }
  }

  @override
  void dispose() {
    OrderService.instance.removeListener(_onOrderServiceChanged);
    super.dispose();
  }

  void _onOrderServiceChanged() {
    if (!mounted) return;
    _resolveLatestOrder();
  }

  void _resolveLatestOrder() {
    final serverId = _currentOrder?.serverId ?? 0;
    if (serverId > 0) {
      final found = OrderService.instance.findOrderByServerId(serverId);
      if (found != null && mounted) {
        setState(() {
          _currentOrder = found;
        });
        return;
      }
    }
    final rawId = _currentOrder?.orderId ?? '';
    if (rawId.isNotEmpty) {
      final found = OrderService.instance.findOrderById(rawId);
      if (found != null && mounted) {
        setState(() {
          _currentOrder = found;
        });
      }
    }
  }

  Future<void> _loadOrderDetail() async {
    final serverId = _currentOrder?.serverId ?? 0;
    if (serverId <= 0 || !ApiClient.instance.hasToken) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updated = await OrderService.instance.fetchOrderDetailRemote(serverId);
      if (mounted) {
        setState(() {
          _currentOrder = updated;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to refresh order details.';
        });
      }
    }
  }

  int _calculateStep(OrderItemModel order) {
    final s = order.rawStatus.toLowerCase().trim();
    if (s == 'delivered' || s == 'completed') return 4;
    if (s == 'out_for_delivery' || s == 'assigned_to_rider') return 3;
    if (s == 'picked_up' ||
        s == 'at_hub' ||
        s == 'received_at_hub' ||
        s == 'in_transit_hub' ||
        s == 'in_transit' ||
        s == 'sorted' ||
        s == 'sorting_hub') {
      return 2;
    }
    if (s == 'preparing' || s == 'processing' || s == 'ready_for_pickup') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;

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
          'Order Tracking & Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (order != null && order.serverId > 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF0F172A)),
              tooltip: 'Refresh Status',
              onPressed: _loadOrderDetail,
            ),
        ],
      ),
      body: order == null && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? _buildNotFoundState()
              : RefreshIndicator(
                  onRefresh: _loadOrderDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (_errorMessage != null) _buildInlineErrorBanner(),
                        _buildStatusHeroBanner(order),
                        _buildStepperCard(order),
                        if (order.rawStatus == 'out_for_delivery' &&
                            order.deliveryOtp.isNotEmpty)
                          _buildOtpCard(order),
                        _buildLogisticsHubCard(order),
                        _buildDeliveryInfoCard(order),
                        _buildProductsCard(order),
                        if (order.dispute != null) _buildDisputeCard(order.dispute!),
                        if (order.review != null) _buildReviewCard(order.review!),
                        _buildPaymentAndOrderDetailsCard(order),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: order != null ? _buildBottomActionBar(order) : null,
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 14),
            const Text(
              'Order Not Found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Order details could not be loaded.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadOrderDetail,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeroBanner(OrderItemModel order) {
    final isCancelled = order.rawStatus == 'cancelled';
    final hasDispute = order.hasDispute;
    final isDelivered = order.rawStatus == 'delivered' || order.rawStatus == 'completed';
    final isOutForDelivery = order.rawStatus == 'out_for_delivery';

    Color bgColor = const Color(0xFF0F172A);
    IconData icon = Icons.local_shipping_outlined;

    if (isCancelled) {
      bgColor = const Color(0xFF7F1D1D);
      icon = Icons.cancel_outlined;
    } else if (hasDispute) {
      bgColor = const Color(0xFF581C87);
      icon = Icons.assignment_return_outlined;
    } else if (isDelivered) {
      bgColor = const Color(0xFF064E3B);
      icon = Icons.check_circle_outline;
    } else if (isOutForDelivery) {
      bgColor = const Color(0xFF0F1E2E);
      icon = Icons.two_wheeler_rounded;
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
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.statusText,
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
            order.etaText,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          if (isCancelled && order.cancellationReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${order.cancellationReason}',
              style: const TextStyle(color: Color(0xFFFECACA), fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepperCard(OrderItemModel order) {
    if (order.rawStatus == 'cancelled' || order.hasDispute) {
      return const SizedBox.shrink();
    }

    final currentStep = _calculateStep(order);
    const steps = [
      {'title': 'Placed', 'icon': Icons.check},
      {'title': 'Packed', 'icon': Icons.inventory_2_outlined},
      {'title': 'Hub Transit', 'icon': Icons.sync_alt_rounded},
      {'title': 'Out for\nDelivery', 'icon': Icons.two_wheeler_rounded},
      {'title': 'Delivered', 'icon': Icons.done_all_rounded},
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY PROGRESS',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineIdx = index ~/ 2;
                final isPassed = currentStep > lineIdx;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    color: isPassed ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
                  ),
                );
              }

              final stepIdx = index ~/ 2;
              final isPassed = currentStep > stepIdx;
              final isCurrent = currentStep == stepIdx;

              return Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: (isPassed || isCurrent) ? const Color(0xFF0066FF) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isPassed || isCurrent) ? const Color(0xFF0066FF) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : (isCurrent
                          ? Icon(steps[stepIdx]['icon'] as IconData, size: 13, color: Colors.white)
                          : Text(
                              '${stepIdx + 1}',
                              style: const TextStyle(
                                fontSize: 10,
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
              final isCurrent = currentStep == idx;
              final isPassed = currentStep > idx;
              return SizedBox(
                width: 58,
                child: Text(
                  s['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: (isCurrent || isPassed) ? FontWeight.w800 : FontWeight.w600,
                    color: (isCurrent || isPassed) ? const Color(0xFF0066FF) : const Color(0xFF64748B),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(OrderItemModel order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Icon(Icons.pin_outlined, color: Color(0xFF0066FF), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Verification OTP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Provide this 6-digit code to the rider upon parcel handover.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF60A5FA)),
            ),
            child: Text(
              order.deliveryOtp,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Color(0xFF0066FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsHubCard(OrderItemModel order) {
    final trackingCode = order.trackingNumber.isNotEmpty ? order.trackingNumber : order.orderId;
    final hasHubRoute = order.originHubName != null ||
        order.currentHubName != null ||
        order.destinationHubName != null;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SHIPPING & HUB TRANSIT',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: trackingCode.replaceAll('#', '')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tracking number copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      trackingCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'COPY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasHubRoute) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hub Routing',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (order.originHubName != null) ...[
                        _buildHubBadge('Origin: ${order.originHubName}', const Color(0xFF2563EB)),
                        const Icon(Icons.arrow_forward, size: 13, color: Color(0xFF94A3B8)),
                      ],
                      if (order.currentHubName != null) ...[
                        _buildHubBadge('Current: ${order.currentHubName}', const Color(0xFF7C3AED)),
                        if (order.destinationHubName != null)
                          const Icon(Icons.arrow_forward, size: 13, color: Color(0xFF94A3B8)),
                      ],
                      if (order.destinationHubName != null)
                        _buildHubBadge('Destination: ${order.destinationHubName}', const Color(0xFF059669)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (order.courierName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Rider: ${order.courierName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      if (order.courierPhone != null ||
                          order.courierVehicle != null ||
                          order.courierPlateNumber != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            order.courierVehicle,
                            order.courierPlateNumber,
                            order.courierPhone,
                          ].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (order.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            const Text(
              'Timeline Activity',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            ...order.statusHistory.map((h) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0066FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.note.isNotEmpty ? h.note : h.status,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          if (h.changedAt.isNotEmpty)
                            Text(h.changedAt, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildHubBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildDeliveryInfoCard(OrderItemModel order) {
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
          const Icon(Icons.location_on_outlined, color: Color(0xFF0066FF), size: 20),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 6),
                if (order.recipientName.isNotEmpty || order.recipientPhone.isNotEmpty)
                  Text(
                    [
                      order.recipientName,
                      if (order.recipientPhone.isNotEmpty) '(${order.recipientPhone})',
                    ].where((s) => s.isNotEmpty).join(' '),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                const SizedBox(height: 2),
                Text(
                  order.shippingAddress.isNotEmpty
                      ? order.shippingAddress
                      : 'Address snapshot unavailable',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(OrderItemModel order) {
    final storeName = order.storeName.isNotEmpty ? order.storeName : 'Seller Store';

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
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 17, color: Color(0xFF0066FF)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  storeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFF1F5F9),
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
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.variant.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(item.variant, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('x${item.quantity}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5)),
                            Text(
                              '₱${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
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
        ],
      ),
    );
  }

  Widget _buildDisputeCard(OrderDisputeInfo dispute) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0ABFC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Return / Refund Request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF701A75)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE879F9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dispute.status.toUpperCase(),
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF701A75)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Reason: ${dispute.reason}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF4A044E))),
          const SizedBox(height: 3),
          Text(dispute.details, style: const TextStyle(fontSize: 11.5, color: Color(0xFF581C87))),
          if (dispute.mediaPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: dispute.mediaPaths.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.white,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(OrderReviewInfo review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${review.rating} / 5 Stars',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                  ),
                ],
              ),
              if (review.canBeEdited)
                TextButton(
                  onPressed: () {
                    final order = _currentOrder;
                    if (order != null) {
                      Navigator.pushNamed(context, AppRoutes.rateProduct, arguments: order);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentAndOrderDetailsCard(OrderItemModel order) {
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
            'PAYMENT & FINANCIALS',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildRow('Order ID', order.orderId),
          const SizedBox(height: 6),
          _buildRow('Payment Method', order.paymentMethod),
          const SizedBox(height: 6),
          _buildRow('Placed At', order.orderDateTimeText),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _buildRow('Merchandise Subtotal', '₱${order.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _buildRow('Shipping Fee', '₱${order.shippingFee.toStringAsFixed(2)}'),
          if (order.discount > 0) ...[
            const SizedBox(height: 6),
            _buildRow('Voucher Discount', '-₱${order.discount.toStringAsFixed(2)}', valueColor: const Color(0xFF059669)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              Text(
                '₱${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0066FF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActionBar(OrderItemModel order) {
    final canConfirmReceipt =
        order.rawStatus == 'out_for_delivery' || order.rawStatus == 'delivered';
    final firstProductId =
        order.items.isNotEmpty ? order.items.first.productId : null;
    final canReview = order.canBeReviewed &&
        (order.review == null || order.review!.canBeEdited);

    final hasAnyAction = order.canBeCancelled ||
        order.canBeReturned ||
        canConfirmReceipt ||
        canReview ||
        firstProductId != null;

    if (!hasAnyAction) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (order.canBeCancelled)
              OutlinedButton(
                onPressed: () async {
                  final updated = await OrderActionDialogs.showCancelOrderDialog(
                    context,
                    order,
                  );
                  if (updated != null && mounted) {
                    setState(() => _currentOrder = updated);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            if (order.canBeReturned)
              OutlinedButton(
                onPressed: () async {
                  final updated = await OrderActionDialogs.showReturnRequestDialog(
                    context,
                    order,
                  );
                  if (updated != null && mounted) {
                    setState(() => _currentOrder = updated);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  side: const BorderSide(color: Color(0xFFDDD6FE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Return / Refund', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            if (canConfirmReceipt)
              ElevatedButton.icon(
                onPressed: () async {
                  final updated = await OrderActionDialogs.showConfirmReceiptDialog(
                    context,
                    order,
                  );
                  if (updated != null && mounted) {
                    setState(() => _currentOrder = updated);
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Order Received', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            if (canReview)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.rateProduct,
                  arguments: order,
                ),
                icon: const Icon(Icons.star_rounded, size: 16),
                label: Text(
                  order.review != null ? 'Edit Review' : 'Rate & Review',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Buy Again', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
