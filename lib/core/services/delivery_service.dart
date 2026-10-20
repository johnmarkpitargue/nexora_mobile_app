import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_order.dart';
import 'rider_service.dart';
import 'earnings_service.dart';

class DeliveryService extends ChangeNotifier {
  static final DeliveryService instance = DeliveryService._();
  DeliveryService._() {
    _initInitialData();
    _initSupabaseListener();
  }

  final List<DeliveryOrder> _availableOrders = [];
  DeliveryOrder? _activeOrder;
  final List<DeliveryOrder> _completedOrders = [];

  List<DeliveryOrder> get availableOrders => List.unmodifiable(_availableOrders);
  DeliveryOrder? get activeOrder => _activeOrder;
  List<DeliveryOrder> get completedOrders => List.unmodifiable(_completedOrders);
  DeliveryOrder? get lastCompletedOrder =>
      _completedOrders.isNotEmpty ? _completedOrders.first : null;

  void _initInitialData() {
    _activeOrder = null;
    _availableOrders.clear();

    // 3. Past Completed Orders History
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

  void _initSupabaseListener() {
    try {
      Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen((data) {
        for (final row in data) {
          final rawId = row['id'].toString();
          final orderCode = (row['order_id'] ?? rawId).toString();
          final status = (row['status'] ?? 'pending').toString().toLowerCase();

          final isMatchActive = _activeOrder != null &&
              (_activeOrder!.id == orderCode || _activeOrder!.id == rawId || _activeOrder!.id.replaceAll('#', '') == orderCode.replaceAll('#', ''));
          final availIdx = _availableOrders.indexWhere(
            (o) => o.id == orderCode || o.id == rawId || o.id.replaceAll('#', '') == orderCode.replaceAll('#', ''),
          );

          if (status == 'pending') {
            if (!isMatchActive && availIdx < 0) {
              final newOrder = DeliveryOrder(
                id: orderCode,
                customerName: (row['customer_id'] ?? 'Customer').toString(),
                customerPhone: '+63 975 963 2035',
                customerAddress: (row['delivery_address'] ?? 'Brgy. Real, Calamba City, Laguna').toString(),
                customerNotes: 'Online order placed via Nexora App',
                merchantName: 'Nexora Official Flagship Store',
                merchantAddress: 'Nexora Central Fulfillment Center',
                merchantPhone: '+63 2 8888 1234',
                items: [
                  OrderItemDetail(
                    name: (row['item_details'] ?? 'Assorted Nexora Items').toString(),
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
              _availableOrders.insert(0, newOrder);
              notifyListeners();
            }
          } else if (status == 'to_deliver' || status == 'ready') {
            if (availIdx >= 0 && !isMatchActive) {
              final order = _availableOrders.removeAt(availIdx);
              _activeOrder = order.copyWith(status: DeliveryStatus.accepted);
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
      });
    } catch (e) {
      debugPrint('⚠️ DeliveryService Supabase listener notice: $e');
    }
  }

  void acceptOrder(String orderId) {
    final index = _availableOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = _availableOrders.removeAt(index);
      _activeOrder = order.copyWith(status: DeliveryStatus.accepted);
      notifyListeners();

      try {
        final clean = orderId.replaceAll('#', '');
        final isNum = int.tryParse(clean) != null;
        if (isNum) {
          Supabase.instance.client.from('orders').update({'status': 'to_deliver'}).eq('id', int.parse(clean));
        } else {
          Supabase.instance.client.from('orders').update({'status': 'to_deliver'}).eq('order_id', clean);
        }
      } catch (e) {
        debugPrint('⚠️ Accept order Supabase sync: $e');
      }
    }
  }

  void declineOrder(String orderId) {
    _availableOrders.removeWhere((o) => o.id == orderId);
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
    notifyListeners();

    try {
      final clean = completed.id.replaceAll('#', '');
      final isNum = int.tryParse(clean) != null;
      if (isNum) {
        Supabase.instance.client.from('orders').update({'status': 'delivered'}).eq('id', int.parse(clean));
      } else {
        Supabase.instance.client.from('orders').update({'status': 'delivered'}).eq('order_id', clean);
      }
    } catch (e) {
      debugPrint('⚠️ Complete order Supabase sync: $e');
    }
  }

  void addSimulatedNewDispatch() {
    final count = _availableOrders.length + _completedOrders.length + 1;
    final newOrder = DeliveryOrder(
      id: 'NX-${9300 + count}-ORD',
      customerName: 'Kristine Bautista',
      customerPhone: '+63 915 221 8899',
      customerAddress: 'Fairways Tower, 5th Ave & McKinley Rd, BGC',
      customerNotes: 'Unit 21-C, buzzer is working.',
      merchantName: 'Zara Flagship BGC',
      merchantAddress: 'One Bonifacio High Street Mall, BGC',
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
}
