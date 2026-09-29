import 'package:flutter/material.dart';
import 'cart_service.dart';

class OrderItemModel {
  final String orderId;
  final String dateText;
  final String statusText;
  final Color statusColor;
  final String etaText;
  final String etaTime;
  final double progress;
  final List<CartItemModel> items;
  final double totalPrice;
  final String paymentMethod;
  final String courierName;
  final double courierRating;
  final String courierAvatarUrl;

  OrderItemModel({
    required this.orderId,
    required this.dateText,
    required this.statusText,
    required this.statusColor,
    required this.etaText,
    required this.etaTime,
    required this.progress,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.courierName,
    required this.courierRating,
    required this.courierAvatarUrl,
  });
}

class OrderService extends ChangeNotifier {
  static final OrderService instance = OrderService._internal();
  OrderService._internal();

  int _orderCounter = 89240;

  final List<OrderItemModel> _activeOrders = [
    OrderItemModel(
      orderId: '#NX-89240',
      dateText: 'Today, 1:15 PM',
      statusText: 'OUT FOR DELIVERY',
      statusColor: const Color(0xFF00B4D8),
      etaText: 'Arriving in ~18 mins',
      etaTime: 'Estimated 4:30 PM',
      progress: 0.72,
      items: [
        CartItemModel(
          id: 'o1',
          storeName: 'Nexora Official Flagship',
          storeBadge: 'MALL',
          title: 'Nexora Studio Pro Wireless',
          variant: 'Matte Space Grey • Qty: 1',
          imageUrl:
              'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=300&q=80',
          price: 2450.00,
        ),
        CartItemModel(
          id: 'o2',
          storeName: 'Urban Minimalist Studio',
          storeBadge: 'PREFERRED+',
          title: 'Aura Minimalist Fleece Hoodie',
          variant: 'Warm Stone • Size: L • Qty: 1',
          imageUrl:
              'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=300&q=80',
          price: 1250.00,
        ),
      ],
      totalPrice: 3700.00,
      paymentMethod: 'Paid via NexoraPay',
      courierName: 'Mark Ronald',
      courierRating: 4.96,
      courierAvatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
    ),
  ];

  final List<OrderItemModel> _pastOrders = [
    OrderItemModel(
      orderId: '#NX-78419',
      dateText: 'Delivered Nov 18',
      statusText: 'Delivered',
      statusColor: const Color(0xFF0891B2),
      etaText: 'Delivered',
      etaTime: 'Completed',
      progress: 1.0,
      items: [
        CartItemModel(
          id: 'p1',
          storeName: 'Nexora Official Flagship',
          storeBadge: 'MALL',
          title: 'Nexora Aura Mechanical Keyboard',
          variant: 'Chalk White • Wireless',
          imageUrl:
              'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=150&q=80',
          price: 3200.00,
        ),
      ],
      totalPrice: 3200.00,
      paymentMethod: 'Paid via GCash',
      courierName: 'Jerome Perez',
      courierRating: 4.92,
      courierAvatarUrl: '',
    ),
    OrderItemModel(
      orderId: '#NX-72015',
      dateText: 'Delivered Nov 02',
      statusText: 'Delivered',
      statusColor: const Color(0xFF0891B2),
      etaText: 'Delivered',
      etaTime: 'Completed',
      progress: 1.0,
      items: [
        CartItemModel(
          id: 'p2',
          storeName: 'Nordic Lifestyle Essentials',
          storeBadge: '',
          title: 'Minimalist Canvas Tote & Water Bottle',
          variant: 'Standard Bundle • Sandstone',
          imageUrl:
              'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=150&q=80',
          price: 1420.00,
        ),
      ],
      totalPrice: 1420.00,
      paymentMethod: 'Paid via NexoraPay',
      courierName: 'Daniel Santos',
      courierRating: 4.95,
      courierAvatarUrl: '',
    ),
  ];

  List<OrderItemModel> get activeOrders => List.unmodifiable(_activeOrders);
  List<OrderItemModel> get pastOrders => List.unmodifiable(_pastOrders);
  OrderItemModel? get latestActiveOrder =>
      _activeOrders.isNotEmpty ? _activeOrders.first : null;

  int get totalOrderCount => _activeOrders.length + _pastOrders.length;

  void placeOrder({
    required List<CartItemModel> items,
    required double totalPrice,
    required String paymentMethod,
  }) {
    _orderCounter++;
    final orderedItems = items.isEmpty
        ? [
            CartItemModel(
              id: 'item_${DateTime.now().millisecondsSinceEpoch}',
              storeName: 'Nexora Official Flagship',
              storeBadge: 'MALL',
              title: 'Nexora Aura 75 Mechanical Keyboard',
              variant: 'Chalk White / Violet • Linear',
              imageUrl:
                  'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=300&q=80',
              price: totalPrice > 0 ? totalPrice : 3200.0,
            ),
          ]
        : items.map((i) => CartItemModel(
            id: i.id,
            storeName: i.storeName,
            storeBadge: i.storeBadge,
            title: i.title,
            variant: '${i.variant} • Qty: ${i.quantity}',
            imageUrl: i.imageUrl,
            price: i.price * i.quantity,
            quantity: i.quantity,
          )).toList();

    final newOrder = OrderItemModel(
      orderId: '#NX-$_orderCounter',
      dateText: 'Just Now',
      statusText: 'OUT FOR DELIVERY',
      statusColor: const Color(0xFF00B4D8),
      etaText: 'Arriving in ~25 mins',
      etaTime: 'Estimated 5:00 PM',
      progress: 0.35,
      items: orderedItems,
      totalPrice: totalPrice > 0 ? totalPrice : 3200.0,
      paymentMethod: paymentMethod,
      courierName: 'Mark Ronald',
      courierRating: 4.96,
      courierAvatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
    );

    _activeOrders.insert(0, newOrder);
    notifyListeners();
  }
}
