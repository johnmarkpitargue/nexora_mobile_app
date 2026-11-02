import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../models/delivery_order.dart';
import 'rider_service.dart';
import 'rider_location_service.dart';
import 'earnings_service.dart';
import 'chat_service.dart';
import 'laguna_places_service.dart';
import 'in_app_notification_service.dart';
import '../../features/courier/services/courier_service.dart';
import '../../features/courier/models/courier_models.dart';

class DeliveryService extends ChangeNotifier {
  static final DeliveryService instance = DeliveryService._();
  DeliveryService._() {
    _initInitialData();
    _initSupabaseListener();
    RiderService.instance.hasActiveTripCallback = () => _activeOrder != null;
    RiderLocationService.instance.onBroadcastToDispatch = (payload) {
      if (_dispatchChannel != null && _isDispatchSubscribed == true) {
        _dispatchChannel!.sendBroadcastMessage(
          event: 'location_update',
          payload: payload,
        );
      }
    };
  }

  /// Explicit initialization hook callable from main.dart after Supabase.initialize
  void ensureInitialized() {
    _initSupabaseListener();
  }

  bool _hasCompletedInitialFetch = false;
  bool _hasStreamInitialSnapshot = false;
  RealtimeChannel? _dispatchChannel;
  bool? _isDispatchSubscribed;
  Timer? _pollTimer;
  Set<String>? _declinedOrderIdsSet;
  Set<String> get _declinedOrderIds => _declinedOrderIdsSet ??= {};
  final Set<String> _notifiedOrderIds = {};

