import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'buyer_account_service.dart';
import 'cart_service.dart';
import 'profile_service.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class OrderItemModel {
  final String orderId;
  final String dateText;
  final String orderDateTimeText;
  final String statusText;
  final Color statusColor;
  final String etaText;
  final String etaTime;
  final double progress;
  final List<CartItemModel> items;
  final double totalPrice;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final String paymentMethod;
  final String shippingOption;
  final String recipientName;
  final String recipientPhone;
  final String shippingAddress;
  final String courierName;
  final double courierRating;
  final String courierAvatarUrl;
  final String buyerEmail;
  final double? deliveryLat;
  final double? deliveryLng;
  final bool isRiderAccepted;
  final bool isRated;
  final int? buyerDriverRating;
  final int? buyerDeliveryRating;
  final String? buyerCourierComment;
  final List<String>? buyerCourierTags;

  OrderItemModel({
    required this.orderId,
    required this.dateText,
    String? orderDateTimeText,
    required this.statusText,
    required this.statusColor,
    required this.etaText,
    required this.etaTime,
    required this.progress,
    required this.items,
    required this.totalPrice,
    double? subtotal,
    double? shippingFee,
    double? discount,
    required this.paymentMethod,
    String? shippingOption,
    String? recipientName,
    String? recipientPhone,
    String? shippingAddress,
    required this.courierName,
    required this.courierRating,
    required this.courierAvatarUrl,
    String? buyerEmail,
    this.deliveryLat,
    this.deliveryLng,
    this.isRiderAccepted = false,
    this.isRated = false,
    this.buyerDriverRating,
    this.buyerDeliveryRating,
    this.buyerCourierComment,
    this.buyerCourierTags,
  }) : buyerEmail = buyerEmail ?? 'guest',
       orderDateTimeText = orderDateTimeText ?? dateText,
       subtotal = subtotal ?? totalPrice,
       shippingFee = shippingFee ?? 0.0,
       discount = discount ?? 0.0,
       shippingOption = shippingOption ?? 'Standard Local Delivery',
       recipientName =
           recipientName ??
           (ProfileService.instance.name.isNotEmpty
               ? ProfileService.instance.name
               : 'Alex Rivera'),
       recipientPhone =
           recipientPhone ??
           (ProfileService.instance.phone.isNotEmpty
               ? ProfileService.instance.phone
               : '+63 917 123 4567'),
       shippingAddress =
           shippingAddress ??
           (ProfileService.instance.address.isNotEmpty
               ? ProfileService.instance.address
               : 'Unit 402, Lumina Heights Tower 2, Makati, Metro Manila');

  OrderItemModel copyWith({
    String? orderId,
    String? dateText,
    String? orderDateTimeText,
    String? statusText,
    Color? statusColor,
    String? etaText,
    String? etaTime,
    double? progress,
    List<CartItemModel>? items,
    double? totalPrice,
    double? subtotal,
    double? shippingFee,
    double? discount,
    String? paymentMethod,
    String? shippingOption,
    String? recipientName,
    String? recipientPhone,
    String? shippingAddress,
    String? courierName,
    double? courierRating,
    String? courierAvatarUrl,
    String? buyerEmail,
    double? deliveryLat,
    double? deliveryLng,
    bool? isRiderAccepted,
    bool? isRated,
    int? buyerDriverRating,
    int? buyerDeliveryRating,
    String? buyerCourierComment,
    List<String>? buyerCourierTags,
  }) {
    return OrderItemModel(
      orderId: orderId ?? this.orderId,
      dateText: dateText ?? this.dateText,
      orderDateTimeText: orderDateTimeText ?? this.orderDateTimeText,
      statusText: statusText ?? this.statusText,
      statusColor: statusColor ?? this.statusColor,
      etaText: etaText ?? this.etaText,
      etaTime: etaTime ?? this.etaTime,
      progress: progress ?? this.progress,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingOption: shippingOption ?? this.shippingOption,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      courierName: courierName ?? this.courierName,
      courierRating: courierRating ?? this.courierRating,
      courierAvatarUrl: courierAvatarUrl ?? this.courierAvatarUrl,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      isRiderAccepted: isRiderAccepted ?? this.isRiderAccepted,
      isRated: isRated ?? this.isRated,
      buyerDriverRating: buyerDriverRating ?? this.buyerDriverRating,
      buyerDeliveryRating: buyerDeliveryRating ?? this.buyerDeliveryRating,
      buyerCourierComment: buyerCourierComment ?? this.buyerCourierComment,
      buyerCourierTags: buyerCourierTags ?? this.buyerCourierTags,
    );
  }

  factory OrderItemModel.fromApiJson(Map<String, dynamic> json) {
    final status = (json['status'] as String? ?? 'pending').toLowerCase();
    String statusText;
    Color statusColor;
    double progress;
    String etaText;
    String etaTime;

    switch (status) {
      case 'processing':
        statusText = 'Processing';
        statusColor = const Color(0xFF3B82F6);
        progress = 0.3;
        etaText = 'Seller is preparing your order';
        etaTime = 'Estimated: 2-3 days';
        break;
      case 'shipped':
        statusText = 'In Transit';
        statusColor = const Color(0xFF8B5CF6);
        progress = 0.6;
        etaText = 'Package in transit with courier';
        etaTime = 'Estimated: 1-2 days';
        break;
      case 'out_for_delivery':
        statusText = 'Out for Delivery';
        statusColor = const Color(0xFF0066FF);
        progress = 0.8;
        etaText = 'Courier is on the way';
        etaTime = 'Expected today';
        break;
      case 'delivered':
      case 'completed':
        statusText = 'Completed';
        statusColor = const Color(0xFF10B981);
        progress = 1.0;
        etaText = 'Delivered successfully';
        etaTime = 'Package received by recipient';
        break;
      case 'cancelled':
        statusText = 'Cancelled';
        statusColor = const Color(0xFFEF4444);
        progress = 0.0;
        etaText = 'Order cancelled';
        etaTime = '-';
        break;
      case 'returned':
        statusText = 'Return / Refund';
        statusColor = const Color(0xFFF97316);
        progress = 0.0;
        etaText = 'Return / refund requested';
        etaTime = '-';
        break;
      case 'pending':
      default:
        statusText = 'Pending Payment';
        statusColor = const Color(0xFFF59E0B);
        progress = 0.1;
        etaText = 'Awaiting payment / confirmation';
        etaTime = 'Estimated: 3-5 days';
        break;
    }

    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems.map((item) {
      if (item is Map<String, dynamic>) {
        return CartItemModel(
          id: item['id']?.toString() ?? '1',
          storeName: json['seller']?['store_name'] ?? 'Nexora Store',
          title: item['title'] ?? item['product_name'] ?? 'Product',
          variant: 'Standard',
          imageUrl: item['image_url'] ?? 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=300&q=80',
          price: (item['unit_price'] as num?)?.toDouble() ?? 0.0,
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        );
      }
      return CartItemModel(
        id: '1',
        storeName: 'Nexora Store',
        title: 'Product',
        variant: 'Standard',
        imageUrl: '',
        price: 0.0,
      );
    }).toList();

    final shippingAddr = json['shipping_address'];
    String recipientName = 'Customer';
    String recipientPhone = '';
    String addressStr = '';
    if (shippingAddr is Map<String, dynamic>) {
      recipientName = shippingAddr['recipient_name'] ?? '';
      recipientPhone = shippingAddr['phone'] ?? '';
      addressStr = shippingAddr['full_address'] ?? shippingAddr['street'] ?? '';
    } else if (shippingAddr is String) {
      addressStr = shippingAddr;
    }

    final shipment = json['shipment'] as Map<String, dynamic>?;
    final rider = shipment?['rider'] as Map<String, dynamic>?;
    final courierName = rider?['name'] as String? ?? 'Nexora Express';

    return OrderItemModel(
      orderId: json['order_number'] as String? ?? '#${json['id']}',
      dateText: json['created_at'] != null
          ? json['created_at'].toString().split('T').first
          : 'Today',
      statusText: statusText,
      statusColor: statusColor,
      etaText: etaText,
      etaTime: etaTime,
      progress: progress,
      items: itemsList,
      totalPrice: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (json['payment_method'] as String? ?? 'COD').toUpperCase(),
      courierName: courierName,
      courierRating: 4.9,
      courierAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      recipientName: recipientName.isNotEmpty ? recipientName : null,
      recipientPhone: recipientPhone.isNotEmpty ? recipientPhone : null,
      shippingAddress: addressStr.isNotEmpty ? addressStr : null,
      isRiderAccepted: shipment != null && shipment['status'] != 'pending',
    );
  }
}

