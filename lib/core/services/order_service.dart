import 'package:flutter/material.dart';

import 'cart_service.dart';
import 'profile_service.dart';

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
  }) : orderDateTimeText = orderDateTimeText ?? dateText,
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
    );
  }
}

class OrderService extends ChangeNotifier {
  static final OrderService instance = OrderService._internal();
  OrderService._internal() {
    _initInitialOrders();
  }

  int _orderCounter = 89240;

  final List<OrderItemModel> _activeOrders = [];
  final List<OrderItemModel> _pastOrders = [];

  void _initInitialOrders() {
    // Initial orders start empty so "To Receive" tab and order tracking start clean
  }

  List<OrderItemModel> get activeOrders => List.unmodifiable(_activeOrders);
  List<OrderItemModel> get pastOrders => List.unmodifiable(_pastOrders);
  OrderItemModel? get latestActiveOrder =>
      _activeOrders.isNotEmpty ? _activeOrders.first : null;

  int get totalOrderCount => _activeOrders.length + _pastOrders.length;

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
        statusText: isUnpaid ? 'To Pay' : 'To Receive',
        statusColor: isUnpaid ? const Color(0xFFF59E0B) : const Color(0xFF00C1D4),
        etaText: isUnpaid
            ? 'Payment Pending'
            : 'Order Placed • Waiting for courier dispatch',
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
        courierName: 'Mark Ronald',
        courierRating: 4.96,
        courierAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
      );

      _activeOrders.insert(0, newOrder);
    }

    notifyListeners();
  }

  void markAsToReceive(String orderId) {
    final index = _activeOrders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      _activeOrders[index] = _activeOrders[index].copyWith(
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
    final index = _activeOrders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final order = _activeOrders.removeAt(index);
      _pastOrders.insert(
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
    final index = _activeOrders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      _activeOrders[index] = _activeOrders[index].copyWith(
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
    final index = _activeOrders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      _activeOrders[index] = _activeOrders[index].copyWith(
        statusText: 'Cancelled',
        statusColor: const Color(0xFFE11D48),
        etaText: 'Order Cancelled',
        etaTime: '-',
        progress: 0.0,
      );
      notifyListeners();
    }
  }
}
