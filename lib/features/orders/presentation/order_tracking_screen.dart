import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/order_service.dart';
import '../../chat/presentation/chat_detail_page.dart';

/// Real-time Order Tracking Screen for Customers with Live Stepper & Connected Rider Info.
///
/// Features:
/// 1. Real-time Supabase stream listener on the 'orders' table connected with the Rider App.
/// 2. Multi-step visual order status indicator (Order Placed, Preparing, Out for Delivery, Delivered).
/// 3. Connected Rider card displaying courier name, vehicle plate, phone call trigger, and direct chat.
/// 4. Delivery Address card with GPS coordinates and "Verify My Delivery Pin" (Google / Apple Maps).
/// 5. Full resilience: seamlessly displays local [OrderItemModel] when offline or stream is connecting.
class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  final OrderItemModel? orderItem;

  const OrderTrackingScreen({
    super.key,
    this.orderId,
    this.orderItem,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Stream<List<Map<String, dynamic>>>? _orderStream;
  bool _isOpeningMap = false;

  String get _cleanId {
    final raw = widget.orderId ?? widget.orderItem?.orderId ?? '';
    return raw.replaceAll('#', '').trim();
  }

  OrderItemModel? get _localOrder {
    if (widget.orderItem != null) return widget.orderItem;
    final id = _cleanId.toLowerCase();
    final allOrders = [
      ...OrderService.instance.activeOrders,
      ...OrderService.instance.pastOrders,
    ];
    for (final o in allOrders) {
      if (o.orderId.replaceAll('#', '').toLowerCase() == id) {
        return o;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final id = _cleanId;
    if (id.isEmpty) return;

    try {
      final isNumeric = int.tryParse(id) != null;
      if (isNumeric) {
        _orderStream = Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('id', int.parse(id));
      } else {
        _orderStream = Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('order_id', id);
      }
    } catch (e) {
      debugPrint('⚠️ Supabase stream note: $e');
      _orderStream = null;
    }
  }

  /// Opens the delivery coordinates in the native map application (Google Maps / Apple Maps)
  Future<void> _verifyDeliveryPin({
    required double? lat,
    required double? lng,
    required String addressLabel,
  }) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery GPS coordinates are not available for this order.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isOpeningMap = true);

    try {
      final encodedLabel = Uri.encodeComponent(
        addressLabel.isNotEmpty ? addressLabel : 'Delivery Location',
      );

      Uri? targetUri;

      // 1. Android native Google Maps Geo intent
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidGeoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedLabel)');
        if (await canLaunchUrl(androidGeoUri)) {
          targetUri = androidGeoUri;
        }
      }
      // 2. iOS native app schemes
      else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final googleMapsUri = Uri.parse('comgooglemaps://?q=$lat,$lng&center=$lat,$lng');
        final appleMapsUri = Uri.parse('maps://?q=$lat,$lng&ll=$lat,$lng');

        if (await canLaunchUrl(googleMapsUri)) {
          targetUri = googleMapsUri;
        } else if (await canLaunchUrl(appleMapsUri)) {
          targetUri = appleMapsUri;
        }
      }

      // 3. Web or browser fallback
      targetUri ??= Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

      final launched = await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final webFallbackUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningMap = false);
      }
    }
  }

  void _showCallRiderDialog(String riderName, String riderPhone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0284C7), size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Call Courier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact your assigned delivery rider for live updates:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF64748B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(riderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text(riderPhone, style: const TextStyle(color: Color(0xFF0066FF), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final telUri = Uri.parse('tel:${riderPhone.replaceAll(' ', '')}');
              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri);
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Simulated call to $riderName at $riderPhone'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _openChatWithRider(String riderName, String orderRef) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          title: '$riderName (Courier)',
          subtitle: 'SPX Express • Active on route',
          orderRef: '#$orderRef',
          avatarIcon: Icons.two_wheeler_rounded,
          avatarBgColor: const Color(0xFF0066FF),
          initialMessages: [
            {
              'isMe': false,
              'text': 'Good day! I have picked up your order #$orderRef. I am on my way to your delivery location.',
              'time': 'Just now',
            },
          ],
        ),
      ),
    );
  }

  /// Maps local order status string to stepper index
  String _mapLocalStatus(OrderItemModel o) {
    final s = o.statusText.toLowerCase();
    if (s.contains('pay') || s.contains('unpaid')) return 'pending';
    if (s.contains('ship') || s.contains('process') || s.contains('prepar')) return 'preparing';
    if (s.contains('complete') || s.contains('delivered')) return 'delivered';
    if (s.contains('cancel')) return 'cancelled';
    if (s.contains('transit') || s.contains('out for delivery')) return 'to_deliver';
    if (s.contains('receive')) {
      if (o.progress >= 0.7 || o.etaText.toLowerCase().contains('way') || o.etaText.toLowerCase().contains('transit')) {
        return 'to_deliver';
      }
      return 'pending';
    }
    return 'pending';
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0066FF);
    const bgLight = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: const Text(
          'Track Your Order',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE TRACKING',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _orderStream != null
          ? StreamBuilder<List<Map<String, dynamic>>>(
              stream: _orderStream,
              builder: (context, snapshot) {
                // If Supabase yields data, use it
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final order = snapshot.data!.first;
                  final rawStatus = (order['status'] ?? 'pending').toString().toLowerCase().trim();
                  final deliveryAddress = (order['delivery_address'] ?? _localOrder?.shippingAddress ?? '192 Tuy-Baanan, Liliw, Laguna').toString();
                  final lat = double.tryParse(order['delivery_lat']?.toString() ?? '') ?? 14.2135;
                  final lng = double.tryParse(order['delivery_lng']?.toString() ?? '') ?? 121.1731;
                  final orderNumber = order['order_id']?.toString() ?? order['order_number']?.toString() ?? order['id']?.toString() ?? _cleanId;
                  final recipientName = order['customer_id']?.toString() ?? _localOrder?.recipientName ?? 'Customer';
                  final recipientPhone = _localOrder?.recipientPhone ?? '(+63) 975 963 2035';
                  final totalAmount = _localOrder != null ? '₱${_localOrder!.totalPrice.toStringAsFixed(2)}' : (order['total_amount'] != null ? '₱${order['total_amount']}' : '₱337.00');

                  return _buildTrackingContent(
                    status: rawStatus,
                    address: deliveryAddress,
                    lat: lat,
                    lng: lng,
                    recipientName: recipientName,
                    recipientPhone: recipientPhone,
                    orderNumber: orderNumber,
                    totalAmount: totalAmount,
                    isLiveRiderConnected: true,
                    localOrder: _localOrder,
                  );
                }

                // If connecting but local order exists, render immediately with local data
                if (_localOrder != null) {
                  return _buildTrackingContent(
                    status: _mapLocalStatus(_localOrder!),
                    address: _localOrder!.shippingAddress,
                    lat: 14.2135,
                    lng: 121.1731,
                    recipientName: _localOrder!.recipientName,
                    recipientPhone: _localOrder!.recipientPhone,
                    orderNumber: _localOrder!.orderId.replaceAll('#', ''),
                    totalAmount: '₱${_localOrder!.totalPrice.toStringAsFixed(2)}',
                    isLiveRiderConnected: false,
                    localOrder: _localOrder,
                  );
                }

                // If waiting and no local order
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3, color: brandBlue),
                        SizedBox(height: 16),
                        Text(
                          'Connecting to live tracking stream...',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Fallback empty state
                return _buildFallbackEmptyState();
              },
            )
          : _localOrder != null
              ? _buildTrackingContent(
                  status: _mapLocalStatus(_localOrder!),
                  address: _localOrder!.shippingAddress,
                  lat: 14.2135,
                  lng: 121.1731,
                  recipientName: _localOrder!.recipientName,
                  recipientPhone: _localOrder!.recipientPhone,
                  orderNumber: _localOrder!.orderId.replaceAll('#', ''),
                  totalAmount: '₱${_localOrder!.totalPrice.toStringAsFixed(2)}',
                  isLiveRiderConnected: false,
                  localOrder: _localOrder,
                )
              : _buildFallbackEmptyState(),
    );
  }

  Widget _buildFallbackEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 54),
            const SizedBox(height: 14),
            const Text(
              'Order Tracking Initialized',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Order reference #$_cleanId is being prepared by merchant and courier dispatch.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back to Orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent({
    required String status,
    required String address,
    required double lat,
    required double lng,
    required String recipientName,
    required String recipientPhone,
    required String orderNumber,
    required String? totalAmount,
    required bool isLiveRiderConnected,
    OrderItemModel? localOrder,
  }) {
    final riderName = localOrder?.courierName.isNotEmpty == true
        ? localOrder!.courierName
        : 'Mark Ronald';
    final riderRating = localOrder?.courierRating ?? 4.96;
    final riderAvatar = localOrder?.courierAvatarUrl.isNotEmpty == true
        ? localOrder!.courierAvatarUrl
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Order Reference & Live Status Banner
          _buildOrderHeaderCard(orderNumber, totalAmount, isLiveRiderConnected),
          const SizedBox(height: 14),

          // 2. Interactive 4-Step Stepper
          _buildStatusTrackerCard(status),
          const SizedBox(height: 14),

          // 3. Connected Rider & Courier Card
          _buildRiderInfoCard(
            riderName: riderName,
            riderRating: riderRating,
            riderAvatar: riderAvatar,
            orderNumber: orderNumber,
            status: status,
          ),
          const SizedBox(height: 14),

          // 4. Delivery Address & GPS Coordinates Card with Google Maps Trigger
          _buildDeliveryAddressCard(
            address: address,
            lat: lat,
            lng: lng,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
          ),
          const SizedBox(height: 14),

          // 5. Items in this order
          if (localOrder != null && localOrder.items.isNotEmpty)
            _buildItemsPreviewCard(localOrder),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Order identifier & overview header
  Widget _buildOrderHeaderCard(String orderNumber, String? totalAmount, bool isLive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORDER REFERENCE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '#$orderNumber',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (totalAmount != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL PAID',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      totalAmount,
                      style: const TextStyle(
                        color: Color(0xFF0066FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFFE0F7FA) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isLive ? Icons.wifi_tethering_rounded : Icons.sync_rounded,
                  size: 15,
                  color: isLive ? const Color(0xFF00B4D8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isLive
                        ? 'Realtime sync active: Connected to Rider App'
                        : 'Order synchronized with local logistics dispatch',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLive ? const Color(0xFF0891B2) : const Color(0xFF475569),
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

  /// 4-Step Stepper & Progress Card
  Widget _buildStatusTrackerCard(String status) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Highlight Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusConfig.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusConfig.icon, color: statusConfig.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusConfig.title,
                      style: TextStyle(
                        color: statusConfig.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusConfig.description,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 18),

          // Visual 4-Step Timeline Stepper
          _buildTimelineStep(
            index: 0,
            activeStep: statusConfig.stepIndex,
            label: 'Order Placed',
            sublabel: 'Payment verified & order logged',
            isFirst: true,
          ),
          _buildTimelineStep(
            index: 1,
            activeStep: statusConfig.stepIndex,
            label: 'Preparing & Packed',
            sublabel: 'Merchant packed items, ready for courier',
          ),
          _buildTimelineStep(
            index: 2,
            activeStep: statusConfig.stepIndex,
            label: 'Out for Delivery',
            sublabel: 'Rider is on the road with your package',
          ),
          _buildTimelineStep(
            index: 3,
            activeStep: statusConfig.stepIndex,
            label: 'Delivered',
            sublabel: 'Package received safely by recipient',
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// Single milestone in the 4-step stepper
  Widget _buildTimelineStep({
    required int index,
    required int activeStep,
    required String label,
    required String sublabel,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isPassed = activeStep > index;
    final isCurrent = activeStep == index;
    final isPending = activeStep < index;

    final Color dotColor = isCurrent
        ? const Color(0xFF0066FF)
        : isPassed
            ? const Color(0xFF10B981)
            : const Color(0xFFCBD5E1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator Dot & Connector Line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isPassed ? const Color(0xFF10B981) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor,
                      width: isCurrent ? 5 : 2,
                    ),
                  ),
                  child: isPassed
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isPassed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Step Label & Subtext
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                      color: isPending ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPending ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
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

  /// Connected Rider Card
  Widget _buildRiderInfoCard({
    required String riderName,
    required double riderRating,
    required String riderAvatar,
    required String orderNumber,
    required String status,
  }) {
    final isOutForDelivery = status == 'to_deliver' || status == 'in_transit' || status == 'out_for_delivery';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0066FF), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Courier & Rider',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Nexora Express • SPX Logistics Partner',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 2),
                    Text(
                      riderRating.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF065F46)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rider Profile Row
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: NetworkImage(riderAvatar),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Honda Click 150i • Plate: ND-8821',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOutForDelivery
                          ? '🛵 Heading to your drop-off point'
                          : '📍 Assigned at Laguna Hub #402',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isOutForDelivery ? const Color(0xFF8B5CF6) : const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Call & Chat
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCallRiderDialog(riderName, '(+63) 975 963 2035'),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Call Rider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openChatWithRider(riderName, orderNumber),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Chat Courier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Clean UI Card for 'delivery_address' and "Verify My Delivery Pin" button
  Widget _buildDeliveryAddressCard({
    required String address,
    required double lat,
    required double lng,
    required String recipientName,
    required String recipientPhone,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C1D4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF00B4D8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Saved destination pin for rider navigation',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recipient summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      recipientName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $recipientPhone',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.pin_drop_outlined, size: 14, color: Color(0xFF0066FF)),
                    const SizedBox(width: 4),
                    Text(
                      'GPS Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // "Verify My Delivery Pin" button triggering Google Maps externally
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isOpeningMap
                  ? null
                  : () => _verifyDeliveryPin(
                        lat: lat,
                        lng: lng,
                        addressLabel: address,
                      ),
              icon: _isOpeningMap
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.map_rounded, size: 19),
              label: Text(
                _isOpeningMap ? 'Opening Maps...' : 'Verify My Delivery Pin on Map',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Package Items Card
  Widget _buildItemsPreviewCard(OrderItemModel localOrder) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ITEMS IN THIS PARCEL',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '${localOrder.items.length} ${localOrder.items.length == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...localOrder.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.image, size: 20, color: Color(0xFF94A3B8)),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.variant,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₱${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Maps the raw database status to display titles, subtexts, and progress index
  _StatusMeta _getStatusConfig(String status) {
    switch (status) {
      case 'preparing':
      case 'processing':
      case 'ready':
        return _StatusMeta(
          title: 'Preparing & Packed',
          description: 'The store has confirmed your items and is packing your parcel.',
          color: const Color(0xFF3B82F6),
          icon: Icons.inventory_2_outlined,
          stepIndex: 1,
        );
      case 'to_deliver':
      case 'in_transit':
      case 'out_for_delivery':
      case 'picked_up':
      case 'shipping':
      case 'shipped':
        return _StatusMeta(
          title: 'Out for Delivery',
          description: 'Your courier has picked up the package and is heading to your pin.',
          color: const Color(0xFF8B5CF6),
          icon: Icons.two_wheeler_rounded,
          stepIndex: 2,
        );
      case 'delivered':
      case 'completed':
        return _StatusMeta(
          title: 'Delivered Successfully',
          description: 'Package has been delivered to your destination. Enjoy your items!',
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
          stepIndex: 3,
        );
      case 'cancelled':
        return _StatusMeta(
          title: 'Order Cancelled',
          description: 'This order was cancelled. Please check your refund or reorder.',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_outlined,
          stepIndex: -1,
        );
      case 'pending':
      default:
        return _StatusMeta(
          title: 'Order Placed',
          description: 'Your order has been sent to the store and is awaiting preparation.',
          color: const Color(0xFFF59E0B),
          icon: Icons.schedule_rounded,
          stepIndex: 0,
        );
    }
  }
}

class _StatusMeta {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final int stepIndex;

  const _StatusMeta({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.stepIndex,
  });
}