class OrderService extends ChangeNotifier {
  static final OrderService instance = OrderService._internal();
  StreamSubscription? _orderStreamSub;
  Timer? _pollingTimer;
  RealtimeChannel? _dispatchChannel;
  RealtimeChannel? _courierDispatchChannel;
  RealtimeChannel? _riderGpsDispatchChannel;
  bool? _isDispatchSubscribed;
  bool? _isCourierDispatchSubscribed;

  OrderService._internal() {
    _initInitialOrders();
    _initSupabaseRealtimeSync();
    _startPeriodicOrderSync();
    BuyerAccountService.instance.addListener(_onBuyerAccountChanged);
  }

  /// Explicit initialization hook callable from main.dart after Supabase.initialize
  void ensureInitialized() {
    _initSupabaseRealtimeSync();
    _startPeriodicOrderSync();
    fetchOrdersRemote();
  }

  void _startPeriodicOrderSync() {
    _pollingTimer?.cancel();
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    // Periodic fallback poll (throttled to 15s to keep egress minimal while realtime streams handle instant updates)
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchOrdersRemote();
    });
  }

  void cancelPeriodicTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _onBuyerAccountChanged() {
    _pruneForeignOrdersForCurrentUser();
    fetchOrdersRemote();
    notifyListeners();
  }

  /// Fetch orders from Laravel backend API
  Future<void> fetchOrdersRemote([String tab = 'all']) async {
    if (!ApiClient.instance.hasToken) return;
    try {
      final res = await ApiClient.instance.get(
        tab == 'all'
            ? ApiConstants.buyerOrders
            : '${ApiConstants.buyerOrders}?tab=$tab',
      );
      final data = res['data'];
      final List list = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] : []);
      final parsed = list
          .map(
            (item) => OrderItemModel.fromApiJson(item as Map<String, dynamic>),
          )
          .toList();

      final userActive = _userActiveOrders.putIfAbsent(
        _currentUserKey,
        () => [],
      );
      final userPast = _userPastOrders.putIfAbsent(_currentUserKey, () => []);

      userActive.clear();
      userPast.clear();

      for (final o in parsed) {
        if (o.statusText == 'Completed' ||
            o.statusText == 'Cancelled' ||
            o.statusText == 'Return / Refund') {
          userPast.add(o);
        } else {
          userActive.add(o);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('fetchOrdersRemote error: $e');
    }
  }

  /// Cancel order via Laravel backend API
  Future<bool> cancelOrderRemote(
    String orderId, [
    String reason = 'Changed my mind',
  ]) async {
    final cleanId = orderId.replaceAll('#', '').replaceAll('ORD-', '').trim();
    cancelOrder(orderId);
    if (!ApiClient.instance.hasToken) return true;
    try {
      await ApiClient.instance.post(
        ApiConstants.buyerOrderCancel(cleanId),
        body: {'reason': reason},
      );
      await fetchOrdersRemote();
      return true;
    } catch (e) {
      debugPrint('cancelOrderRemote error: $e');
      return false;
    }
  }

  /// Confirm delivery receipt via Laravel backend API
  Future<bool> confirmReceiptRemote(String orderId) async {
    final cleanId = orderId.replaceAll('#', '').replaceAll('ORD-', '').trim();
    if (!ApiClient.instance.hasToken) return true;
    try {
      await ApiClient.instance.post(
        ApiConstants.buyerOrderConfirmReceipt(cleanId),
      );
      await fetchOrdersRemote();
      return true;
    } catch (e) {
      debugPrint('confirmReceiptRemote error: $e');
      return false;
    }
  }

  /// Submit return/refund via Laravel backend API
  Future<bool> submitReturnRemote(
    String orderId, {
    required String reason,
    String? notes,
  }) async {
    final cleanId = orderId.replaceAll('#', '').replaceAll('ORD-', '').trim();
    if (!ApiClient.instance.hasToken) return true;
    try {
      await ApiClient.instance.post(
        ApiConstants.buyerOrderReturn(cleanId),
        body: {
          'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      await fetchOrdersRemote();
      return true;
    } catch (e) {
      debugPrint('submitReturnRemote error: $e');
      return false;
    }
  }

  /// Submit product review via Laravel backend API
  Future<bool> submitReviewRemote(
    String orderId, {
    required int rating,
    String? comment,
  }) async {
    final cleanId = orderId.replaceAll('#', '').replaceAll('ORD-', '').trim();
    if (!ApiClient.instance.hasToken) return true;
    try {
      await ApiClient.instance.post(
        ApiConstants.buyerOrderReview(cleanId),
        body: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      await fetchOrdersRemote();
      return true;
    } catch (e) {
      debugPrint('submitReviewRemote error: $e');
      return false;
    }
  }

  void _pruneForeignOrdersForCurrentUser() {
    final key = _currentUserKey;
    if (key == 'guest') {
      _userActiveOrders.remove('guest');
      _userPastOrders.remove('guest');
      return;
    }
    final active = _userActiveOrders[key];
    if (active != null) {
      active.removeWhere(
        (o) => o.buyerEmail != 'guest' && o.buyerEmail.toLowerCase() != key,
      );
    }
    final past = _userPastOrders[key];
    if (past != null) {
      past.removeWhere(
        (o) => o.buyerEmail != 'guest' && o.buyerEmail.toLowerCase() != key,
      );
    }
  }

  int _orderCounter = 10000 + (DateTime.now().millisecondsSinceEpoch % 89999);

  // User-scoped orders: Maps keyed by buyer email (or 'guest')
  final Map<String, List<OrderItemModel>> _userActiveOrders = {};
  final Map<String, List<OrderItemModel>> _userPastOrders = {};
  final Set<String> _locallyCancelledOrders = {};

  // Live Rider phone GPS cache keyed by normalized orderId (lazy-initialized for hot-reload safety)
  Map<String, Map<String, double>>? _liveRiderLocationsMap;
  Map<String, Map<String, double>> get _liveRiderLocations =>
      _liveRiderLocationsMap ??= {};

  Map<String, double>? getLiveRiderLocation(String orderId) {
    final clean = orderId.replaceAll('#', '').trim().toLowerCase();
    return _liveRiderLocations[clean];
  }

  void updateLiveRiderLocation(Map<String, dynamic> payload) {
    final rawId = (payload['order_id'] ?? payload['id'] ?? '')
        .toString()
        .replaceAll('#', '')
        .trim()
        .toLowerCase();
    final lat =
        (payload['rider_lat'] as num?)?.toDouble() ??
        double.tryParse(payload['rider_lat']?.toString() ?? '');
    final lng =
        (payload['rider_lng'] as num?)?.toDouble() ??
        double.tryParse(payload['rider_lng']?.toString() ?? '');
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) return;

    final speed =
        (payload['rider_speed'] as num?)?.toDouble() ??
        double.tryParse(payload['rider_speed']?.toString() ?? '') ??
        0.0;
    final heading =
        (payload['rider_heading'] as num?)?.toDouble() ??
        double.tryParse(payload['rider_heading']?.toString() ?? '') ??
        0.0;
    final accuracy =
        (payload['rider_accuracy'] as num?)?.toDouble() ??
        double.tryParse(payload['rider_accuracy']?.toString() ?? '') ??
        5.0;

    final locMap = <String, double>{
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
    };
    if (rawId.isNotEmpty) {
      _liveRiderLocations[rawId] = locMap;
    }
    _liveRiderLocations['latest'] = locMap;
    notifyListeners();
  }

  void requestRiderLocation(String orderId) {
    if (!isSupabaseReady) return;
    if (_dispatchChannel == null) {
      _initSupabaseRealtimeSync();
    }
    final clean = orderId.replaceAll('#', '').trim();
    if (_dispatchChannel != null && _isDispatchSubscribed == true) {
      _dispatchChannel!.sendBroadcastMessage(
        event: 'request_rider_location',
        payload: {'order_id': clean},
      );
    }
  }

  // Live rider rating registry so buyer ratings immediately reflect on the rider's rating (lazy-initialized for hot-reload safety)
  Map<String, double>? _liveCourierRatingsMap;
  Map<String, double> get _liveCourierRatings => _liveCourierRatingsMap ??= {
    'Pedro Jose Garcia': 4.96,
    'Juan Carlos Ramos': 4.88,
    'Michael Bryan Santos': 4.92,
    'Christian Jay Alcantara': 4.85,
  };

  double getLiveCourierRating(String courierName, {double fallback = 4.96}) {
    try {
      final clean = courierName.trim();
      if (clean.isEmpty) return fallback;
      for (final entry in _liveCourierRatings.entries) {
        if (entry.key.toLowerCase() == clean.toLowerCase()) {
          return entry.value;
        }
      }
    } catch (_) {}
    return fallback;
  }

  OrderItemModel? findOrderById(String orderId) {
    final clean = orderId.replaceAll('#', '').trim().toLowerCase();
    for (final o in activeOrders) {
      if (o.orderId.replaceAll('#', '').trim().toLowerCase() == clean) return o;
    }
    for (final o in pastOrders) {
      if (o.orderId.replaceAll('#', '').trim().toLowerCase() == clean) return o;
    }
    return null;
  }

  String get _currentUserKey {
    final buyer = BuyerAccountService.instance.currentBuyer;
    if (buyer != null && buyer.email.isNotEmpty) {
      return buyer.email.toLowerCase().trim();
    }
    return 'guest';
  }

  List<OrderItemModel> get _currentActiveList =>
      _userActiveOrders.putIfAbsent(_currentUserKey, () => []);

  List<OrderItemModel> get _currentPastList =>
      _userPastOrders.putIfAbsent(_currentUserKey, () => []);

  void _initInitialOrders() {
    _userActiveOrders.clear();
    _userPastOrders.clear();
  }

  bool get isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static String normalizeRemoteStatus(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'atmerchant') return 'at_store';
    if (s == 'pickedup') return 'picked_up';
    if (s == 'atcustomer') return 'in_transit';
    return s;
  }

  bool syncOrderFromRemoteStatus(
    String orderId,
    String rawStatus, {
    String? courierName,
    double? courierRating,
    bool? riderAccepted,
    Map<String, dynamic>? rowData,
  }) {
    final cleanId = orderId.replaceAll('#', '').trim().toLowerCase();
    final status = normalizeRemoteStatus(rawStatus);
    if (cleanId.isEmpty || status.isEmpty) return false;

    // If order was cancelled by user, never let stale status revert it
    if (_locallyCancelledOrders.contains(cleanId)) {
      if (status != 'cancelled') return false;
    }

    if (courierName != null &&
        courierName.trim().isNotEmpty &&
        courierRating != null) {
      _liveCourierRatings[courierName.trim()] = courierRating;
    }

    bool anyUpdated = false;
    final allKeys = <String>{
      _currentUserKey,
      ..._userActiveOrders.keys,
      ..._userPastOrders.keys,
    };

    for (final key in allKeys) {
      final userActive = _userActiveOrders.putIfAbsent(key, () => []);
      final userPast = _userPastOrders.putIfAbsent(key, () => []);

      final activeIdx = userActive.indexWhere(
        (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == cleanId,
      );
      final pastIdx = userPast.indexWhere(
        (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == cleanId,
      );

      if (activeIdx == -1 && pastIdx == -1) continue;

      if (status == 'delivered' || status == 'completed') {
        if (activeIdx != -1) {
          final current = userActive.removeAt(activeIdx);
          final updatedCourier =
              (courierName != null && courierName.trim().isNotEmpty)
              ? courierName.trim()
              : current.courierName;
          final updatedRating =
              courierRating ??
              getLiveCourierRating(
                updatedCourier,
                fallback: current.courierRating,
              );
          userPast.insert(
            0,
            current.copyWith(
              statusText: 'Completed',
              statusColor: const Color(0xFF10B981),
              etaText: 'Delivered successfully',
              etaTime: 'Package received by recipient',
              progress: 1.0,
              courierName: updatedCourier,
              courierRating: updatedRating,
              isRiderAccepted: true,
            ),
          );
          anyUpdated = true;
        } else if (pastIdx != -1) {
          final current = userPast[pastIdx];
          if (current.statusText != 'Completed' || current.progress < 1.0) {
            userPast[pastIdx] = current.copyWith(
              statusText: 'Completed',
              statusColor: const Color(0xFF10B981),
              etaText: 'Delivered successfully',
              etaTime: 'Package received by recipient',
              progress: 1.0,
              isRiderAccepted: true,
            );
            anyUpdated = true;
          }
        }
      } else if (status == 'picked_up' ||
          status == 'in_transit' ||
          status == 'to_deliver' ||
          status == 'out_for_delivery' ||
          status == 'shipping' ||
          status == 'shipped') {
        if (activeIdx != -1) {
          final current = userActive[activeIdx];
          final updatedCourier =
              (courierName != null && courierName.trim().isNotEmpty)
              ? courierName.trim()
              : current.courierName;
          final updatedRating =
              courierRating ??
              getLiveCourierRating(
                updatedCourier,
                fallback: current.courierRating,
              );
          final etaDesc = status == 'picked_up'
              ? 'Courier scanned & picked up your parcel — heading to you'
              : 'Parcel is out for delivery with $updatedCourier';
          if (current.statusText != 'To Receive' ||
              current.etaText != etaDesc ||
              !current.isRiderAccepted ||
              current.progress != 0.75 ||
              current.courierName != updatedCourier) {
            userActive[activeIdx] = current.copyWith(
              statusText: 'To Receive',
              statusColor: const Color(0xFF00B4D8),
              etaText: etaDesc,
              etaTime: 'Rider is on the road',
              progress: 0.75,
              courierName: updatedCourier,
              courierRating: updatedRating,
              isRiderAccepted: true,
            );
            anyUpdated = true;
          }
        }
      } else if (status == 'accepted' || status == 'at_store') {
        if (activeIdx != -1) {
          final current = userActive[activeIdx];
          final updatedCourier =
              (courierName != null && courierName.trim().isNotEmpty)
              ? courierName.trim()
              : current.courierName;
          final updatedRating =
              courierRating ??
              getLiveCourierRating(
                updatedCourier,
                fallback: current.courierRating,
              );
          final etaDesc = status == 'at_store'
              ? 'Courier arrived at merchant store — verifying & scanning parcel'
              : 'Rider $updatedCourier accepted your order — heading to store';
          final nextProgress = status == 'at_store' ? 0.55 : 0.45;
          if (current.statusText != 'To Ship' ||
              current.etaText != etaDesc ||
              !current.isRiderAccepted ||
              current.progress != nextProgress ||
              current.courierName != updatedCourier) {
            userActive[activeIdx] = current.copyWith(
              statusText: 'To Ship',
              statusColor: const Color(0xFF008060),
              etaText: etaDesc,
              etaTime: status == 'at_store'
                  ? 'Being handed over to courier'
                  : 'Rider Accepted • En route to pickup',
              progress: nextProgress,
              courierName: updatedCourier,
              courierRating: updatedRating,
              isRiderAccepted: true,
            );
            anyUpdated = true;
          }
        }
      } else if (status == 'ready' ||
          status == 'preparing' ||
          status == 'processing') {
        if (activeIdx != -1) {
          final current = userActive[activeIdx];
          const prepDesc = 'Merchant is packing your parcel for courier pickup';
          if (current.statusText != 'To Ship' || current.progress < 0.45) {
            userActive[activeIdx] = current.copyWith(
              statusText: 'To Ship',
              statusColor: const Color(0xFF008060),
              etaText: prepDesc,
              progress: 0.45,
            );
            anyUpdated = true;
          }
        }
      } else if (status == 'pending') {
        // If order was cancelled locally or remotely, do not revert to pending!
        if (pastIdx != -1 &&
            userPast[pastIdx].statusText.toLowerCase() == 'cancelled') {
          continue;
        }
        if (activeIdx != -1) {
          final current = userActive[activeIdx];
          if (current.statusText.toLowerCase() == 'cancelled') {
            continue;
          }
          if (current.statusText != 'To Ship' &&
              current.statusText != 'To Pay') {
            userActive[activeIdx] = current.copyWith(
              statusText: 'To Ship',
              statusColor: const Color(0xFF008060),
              etaText: 'Order Placed • Merchant is preparing your parcel',
              progress: 0.25,
              isRiderAccepted: false,
            );
            anyUpdated = true;
          }
        }
      } else if (status == 'cancelled' || status == 'failed_delivery') {
        if (activeIdx != -1) {
          final current = userActive.removeAt(activeIdx);
          userPast.insert(
            0,
            current.copyWith(
              statusText: 'Cancelled',
              statusColor: const Color(0xFFEF4444),
              etaText: 'Order Cancelled',
              etaTime: 'Delivery cancelled',
              progress: 0.0,
            ),
          );
          anyUpdated = true;
        } else if (pastIdx != -1) {
          final current = userPast[pastIdx];
          if (current.statusText != 'Cancelled') {
            userPast[pastIdx] = current.copyWith(
              statusText: 'Cancelled',
              statusColor: const Color(0xFFEF4444),
              etaText: 'Order Cancelled',
              etaTime: 'Delivery cancelled',
              progress: 0.0,
            );
            anyUpdated = true;
          }
        }
      }
    }

    if (anyUpdated) {
      notifyListeners();
    }
    return anyUpdated;
  }

  Future<void> refreshOrdersFromSupabase() async {
    if (!isSupabaseReady) return;
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select(
            'id, order_id, customer_id, buyer_email, buyer_name, item_details, delivery_address, delivery_lat, delivery_lng, status, created_at, courier_name, courier_rating, is_rider_accepted, total_price, subtotal, shipping_fee, payment_method',
          )
          .order('created_at', ascending: false)
          .limit(20);
      _processSupabaseOrderRows(List<Map<String, dynamic>>.from(rows));
    } catch (_) {}
  }

  void _processSupabaseOrderRows(List<Map<String, dynamic>> rows) {
    bool hasChanges = false;
    final currentKey = _currentUserKey;
    final currentBuyer = BuyerAccountService.instance.currentBuyer;

    for (final row in rows) {
      final rawId = (row['order_id'] ?? row['id'] ?? '')
          .toString()
          .replaceAll('#', '')
          .trim()
          .toLowerCase();
      if (rawId.isEmpty) continue;
      if (_locallyCancelledOrders.contains(rawId)) {
        // If order was cancelled locally, do not resurrect as active
        continue;
      }

      final status = normalizeRemoteStatus((row['status'] ?? '').toString());
      final userActive = _currentActiveList;
      final userPast = _currentPastList;

      final activeIdx = userActive.indexWhere(
        (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == rawId,
      );
      final pastIdx = userPast.indexWhere(
        (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == rawId,
      );

      // If this order already exists locally on this device, always sync its status!
      if (activeIdx != -1 || pastIdx != -1) {
        final updated = syncOrderFromRemoteStatus(rawId, status, rowData: row);
        if (updated) hasChanges = true;
        continue;
      }

      if (currentKey == 'guest') continue;

      final rowCustomerEmail =
          (row['buyer_email'] ?? row['customer_email'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
      final rowCustomerId = (row['customer_id'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      final rowBuyerId = (row['buyer_id'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      // Only match orders strictly associated with the active buyer's email or account id
      final isForCurrentUser =
          (rowCustomerEmail.isNotEmpty && rowCustomerEmail == currentKey) ||
          (rowCustomerId.isNotEmpty &&
              (rowCustomerId == currentKey ||
                  (currentBuyer != null &&
                      rowCustomerId == currentBuyer.id.toLowerCase()))) ||
          (rowBuyerId.isNotEmpty &&
              currentBuyer != null &&
              rowBuyerId == currentBuyer.id.toLowerCase());

      if (!isForCurrentUser) continue;

      if (status == 'delivered' || status == 'completed') {
        final newPast = _buildOrderFromRow(
          row,
          'Completed',
          1.0,
          const Color(0xFF10B981),
        );
        userPast.insert(0, newPast.copyWith(isRiderAccepted: true));
        hasChanges = true;
      } else if (status == 'to_deliver' ||
          status == 'in_transit' ||
          status == 'out_for_delivery' ||
          status == 'picked_up' ||
          status == 'shipping' ||
          status == 'shipped') {
        final newActive = _buildOrderFromRow(
          row,
          'To Receive',
          0.75,
          const Color(0xFF00B4D8),
        );
        userActive.insert(0, newActive.copyWith(isRiderAccepted: true));
        hasChanges = true;
      } else if (status == 'accepted' || status == 'at_store') {
        final newActive = _buildOrderFromRow(
          row,
          'To Ship',
          status == 'at_store' ? 0.55 : 0.45,
          const Color(0xFF008060),
        );
        userActive.insert(0, newActive.copyWith(isRiderAccepted: true));
        hasChanges = true;
      } else if (status == 'pending' ||
          status == 'ready' ||
          status == 'preparing' ||
          status == 'processing') {
        final newActive = _buildOrderFromRow(
          row,
          'To Ship',
          0.25,
          const Color(0xFF008060),
        );
        userActive.insert(0, newActive);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  void _initSupabaseRealtimeSync() {
    if (!isSupabaseReady) return;
    try {
      _orderStreamSub?.cancel();
      _orderStreamSub = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .listen(
            (rows) {
              _processSupabaseOrderRows(rows);
            },
            onError: (err, stack) {
              debugPrint(
                '📡 OrderService Supabase stream sync notice (offline/reconnecting): $err',
              );
            },
            cancelOnError: false,
          );

      if (_dispatchChannel != null) {
        Supabase.instance.client.removeChannel(_dispatchChannel!);
      }
      _isDispatchSubscribed = false;
      _dispatchChannel = Supabase.instance.client.channel('orders_dispatch');
      _dispatchChannel!
          .onBroadcast(
            event: 'status_updated',
            callback: (payload) => _handleBroadcastStatusUpdate(payload),
          )
          .onBroadcast(
            event: 'order_status_updated',
            callback: (payload) => _handleBroadcastStatusUpdate(payload),
          )
          .onBroadcast(
            event: 'order_accepted',
            callback: (payload) => _handleBroadcastStatusUpdate({
              ...payload,
              'status': payload['status'] ?? 'accepted',
              'rider_accepted': true,
            }),
          )
          .onBroadcast(
            event: 'location_update',
            callback: (payload) => updateLiveRiderLocation(payload),
          )
          .onBroadcast(
            event: 'rider_rating_updated',
            callback: (payload) {
              final courierName =
                  (payload['courier_name'] ?? payload['rider_name'] ?? '')
                      .toString()
                      .trim();
              final newRating =
                  (payload['new_courier_rating'] as num?)?.toDouble() ??
                  double.tryParse(
                    payload['new_courier_rating']?.toString() ?? '',
                  );
              if (courierName.isNotEmpty && newRating != null) {
                _updateCourierRatingInMemory(courierName, newRating);
              }
            },
          )
          .subscribe((status, [err]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              _isDispatchSubscribed = true;
            }
          });

      if (_courierDispatchChannel != null) {
        Supabase.instance.client.removeChannel(_courierDispatchChannel!);
      }
      _isCourierDispatchSubscribed = false;
      _courierDispatchChannel = Supabase.instance.client.channel(
        'orders_dispatch_courier',
      );
      _courierDispatchChannel!.subscribe((status, [err]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _isCourierDispatchSubscribed = true;
        }
      });

      if (_riderGpsDispatchChannel != null) {
        Supabase.instance.client.removeChannel(_riderGpsDispatchChannel!);
      }
      _riderGpsDispatchChannel = Supabase.instance.client.channel(
        'rider_gps_dispatch',
      );
      _riderGpsDispatchChannel!
          .onBroadcast(
            event: 'location_update',
            callback: (payload) => updateLiveRiderLocation(payload),
          )
          .subscribe();
    } catch (e) {
      debugPrint('⚠️ OrderService Supabase realtime notice: $e');
    }
  }

  void _updateCourierRatingInMemory(String courierName, double newRating) {
    _liveCourierRatings[courierName] = newRating;
    for (final list in _userActiveOrders.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].courierName.toLowerCase() == courierName.toLowerCase()) {
          list[i] = list[i].copyWith(courierRating: newRating);
        }
      }
    }
    for (final list in _userPastOrders.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].courierName.toLowerCase() == courierName.toLowerCase()) {
          list[i] = list[i].copyWith(courierRating: newRating);
        }
      }
    }
    notifyListeners();
  }

  void _handleBroadcastStatusUpdate(Map<String, dynamic> payload) {
    updateLiveRiderLocation(payload);
    final rawId = (payload['order_id'] ?? payload['id'] ?? '')
        .toString()
        .replaceAll('#', '')
        .trim()
        .toLowerCase();
    final status = (payload['status'] ?? '').toString().toLowerCase().trim();
    final courierName = (payload['courier_name'] ?? payload['rider_name'] ?? '')
        .toString()
        .trim();
    final courierRatingPayload =
        (payload['courier_rating'] as num?)?.toDouble() ??
        double.tryParse(payload['courier_rating']?.toString() ?? '');
    if (rawId.isEmpty || status.isEmpty) return;

    syncOrderFromRemoteStatus(
      rawId,
      status,
      courierName: courierName.isNotEmpty ? courierName : null,
      courierRating: courierRatingPayload,
      riderAccepted: payload['rider_accepted'] == true,
    );
  }

  /// Extracts clean item title if stored as JSON with chat history
  static String extractItemTitle(dynamic raw) {
    if (raw == null) return 'Assorted Items';
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

  OrderItemModel _buildOrderFromRow(
    Map<String, dynamic> row,
    String statusText,
    double progress,
    Color statusColor,
  ) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final orderId =
        '#${(row['order_id'] ?? row['id'] ?? 'NX-00000').toString().replaceAll('#', '')}';
    final details = extractItemTitle(row['item_details']);
    final address = (row['delivery_address'] ?? '192 Tuy-Baanan, Liliw, Laguna')
        .toString();

    return OrderItemModel(
      orderId: orderId,
      dateText: 'Today, $timeStr',
      statusText: statusText,
      statusColor: statusColor,
      etaText: statusText == 'Completed'
          ? 'Delivered successfully'
          : (statusText == 'To Receive'
                ? 'Parcel is out for delivery'
                : 'Order Placed • Merchant is preparing your parcel'),
      etaTime: 'Expected delivery: 8 - 9 Oct',
      progress: progress,
      items: [
        CartItemModel(
          id: 'item_${row['id'] ?? DateTime.now().millisecondsSinceEpoch}',
          title: details,
          variant: 'Standard Edition',
          price: 311.0,
          quantity: 1,
          storeName: 'Nexora Official Flagship',
          storeBadge: 'MALL',
          imageUrl: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?auto=format&fit=crop&w=300&q=80',
        ),
      ],
      totalPrice: 311.0,
      paymentMethod: 'Cash on Delivery',
      shippingAddress: address,
      courierName: 'Pedro Jose Garcia',
      courierRating: 4.96,
      courierAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
      buyerEmail: _currentUserKey,
    );
  }

  List<OrderItemModel> get activeOrders =>
      List.unmodifiable(_userActiveOrders[_currentUserKey] ?? const []);

  List<OrderItemModel> get pastOrders =>
      List.unmodifiable(_userPastOrders[_currentUserKey] ?? const []);

  OrderItemModel? get latestActiveOrder {
    final list = _userActiveOrders[_currentUserKey];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  int get totalOrderCount => activeOrders.length + pastOrders.length;

  void updateOrderStatus(String orderId, String newStatusText) {
    final clean = orderId.replaceAll('#', '').trim();
    final userActive = _currentActiveList;
    final idx = userActive.indexWhere(
      (o) => o.orderId.replaceAll('#', '').trim() == clean,
    );
    if (idx != -1) {
      final current = userActive[idx];
      final isDelivered =
          newStatusText.toLowerCase().contains('delivered') ||
          newStatusText.toLowerCase().contains('completed');
      final isOutForDelivery =
          newStatusText.toLowerCase().contains('receive') ||
          newStatusText.toLowerCase().contains('transit') ||
          newStatusText.toLowerCase().contains('out');

      final updated = current.copyWith(
        statusText: newStatusText,
        progress: isDelivered ? 1.0 : (isOutForDelivery ? 0.75 : 0.4),
        statusColor: isDelivered
            ? const Color(0xFF10B981)
            : (isOutForDelivery
                  ? const Color(0xFF00C1D4)
                  : const Color(0xFF3B82F6)),
      );
      userActive[idx] = updated;
      notifyListeners();
    }
  }

  void placeOrder({
    required List<CartItemModel> items,
    required double totalPrice,
    required String paymentMethod,
    String? recipientName,
    String? recipientPhone,
    String? shippingAddress,
    String? shippingOption,
    double? shippingFee,
    double? subtotal,
    double? discount,
    String? estimatedArrival,
    double? deliveryLat,
    double? deliveryLng,
  }) {
    final rawItems = items.isEmpty
        ? [
            CartItemModel(
              id: 'item_${DateTime.now().millisecondsSinceEpoch}',
              storeName: 'Nexora Official Flagship',
              storeBadge: 'MALL',
              title: 'Nexora Aura 75 Mechanical Keyboard',
              variant: 'Chalk White / Violet • Linear',
              imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=300&q=80',
              price: totalPrice > 0 ? totalPrice : 3200.0,
            ),
          ]
        : items;

    final isUnpaid =
        paymentMethod.toLowerCase().contains('pending') ||
        paymentMethod.toLowerCase().contains('transfer') ||
        paymentMethod.toLowerCase().contains('card') ||
        paymentMethod.toLowerCase().contains('later');

    // Group items by storeName so each seller receives a distinct package
    final Map<String, List<CartItemModel>> storeGroups = {};
    for (final item in rawItems) {
      final key = item.storeName.trim().isNotEmpty
          ? item.storeName.trim()
          : 'Nexora Official Flagship';
      storeGroups.putIfAbsent(key, () => []).add(item);
    }

    final overallSum = rawItems.fold<double>(
      0.0,
      (sum, i) => sum + (i.price * i.quantity),
    );

    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[now.month - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final formattedDateTime = '${now.day} $month ${now.year}, $hour:$minute';

    final effectiveRecipientName =
        recipientName ?? ProfileService.instance.name;
    final effectiveRecipientPhone =
        recipientPhone ?? ProfileService.instance.phone;
    final effectiveShippingAddress =
        shippingAddress ?? ProfileService.instance.address;

    for (final entry in storeGroups.entries) {
      final storeName = entry.key;
      final groupItems = entry.value
          .map(
            (i) => CartItemModel(
              id: i.id,
              storeName: storeName,
              storeBadge: i.storeBadge.isNotEmpty ? i.storeBadge : 'MALL',
              title: i.title,
              variant: i.variant.contains('Qty:')
                  ? i.variant
                  : '${i.variant} • Qty: ${i.quantity}',
              imageUrl: i.imageUrl,
              price: i.price,
              originalPrice: i.originalPrice,
              quantity: i.quantity,
            ),
          )
          .toList();

      _orderCounter++;
      final groupSubtotal = groupItems.fold<double>(
        0.0,
        (sum, i) => sum + (i.price * i.quantity),
      );
      final groupTotalPrice = overallSum > 0 && totalPrice > 0
          ? (groupSubtotal / overallSum) * totalPrice
          : (groupSubtotal > 0 ? groupSubtotal : totalPrice);

      final newOrder = OrderItemModel(
        orderId: '#NX-$_orderCounter',
        dateText: 'Today',
        orderDateTimeText: formattedDateTime,
        statusText: isUnpaid ? 'To Pay' : 'To Ship',
        statusColor: isUnpaid
            ? const Color(0xFFF59E0B)
            : const Color(0xFF3B82F6),
        etaText: isUnpaid
            ? 'Payment Pending'
            : 'Order Placed • Merchant is preparing your parcel',
        etaTime: isUnpaid
            ? 'Awaiting Payment'
            : (estimatedArrival != null
                  ? 'Expected delivery: $estimatedArrival'
                  : 'Expected delivery: Today'),
        progress: isUnpaid ? 0.1 : 0.25,
        items: groupItems,
        totalPrice: groupTotalPrice,
        subtotal: groupSubtotal,
        shippingFee:
            (shippingFee ?? 0.0) /
            (storeGroups.isNotEmpty ? storeGroups.length : 1),
        discount:
            (discount ?? 0.0) /
            (storeGroups.isNotEmpty ? storeGroups.length : 1),
        paymentMethod: paymentMethod,
        shippingOption: shippingOption ?? 'Standard Local Delivery',
        recipientName: effectiveRecipientName,
        recipientPhone: effectiveRecipientPhone,
        shippingAddress: effectiveShippingAddress,
        courierName: 'Pedro Jose Garcia',
        courierRating: getLiveCourierRating('Pedro Jose Garcia'),
        courierAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
        buyerEmail: _currentUserKey,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        isRiderAccepted: false,
      );

      _currentActiveList.insert(0, newOrder);

      // Insert into Supabase orders table & broadcast over persistent channels so Rider App receives it immediately
      if (isSupabaseReady) {
        final cleanId = newOrder.orderId.replaceAll('#', '');
        final itemsSummary = groupItems
            .map((e) => '${e.quantity}x ${e.title}')
            .join(', ');
        final customerNameStr = effectiveRecipientName.isNotEmpty
            ? effectiveRecipientName
            : 'Customer';
        final latVal = deliveryLat ?? 14.1407;
        final lngVal = deliveryLng ?? 121.4692;
        _syncNewOrderToSupabase(
          cleanId: cleanId,
          customerNameStr: customerNameStr,
          itemsSummary: itemsSummary,
          effectiveShippingAddress: effectiveShippingAddress,
          latVal: latVal,
          lngVal: lngVal,
          groupTotalPrice: groupTotalPrice,
        );
      }
    }

    notifyListeners();
  }

  Future<void> _syncNewOrderToSupabase({
    required String cleanId,
    required String customerNameStr,
    required String itemsSummary,
    required String effectiveShippingAddress,
    required double latVal,
    required double lngVal,
    required double groupTotalPrice,
  }) async {
    try {
      if (_dispatchChannel == null) {
        _initSupabaseRealtimeSync();
      }

      // 1. Broadcast over persistent Realtime channels (`orders_dispatch` & `orders_dispatch_courier`)
      final payload = {
        'order_id': cleanId,
        'customer_id': customerNameStr,
        'customer_email': _currentUserKey,
        'buyer_email': _currentUserKey,
        'item_details': itemsSummary,
        'delivery_address': effectiveShippingAddress,
        'delivery_lat': latVal,
        'delivery_lng': lngVal,
        'status': 'pending',
        'total': groupTotalPrice,
      };

      Future<void> sendOrderBroadcast() async {
        try {
          if (_dispatchChannel != null && _isDispatchSubscribed == true) {
            await _dispatchChannel!.sendBroadcastMessage(
              event: 'order_created',
              payload: payload,
            );
          }
          if (_courierDispatchChannel != null &&
              _isCourierDispatchSubscribed == true) {
            await _courierDispatchChannel!.sendBroadcastMessage(
              event: 'order_created',
              payload: payload,
            );
          }
        } catch (_) {}
      }

      await sendOrderBroadcast();
      Future.delayed(const Duration(milliseconds: 700), sendOrderBroadcast);

      // 2. Insert into Supabase `orders` table using valid schema columns only
      try {
        await Supabase.instance.client.from('orders').insert({
          'order_id': cleanId,
          'customer_id': customerNameStr,
          'buyer_name': customerNameStr,
          'buyer_email': _currentUserKey,
          'item_details': itemsSummary,
          'delivery_address': effectiveShippingAddress,
          'delivery_lat': latVal,
          'delivery_lng': lngVal,
          'status': 'pending',
        });
        debugPrint('✅ Order $cleanId inserted into Supabase orders table!');
      } catch (err) {
        try {
          await Supabase.instance.client.from('orders').insert({
            'customer_id': customerNameStr,
            'item_details': itemsSummary,
            'delivery_address': effectiveShippingAddress,
            'delivery_lat': latVal,
            'delivery_lng': lngVal,
            'status': 'pending',
          });
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ _syncNewOrderToSupabase notice: $e');
    }
  }

  /// Submits a buyer's delivery rider rating, updates the rider's overall rating,
  /// and broadcasts the rating in real-time to the Rider & Courier App.
  Future<double> submitRiderRating({
    required String orderId,
    required int driverRating,
    required int deliveryRating,
    required int productRating,
    required int sellerRating,
    String? courierComment,
    List<String>? courierTags,
    String? productReview,
    String? courierName,
  }) async {
    final cleanId = orderId.replaceAll('#', '').trim().toLowerCase();
    String resolvedCourierName = (courierName ?? '').trim();

    // Find the order to get its courierName if not explicitly passed
    for (final list in [
      ..._userPastOrders.values,
      ..._userActiveOrders.values,
    ]) {
      for (final o in list) {
        if (o.orderId.replaceAll('#', '').trim().toLowerCase() == cleanId) {
          if (resolvedCourierName.isEmpty) {
            resolvedCourierName = o.courierName;
          }
          break;
        }
      }
    }
    if (resolvedCourierName.isEmpty) {
      resolvedCourierName = 'Pedro Jose Garcia';
    }

    final currentRating = getLiveCourierRating(resolvedCourierName);
    // Weighted blend of Driver Service (70%) + Delivery Speed (30%) with 3 baseline reviews
    // so every buyer rating visibly and realistically updates the rider's rating!
    final double buyerRiderScore =
        (driverRating * 0.7) + (deliveryRating * 0.3);
    final double rawNewRating = ((currentRating * 3.0) + buyerRiderScore) / 4.0;
    final double newCourierRating = double.parse(
      rawNewRating.clamp(1.0, 5.0).toStringAsFixed(2),
    );

    _liveCourierRatings[resolvedCourierName] = newCourierRating;

    String customerName = ProfileService.instance.name.isNotEmpty
        ? ProfileService.instance.name
        : 'Verified Buyer';

    // Update the target order (and all orders assigned to this rider)
    void updateList(List<OrderItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        final isTarget =
            item.orderId.replaceAll('#', '').trim().toLowerCase() == cleanId;
        final isSameRider =
            item.courierName.toLowerCase() == resolvedCourierName.toLowerCase();
        if (isTarget) {
          if (item.recipientName.isNotEmpty) {
            customerName = item.recipientName;
          }
          list[i] = item.copyWith(
            courierName: resolvedCourierName,
            courierRating: newCourierRating,
            isRated: true,
            buyerDriverRating: driverRating,
            buyerDeliveryRating: deliveryRating,
            buyerCourierComment: courierComment,
            buyerCourierTags: courierTags,
          );
        } else if (isSameRider) {
          list[i] = item.copyWith(courierRating: newCourierRating);
        }
      }
    }

    for (final list in _userPastOrders.values) {
      updateList(list);
    }
    for (final list in _userActiveOrders.values) {
      updateList(list);
    }

    notifyListeners();

    // Broadcast to Rider & Courier App via Supabase Realtime
    if (isSupabaseReady) {
      final rawCleanId = orderId.replaceAll('#', '').trim();
      final ratingPayload = {
        'order_id': rawCleanId,
        'courier_name': resolvedCourierName,
        'driver_rating': driverRating,
        'delivery_rating': deliveryRating,
        'product_rating': productRating,
        'seller_rating': sellerRating,
        'combined_rating': double.parse(buyerRiderScore.toStringAsFixed(2)),
        'new_courier_rating': newCourierRating,
        'comment': courierComment ?? '',
        'tags': courierTags ?? <String>[],
        'customer_name': customerName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      try {
        if (_dispatchChannel == null) {
          _initSupabaseRealtimeSync();
        }
        if (_dispatchChannel != null && _isDispatchSubscribed == true) {
          await _dispatchChannel!.sendBroadcastMessage(
            event: 'rider_rated',
            payload: ratingPayload,
          );
        }
        if (_courierDispatchChannel != null &&
            _isCourierDispatchSubscribed == true) {
          await _courierDispatchChannel!.sendBroadcastMessage(
            event: 'rider_rated',
            payload: ratingPayload,
          );
        }

        final trackCh = Supabase.instance.client.channel(
          'rider_tracking_$rawCleanId',
        );
        trackCh.subscribe((status, [err]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            trackCh.sendBroadcastMessage(
              event: 'rider_rated',
              payload: ratingPayload,
            );
          }
        });
      } catch (e) {
        debugPrint('⚠️ submitRiderRating Supabase broadcast notice: $e');
      }
    }

    return newCourierRating;
  }

  void markAsToReceive(String orderId) {
    final list = _currentActiveList;
    final index = list.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      list[index] = list[index].copyWith(
        statusText: 'To Receive',
        statusColor: const Color(0xFF00B4D8),
        etaText: 'Parcel is in transit with SPX Express',
        etaTime: 'Arriving within 1-2 days',
        progress: 0.7,
      );
      notifyListeners();
    }
  }

  void receiveOrder(String orderId) {
    final activeList = _currentActiveList;
    final pastList = _currentPastList;
    final index = activeList.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final order = activeList.removeAt(index);
      pastList.insert(
        0,
        order.copyWith(
          statusText: 'Completed',
          statusColor: const Color(0xFF10B981),
          etaText: 'Delivered successfully',
          etaTime: 'Received by recipient',
          progress: 1.0,
        ),
      );
      notifyListeners();
    }
  }

  void payOrder(String orderId) {
    final list = _currentActiveList;
    final index = list.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      list[index] = list[index].copyWith(
        statusText: 'To Ship',
        statusColor: const Color(0xFF008060),
        etaText: 'Seller is preparing your order',
        etaTime: 'Awaiting Courier Pickup',
        progress: 0.25,
      );
      notifyListeners();
    }
  }

  void shipOrder(String orderId) {
    markAsToReceive(orderId);
  }

  void cancelOrder(String orderId) {
    final clean = orderId.replaceAll('#', '').trim().toLowerCase();
    final rawClean = orderId.replaceAll('#', '').trim();
    if (clean.isEmpty) return;

    _locallyCancelledOrders.add(clean);
    _locallyCancelledOrders.add(rawClean.toLowerCase());

    OrderItemModel? targetOrder;

    // 1. Search in active orders across all user lists
    for (final list in _userActiveOrders.values) {
      final idx = list.indexWhere(
        (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == clean,
      );
      if (idx != -1) {
        targetOrder = list.removeAt(idx);
        break;
      }
    }

    // 2. If already in past orders, remove and prepare to re-insert as Cancelled
    if (targetOrder == null) {
      for (final list in _userPastOrders.values) {
        final idx = list.indexWhere(
          (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == clean,
        );
        if (idx != -1) {
          targetOrder = list.removeAt(idx);
          break;
        }
      }
    }

    final cancelledOrder =
        (targetOrder ??
                OrderItemModel(
                  orderId: orderId.startsWith('#') ? orderId : '#$orderId',
                  dateText: 'Today',
                  statusText: 'Cancelled',
                  statusColor: const Color(0xFFEF4444),
                  etaText: 'Order Cancelled',
                  etaTime: '-',
                  progress: 0.0,
                  items: const [],
                  totalPrice: 0.0,
                  paymentMethod: 'Cash on Delivery',
                  courierName: 'Pedro Jose Garcia',
                  courierRating: 4.96,
                  courierAvatarUrl: '',
                ))
            .copyWith(
              statusText: 'Cancelled',
              statusColor: const Color(0xFFEF4444),
              etaText: 'Order Cancelled',
              etaTime: '-',
              progress: 0.0,
            );

    // Ensure it's in current user's past list
    _currentPastList.removeWhere(
      (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == clean,
    );
    _currentPastList.insert(0, cancelledOrder);

    // Also update target's buyer list if different
    if (cancelledOrder.buyerEmail.isNotEmpty &&
        cancelledOrder.buyerEmail != _currentUserKey) {
      final buyerPast = _userPastOrders.putIfAbsent(
        cancelledOrder.buyerEmail,
        () => [],
      );
      buyerPast.removeWhere(
        (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == clean,
      );
      buyerPast.insert(0, cancelledOrder);
    }

    notifyListeners();

    // 3. Persist cancellation to Supabase with comprehensive filters
    if (isSupabaseReady) {
      try {
        final isNum = int.tryParse(rawClean) != null;
        if (isNum) {
          Supabase.instance.client
              .from('orders')
              .update({'status': 'cancelled'})
              .eq('id', int.parse(rawClean))
              .catchError((_) {});
        }
        // Match exact, lowercase, with hash, and ilike pattern
        Supabase.instance.client
            .from('orders')
            .update({'status': 'cancelled'})
            .eq('order_id', rawClean)
            .catchError((_) {});
        Supabase.instance.client
            .from('orders')
            .update({'status': 'cancelled'})
            .eq('order_id', '#$rawClean')
            .catchError((_) {});
        Supabase.instance.client
            .from('orders')
            .update({'status': 'cancelled'})
            .ilike('order_id', '%$rawClean%')
            .catchError((_) {});
        Supabase.instance.client
            .from('orders')
            .update({'status': 'cancelled'})
            .eq('id', rawClean)
            .catchError((_) {});

        if (_dispatchChannel != null && _isDispatchSubscribed == true) {
          _dispatchChannel!.sendBroadcastMessage(
            event: 'status_updated',
            payload: {'order_id': rawClean, 'status': 'cancelled'},
          );
        }
        if (_courierDispatchChannel != null &&
            _isCourierDispatchSubscribed == true) {
          _courierDispatchChannel!.sendBroadcastMessage(
            event: 'status_updated',
            payload: {'order_id': rawClean, 'status': 'cancelled'},
          );
        }
      } catch (e) {
        debugPrint('⚠️ cancelOrder Supabase notice: $e');
      }
    }
  }

  /// Updates delivery pin and address on active orders and syncs to Supabase & Rider real-time channels
  Future<void> updateOrderDeliveryPin({
    required String orderId,
    required double lat,
    required double lng,
    required String address,
  }) async {
    final cleanId = orderId.replaceAll('#', '').trim();
    // 1. Update in-memory active orders across all user keys
    for (final list in _userActiveOrders.values) {
      final idx = list.indexWhere(
        (o) => o.orderId.replaceAll('#', '').trim() == cleanId,
      );
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          deliveryLat: lat,
          deliveryLng: lng,
          shippingAddress: address,
        );
      }
    }
    notifyListeners();

    // 2. Sync to Supabase orders table with high precision
    try {
      final isNum = int.tryParse(cleanId) != null;
      if (isNum) {
        await Supabase.instance.client
            .from('orders')
            .update({
              'delivery_lat': lat,
              'delivery_lng': lng,
              'delivery_address': address,
            })
            .eq('id', int.parse(cleanId))
            .catchError((_) {});
      }
      await Supabase.instance.client
          .from('orders')
          .update({
            'delivery_lat': lat,
            'delivery_lng': lng,
            'delivery_address': address,
          })
          .eq('order_id', cleanId)
          .catchError((_) {});
      await Supabase.instance.client
          .from('orders')
          .update({
            'delivery_lat': lat,
            'delivery_lng': lng,
            'delivery_address': address,
          })
          .eq('id', cleanId)
          .catchError((_) {});

      // 3. Broadcast on orders_dispatch channel so Rider App instantly receives updated location
      final dispatchChannel = Supabase.instance.client.channel(
        'orders_dispatch',
      );
      dispatchChannel.sendBroadcastMessage(
        event: 'location_updated',
        payload: {
          'order_id': cleanId,
          'delivery_lat': lat,
          'delivery_lng': lng,
          'delivery_address': address,
        },
      );

      // 4. Also broadcast on individual order channel
      final trackingChannel = Supabase.instance.client.channel(
        'rider_tracking_$cleanId',
      );
      trackingChannel.sendBroadcastMessage(
        event: 'location_updated',
        payload: {
          'order_id': cleanId,
          'delivery_lat': lat,
          'delivery_lng': lng,
          'delivery_address': address,
        },
      );
    } catch (e) {
      debugPrint('⚠️ updateOrderDeliveryPin Supabase broadcast error: $e');
    }
  }

  /// Clears active & past orders for the current user
  void clearActiveUserOrders() {
    _userActiveOrders.remove(_currentUserKey);
    _userPastOrders.remove(_currentUserKey);
    notifyListeners();
  }

  /// Resets all user orders
  void clearAllOrders() {
    _userActiveOrders.clear();
    _userPastOrders.clear();
    _locallyCancelledOrders.clear();
    notifyListeners();
  }
}
