import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/order_service.dart';
import '../../../core/services/order_chat_service.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../../core/services/laguna_places_service.dart';
import '../../../core/services/address_service.dart';
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

  const OrderTrackingScreen({super.key, this.orderId, this.orderItem});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  Stream<List<Map<String, dynamic>>>? _orderStream;
  RealtimeChannel? _trackingChannel;
  String? _broadcastStatusOverride;
  String? _broadcastCourierNameOverride;
  bool _isOpeningMap = false;

  late AnimationController _mapAnimationController;
  final bool _isSatelliteMode = false;
  double? _liveRiderLat;
  double? _liveRiderLng;
  double? _liveRiderSpeed;
  double? _liveRiderHeading;
  double? _liveRiderAccuracy;
  Offset _mapPanOffset = Offset.zero;
  final int _tileZoom = 15;
  bool? _userAdjustedZoom;

  String get _cleanId {
    final raw = widget.orderId ?? widget.orderItem?.orderId ?? '';
    final cleaned = raw.replaceAll('#', '').trim();
    if (cleaned.isNotEmpty) return cleaned;
    final active = OrderService.instance.activeOrders;
    if (active.isNotEmpty) {
      return active.first.orderId.replaceAll('#', '').trim();
    }
    return 'NX-8942-ORD';
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

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // pi / 180
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  void _syncCachedRiderGps() {
    final cached =
        OrderService.instance.getLiveRiderLocation(_cleanId) ??
        OrderService.instance.getLiveRiderLocation('latest');
    if (cached != null) {
      _liveRiderLat = cached['lat'] ?? _liveRiderLat;
      _liveRiderLng = cached['lng'] ?? _liveRiderLng;
      _liveRiderSpeed = cached['speed'] ?? _liveRiderSpeed;
      _liveRiderHeading = cached['heading'] ?? _liveRiderHeading;
      _liveRiderAccuracy = cached['accuracy'] ?? _liveRiderAccuracy;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncCachedRiderGps();
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    OrderService.instance.addListener(_onOrderServiceChanged);
    _initStream();
    OrderService.instance.requestRiderLocation(_cleanId);

    // Subscribe to real-time chat with courier
    OrderChatService.instance.subscribeToOrder(_cleanId);
    OrderChatService.instance.onNewMessageReceived = (msg) {
      if (!mounted) return;
      final rawSender = (msg['senderName'] as String?)?.isNotEmpty == true
          ? msg['senderName'] as String
          : (_localOrder?.courierName.isNotEmpty == true
                ? _localOrder!.courierName
                : 'Pedro Jose Garcia');
      final riderName = rawSender.contains('Mark')
          ? 'Pedro Jose Garcia'
          : rawSender;
      final targetOrderId = (msg['orderId'] as String?)?.isNotEmpty == true
          ? msg['orderId'] as String
          : _cleanId;
      final text = (msg['text'] ?? '').toString();

      InAppNotificationService.instance.showNotification(
        senderName: riderName,
        message: text,
        orderId: targetOrderId,
        icon: Icons.two_wheeler_rounded,
        accentColor: const Color(0xFF00B4D8),
        onReply: () {
          _openChatWithRider(riderName, targetOrderId);
        },
      );
    };
  }

  void _onOrderServiceChanged() {
    if (mounted) {
      setState(() {
        _syncCachedRiderGps();
      });
    }
  }

  @override
  void dispose() {
    OrderService.instance.removeListener(_onOrderServiceChanged);
    OrderChatService.instance.onNewMessageReceived = null;
    _mapAnimationController.dispose();
    try {
      if (_trackingChannel != null) {
        Supabase.instance.client.removeChannel(_trackingChannel!);
      }
    } catch (_) {}
    super.dispose();
  }

  void _initStream() {
    final id = _cleanId;
    if (id.isEmpty) return;

    try {
      final isNumeric = int.tryParse(id) != null;
      final rawStream = isNumeric
          ? Supabase.instance.client
                .from('orders')
                .stream(primaryKey: ['id'])
                .eq('id', int.parse(id))
          : Supabase.instance.client
                .from('orders')
                .stream(primaryKey: ['id'])
                .eq('order_id', id);

      _orderStream = rawStream.handleError((err) {
        debugPrint(
          '📡 Order tracking Supabase stream notice (offline/reconnecting): $err',
        );
      });

      // Live Supabase Broadcast channel for real rider coordinates & stage updates
      _trackingChannel = Supabase.instance.client.channel('rider_tracking_$id');
      _trackingChannel
          ?.onBroadcast(
            event: 'location_update',
            callback: (payload) {
              if (!mounted) return;
              final lat = double.tryParse(
                payload['rider_lat']?.toString() ?? '',
              );
              final lng = double.tryParse(
                payload['rider_lng']?.toString() ?? '',
              );
              final speed = double.tryParse(
                payload['rider_speed']?.toString() ?? '',
              );
              final heading = double.tryParse(
                payload['rider_heading']?.toString() ?? '',
              );
              final accuracy = double.tryParse(
                payload['rider_accuracy']?.toString() ?? '',
              );
              final rawStatus = payload['status']
                  ?.toString()
                  .toLowerCase()
                  .trim();
              final status = rawStatus != null
                  ? OrderService.normalizeRemoteStatus(rawStatus)
                  : null;
              final courierName = payload['courier_name']?.toString().trim();

              if (lat != null && lng != null) {
                OrderService.instance.updateLiveRiderLocation({
                  ...payload,
                  'order_id': id,
                });
                if (status != null && status.isNotEmpty) {
                  OrderService.instance.syncOrderFromRemoteStatus(
                    id,
                    status,
                    courierName: courierName,
                  );
                }
                setState(() {
                  _liveRiderLat = lat;
                  _liveRiderLng = lng;
                  if (speed != null) _liveRiderSpeed = speed;
                  if (heading != null) _liveRiderHeading = heading;
                  if (accuracy != null) _liveRiderAccuracy = accuracy;
                  if (status != null && status.isNotEmpty) {
                    _broadcastStatusOverride = status;
                  }
                  if (courierName != null && courierName.isNotEmpty) {
                    _broadcastCourierNameOverride = courierName;
                  }
                });
              }
            },
          )
          .onBroadcast(
            event: 'status_update',
            callback: (payload) {
              if (!mounted) return;
              OrderService.instance.updateLiveRiderLocation({
                ...payload,
                'order_id': id,
              });
              final rawStatus = payload['status']
                  ?.toString()
                  .toLowerCase()
                  .trim();
              final status = rawStatus != null
                  ? OrderService.normalizeRemoteStatus(rawStatus)
                  : null;
              final courierName =
                  (payload['courier_name'] ?? payload['rider_name'])
                      ?.toString()
                      .trim();
              final lat = double.tryParse(
                payload['rider_lat']?.toString() ?? '',
              );
              final lng = double.tryParse(
                payload['rider_lng']?.toString() ?? '',
              );
              if (status != null && status.isNotEmpty) {
                OrderService.instance.syncOrderFromRemoteStatus(
                  id,
                  status,
                  courierName: courierName,
                );
              }
              setState(() {
                if (lat != null && lng != null) {
                  _liveRiderLat = lat;
                  _liveRiderLng = lng;
                }
                if (status != null && status.isNotEmpty) {
                  _broadcastStatusOverride = status;
                }
                if (courierName != null && courierName.isNotEmpty) {
                  _broadcastCourierNameOverride = courierName;
                }
              });
            },
          )
          .onBroadcast(
            event: 'rider_rated',
            callback: (payload) {
              if (!mounted) return;
              setState(() {});
            },
          )
          .subscribe((status, [error]) {
            debugPrint('📡 Rider tracking channel status: $status');
            if (status == RealtimeSubscribeStatus.subscribed) {
              _trackingChannel?.sendBroadcastMessage(
                event: 'request_rider_location',
                payload: {'order_id': id},
              );
              OrderService.instance.requestRiderLocation(id);
            }
          });
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
          content: Text(
            'Delivery GPS coordinates are not available for this order.',
          ),
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
        final androidGeoUri = Uri.parse(
          'geo:$lat,$lng?q=$lat,$lng($encodedLabel)',
        );
        if (await canLaunchUrl(androidGeoUri)) {
          targetUri = androidGeoUri;
        }
      }
      // 2. iOS native app schemes
      else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final googleMapsUri = Uri.parse(
          'comgooglemaps://?q=$lat,$lng&center=$lat,$lng',
        );
        final appleMapsUri = Uri.parse('maps://?q=$lat,$lng&ll=$lat,$lng');

        if (await canLaunchUrl(googleMapsUri)) {
          targetUri = googleMapsUri;
        } else if (await canLaunchUrl(appleMapsUri)) {
          targetUri = appleMapsUri;
        }
      }

      // 3. Web or browser fallback
      targetUri ??= Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );

      final launched = await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final webFallbackUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
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
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: Color(0xFF0284C7),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Call Courier',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
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
                        Text(
                          riderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          riderPhone,
                          style: const TextStyle(
                            color: Color(0xFF0066FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
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
                    content: Text(
                      'Simulated call to $riderName at $riderPhone',
                    ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openChatWithRider(String riderName, String orderRef) {
    final effectiveRef = orderRef.isNotEmpty
        ? orderRef.replaceAll('#', '').trim()
        : _cleanId;
    final existingMessages = OrderChatService.instance.getMessages(
      effectiveRef,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          orderId: effectiveRef,
          title: '$riderName (Courier)',
          subtitle: 'SPX Express • Active on route',
          orderRef: '#$effectiveRef',
          avatarIcon: Icons.two_wheeler_rounded,
          avatarBgColor: const Color(0xFF0066FF),
          initialMessages: existingMessages.isNotEmpty
              ? existingMessages
              : const [],
        ),
      ),
    );
  }

  /// Maps local order status string to stepper index
  String _mapLocalStatus(OrderItemModel o) {
    if (_broadcastStatusOverride != null &&
        _broadcastStatusOverride!.isNotEmpty) {
      return OrderService.normalizeRemoteStatus(_broadcastStatusOverride!);
    }
    final s = o.statusText.toLowerCase();
    final eta = o.etaText.toLowerCase();
    if (s.contains('pay') || s.contains('unpaid')) return 'pending';
    if (s.contains('complete') || s.contains('delivered') || o.progress >= 1.0) {
      return 'delivered';
    }
    if (s.contains('cancel')) return 'cancelled';
    if (s.contains('transit') ||
        s.contains('out for delivery') ||
        s.contains('receive') ||
        eta.contains('picked up') ||
        eta.contains('out for delivery') ||
        o.progress >= 0.7) {
      return 'in_transit';
    }
    if (eta.contains('arrived at merchant') || eta.contains('scanning')) {
      return 'at_store';
    }
    if (o.isRiderAccepted || eta.contains('accepted')) return 'accepted';
    if (o.progress >= 0.45) return 'preparing';
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
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
                  final dbStatus = OrderService.normalizeRemoteStatus(
                    (order['status'] ?? 'pending').toString(),
                  );
                  final rawStatus = _broadcastStatusOverride != null
                      ? OrderService.normalizeRemoteStatus(
                          _broadcastStatusOverride!,
                        )
                      : dbStatus;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    OrderService.instance.syncOrderFromRemoteStatus(
                      _cleanId,
                      rawStatus,
                      rowData: order,
                    );
                  });
                  final deliveryAddress =
                      (order['delivery_address'] ??
                              _localOrder?.shippingAddress ??
                              '192 Tuy-Baanan, Liliw, Laguna')
                          .toString();
                  double? parsedLat =
                      (order['delivery_lat'] as num?)?.toDouble() ??
                      double.tryParse(order['delivery_lat']?.toString() ?? '');
                  double? parsedLng =
                      (order['delivery_lng'] as num?)?.toDouble() ??
                      double.tryParse(order['delivery_lng']?.toString() ?? '');
                  if (parsedLat == null ||
                      parsedLng == null ||
                      parsedLat == 0.0 ||
                      parsedLng == 0.0) {
                    final resolved = LagunaPlacesService.instance
                        .resolveCoordinates(deliveryAddress);
                    parsedLat = resolved.latitude;
                    parsedLng = resolved.longitude;
                  }
                  final lat = parsedLat;
                  final lng = parsedLng;
                  final orderNumber =
                      order['order_id']?.toString() ??
                      order['order_number']?.toString() ??
                      order['id']?.toString() ??
                      _cleanId;
                  final recipientName =
                      order['customer_id']?.toString() ??
                      _localOrder?.recipientName ??
                      'Customer';
                  final recipientPhone =
                      _localOrder?.recipientPhone ?? '(+63) 975 963 2035';
                  final totalAmount = _localOrder != null
                      ? '₱${_localOrder!.totalPrice.toStringAsFixed(2)}'
                      : (order['total_amount'] != null
                            ? '₱${order['total_amount']}'
                            : '₱337.00');

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
                  double localLat = _localOrder!.deliveryLat ?? 0.0;
                  double localLng = _localOrder!.deliveryLng ?? 0.0;
                  if (localLat == 0.0 || localLng == 0.0) {
                    final defaultAddr = AddressService.instance.defaultAddress;
                    if (defaultAddr != null &&
                        defaultAddr.latitude != null &&
                        defaultAddr.latitude != 0.0) {
                      localLat = defaultAddr.latitude!;
                      localLng = defaultAddr.longitude ?? 0.0;
                    } else {
                      final resolved = LagunaPlacesService.instance
                          .resolveCoordinates(_localOrder!.shippingAddress);
                      localLat = resolved.latitude;
                      localLng = resolved.longitude;
                    }
                  }

                  return _buildTrackingContent(
                    status: _mapLocalStatus(_localOrder!),
                    address: _localOrder!.shippingAddress,
                    lat: localLat,
                    lng: localLng,
                    recipientName: _localOrder!.recipientName,
                    recipientPhone: _localOrder!.recipientPhone,
                    orderNumber: _localOrder!.orderId.replaceAll('#', ''),
                    totalAmount:
                        '₱${_localOrder!.totalPrice.toStringAsFixed(2)}',
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
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          color: brandBlue,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Connecting to live tracking stream...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
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
          ? Builder(
              builder: (context) {
                double localLat = _localOrder!.deliveryLat ?? 0.0;
                double localLng = _localOrder!.deliveryLng ?? 0.0;
                if (localLat == 0.0 || localLng == 0.0) {
                  final defaultAddr = AddressService.instance.defaultAddress;
                  if (defaultAddr != null &&
                      defaultAddr.latitude != null &&
                      defaultAddr.latitude != 0.0) {
                    localLat = defaultAddr.latitude!;
                    localLng = defaultAddr.longitude ?? 0.0;
                  } else {
                    final resolved = LagunaPlacesService.instance
                        .resolveCoordinates(_localOrder!.shippingAddress);
                    localLat = resolved.latitude;
                    localLng = resolved.longitude;
                  }
                }
                return _buildTrackingContent(
                  status: _mapLocalStatus(_localOrder!),
                  address: _localOrder!.shippingAddress,
                  lat: localLat,
                  lng: localLng,
                  recipientName: _localOrder!.recipientName,
                  recipientPhone: _localOrder!.recipientPhone,
                  orderNumber: _localOrder!.orderId.replaceAll('#', ''),
                  totalAmount: '₱${_localOrder!.totalPrice.toStringAsFixed(2)}',
                  isLiveRiderConnected: false,
                  localOrder: _localOrder,
                );
              },
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
            const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF94A3B8),
              size: 54,
            ),
            const SizedBox(height: 14),
            const Text(
              'Order Tracking Initialized',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
    final riderName =
        (_broadcastCourierNameOverride != null &&
            _broadcastCourierNameOverride!.isNotEmpty)
        ? _broadcastCourierNameOverride!
        : (localOrder?.courierName.isNotEmpty == true
              ? localOrder!.courierName
              : 'Pedro Jose Garcia');
    final riderRating = OrderService.instance.getLiveCourierRating(
      riderName,
      fallback: localOrder?.courierRating ?? 4.96,
    );
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

          // 2. In-App Live GPS Interactive Map (Hidden: web backend does not support live mobile GPS tracking)
          Visibility(
            visible: false,
            child: _buildInAppLiveGpsMapCard(
              status: status,
              lat: lat,
              lng: lng,
              address: address,
              riderName: riderName,
            ),
          ),
          const SizedBox(height: 14),

          // 3. Interactive 4-Step Stepper
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

          // 4. Delivery Address & GPS Coordinates Card with Pinpoint Adjustment & Maps
          _buildDeliveryAddressCard(
            address: address,
            lat: lat,
            lng: lng,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            orderNumber: orderNumber,
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

  /// In-App Live GPS Real-World Interactive Map Card (OpenStreetMap / Carto)
  Widget _buildInAppLiveGpsMapCard({
    required String status,
    required double lat,
    required double lng,
    required String address,
    required String riderName,
  }) {
    final isOutForDelivery =
        status == 'to_deliver' ||
        status == 'in_transit' ||
        status == 'out_for_delivery' ||
        status == 'picked_up';
    final isDelivered = status == 'delivered' || status == 'completed';

    // 1. Resolve real Rider phone GPS coordinates (no fake Calamba sine-wave simulation)
    final bool hasRealPhoneGps = _liveRiderLat != null && _liveRiderLng != null;
    double currentRiderLat;
    double currentRiderLng;

    if (hasRealPhoneGps) {
      currentRiderLat = _liveRiderLat!;
      currentRiderLng = _liveRiderLng!;
    } else if (isDelivered) {
      currentRiderLat = lat;
      currentRiderLng = lng;
    } else {
      // Before Rider's phone GPS connects, position dispatch pin near buyer's area
      currentRiderLat = lat + 0.0032;
      currentRiderLng = lng - 0.0028;
    }

    // 2. Real geographical distance (Haversine formula) & dynamic ETA
    final distKm = _calculateDistanceKm(
      currentRiderLat,
      currentRiderLng,
      lat,
      lng,
    );
    final effectiveSpeedKmh =
        (_liveRiderSpeed != null && _liveRiderSpeed! > 5.0)
        ? _liveRiderSpeed!
        : 24.0;
    final etaMinutes = (distKm / effectiveSpeedKmh * 60.0).round().clamp(1, 60);

    // 3. Auto-fit zoom level to show both Rider's real phone GPS and Buyer's destination
    int autoZoom = 15;
    if (distKm > 25) {
      autoZoom = 10;
    } else if (distKm > 12) {
      autoZoom = 11;
    } else if (distKm > 6) {
      autoZoom = 12;
    } else if (distKm > 3) {
      autoZoom = 13;
    } else if (distKm > 1.2) {
      autoZoom = 14;
    } else if (distKm > 0.4) {
      autoZoom = 15;
    } else {
      autoZoom = 16;
    }
    final int z = (_userAdjustedZoom == true) ? _tileZoom : autoZoom;
    final double centerLat = (currentRiderLat + lat) / 2.0;
    final double centerLng = (currentRiderLng + lng) / 2.0;

    return Container(
      decoration: BoxDecoration(
        color: _isSatelliteMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSatelliteMode
              ? const Color(0xFF1E293B)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Bar: Real GPS Tag + Live Distance & ETA
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'REAL-TIME GPS MAP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _isSatelliteMode
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _isSatelliteMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDelivered
                        ? 'Delivered'
                        : (isOutForDelivery
                              ? '${distKm.toStringAsFixed(1)} km • ETA $etaMinutes min'
                              : 'In Hub Dispatch'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isSatelliteMode
                          ? Colors.white70
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Interactive Real Geographic Tile Map Viewport
          SizedBox(
            height: 250,
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapWidth = constraints.maxWidth;
                  final mapHeight = constraints.maxHeight;

                  // Web Mercator tile projection
                  final double globalTileX =
                      (centerLng + 180.0) / 360.0 * (1 << z);
                  final double latRad = centerLat * math.pi / 180.0;
                  final double globalTileY =
                      (1.0 -
                          (math.log(
                                math.tan(latRad) + (1.0 / math.cos(latRad)),
                              ) /
                              math.pi)) /
                      2.0 *
                      (1 << z);

                  final int centerTileX = globalTileX.floor();
                  final int centerTileY = globalTileY.floor();

                  final double fracX = globalTileX - centerTileX;
                  final double fracY = globalTileY - centerTileY;

                  final double originPixelX =
                      (mapWidth / 2) - (fracX * 256.0) + _mapPanOffset.dx;
                  final double originPixelY =
                      (mapHeight / 2) - (fracY * 256.0) + _mapPanOffset.dy;

                  // Render tile grid
                  final tileWidgets = <Widget>[];
                  for (int dx = -2; dx <= 2; dx++) {
                    for (int dy = -2; dy <= 2; dy++) {
                      final double tileLeft = originPixelX + (dx * 256.0);
                      final double tileTop = originPixelY + (dy * 256.0);

                      if (tileLeft + 256 < 0 ||
                          tileLeft > mapWidth ||
                          tileTop + 256 < 0 ||
                          tileTop > mapHeight) {
                        continue;
                      }

                      final int tileX = centerTileX + dx;
                      final int tileY = centerTileY + dy;
                      // OpenStreetMap Standard Tiles (crisp, updated road network & POIs, zero watermark) / Esri Satellite
                      final String tileUrl = _isSatelliteMode
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$tileY/$tileX'
                          : 'https://tile.openstreetmap.org/$z/$tileX/$tileY.png';

                      tileWidgets.add(
                        Positioned(
                          left: tileLeft,
                          top: tileTop,
                          width: 256,
                          height: 256,
                          child: Image.network(
                            tileUrl,
                            headers: kIsWeb
                                ? null
                                : const {
                                    'User-Agent': 'NexoraBuyerApp/1.0 (com.example.nexora_flutter_app)',
                                  },
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: _isSatelliteMode
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  child: Center(
                                    child: Icon(
                                      Icons.map_outlined,
                                      size: 24,
                                      color: _isSatelliteMode
                                          ? Colors.white12
                                          : Colors.black12,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      );
                    }
                  }

                  return GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _mapPanOffset += details.delta;
                      });
                    },
                    child: Stack(
                      children: [
                        // Background base color
                        Container(
                          color: _isSatelliteMode
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                        ),

                        // Real map tiles
                        ...tileWidgets,

                        // Real Coordinate Route & Marker Overlay
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _mapAnimationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _RealTileOverlayPainter(
                                  animationProgress:
                                      _mapAnimationController.value,
                                  isSatelliteMode: _isSatelliteMode,
                                  status: status,
                                  z: z,
                                  globalTileX: globalTileX,
                                  globalTileY: globalTileY,
                                  panOffset: _mapPanOffset,
                                  destLat: lat,
                                  destLng: lng,
                                  riderLat: currentRiderLat,
                                  riderLng: currentRiderLng,
                                  riderName: riderName,
                                  destinationAddress: address,
                                  riderSpeed: _liveRiderSpeed,
                                  riderHeading: _liveRiderHeading,
                                  riderAccuracy: _liveRiderAccuracy,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Order identifier & overview header
  Widget _buildOrderHeaderCard(
    String orderNumber,
    String? totalAmount,
    bool isLive,
  ) {
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
                  color: isLive
                      ? const Color(0xFF00B4D8)
                      : const Color(0xFF64748B),
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
                      color: isLive
                          ? const Color(0xFF0891B2)
                          : const Color(0xFF475569),
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
                child: Icon(
                  statusConfig.icon,
                  color: statusConfig.color,
                  size: 24,
                ),
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
                      color: isPassed
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
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
                      color: isPending
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPending
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF64748B),
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
    final isOutForDelivery =
        status == 'to_deliver' ||
        status == 'in_transit' ||
        status == 'out_for_delivery' ||
        status == 'picked_up' ||
        status == 'at_store';

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
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Color(0xFF0066FF),
                  size: 20,
                ),
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
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
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
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      riderRating.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: Color(0xFF065F46),
                      ),
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
                          ? (_liveRiderSpeed != null && _liveRiderSpeed! > 1.5
                                ? '🛵 En route • ${_liveRiderSpeed!.round()} km/h live speed'
                                : (_liveRiderSpeed != null
                                      ? '🛵 En route • Stopped (0 km/h)'
                                      : '🛵 Heading to your drop-off point'))
                          : '📍 Assigned at Laguna Hub #402',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isOutForDelivery
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF0284C7),
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
                  onPressed: () =>
                      _showCallRiderDialog(riderName, '(+63) 975 963 2035'),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text(
                    'Call Rider',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              // Chat Courier (Hidden: web backend does not support buyer-rider chat)
              Visibility(
                visible: false,
                child: Expanded(
                  child: AnimatedBuilder(
                    animation: OrderChatService.instance,
                    builder: (context, _) {
                      final unread = OrderChatService.instance.getUnreadCount(
                        _cleanId,
                      );
                      return ElevatedButton.icon(
                        onPressed: () =>
                            _openChatWithRider(riderName, orderNumber),
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          label: Text(
                            '$unread',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: const Color(0xFFEF4444),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                          ),
                        ),
                        label: Text(
                          unread > 0
                              ? 'Chat Courier ($unread)'
                              : 'Chat Courier',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: unread > 0
                              ? const Color(0xFF0052CC)
                              : const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  (isOutForDelivery ||
                      status == 'delivered' ||
                      _localOrder?.isRiderAccepted == true)
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    (isOutForDelivery ||
                        status == 'delivered' ||
                        _localOrder?.isRiderAccepted == true)
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  (isOutForDelivery ||
                          status == 'delivered' ||
                          _localOrder?.isRiderAccepted == true)
                      ? Icons.verified_rounded
                      : Icons.hourglass_top_rounded,
                  size: 16,
                  color:
                      (isOutForDelivery ||
                          status == 'delivered' ||
                          _localOrder?.isRiderAccepted == true)
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (isOutForDelivery ||
                            status == 'delivered' ||
                            _localOrder?.isRiderAccepted == true)
                        ? 'Rider Acceptance: Accepted by $riderName (${riderRating.toStringAsFixed(2)} ★)'
                        : 'Rider Acceptance: Waiting for rider to accept order',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color:
                          (isOutForDelivery ||
                              status == 'delivered' ||
                              _localOrder?.isRiderAccepted == true)
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
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

  /// Clean UI Card for 'delivery_address', "Adjust Doorstep Pin", and "Verify My Delivery Pin" button
  Widget _buildDeliveryAddressCard({
    required String address,
    required double lat,
    required double lng,
    required String recipientName,
    required String recipientPhone,
    String? orderNumber,
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
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      recipientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $recipientPhone',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
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
                    const Icon(
                      Icons.pin_drop_outlined,
                      size: 14,
                      color: Color(0xFF0066FF),
                    ),
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

          // "Adjust Delivery Doorstep Pin" button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _openAdjustPinModal(
                orderNumber: orderNumber ?? _cleanId,
                currentLat: lat,
                currentLng: lng,
                currentAddress: address,
              ),
              icon: const Icon(Icons.edit_location_alt_rounded, size: 19),
              label: const Text(
                'Adjust / Fine-Tune Doorstep Pin',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
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
          const SizedBox(height: 10),

          // "Verify My Delivery Pin" button triggering Google Maps externally
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _isOpeningMap
                  ? null
                  : () => _verifyDeliveryPin(
                      lat: lat,
                      lng: lng,
                      addressLabel: address,
                    ),
              icon: _isOpeningMap
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0066FF),
                      ),
                    )
                  : const Icon(Icons.map_rounded, size: 18),
              label: Text(
                _isOpeningMap
                    ? 'Opening Maps...'
                    : 'Verify Pin in External Maps',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0066FF),
                side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
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

  /// Interactive Modal allowing customer to fine-tune doorstep pin and sync to rider in real time
  void _openAdjustPinModal({
    required String orderNumber,
    required double currentLat,
    required double currentLng,
    required String currentAddress,
  }) {
    double tempLat = currentLat;
    double tempLng = currentLng;
    int tempZoom = 15;
    String tempPlaceName = currentAddress;
    final searchController = TextEditingController();
    List<LagunaPlace> searchSuggestions = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final int z = tempZoom;
          final double globalTileX = (tempLng + 180.0) / 360.0 * (1 << z);
          final double latRad = tempLat * math.pi / 180.0;
          final double globalTileY =
              (1.0 -
                  (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) /
                      math.pi)) /
              2.0 *
              (1 << z);

          final int centerTileX = globalTileX.floor();
          final int centerTileY = globalTileY.floor();
          final double fracX = globalTileX - centerTileX;
          final double fracY = globalTileY - centerTileY;

          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Modal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pin_drop_rounded,
                          color: Color(0xFF0066FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set / Adjust Delivery Pin on Map',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Rider navigation reflects your pin live in real time',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Search Bar for Landmarks / Streets nationwide
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText:
                                  'Search place, landmark, or street in PH...',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            onChanged: (val) async {
                              if (val.trim().isEmpty) {
                                setModalState(() => searchSuggestions = []);
                              } else {
                                final res = await LagunaPlacesService.instance
                                    .searchPlaces(val);
                                setModalState(() => searchSuggestions = res);
                              }
                            },
                          ),
                        ),
                        if (searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              searchController.clear();
                              setModalState(() => searchSuggestions = []);
                            },
                            child: const Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (searchSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: searchSuggestions.length.clamp(0, 5),
                      separatorBuilder: (ctx, index) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, idx) {
                        final p = searchSuggestions[idx];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Color(0xFF0066FF),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${p.cityOrMunicipality}, ${p.province} • ${p.postalCode}',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          onTap: () {
                            setModalState(() {
                              tempLat = p.latitude;
                              tempLng = p.longitude;
                              tempPlaceName =
                                  '${p.name}, ${p.cityOrMunicipality}';
                              searchSuggestions = [];
                              searchController.text = p.name;
                            });
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 8),

                // Interactive Map Viewport with Center Pin & Drag Controls
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRect(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final mapWidth = constraints.maxWidth;
                            final mapHeight = constraints.maxHeight;
                            final originX = (mapWidth / 2) - (fracX * 256.0);
                            final originY = (mapHeight / 2) - (fracY * 256.0);

                            final tiles = <Widget>[];
                            for (int dx = -2; dx <= 2; dx++) {
                              for (int dy = -2; dy <= 2; dy++) {
                                final left = originX + (dx * 256.0);
                                final top = originY + (dy * 256.0);

                                if (left + 256 < 0 ||
                                    left > mapWidth ||
                                    top + 256 < 0 ||
                                    top > mapHeight) {
                                  continue;
                                }

                                final tx = centerTileX + dx;
                                final ty = centerTileY + dy;
                                final osmTileUrl =
                                    'https://tile.openstreetmap.org/$z/$tx/$ty.png';

                                tiles.add(
                                  Positioned(
                                    left: left,
                                    top: top,
                                    width: 256,
                                    height: 256,
                                    child: Image.network(
                                      osmTileUrl,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: const Color(0xFFDCF0D8),
                                              ),
                                    ),
                                  ),
                                );
                              }
                            }

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) {
                                setModalState(() {
                                  final moveDx = details.delta.dx;
                                  final moveDy = details.delta.dy;
                                  final metersPerPixel =
                                      156543.03392 *
                                      math.cos(tempLat * math.pi / 180.0) /
                                      math.pow(2, z);
                                  final double deltaLng =
                                      -(moveDx * metersPerPixel) /
                                      (111320.0 *
                                          math.cos(tempLat * math.pi / 180.0));
                                  final double deltaLat =
                                      (moveDy * metersPerPixel) / 110540.0;

                                  tempLat = (tempLat + deltaLat).clamp(
                                    -85.0,
                                    85.0,
                                  );
                                  tempLng = (tempLng + deltaLng).clamp(
                                    -180.0,
                                    180.0,
                                  );
                                });
                              },
                              onPanEnd: (_) {
                                setModalState(() {
                                  final nearest = LagunaPlacesService.instance
                                      .getNearestPlace(tempLat, tempLng);
                                  tempPlaceName =
                                      '${nearest.name}, ${nearest.cityOrMunicipality}';
                                });
                              },
                              child: Container(
                                color: const Color(0xFFDCF0D8),
                                child: Stack(children: tiles),
                              ),
                            );
                          },
                        ),
                      ),

                      // Fixed Center Target Pin
                      IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.doorbell_rounded,
                                    color: Color(0xFF0066FF),
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Delivery Doorstep Pin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(
                              Icons.location_on_rounded,
                              size: 44,
                              color: Color(0xFFEA4335),
                            ),
                            Container(
                              width: 10,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Map Zoom +/- and Locate Controls
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'tracking_map_locate',
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0066FF),
                              elevation: 3,
                              onPressed: () async {
                                final loc = await LagunaPlacesService.instance
                                    .getCurrentDeviceLocation();
                                if (loc != null) {
                                  setModalState(() {
                                    tempLat = loc.latitude;
                                    tempLng = loc.longitude;
                                    tempPlaceName = loc.name;
                                  });
                                }
                              },
                              child: const Icon(
                                Icons.my_location_rounded,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () {
                                      if (tempZoom < 18) {
                                        setModalState(() => tempZoom++);
                                      }
                                    },
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const Divider(height: 1),
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: () {
                                      if (tempZoom > 12) {
                                        setModalState(() => tempZoom--);
                                      }
                                    },
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Confirmation Card
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tempPlaceName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GPS: ${tempLat.toStringAsFixed(6)}° N, ${tempLng.toStringAsFixed(6)}° E',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(modalCtx);
                            await OrderService.instance.updateOrderDeliveryPin(
                              orderId: orderNumber,
                              lat: tempLat,
                              lng: tempLng,
                              address: tempPlaceName,
                            );
                            if (mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✓ Delivery doorstep pin updated to ${tempLat.toStringAsFixed(4)}, ${tempLng.toStringAsFixed(4)}! Rider navigation notified in real time.',
                                  ),
                                  backgroundColor: const Color(0xFF0066FF),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Confirm & Update Pin for Rider',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
          ...localOrder.items.map(
            (item) => Padding(
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
                        child: const Icon(
                          Icons.image,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.variant,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
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

  /// Maps the raw database status to display titles, subtexts, and progress index
  _StatusMeta _getStatusConfig(String rawStatus) {
    final status = OrderService.normalizeRemoteStatus(rawStatus);
    switch (status) {
      case 'accepted':
      case 'preparing':
      case 'processing':
      case 'ready':
      case 'at_store':
        return _StatusMeta(
          title: status == 'at_store'
              ? 'Courier at Store • Scanning'
              : status == 'accepted'
              ? 'Rider Accepted • En Route to Store'
              : 'Preparing & Packed',
          description: status == 'at_store'
              ? 'Your assigned courier has arrived at the merchant store and is scanning your parcel.'
              : status == 'accepted'
              ? 'Your rider has accepted the delivery and is heading to the merchant store to pick up your parcel.'
              : 'The store has confirmed your items and is packing your parcel.',
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
          description:
              'This order was cancelled. Please check your refund or reorder.',
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

/// Custom overlay painter for the real-world geographic tile map.
/// Projects real GPS coordinates (latitude, longitude) directly onto the Carto / OpenStreetMap tile layer.
class _RealTileOverlayPainter extends CustomPainter {
  final double animationProgress;
  final bool isSatelliteMode;
  final String status;
  final int z;
  final double globalTileX;
  final double globalTileY;
  final Offset panOffset;
  final double destLat;
  final double destLng;
  final double riderLat;
  final double riderLng;
  final String riderName;
  final String destinationAddress;
  final double? riderSpeed;
  final double? riderHeading;
  final double? riderAccuracy;

  _RealTileOverlayPainter({
    required this.animationProgress,
    required this.isSatelliteMode,
    required this.status,
    required this.z,
    required this.globalTileX,
    required this.globalTileY,
    required this.panOffset,
    required this.destLat,
    required this.destLng,
    required this.riderLat,
    required this.riderLng,
    required this.riderName,
    required this.destinationAddress,
    this.riderSpeed,
    this.riderHeading,
    this.riderAccuracy,
  });

  Offset toScreen(Size size, double lat, double lng) {
    final double gx = (lng + 180.0) / 360.0 * (1 << z);
    final double r = lat * math.pi / 180.0;
    final double gy =
        (1.0 - (math.log(math.tan(r) + (1.0 / math.cos(r))) / math.pi)) /
        2.0 *
        (1 << z);

    final double px =
        (size.width / 2) + ((gx - globalTileX) * 256.0) + panOffset.dx;
    final double py =
        (size.height / 2) + ((gy - globalTileY) * 256.0) + panOffset.dy;
    return Offset(px, py);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final destPos = toScreen(size, destLat, destLng);
    final riderPos = toScreen(size, riderLat, riderLng);
    final isDelivered = status == 'delivered' || status == 'completed';

    // 1. Draw Connecting Route Line between Rider and Customer Pin
    if (!isDelivered) {
      final routePath = Path();
      routePath.moveTo(riderPos.dx, riderPos.dy);
      final midX = (riderPos.dx + destPos.dx) / 2 + 10;
      final midY = (riderPos.dy + destPos.dy) / 2 - 10;
      routePath.quadraticBezierTo(midX, midY, destPos.dx, destPos.dy);

      // Route Outer Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF0066FF).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(routePath, glowPaint);

      // Route Solid Line
      final linePaint = Paint()
        ..color = const Color(0xFF0066FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(routePath, linePaint);

      // Moving animated pulses along the route
      final pathMetrics = routePath.computeMetrics().toList();
      if (pathMetrics.isNotEmpty) {
        final metric = pathMetrics.first;
        final totalLen = metric.length;
        if (totalLen > 10) {
          final pulseOffset = (animationProgress * 30) % 30;
          final pulsePaint = Paint()
            ..color = const Color(0xFF38BDF8)
            ..style = PaintingStyle.fill;

          for (double d = pulseOffset; d < totalLen; d += 28) {
            final tangent = metric.getTangentForOffset(d);
            if (tangent != null) {
              canvas.drawCircle(tangent.position, 2.5, pulsePaint);
            }
          }
        }
      }
    }

    // 2. Draw Customer Destination Pin
    _drawDestinationPin(canvas, destPos);

    // 3. Draw Rider Marker
    if (!isDelivered) {
      _drawRiderMarker(canvas, riderPos);
    }
  }

  void _drawDestinationPin(Canvas canvas, Offset pos) {
    if (status == 'delivered' || status == 'completed') {
      final pulseRadius = 14 + (animationProgress * 16);
      final pulsePaint = Paint()
        ..color = const Color(0xFF10B981)
            .withValues(alpha: (1.0 - animationProgress) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(pos, pulseRadius, pulsePaint);
    }

    // Shadow
    canvas.drawCircle(
      Offset(pos.dx, pos.dy + 2),
      13,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    // Green pin base
    canvas.drawCircle(pos, 11, Paint()..color = const Color(0xFF10B981));
    // White inner ring
    canvas.drawCircle(pos, 4.5, Paint()..color = Colors.white);

    // Label pill above
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Your Pin',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 17),
        width: tp.width + 10,
        height: 16,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      pillRRect,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    tp.paint(canvas, Offset(pos.dx - (tp.width / 2), pos.dy - 23));
  }

  void _drawRiderMarker(Canvas canvas, Offset pos) {
    final pulse1 = animationProgress;
    final pulse2 = (animationProgress + 0.5) % 1.0;

    // Radar ripples expanding outward
    final ripplePaint1 = Paint()
      ..color = const Color(0xFF0066FF).withValues(alpha: (1.0 - pulse1) * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(pos, 14 + (pulse1 * 24), ripplePaint1);

    final ripplePaint2 = Paint()
      ..color = const Color(0xFF0066FF).withValues(alpha: (1.0 - pulse2) * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, 14 + (pulse2 * 24), ripplePaint2);

    // Glow halo
    canvas.drawCircle(
      pos,
      15,
      Paint()
        ..color = const Color(0xFF0066FF).withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Blue circle marker
    final riderBadgePaint = Paint()..color = const Color(0xFF0066FF);
    canvas.drawCircle(pos, 13, riderBadgePaint);

    final riderBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(pos, 13, riderBorderPaint);

    // Vehicle heading pointer arrow
    if (riderHeading != null && riderHeading! > 0) {
      final rad = (riderHeading! - 90) * math.pi / 180.0;
      final tipX = pos.dx + math.cos(rad) * 18;
      final tipY = pos.dy + math.sin(rad) * 18;
      final leftX = pos.dx + math.cos(rad + 2.5) * 10;
      final leftY = pos.dy + math.sin(rad + 2.5) * 10;
      final rightX = pos.dx + math.cos(rad - 2.5) * 10;
      final rightY = pos.dy + math.sin(rad - 2.5) * 10;

      final arrowPath = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(leftX, leftY)
        ..lineTo(pos.dx, pos.dy)
        ..lineTo(rightX, rightY)
        ..close();

      canvas.drawPath(arrowPath, Paint()..color = const Color(0xFF00C4FF));
    }

    // Inner white dot
    canvas.drawCircle(pos, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RealTileOverlayPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isSatelliteMode != isSatelliteMode ||
        oldDelegate.status != status ||
        oldDelegate.z != z ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.riderLat != riderLat ||
        oldDelegate.riderLng != riderLng ||
        oldDelegate.destLat != destLat ||
        oldDelegate.destLng != destLng ||
        oldDelegate.riderSpeed != riderSpeed ||
        oldDelegate.riderHeading != riderHeading ||
        oldDelegate.riderAccuracy != riderAccuracy;
  }
}
