enum DeliveryStatus {
  available,
  accepted,
  atMerchant,
  pickedUp,
  atCustomer,
  delivered,
  cancelled,
}

extension DeliveryStatusExt on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.available:
        return 'Dispatch Request';
      case DeliveryStatus.accepted:
        return 'Headed to Store';
      case DeliveryStatus.atMerchant:
        return 'At Store / Picking Up';
      case DeliveryStatus.pickedUp:
        return 'In Transit to Customer';
      case DeliveryStatus.atCustomer:
        return 'Arrived at Drop-off';
      case DeliveryStatus.delivered:
        return 'Completed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case DeliveryStatus.available:
        return 0;
      case DeliveryStatus.accepted:
        return 1;
      case DeliveryStatus.atMerchant:
        return 2;
      case DeliveryStatus.pickedUp:
        return 3;
      case DeliveryStatus.atCustomer:
        return 4;
      case DeliveryStatus.delivered:
        return 5;
      case DeliveryStatus.cancelled:
        return -1;
    }
  }
}

class OrderItemDetail {
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  const OrderItemDetail({
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });
}

class DeliveryOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String customerNotes;
  final String merchantName;
  final String merchantAddress;
  final String merchantPhone;
  final List<OrderItemDetail> items;
  final double deliveryFee;
  final double tip;
  final double orderTotal;
  final String paymentType; // 'COD' or 'Prepaid (GCash/NexoraPay)'
  final double distanceKm;
  final int estimatedMinutes;
  final DateTime createdAt;
  final DeliveryStatus status;
  final String? proofPhotoPath;
  final String? recipientNotes;
  final int acceptanceCountdownSec;

  const DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.customerNotes = '',
    required this.merchantName,
    required this.merchantAddress,
    required this.merchantPhone,
    required this.items,
    required this.deliveryFee,
    this.tip = 0.0,
    required this.orderTotal,
    required this.paymentType,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.createdAt,
    this.status = DeliveryStatus.available,
    this.proofPhotoPath,
    this.recipientNotes,
    this.acceptanceCountdownSec = 30,
  });

  double get riderEarnings => deliveryFee + tip;

  DeliveryOrder copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerNotes,
    String? merchantName,
    String? merchantAddress,
    String? merchantPhone,
    List<OrderItemDetail>? items,
    double? deliveryFee,
    double? tip,
    double? orderTotal,
    String? paymentType,
    double? distanceKm,
    int? estimatedMinutes,
    DateTime? createdAt,
    DeliveryStatus? status,
    String? proofPhotoPath,
    String? recipientNotes,
    int? acceptanceCountdownSec,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerNotes: customerNotes ?? this.customerNotes,
      merchantName: merchantName ?? this.merchantName,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tip: tip ?? this.tip,
      orderTotal: orderTotal ?? this.orderTotal,
      paymentType: paymentType ?? this.paymentType,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      proofPhotoPath: proofPhotoPath ?? this.proofPhotoPath,
      recipientNotes: recipientNotes ?? this.recipientNotes,
      acceptanceCountdownSec: acceptanceCountdownSec ?? this.acceptanceCountdownSec,
    );
  }
}
