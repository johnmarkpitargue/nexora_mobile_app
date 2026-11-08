import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/order_service.dart';
import 'widgets/order_action_dialogs.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderItemModel? order;

  const OrderDetailsPage({
    super.key,
    this.order,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
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

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;

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
          if (order != null && order.serverId > 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              tooltip: 'Refresh Order',
              onPressed: _loadOrderDetail,
            ),
        ],
      ),
      body: order == null && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? _buildOrderNotFoundState()
              : RefreshIndicator(
                  onRefresh: _loadOrderDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) _buildInlineErrorBanner(),
                        _buildStatusBanner(order),
                        if (order.rawStatus == 'out_for_delivery' &&
                            order.deliveryOtp.isNotEmpty)
                          _buildOtpCard(order),
                        _buildHubAndTrackingCard(order),
                        _buildDeliveryAddressCard(order),
                        _buildProductsCard(order),
                        if (order.dispute != null) _buildDisputeCard(order.dispute!),
                        if (order.review != null) _buildReviewCard(order.review!),
                        _buildPaymentAndSummaryCard(order),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: order != null ? _buildBottomActionBar(order) : null,
    );
  }

  Widget _buildOrderNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 32,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Not Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'The requested order details could not be loaded.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text('Back to Orders', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildStatusBanner(OrderItemModel order) {
    final isCancelled = order.rawStatus == 'cancelled';
    final hasDispute = order.hasDispute;
    final isDelivered = order.rawStatus == 'delivered' || order.rawStatus == 'completed';

    final gradientColors = isCancelled
        ? const [Color(0xFF475569), Color(0xFF64748B)]
        : hasDispute
            ? const [Color(0xFF6D28D9), Color(0xFF7C3AED)]
            : isDelivered
                ? const [Color(0xFF047857), Color(0xFF059669)]
                : const [Color(0xFF0F1E2E), Color(0xFF1E3A8A)];

    final icon = isCancelled
        ? Icons.cancel_outlined
        : hasDispute
            ? Icons.assignment_return_outlined
            : isDelivered
                ? Icons.check_circle_outline
                : Icons.local_shipping_outlined;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.etaText,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 12.5,
                  ),
                ),
                if (isCancelled && order.cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reason: ${order.cancellationReason}',
                    style: const TextStyle(
                      color: Color(0xFFFECACA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(OrderItemModel order) {
    return Container(
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

  Widget _buildHubAndTrackingCard(OrderItemModel order) {
    final trackingCode = order.trackingNumber.isNotEmpty ? order.trackingNumber : order.orderId;
    final hasHubRoute = order.originHubName != null ||
        order.currentHubName != null ||
        order.destinationHubName != null;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Logistics & Transit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
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
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trackingCode,
                        style: const TextStyle(
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'COPY',
                        style: TextStyle(
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hasHubRoute) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hub Transit Path',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (order.originHubName != null) ...[
                        _buildHubTag('Origin: ${order.originHubName}', const Color(0xFF2563EB)),
                        const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF94A3B8)),
                      ],
                      if (order.currentHubName != null) ...[
                        _buildHubTag('Current: ${order.currentHubName}', const Color(0xFF7C3AED)),
                        if (order.destinationHubName != null)
                          const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF94A3B8)),
                      ],
                      if (order.destinationHubName != null)
                        _buildHubTag('Destination: ${order.destinationHubName}', const Color(0xFF059669)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (order.courierName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Rider: ${order.courierName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: Color(0xFF0F172A),
                          ),
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
            ),
          ],
          if (order.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            const Text(
              'Activity History',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: Color(0xFF0F172A),
              ),
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
                      width: 8,
                      height: 8,
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (h.changedAt.isNotEmpty)
                            Text(
                              h.changedAt,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
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

  Widget _buildHubTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressCard(OrderItemModel order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF0066FF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                if (order.recipientName.isNotEmpty || order.recipientPhone.isNotEmpty)
                  Text(
                    [
                      order.recipientName,
                      if (order.recipientPhone.isNotEmpty) '(${order.recipientPhone})',
                    ].where((s) => s.isNotEmpty).join(' '),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  order.shippingAddress.isNotEmpty
                      ? order.shippingAddress
                      : 'Delivery address snapshot unavailable',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF0066FF)),
              const SizedBox(width: 8),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
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
                      width: 64,
                      height: 64,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.variant.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.variant,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
        ],
      ),
    );
  }

  Widget _buildDisputeCard(OrderDisputeInfo dispute) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Color(0xFF701A75),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE879F9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dispute.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF701A75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${dispute.reason}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF4A044E)),
          ),
          const SizedBox(height: 4),
          Text(
            dispute.details,
            style: const TextStyle(fontSize: 12, color: Color(0xFF581C87)),
          ),
          if (dispute.mediaPaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dispute.mediaPaths.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.white,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 24),
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
      padding: const EdgeInsets.all(16),
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
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${review.rating} / 5 Stars',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
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
            Text(
              review.comment!,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F)),
            ),
          ],
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.photos.map((url) {
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

  Widget _buildPaymentAndSummaryCard(OrderItemModel order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Order Number', order.orderId),
          const SizedBox(height: 8),
          _buildSummaryRow('Payment Method', order.paymentMethod),
          const SizedBox(height: 8),
          _buildSummaryRow('Order Placed', order.orderDateTimeText),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSummaryRow('Merchandise Subtotal', '₱${order.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _buildSummaryRow('Shipping Fee', '₱${order.shippingFee.toStringAsFixed(2)}'),
          if (order.discount > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Voucher Discount',
              '-₱${order.discount.toStringAsFixed(2)}',
              valueColor: const Color(0xFF059669),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
              Text(
                '₱${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0066FF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
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