  /// Extracts clean readable item title if stored as JSON with chat history
  static String extractItemTitle(dynamic raw) {
    if (raw == null) return 'Assorted Nexora Items';
    final str = raw.toString();
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        final parsed = jsonDecode(str);
        if (parsed is Map && parsed['title'] != null) {
          return parsed['title'].toString();
        }
      } catch (_) {}
    }
    return str;
  }

  final List<DeliveryOrder> _availableOrders = [];
  DeliveryOrder? _activeOrder;
  final List<DeliveryOrder> _completedOrders = [];

  // Continuous active delivery progress state (preserved across navigation/reopens)
  int _activeOrderStage = 0;
  bool _pkg1Scanned = false;
  bool _pkg2Scanned = false;
  bool _tamperSealChecked = true;
  bool _fragileSecuredChecked = true;
  bool _handoverCodeVerified = false;
  DateTime? _deliveryCompletedTime;

  List<DeliveryOrder> get availableOrders => List.unmodifiable(_availableOrders);
  DeliveryOrder? get activeOrder => _activeOrder;
  List<DeliveryOrder> get completedOrders => List.unmodifiable(_completedOrders);
  DeliveryOrder? get lastCompletedOrder =>
      _completedOrders.isNotEmpty ? _completedOrders.first : null;

  int get activeOrderStage => _activeOrderStage;
  bool get pkg1Scanned => _pkg1Scanned;
  bool get pkg2Scanned => _pkg2Scanned;
  bool get tamperSealChecked => _tamperSealChecked;
  bool get fragileSecuredChecked => _fragileSecuredChecked;
  bool get handoverCodeVerified => _handoverCodeVerified;
  DateTime? get deliveryCompletedTime => _deliveryCompletedTime;

  void _initInitialData() {
    _activeOrder = null;
    _activeOrderStage = 0;
    _pkg1Scanned = false;
    _pkg2Scanned = false;
    _tamperSealChecked = true;
    _fragileSecuredChecked = true;
    _handoverCodeVerified = false;
    _deliveryCompletedTime = null;
    _availableOrders.clear();
    _notifiedOrderIds.clear();

    // Past Completed Orders History
    _completedOrders.addAll([
      DeliveryOrder(
        id: 'NX-8720-ORD',
        customerName: 'Clara Del Rosario',
        customerPhone: '+63 927 334 1122',
        customerAddress: 'San Lorenzo Village, Makati City',
        merchantName: 'Sephora Beauty Nexora Annex',
        merchantAddress: 'Power Plant Mall, Rockwell, Makati',
        merchantPhone: '+63 2 8111 2233',
        items: const [
          OrderItemDetail(
            name: 'Glow Recipe Watermelon Dew Drops',
            quantity: 2,
            price: 2150.00,
            imageUrl: 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=200',
          ),
        ],
        deliveryFee: 130.00,
        tip: 30.00,
        orderTotal: 4460.00,
        paymentType: 'Prepaid',
        distanceKm: 2.9,
        estimatedMinutes: 16,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: DeliveryStatus.delivered,
        recipientNotes: 'Received by homeowner directly.',
      ),
      DeliveryOrder(
        id: 'NX-8641-ORD',
        customerName: 'David Lee',
        customerPhone: '+63 919 778 9911',
        customerAddress: 'Century City Mall Residences, Poblacion, Makati',
        merchantName: 'Logitech Official Store',
        merchantAddress: 'Glorietta 2, Ayala Center, Makati',
        merchantPhone: '+63 2 8444 5555',
        items: const [
          OrderItemDetail(
            name: 'Logitech MX Master 3S Ergonomic Mouse',
            quantity: 1,
            price: 6195.00,
            imageUrl: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=200',
          ),
        ],
        deliveryFee: 150.00,
        tip: 20.00,
        orderTotal: 6365.00,
        paymentType: 'Prepaid',
        distanceKm: 3.2,
        estimatedMinutes: 20,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        status: DeliveryStatus.delivered,
        recipientNotes: 'Left with condo concierge as instructed.',
      ),
    ]);
  }

  bool get isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the latest pending orders from Supabase and adds any new ones to `_availableOrders`.
  Future<void> refreshAvailableOrders() async {
    // 1. Fetch remote job offers from Laravel Sanctum API if authenticated
    if (ApiClient.instance.isAuthenticated) {
      try {
        final res = await ApiClient.instance.get(ApiConstants.riderOffers);
        final list = res.data as List<dynamic>? ?? [];
        bool addedAny = false;
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final offerId = map['id']?.toString() ?? '';
          final orderCode = (map['order_number'] ?? map['order_id'] ?? offerId).toString();
          final clean = orderCode.replaceAll('#', '').trim();
          if (_declinedOrderIds.contains(clean) || _declinedOrderIds.contains(offerId)) {
            continue;
          }
          final availIdx = _availableOrders.indexWhere(
            (o) => o.id == orderCode || o.id.replaceAll('#', '').trim() == clean,
          );
          if (availIdx < 0) {
            _availableOrders.insert(0, DeliveryOrder.fromApiOffer(map));
            addedAny = true;
          }
        }
        if (addedAny) {
          notifyListeners();
        }
      } catch (_) {}
    }

    if (!isSupabaseReady) return;
    try {
      final currentRider = RiderService.instance.profile;
      final currentRiderName = currentRider.name.trim().toLowerCase();
      final currentRiderId = currentRider.id.trim().toLowerCase();

      final data = await Supabase.instance.client
          .from('orders')
          .select(
              'id, order_id, status, customer_id, buyer_name, buyer_email, item_details, delivery_address, delivery_lat, delivery_lng, created_at, payment_method, total_price, courier_name, rider_id, is_rider_accepted')
          .order('created_at', ascending: false)
          .limit(20);
      bool addedAny = false;
      for (final row in data) {
        final rawId = row['id'].toString();
        final orderCode = (row['order_id'] ?? rawId).toString();
        final clean = orderCode.replaceAll('#', '').trim();
        if (_declinedOrderIds.contains(clean) || _declinedOrderIds.contains(rawId)) {
          continue;
        }
        final status = (row['status'] ?? 'pending').toString().toLowerCase();

        final rowCourierName = (row['courier_name'] ?? '').toString().trim().toLowerCase();
        final rowRiderId = (row['rider_id'] ?? '').toString().trim().toLowerCase();
        final isMyDelivery = (rowCourierName.isNotEmpty && rowCourierName == currentRiderName) ||
            (rowRiderId.isNotEmpty && rowRiderId == currentRiderId);

        final isMatchActive = _activeOrder != null &&
            (_activeOrder!.id == orderCode ||
                _activeOrder!.id == rawId ||
                _activeOrder!.id.replaceAll('#', '').trim() == clean);
        final isMatchCompleted = _completedOrders.any(
          (o) =>
              o.id == orderCode ||
              o.id == rawId ||
              o.id.replaceAll('#', '').trim() == clean,
        );
        final availIdx = _availableOrders.indexWhere(
          (o) =>
              o.id == orderCode ||
              o.id == rawId ||
              o.id.replaceAll('#', '').trim() == clean,
        );

        if (status == 'pending' || status == 'ready') {
          if (!isMatchActive && !isMatchCompleted && availIdx < 0) {
            final newOrder = _createDeliveryOrderFromRow(orderCode, row);
            _availableOrders.insert(0, newOrder);
            RiderChatService.instance.subscribeToOrder(orderCode, customerName: newOrder.customerName);
            addedAny = true;

            // Only notify if initial load was already completed AND not yet notified
            if (_hasCompletedInitialFetch && !_notifiedOrderIds.contains(clean)) {
              _notifiedOrderIds.add(clean);
              InAppNotificationService.instance.showNotification(
                senderName: 'New Delivery Dispatch',
                message: 'Order #$orderCode (${newOrder.merchantName} ➔ ${newOrder.customerName}) is ready for pickup!',
                orderId: orderCode,
                icon: Icons.two_wheeler_rounded,
                accentColor: const Color(0xFF0066FF),
              );
            } else {
              _notifiedOrderIds.add(clean);
            }
          }
        } else if (status == 'accepted' ||
            status == 'at_store' ||
            status == 'picked_up' ||
            status == 'in_transit' ||
            status == 'to_deliver') {
          if (availIdx >= 0) {
            _availableOrders.removeAt(availIdx);
            addedAny = true;
          }
          // Only restore active order if assigned to THIS rider
          if (isMyDelivery && _activeOrder == null) {
            _activeOrder = _createDeliveryOrderFromRow(orderCode, row).copyWith(status: DeliveryStatus.accepted);
            _activeOrderStage = status == 'in_transit' || status == 'to_deliver'
                ? 3
                : status == 'picked_up'
                    ? 2
                    : status == 'at_store'
                        ? 1
                        : 0;
            addedAny = true;
          }
        } else if (status == 'delivered') {
          if (isMatchActive) {
            completeCurrentDelivery();
          } else if (availIdx >= 0) {
            _availableOrders.removeAt(availIdx);
            addedAny = true;
          }
        }
      }
      _hasCompletedInitialFetch = true;
      if (addedAny) {
        notifyListeners();
      }
    } catch (_) {
      _hasCompletedInitialFetch = true;
    }
  }

  void _initSupabaseListener() {
    if (!isSupabaseReady) return;
    try {
      // 1. Initial REST fetch & periodic poll for pending orders (15s to keep egress minimal)
      refreshAvailableOrders();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => refreshAvailableOrders(),
      );

      // 2. Real-time broadcast channel for instant new orders from Buyer App
      if (_dispatchChannel != null) {
        Supabase.instance.client.removeChannel(_dispatchChannel!);
      }
      _isDispatchSubscribed = false;
      final dispatchChannel = Supabase.instance.client.channel('orders_dispatch');
      _dispatchChannel = dispatchChannel;
      dispatchChannel.onBroadcast(
        event: 'order_created',
        callback: (payload) {
          final orderCode = (payload['order_id'] ?? '').toString();
          if (orderCode.isEmpty) return;
          final clean = orderCode.replaceAll('#', '').trim();
          final isMatchActive = _activeOrder != null && _activeOrder!.id.replaceAll('#', '').trim() == clean;
          final availIdx = _availableOrders.indexWhere((o) => o.id.replaceAll('#', '').trim() == clean);
          if (!isMatchActive && availIdx < 0) {
            final addressStr = (payload['delivery_address'] ?? 'Tuy-Baanan, Liliw, Laguna').toString();
            final rawLat = (payload['delivery_lat'] as num?)?.toDouble();
            final rawLng = (payload['delivery_lng'] as num?)?.toDouble();

            double lat = rawLat ?? 0.0;
            double lng = rawLng ?? 0.0;
            if (lat == 0.0 || lng == 0.0) {
              final resolved = LagunaPlacesService.instance.resolveCoordinates(addressStr);
              lat = resolved.latitude;
              lng = resolved.longitude;
            }

            final newOrder = DeliveryOrder(
              id: orderCode,
              customerName: (payload['customer_id'] ?? 'Alex Rivera').toString(),
              customerPhone: '+63 975 963 2035',
              customerAddress: addressStr,
              customerLat: lat,
              customerLng: lng,
              customerNotes: 'Online order placed via Nexora App',
              merchantName: 'Nexora Official Flagship Store',
              merchantAddress: 'Nexora Central Fulfillment Center',
              merchantPhone: '+63 2 8888 1234',
              items: [
                OrderItemDetail(
                  name: extractItemTitle(payload['item_details']),
                  quantity: 1,
                  price: 299.0,
                  imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200',
                ),
              ],
              deliveryFee: 120.0,
              tip: 25.0,
              orderTotal: (payload['total'] as num?)?.toDouble() ?? 444.0,
              paymentType: 'Cash on Delivery',
              distanceKm: 2.8,
              estimatedMinutes: 15,
              createdAt: DateTime.now(),
              status: DeliveryStatus.available,
            );
            _availableOrders.insert(0, newOrder);
            _notifiedOrderIds.add(clean);
            RiderChatService.instance.subscribeToOrder(orderCode, customerName: newOrder.customerName);
            notifyListeners();

            InAppNotificationService.instance.showNotification(
              senderName: 'New Delivery Dispatch',
              message: 'Order #$orderCode (${newOrder.merchantName} ➔ ${newOrder.customerName}) is ready for pickup!',
              orderId: orderCode,
              icon: Icons.two_wheeler_rounded,
              accentColor: const Color(0xFF0066FF),
            );
          }
        },
      );

      // Respond immediately when Buyer App opens tracking and requests Rider's real phone GPS
      dispatchChannel.onBroadcast(
        event: 'request_rider_location',
        callback: (payload) {
          final orderCode = (payload['order_id'] ?? '').toString().replaceAll('#', '').trim();
          final targetId = orderCode.isNotEmpty
              ? orderCode
              : (_activeOrder?.id.replaceAll('#', '').trim() ?? '');
          if (targetId.isNotEmpty) {
            RiderLocationService.instance.broadcastCurrentPhoneLocation(
              orderId: targetId,
            );
          }
        },
      );

      // Real-time location update broadcast handler (when customer updates doorstep pin)
      dispatchChannel.onBroadcast(
        event: 'location_updated',
        callback: (payload) {
          final orderCode = (payload['order_id'] ?? '').toString();
          if (orderCode.isEmpty) return;
          final rawLat = (payload['delivery_lat'] as num?)?.toDouble() ??
              double.tryParse(payload['delivery_lat']?.toString() ?? '');
          final rawLng = (payload['delivery_lng'] as num?)?.toDouble() ??
              double.tryParse(payload['delivery_lng']?.toString() ?? '');
          final addressStr = payload['delivery_address']?.toString();
          _handleLocationUpdated(orderCode, rawLat, rawLng, addressStr);
        },
      );

      // Real-time buyer rating broadcast handler (when buyer rates the delivery rider)
      dispatchChannel.onBroadcast(
        event: 'rider_rated',
        callback: (payload) {
          final orderCode = (payload['order_id'] ?? '').toString().replaceAll('#', '').trim();
          final driverStars = (payload['driver_rating'] as num?)?.toInt() ??
              int.tryParse(payload['driver_rating']?.toString() ?? '') ??
              5;
          final deliveryStars = (payload['delivery_rating'] as num?)?.toInt() ??
              int.tryParse(payload['delivery_rating']?.toString() ?? '') ??
              5;
          final newRating = (payload['new_courier_rating'] as num?)?.toDouble() ??
              double.tryParse(payload['new_courier_rating']?.toString() ?? '');
          final comment = (payload['comment'] ?? '').toString();
          final rawTags = payload['tags'];
          final tags = rawTags is List ? rawTags.map((e) => e.toString()).toList() : <String>[];
          final courierName = (payload['courier_name'] ?? RiderService.instance.profile.name).toString();

          final updatedRating = RiderService.instance.applyBuyerRating(
            orderId: orderCode,
            driverRating: driverStars,
            deliveryRating: deliveryStars,
            newCourierRating: newRating,
            comment: comment,
            tags: tags,
          );
          CourierService.instance.updateRiderRating(courierName, updatedRating);
          notifyListeners();

          InAppNotificationService.instance.showNotification(
            senderName: 'New Customer Rating ($driverStars★)',
            message: comment.isNotEmpty
                ? '"$comment" • Overall Rating: ${updatedRating.toStringAsFixed(2)} ★'
                : 'Order #$orderCode rated $driverStars★! Your overall rating is now ${updatedRating.toStringAsFixed(2)} ★.',
            orderId: orderCode,
            icon: Icons.star_rounded,
            accentColor: const Color(0xFFF59E0B),
          );
        },
      );
      dispatchChannel.subscribe((status, [err]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _isDispatchSubscribed = true;
        }
      });

      // 3. Postgres stream subscription
      Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((data) {
        final currentRider = RiderService.instance.profile;
        final currentRiderName = currentRider.name.trim().toLowerCase();
        final currentRiderId = currentRider.id.trim().toLowerCase();

        for (final row in data) {
          final rawId = row['id'].toString();
          final orderCode = (row['order_id'] ?? rawId).toString();
          final clean = orderCode.replaceAll('#', '').trim();
          final status = (row['status'] ?? 'pending').toString().toLowerCase();

          final rowCourierName = (row['courier_name'] ?? '').toString().trim().toLowerCase();
          final rowRiderId = (row['rider_id'] ?? '').toString().trim().toLowerCase();
          final isMyDelivery = (rowCourierName.isNotEmpty && rowCourierName == currentRiderName) ||
              (rowRiderId.isNotEmpty && rowRiderId == currentRiderId);

          // Sync real-time delivery coordinates if changed by customer
          final rowLat = (row['delivery_lat'] as num?)?.toDouble() ??
              double.tryParse(row['delivery_lat']?.toString() ?? '');
          final rowLng = (row['delivery_lng'] as num?)?.toDouble() ??
              double.tryParse(row['delivery_lng']?.toString() ?? '');
          final rowAddress = row['delivery_address']?.toString();
          if (rowLat != null && rowLng != null && rowLat != 0.0 && rowLng != 0.0) {
            _handleLocationUpdated(orderCode, rowLat, rowLng, rowAddress);
          }

          final isMatchActive = _activeOrder != null &&
              (_activeOrder!.id == orderCode || _activeOrder!.id == rawId || _activeOrder!.id.replaceAll('#', '') == clean);
          final availIdx = _availableOrders.indexWhere(
            (o) => o.id == orderCode || o.id == rawId || o.id.replaceAll('#', '') == clean,
          );

          if (status == 'pending' || status == 'ready') {
            if (!isMatchActive && availIdx < 0) {
              final newOrder = _createDeliveryOrderFromRow(orderCode, row);
              _availableOrders.insert(0, newOrder);
              RiderChatService.instance.subscribeToOrder(orderCode, customerName: newOrder.customerName);
              notifyListeners();

              // Only notify if initial stream snapshot has already passed AND not notified yet
              if (_hasStreamInitialSnapshot && !_notifiedOrderIds.contains(clean)) {
                _notifiedOrderIds.add(clean);
                InAppNotificationService.instance.showNotification(
                  senderName: 'New Delivery Dispatch',
                  message: 'Order #$orderCode (${newOrder.merchantName} ➔ ${newOrder.customerName}) is ready for pickup!',
                  orderId: orderCode,
                  icon: Icons.two_wheeler_rounded,
                  accentColor: const Color(0xFF0066FF),
                );
              } else {
                _notifiedOrderIds.add(clean);
              }
            }
          } else if (status == 'accepted' ||
              status == 'at_store' ||
              status == 'picked_up' ||
              status == 'in_transit' ||
              status == 'to_deliver') {
            if (availIdx >= 0) {
              _availableOrders.removeAt(availIdx);
              notifyListeners();
            }
            // Only restore active order if assigned to THIS rider
            if (isMyDelivery && _activeOrder == null) {
              _activeOrder = _createDeliveryOrderFromRow(orderCode, row).copyWith(status: DeliveryStatus.accepted);
              _activeOrderStage = status == 'in_transit' || status == 'to_deliver'
                  ? 3
                  : status == 'picked_up'
                      ? 2
                      : status == 'at_store'
                          ? 1
                          : 0;
              notifyListeners();
            }
          } else if (status == 'delivered') {
            if (isMatchActive) {
              completeCurrentDelivery();
            } else if (availIdx >= 0) {
              _availableOrders.removeAt(availIdx);
              notifyListeners();
            }
          }
        }
        _hasStreamInitialSnapshot = true;
      });
    } catch (e) {
      debugPrint('⚠️ DeliveryService Supabase listener notice: $e');
    }
  }

  void _handleLocationUpdated(String orderCode, double? rawLat, double? rawLng, String? addressStr) {
    if (rawLat == null || rawLng == null || rawLat == 0.0 || rawLng == 0.0) return;
    final clean = orderCode.replaceAll('#', '').trim();
    bool changed = false;

    if (_activeOrder != null && _activeOrder!.id.replaceAll('#', '').trim() == clean) {
      if ((_activeOrder!.customerLat - rawLat).abs() > 0.00001 ||
          (_activeOrder!.customerLng - rawLng).abs() > 0.00001 ||
          (addressStr != null && addressStr != _activeOrder!.customerAddress)) {
        _activeOrder = _activeOrder!.copyWith(
          customerLat: rawLat,
          customerLng: rawLng,
          customerAddress: addressStr ?? _activeOrder!.customerAddress,
        );
        changed = true;
        debugPrint('📍 [Rider] Active order $clean destination pin updated to ($rawLat, $rawLng)');

        InAppNotificationService.instance.showNotification(
          senderName: 'Customer Updated Pinpoint',
          message: 'Doorstep pin updated for Order #$clean: ${addressStr ?? "New GPS coordinates"}',
          orderId: clean,
          icon: Icons.edit_location_alt_rounded,
          accentColor: const Color(0xFF10B981),
        );
      }
    }

    final availIdx = _availableOrders.indexWhere((o) => o.id.replaceAll('#', '').trim() == clean);
    if (availIdx >= 0) {
      if ((_availableOrders[availIdx].customerLat - rawLat).abs() > 0.00001 ||
          (_availableOrders[availIdx].customerLng - rawLng).abs() > 0.00001 ||
          (addressStr != null && addressStr != _availableOrders[availIdx].customerAddress)) {
        _availableOrders[availIdx] = _availableOrders[availIdx].copyWith(
          customerLat: rawLat,
          customerLng: rawLng,
          customerAddress: addressStr ?? _availableOrders[availIdx].customerAddress,
        );
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void _syncStatusToSupabase(String orderId, String status, {bool isAccepting = false, String? proofPhoto}) {
    final clean = orderId.replaceAll('#', '').trim();
    final riderName = RiderService.instance.profile.name;
    final riderRating = RiderService.instance.profile.rating;

    // Sync with CourierService so both Rider and Courier modes stay in sync
    CourierService.instance.syncFromDeliveryOrder(clean, status, riderName: riderName);

    // Also update RiderLocationService status and broadcast real phone GPS
    RiderLocationService.instance.updateOrderStatus(status);

    if (!isSupabaseReady) return;
    try {
      _updateOrderRowInSupabase(clean, status, isAccepting: isAccepting, proofPhoto: proofPhoto);

      final statusPayload = <String, dynamic>{
        'order_id': clean,
        'status': status,
        'rider_accepted': true,
        'courier_name': riderName,
        'courier_rating': riderRating,
        if (proofPhoto != null && proofPhoto.isNotEmpty) 'proof_photo': proofPhoto,
        if (RiderLocationService.instance.hasRealGpsFix) ...{
          'rider_lat': RiderLocationService.instance.currentLat,
          'rider_lng': RiderLocationService.instance.currentLng,
          'rider_speed': RiderLocationService.instance.currentSpeedKmh,
          'rider_heading': RiderLocationService.instance.currentHeading,
          'rider_accuracy': RiderLocationService.instance.currentAccuracyMeters,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Broadcast status update on persistent _dispatchChannel (avoiding channel clobbering)
      if (_dispatchChannel != null && _isDispatchSubscribed == true) {
        if (isAccepting) {
          _dispatchChannel!.sendBroadcastMessage(
            event: 'order_accepted',
            payload: statusPayload,
          );
        }
        _dispatchChannel!.sendBroadcastMessage(
          event: 'status_updated',
          payload: statusPayload,
        );
      }

      final trackCh = Supabase.instance.client.channel('rider_tracking_$clean');
      trackCh.subscribe((subStatus, [err]) {
        if (subStatus == RealtimeSubscribeStatus.subscribed) {
          trackCh.sendBroadcastMessage(
            event: 'status_update',
            payload: statusPayload,
          );
        }
      });
    } catch (e) {
      debugPrint('⚠️ Order status Supabase sync: $e');
    }
  }

  Future<void> _updateOrderRowInSupabase(String clean, String status, {bool isAccepting = false, String? proofPhoto}) async {
    final updateData = <String, dynamic>{'status': status};
    if (isAccepting) {
      updateData['courier_name'] = RiderService.instance.profile.name;
      updateData['rider_id'] = RiderService.instance.profile.id;
      updateData['is_rider_accepted'] = true;
    }
    if (proofPhoto != null && proofPhoto.isNotEmpty) {
      updateData['proof_photo'] = proofPhoto;
    }
    final isNum = int.tryParse(clean) != null;
    if (isNum) {
      try {
        await Supabase.instance.client.from('orders').update(updateData).eq('id', int.parse(clean));
      } catch (_) {}
    }
    try {
      await Supabase.instance.client.from('orders').update(updateData).eq('order_id', clean);
    } catch (_) {}
    try {
      await Supabase.instance.client.from('orders').update(updateData).eq('id', clean);
    } catch (_) {}
  }

  /// Activate a CourierParcel as the active delivery order for 5-stage navigation & handover
  void activateCourierParcel(CourierParcel parcel) {
    final order = CourierService.instance.toDeliveryOrder(parcel);
    final initialStatus =
        parcel.status == CourierParcelStatus.inTransit ? 'in_transit' : 'to_deliver';
    _activeOrder = order.copyWith(status: DeliveryStatus.accepted);
    _activeOrderStage = parcel.status == CourierParcelStatus.inTransit ? 2 : 0;
    _pkg1Scanned = parcel.status == CourierParcelStatus.inTransit;
    _pkg2Scanned = parcel.status == CourierParcelStatus.inTransit;
    _tamperSealChecked = true;
    _fragileSecuredChecked = true;
    _handoverCodeVerified = false;
    _deliveryCompletedTime = null;
    RiderService.instance.recordOrderAccepted();
    RiderChatService.instance.subscribeToOrder(parcel.id, customerName: parcel.customerName);
    RiderLocationService.instance.startTracking(
      orderId: parcel.id,
      riderName: RiderService.instance.profile.name,
      status: initialStatus,
    );
    notifyListeners();
    _syncStatusToSupabase(
      parcel.id,
      initialStatus,
      isAccepting: true,
    );
  }

  void acceptOrder(String orderId, {Map<String, dynamic>? fallbackRow}) {
    final clean = orderId.replaceAll('#', '').trim();
    final index = _availableOrders.indexWhere(
      (o) => o.id == orderId || o.id.replaceAll('#', '').trim() == clean,
    );
    DeliveryOrder? order;
    if (index != -1) {
      order = _availableOrders.removeAt(index);
    } else if (fallbackRow != null) {
      order = _createDeliveryOrderFromRow(clean, fallbackRow);
    }

    if (order != null) {
      _activeOrderStage = 0;
      _pkg1Scanned = false;
      _pkg2Scanned = false;
      _tamperSealChecked = true;
      _fragileSecuredChecked = true;
      _handoverCodeVerified = false;
      _deliveryCompletedTime = null;
      _activeOrder = order.copyWith(status: DeliveryStatus.accepted);
      RiderService.instance.recordOrderAccepted();
      RiderChatService.instance.subscribeToOrder(order.id, customerName: order.customerName);
      // Immediately start tracking & broadcasting Rider's real phone GPS
      RiderLocationService.instance.startTracking(
        orderId: order.id,
        riderName: RiderService.instance.profile.name,
        status: 'accepted',
      );
      notifyListeners();

      _syncStatusToSupabase(order.id, 'accepted', isAccepting: true);
    }
  }

  void updateActiveOrderStage(int stage) {
    if (_activeOrder == null) return;
    _activeOrderStage = stage;

    DeliveryStatus nextStatus;
    String statusStr = 'accepted';
    switch (stage) {
      case 0:
        nextStatus = DeliveryStatus.accepted;
        statusStr = 'accepted';
        break;
      case 1:
        nextStatus = DeliveryStatus.atMerchant;
        statusStr = 'at_store';
        break;
      case 2:
        nextStatus = DeliveryStatus.pickedUp;
        statusStr = 'picked_up';
        break;
      case 3:
        nextStatus = DeliveryStatus.atCustomer;
        statusStr = 'in_transit';
        break;
      case 4:
      default:
        nextStatus = DeliveryStatus.delivered;
        statusStr = 'delivered';
        _deliveryCompletedTime ??= DateTime.now();
        break;
    }

    _activeOrder = _activeOrder!.copyWith(status: nextStatus);
    notifyListeners();

    _syncStatusToSupabase(_activeOrder!.id, statusStr);
  }

  void updateActiveOrderScanProgress({
    bool? pkg1,
    bool? pkg2,
    bool? tamperSealChecked,
    bool? fragileSecuredChecked,
    bool? handoverVerified,
    DateTime? completedTime,
  }) {
    if (pkg1 != null) _pkg1Scanned = pkg1;
    if (pkg2 != null) _pkg2Scanned = pkg2;
    if (tamperSealChecked != null) _tamperSealChecked = tamperSealChecked;
    if (fragileSecuredChecked != null) _fragileSecuredChecked = fragileSecuredChecked;
    if (handoverVerified != null) _handoverCodeVerified = handoverVerified;
    if (completedTime != null) _deliveryCompletedTime = completedTime;
    notifyListeners();
  }

  void declineOrder(String orderId) {
    final clean = orderId.replaceAll('#', '').trim();
    _declinedOrderIds.add(clean);
    _availableOrders.removeWhere(
      (o) => o.id == orderId || o.id.replaceAll('#', '').trim() == clean,
    );
    RiderService.instance.recordOrderDeclined();
    notifyListeners();
  }

  void advanceStatus() {
    if (_activeOrder == null) return;

    DeliveryStatus nextStatus;
    switch (_activeOrder!.status) {
      case DeliveryStatus.available:
        nextStatus = DeliveryStatus.accepted;
        break;
      case DeliveryStatus.accepted:
        nextStatus = DeliveryStatus.atMerchant;
        break;
      case DeliveryStatus.atMerchant:
        nextStatus = DeliveryStatus.pickedUp;
        break;
      case DeliveryStatus.pickedUp:
        nextStatus = DeliveryStatus.atCustomer;
        break;
      case DeliveryStatus.atCustomer:
        completeCurrentDelivery();
        return;
      case DeliveryStatus.delivered:
      case DeliveryStatus.cancelled:
        return;
    }

    _activeOrder = _activeOrder!.copyWith(status: nextStatus);
    notifyListeners();
  }

  void completeCurrentDelivery({String? photoPath, String? notes}) {
    if (_activeOrder == null) return;

    final completed = _activeOrder!.copyWith(
      status: DeliveryStatus.delivered,
      proofPhotoPath: photoPath,
      recipientNotes: notes ?? 'Handed to recipient successfully',
    );

    _completedOrders.insert(0, completed);

    // Credit Rider earnings
    final earnings = completed.riderEarnings;
    RiderService.instance.addEarnings(earnings);

    // Record earnings transaction
    EarningsService.instance.recordDeliveryEarnings(
      orderId: completed.id,
      deliveryFee: completed.deliveryFee,
      tip: completed.tip,
    );

    _activeOrder = null;
    _activeOrderStage = 0;
    _pkg1Scanned = false;
    _pkg2Scanned = false;
    _tamperSealChecked = true;
    _fragileSecuredChecked = true;
    _handoverCodeVerified = false;
    _deliveryCompletedTime = null;
    notifyListeners();

    _syncStatusToSupabase(completed.id, 'delivered', proofPhoto: photoPath);
    RiderLocationService.instance.stopTracking();
  }

  Future<bool> acceptOrderRemote(String orderId, {String? offerId}) async {
    final clean = orderId.replaceAll('#', '').trim();
    final effectiveOfferId = offerId ?? clean;

    if (ApiClient.instance.isAuthenticated) {
      try {
        final idempotencyKey = 'accept_${clean}_${DateTime.now().millisecondsSinceEpoch}';
        await ApiClient.instance.post(
          ApiConstants.acceptOffer(effectiveOfferId),
          headers: {'Idempotency-Key': idempotencyKey},
        );
      } catch (_) {}
    }

    acceptOrder(orderId);
    return true;
  }

  Future<bool> declineOrderRemote(String orderId, {String? offerId}) async {
    final clean = orderId.replaceAll('#', '').trim();
    final effectiveOfferId = offerId ?? clean;

    if (ApiClient.instance.isAuthenticated) {
      try {
        await ApiClient.instance.post(ApiConstants.declineOffer(effectiveOfferId));
      } catch (_) {}
    }

    declineOrder(orderId);
    return true;
  }

  Future<bool> confirmPickupRemote(String trackingNumber) async {
    if (ApiClient.instance.isAuthenticated) {
      try {
        final idempotencyKey = 'pickup_${trackingNumber}_${DateTime.now().millisecondsSinceEpoch}';
        await ApiClient.instance.post(
          ApiConstants.pickup,
          body: {'tracking_number': trackingNumber.trim()},
          headers: {'Idempotency-Key': idempotencyKey},
        );
        updateActiveOrderStage(2);
        return true;
      } catch (e) {
        debugPrint('Confirm pickup remote notice: $e');
      }
    }
    updateActiveOrderStage(2);
    return true;
  }

  Future<bool> completeDeliveryRemote({
    required String orderId,
    required String deliveryOtp,
    required String podFilePath,
    String? notes,
  }) async {
    if (ApiClient.instance.isAuthenticated) {
      try {
        final idempotencyKey = 'complete_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
        final multipartFile = await http.MultipartFile.fromPath('pod_image', podFilePath);

        await ApiClient.instance.multipartPost(
          ApiConstants.completeDelivery(orderId),
          fields: {
            'delivery_otp': deliveryOtp.trim(),
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          },
          files: {'pod_image': multipartFile},
          headers: {'Idempotency-Key': idempotencyKey},
        );

        completeCurrentDelivery(photoPath: podFilePath, notes: notes);
        return true;
      } catch (e) {
        debugPrint('Complete delivery remote notice: $e');
      }
    }

    completeCurrentDelivery(photoPath: podFilePath, notes: notes);
    return true;
  }

  Future<bool> failDeliveryRemote({
    required String orderId,
    required String reason,
    String? notes,
  }) async {
    if (ApiClient.instance.isAuthenticated) {
      try {
        final idempotencyKey = 'fail_${orderId}_${DateTime.now().millisecondsSinceEpoch}';
        await ApiClient.instance.post(
          ApiConstants.failDelivery(orderId),
          body: {
            'reason': reason,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          },
          headers: {'Idempotency-Key': idempotencyKey},
        );
      } catch (e) {
        debugPrint('Fail delivery remote notice: $e');
      }
    }
    return true;
  }

  Future<List<DeliveryOrder>> fetchActiveDeliveriesRemote() async {
    if (!ApiClient.instance.isAuthenticated) return [];
    try {
      final res = await ApiClient.instance.get(ApiConstants.activeDeliveries);
      final list = res.data as List<dynamic>? ?? [];
      return list.map((item) => DeliveryOrder.fromApiOrder(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<DeliveryOrder>> fetchDeliveryHistoryRemote() async {
    if (!ApiClient.instance.isAuthenticated) return _completedOrders;
    try {
      final res = await ApiClient.instance.get(ApiConstants.deliveryHistory);
      final list = res.data as List<dynamic>? ?? [];
      final orders = list.map((item) => DeliveryOrder.fromApiOrder(item as Map<String, dynamic>)).toList();
      if (orders.isNotEmpty) {
        _completedOrders.clear();
        _completedOrders.addAll(orders);
        notifyListeners();
      }
      return orders;
    } catch (_) {
      return _completedOrders;
    }
  }

  void addSimulatedNewDispatch() {
    final count = _availableOrders.length + _completedOrders.length + 1;
    final newOrder = DeliveryOrder(
      id: 'NX-${9300 + count}-ORD',
      customerName: 'Kristine Bautista',
      customerPhone: '+63 915 221 8899',
      customerAddress: 'Fairways Tower, 5th Ave & McKinley Rd',
      customerNotes: 'Unit 21-C, buzzer is working.',
      merchantName: 'Zara Official Store',
      merchantAddress: 'One High Street Mall',
      merchantPhone: '+63 2 8999 0011',
      items: const [
        OrderItemDetail(
          name: 'Cropped Linen Blend Blazer',
          quantity: 1,
          price: 3995.00,
          imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=200',
        ),
      ],
      deliveryFee: 135.00,
      tip: 35.00,
      orderTotal: 4165.00,
      paymentType: 'Prepaid',
      distanceKm: 2.1,
      estimatedMinutes: 12,
      createdAt: DateTime.now(),
      status: DeliveryStatus.available,
    );

    _availableOrders.insert(0, newOrder);
    notifyListeners();
  }

  DeliveryOrder _createDeliveryOrderFromRow(String orderCode, Map<String, dynamic> row) {
    final addressStr = (row['delivery_address'] ?? 'Tuy-Baanan, Liliw, Laguna').toString();
    final rawLat = (row['delivery_lat'] as num?)?.toDouble();
    final rawLng = (row['delivery_lng'] as num?)?.toDouble();

    double lat = rawLat ?? 0.0;
    double lng = rawLng ?? 0.0;
    if (lat == 0.0 || lng == 0.0) {
      final resolved = LagunaPlacesService.instance.resolveCoordinates(addressStr);
      lat = resolved.latitude;
      lng = resolved.longitude;
    }

    return DeliveryOrder(
      id: orderCode,
      customerName: (row['customer_id'] ?? 'Alex Rivera').toString(),
      customerPhone: '+63 975 963 2035',
      customerAddress: addressStr,
      customerLat: lat,
      customerLng: lng,
      customerNotes: 'Online order placed via Nexora App',
      merchantName: 'Nexora Official Flagship Store',
      merchantAddress: 'Nexora Central Fulfillment Center',
      merchantPhone: '+63 2 8888 1234',
      items: [
        OrderItemDetail(
          name: extractItemTitle(row['item_details']),
          quantity: 1,
          price: 299.0,
          imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200',
        ),
      ],
      deliveryFee: 120.0,
      tip: 25.0,
      orderTotal: 444.0,
      paymentType: 'Cash on Delivery',
      distanceKm: 2.8,
      estimatedMinutes: 15,
      createdAt: DateTime.now(),
      status: DeliveryStatus.available,
    );
  }
}
