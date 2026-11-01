import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/rider_location_service.dart';
import '../../../core/services/delivery_service.dart';

/// Live Orders Screen for Rider App.
///
/// Features:
/// 1. Connects to Supabase Realtime stream on 'orders' table.
/// 2. Instantly updates when the Customer app inserts a new order.
/// 3. "Navigate (Google Maps)" button launches Google Maps externally via [url_launcher]
///    using [LaunchMode.externalApplication], keeping this Rider app active in the background.
class RiderLiveOrdersScreen extends StatefulWidget {
  const RiderLiveOrdersScreen({super.key});

  @override
  State<RiderLiveOrdersScreen> createState() => _RiderLiveOrdersScreenState();
}

class _RiderLiveOrdersScreenState extends State<RiderLiveOrdersScreen> {
  late final Stream<List<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    // Connect to Supabase Realtime stream
    _ordersStream = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Launches Google Maps Navigation externally so Rider app remains alive in background
  Future<void> _launchNavigation({
    required double lat,
    required double lng,
    required String addressLabel,
  }) async {
    final encodedLabel = Uri.encodeComponent(addressLabel.isNotEmpty ? addressLabel : 'Customer Delivery');

    Uri? targetUri;

    // 1. Android Native Navigation Intent (Turn-by-turn mode)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidIntentUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      if (await canLaunchUrl(androidIntentUri)) {
        targetUri = androidIntentUri;
      }
    }
    // 2. iOS Native Maps URL Schemes
    else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final googleMapsApp = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
      final appleMapsApp = Uri.parse('maps://?daddr=$lat,$lng&dirflg=d');

      if (await canLaunchUrl(googleMapsApp)) {
        targetUri = googleMapsApp;
      } else if (await canLaunchUrl(appleMapsApp)) {
        targetUri = appleMapsApp;
      }
    }

    // 3. Universal Web / Google Maps Navigation fallback (works cross-platform)
    targetUri ??= Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      final bool launched = await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback to standard web Google Maps link if needed
        final webFallback = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng($encodedLabel)',
        );
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open map: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Updates status in Supabase so customer app updates in real-time
  Future<void> _updateOrderStatus(String orderId, String newStatus, {String? orderCode}) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Broadcast live rider location & real speed update to Buyer App in real-time
      if (orderCode != null) {
        final clean = orderCode.replaceAll('#', '').trim();
        final loc = RiderLocationService.instance;
        await loc.getCurrentLocation();

        final channel = Supabase.instance.client.channel('rider_tracking_$clean');
        channel.subscribe();
        await channel.sendBroadcastMessage(
          event: 'location_update',
          payload: {
            'rider_lat': loc.currentLat,
            'rider_lng': loc.currentLng,
            'rider_speed': double.parse(loc.currentSpeedKmh.toStringAsFixed(1)),
            'rider_heading': double.parse(loc.currentHeading.toStringAsFixed(1)),
            'rider_accuracy': double.parse(loc.currentAccuracyMeters.toStringAsFixed(1)),
            'rider_name': 'Pedro Jose Garcia',
            'status': newStatus,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (newStatus.toLowerCase() == 'to_deliver') {
          loc.startTracking(orderId: clean, status: newStatus);
        } else if (newStatus.toLowerCase() == 'delivered') {
          loc.stopTracking();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to "${newStatus.toUpperCase()}"'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return const Color(0xFF3B82F6); // Blue
      case 'to_deliver':
        return const Color(0xFF8B5CF6); // Purple
      case 'delivered':
        return const Color(0xFF10B981); // Emerald
      case 'pending':
      default:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0066FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Live Incoming Orders',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Live Realtime Indicator
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
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'REALTIME',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 3, color: brandBlue),
                  SizedBox(height: 16),
                  Text(
                    'Listening to incoming customer orders...',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // 2. Stream Error State
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444), size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Connection Error',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          // 3. Empty State
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        size: 42,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Active Orders Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Orders placed by customers in the Customer App will appear here in real-time automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Live Orders List
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];
              final rawId = order['id'].toString();
              final orderCode = order['order_id'] ?? rawId.substring(0, 8);
              final items = DeliveryService.extractItemTitle(order['item_details']);
              final address = order['delivery_address'] ?? 'No address provided';
              final status = (order['status'] ?? 'pending').toString().toLowerCase();

              final double lat = double.tryParse(order['delivery_lat']?.toString() ?? '') ?? 14.2135;
              final double lng = double.tryParse(order['delivery_lng']?.toString() ?? '') ?? 121.1731;

              final statusColor = _getStatusColor(status);

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: brandBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: brandBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Order #$orderCode',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Item Details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              items,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // GPS Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'GPS: $lat, $lng',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Button: Launch External Google Maps Navigation
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchNavigation(
                            lat: lat,
                            lng: lng,
                            addressLabel: address,
                          ),
                          icon: const Icon(Icons.navigation_rounded, size: 20),
                          label: const Text(
                            'Navigate (Google Maps)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), // Emerald green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Step-by-Step Status Progressor (Pending -> Accepted -> At Store -> In Transit -> Delivered)
                      if (status != 'delivered') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (status == 'pending') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    DeliveryService.instance.acceptOrder(
                                      orderCode.toString(),
                                      fallbackRow: order,
                                    );
                                    _updateOrderStatus(rawId, 'accepted', orderCode: orderCode.toString());
                                  },
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                  label: const Text(
                                    'Accept Order',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (status == 'accepted' || status == 'ready') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    DeliveryService.instance.updateActiveOrderStage(1);
                                    _updateOrderStatus(rawId, 'at_store', orderCode: orderCode.toString());
                                  },
                                  icon: const Icon(Icons.storefront_rounded, size: 18),
                                  label: const Text(
                                    'Arrived at Store',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (status == 'at_store') ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    DeliveryService.instance.updateActiveOrderStage(3);
                                    _updateOrderStatus(rawId, 'in_transit', orderCode: orderCode.toString());
                                  },
                                  icon: const Icon(Icons.local_shipping_rounded, size: 18),
                                  label: const Text(
                                    'Confirm Pickup (Out for Delivery)',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (status == 'picked_up' || status == 'in_transit' || status == 'to_deliver') ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    DeliveryService.instance.completeCurrentDelivery();
                                    _updateOrderStatus(rawId, 'delivered', orderCode: orderCode.toString());
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF10B981),
                                    side: const BorderSide(color: Color(0xFF10B981)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Mark Delivered'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
