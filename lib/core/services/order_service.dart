import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../utils/image_url_helper.dart';
import '../utils/variant_helper.dart';
import 'buyer_account_service.dart';
import 'cart_service.dart';

class OrderStatusHistoryEntry {
  final int id;
  final String status;
  final String note;
  final String changedAt;

  const OrderStatusHistoryEntry({
    required this.id,
    required this.status,
    required this.note,
    required this.changedAt,
  });

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryEntry(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      status: (json['status'] ?? '').toString().trim(),
      note: (json['note'] ?? '').toString().trim(),
      changedAt: (json['changed_at'] ?? '').toString().trim(),
    );
  }
}

class OrderDisputeInfo {
  final int id;
  final String reason;
  final String details;
  final String status;
  final List<String> mediaPaths;
  final String createdAt;

  const OrderDisputeInfo({
    required this.id,
    required this.reason,
    required this.details,
    required this.status,
    required this.mediaPaths,
    required this.createdAt,
  });

  factory OrderDisputeInfo.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media_paths'] as List? ?? const [];
    final resolvedMedia = rawMedia
        .map((e) => ImageUrlHelper.resolve(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return OrderDisputeInfo(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      reason: (json['reason'] ?? '').toString().trim(),
      details: (json['details'] ?? '').toString().trim(),
      status: (json['status'] ?? 'open').toString().trim(),
      mediaPaths: resolvedMedia,
      createdAt: (json['created_at'] ?? '').toString().trim(),
    );
  }
}

class OrderReviewInfo {
  final int id;
  final int rating;
  final String? comment;
  final List<String> photos;
  final int editedCount;
  final bool canBeEdited;
  final String createdAt;

  const OrderReviewInfo({
    required this.id,
    required this.rating,
    this.comment,
    required this.photos,
    required this.editedCount,
    required this.canBeEdited,
    required this.createdAt,
  });

  factory OrderReviewInfo.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List? ?? const [];
    final resolvedPhotos = rawPhotos
        .map((e) => ImageUrlHelper.resolve(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return OrderReviewInfo(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString(),
      photos: resolvedPhotos,
      editedCount: (json['edited_count'] as num?)?.toInt() ?? 0,
      canBeEdited: json['can_be_edited'] as bool? ?? false,
      createdAt: (json['created_at'] ?? '').toString().trim(),
    );
  }
}

class OrderTabCounts {
  final int all;
  final int toPay;
  final int toShip;
  final int toReceive;
  final int completed;
  final int cancelled;
  final int returnRefund;

  const OrderTabCounts({
    this.all = 0,
    this.toPay = 0,
    this.toShip = 0,
    this.toReceive = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.returnRefund = 0,
  });

  factory OrderTabCounts.fromJson(Map<String, dynamic> json) {
    int readInt(String key) => (json[key] as num?)?.toInt() ?? 0;
    return OrderTabCounts(
      all: readInt('all'),
      toPay: readInt('to_pay'),
      toShip: readInt('to_ship'),
      toReceive: readInt('to_receive'),
      completed: readInt('completed'),
      cancelled: readInt('cancelled'),
      returnRefund: readInt('return_refund'),
    );
  }
}

class OrderStatusPresentation {
  final String statusText;
  final String tabBucket;
  final Color statusColor;
  final double progress;
  final String etaText;
  final String etaTime;

  const OrderStatusPresentation({
    required this.statusText,
    required this.tabBucket,
    required this.statusColor,
    required this.progress,
    required this.etaText,
    required this.etaTime,
  });
}

class OrderItemModel {
  final int serverId;
  final String orderId;
  final String rawStatus;
  final String tabBucket;
  final int? sellerId;
  final String storeName;
  final String trackingNumber;
  final String deliveryOtp;
  final String cancellationReason;
  final String? currentHubName;
  final String? originHubName;
  final String? destinationHubName;
  final bool canBeCancelled;
  final bool canBeReturned;
  final bool canBeReviewed;
  final bool hasDispute;
  final bool hasReview;
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
  final String? courierPhone;
  final String? courierVehicle;
  final String? courierPlateNumber;
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
  final List<OrderStatusHistoryEntry> statusHistory;
  final OrderDisputeInfo? dispute;
  final OrderReviewInfo? review;

  OrderItemModel({
    this.serverId = 0,
    required this.orderId,
    this.rawStatus = 'placed',
    this.tabBucket = 'to_ship',
    this.sellerId,
    this.storeName = '',
    this.trackingNumber = '',
    this.deliveryOtp = '',
    this.cancellationReason = '',
    this.currentHubName,
    this.originHubName,
    this.destinationHubName,
    this.canBeCancelled = false,
    this.canBeReturned = false,
    this.canBeReviewed = false,
    this.hasDispute = false,
    this.hasReview = false,
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
    this.courierName = '',
    this.courierPhone,
    this.courierVehicle,
    this.courierPlateNumber,
    this.courierRating = 0.0,
    this.courierAvatarUrl = '',
    String? buyerEmail,
    this.deliveryLat,
    this.deliveryLng,
    this.isRiderAccepted = false,
    this.isRated = false,
    this.buyerDriverRating,
    this.buyerDeliveryRating,
    this.buyerCourierComment,
    this.buyerCourierTags,
    this.statusHistory = const [],
    this.dispute,
    this.review,
  }) : buyerEmail = buyerEmail ?? '',
       orderDateTimeText = orderDateTimeText ?? dateText,
       subtotal = subtotal ?? totalPrice,
       shippingFee = shippingFee ?? 0.0,
       discount = discount ?? 0.0,
       shippingOption = shippingOption ?? 'Standard Local Delivery',
       recipientName = recipientName ?? '',
       recipientPhone = recipientPhone ?? '',
       shippingAddress = shippingAddress ?? '';

  bool get isPastOrder =>
      rawStatus == 'cancelled' ||
      rawStatus == 'delivered' ||
      rawStatus == 'completed' ||
      rawStatus == 'returned' ||
      rawStatus == 'return_to_sender' ||
      rawStatus == 'returned_to_sender' ||
      hasDispute;

  bool matchesTab(String tab) {
    switch (tab) {
      case 'all':
        return true;
      case 'to_pay':
        return false; // COD only (matches backend OrderController@index)
      case 'to_ship':
        return const {'placed', 'confirmed', 'preparing', 'processing'}
            .contains(rawStatus);
      case 'to_receive':
        return const {
          'ready_for_pickup',
          'assigned',
          'picked_up',
          'at_hub',
          'at_sorting_center',
          'received_at_hub',
          'in_transit_hub',
          'in_transit',
          'sorting_hub',
          'sorted',
          'assigned_to_rider',
          'out_for_delivery',
          'failed_delivery',
          'delivery_failed',
          'shipped',
          'shipping',
          'to_deliver',
        }.contains(rawStatus);
      case 'completed':
        return rawStatus == 'completed' || rawStatus == 'delivered';
      case 'cancelled':
        return rawStatus == 'cancelled';
      case 'return_refund':
        return hasDispute ||
            const {
              'returned',
              'return_to_sender',
              'returned_to_sender',
            }.contains(rawStatus);
      default:
        return true;
    }
  }

  static OrderStatusPresentation describeStatus(
    String rawStatus, {
    bool hasDispute = false,
    String? currentHubName,
  }) {
    final s = rawStatus.trim().toLowerCase();
    final hubSuffix =
        (currentHubName != null && currentHubName.trim().isNotEmpty)
        ? ' (${currentHubName.trim()})'
        : '';

    if (hasDispute &&
        s != 'returned' &&
        s != 'return_to_sender' &&
        s != 'returned_to_sender' &&
        s != 'cancelled') {
      return OrderStatusPresentation(
        statusText: 'Return / Refund Requested',
        tabBucket: 'return_refund',
        statusColor: const Color(0xFF7C3AED),
        progress: 1.0,
        etaText: 'Return / refund request under review',
        etaTime: '-',
      );
    }

    switch (s) {
      case 'placed':
        return const OrderStatusPresentation(
          statusText: 'Order Placed',
          tabBucket: 'to_ship',
          statusColor: Color(0xFF3B82F6),
          progress: 0.15,
          etaText: 'Order placed • Waiting for seller confirmation',
          etaTime: 'Estimated: 2-3 days',
        );
      case 'confirmed':
        return const OrderStatusPresentation(
          statusText: 'Confirmed by Seller',
          tabBucket: 'to_ship',
          statusColor: Color(0xFF3B82F6),
          progress: 0.25,
          etaText: 'Seller confirmed your order',
          etaTime: 'Estimated: 2-3 days',
        );
      case 'preparing':
      case 'processing':
        return const OrderStatusPresentation(
          statusText: 'Preparing',
          tabBucket: 'to_ship',
          statusColor: Color(0xFF2563EB),
          progress: 0.35,
          etaText: 'Seller is preparing your parcel for dispatch',
          etaTime: 'Estimated: 2-3 days',
        );
      case 'ready_for_pickup':
      case 'assigned':
        return const OrderStatusPresentation(
          statusText: 'Ready for Pickup',
          tabBucket: 'to_receive',
          statusColor: Color(0xFFD97706),
          progress: 0.45,
          etaText: 'Parcel packed • Awaiting pickup rider',
          etaTime: 'Estimated: 1-3 days',
        );
      case 'picked_up':
        return const OrderStatusPresentation(
          statusText: 'Picked Up',
          tabBucket: 'to_receive',
          statusColor: Color(0xFF7C3AED),
          progress: 0.55,
          etaText: 'Rider picked up parcel from seller',
          etaTime: 'Estimated: 1-2 days',
        );
      case 'at_hub':
      case 'received_at_hub':
      case 'at_sorting_center':
      case 'sorting_hub':
      case 'sorted':
        return OrderStatusPresentation(
          statusText: s == 'received_at_hub'
              ? 'Received at Hub'
              : (s == 'sorted' ? 'Sorted at Hub' : 'At Logistics Hub'),
          tabBucket: 'to_receive',
          statusColor: const Color(0xFF6366F1),
          progress: 0.65,
          etaText: 'Parcel checked in at hub$hubSuffix',
          etaTime: 'Estimated: 1-2 days',
        );
      case 'in_transit_hub':
      case 'in_transit':
      case 'shipped':
      case 'shipping':
        return OrderStatusPresentation(
          statusText: s == 'in_transit_hub'
              ? 'In Transit Between Hubs'
              : 'In Transit',
          tabBucket: 'to_receive',
          statusColor: const Color(0xFF8B5CF6),
          progress: 0.72,
          etaText: s == 'in_transit_hub'
              ? 'Parcel is in transit between hubs$hubSuffix'
              : 'Parcel is in transit$hubSuffix',
          etaTime: 'Estimated: 1-2 days',
        );
      case 'assigned_to_rider':
        return const OrderStatusPresentation(
          statusText: 'Assigned to Rider',
          tabBucket: 'to_receive',
          statusColor: Color(0xFF0284C7),
          progress: 0.80,
          etaText: 'Parcel assigned to delivery rider',
          etaTime: 'Expected soon',
        );
      case 'out_for_delivery':
      case 'to_deliver':
        return const OrderStatusPresentation(
          statusText: 'Out for Delivery',
          tabBucket: 'to_receive',
          statusColor: Color(0xFF0066FF),
          progress: 0.90,
          etaText: 'Delivery rider is on the way with your parcel',
          etaTime: 'Expected today',
        );
      case 'failed_delivery':
      case 'delivery_failed':
        return const OrderStatusPresentation(
          statusText: 'Delivery Failed',
          tabBucket: 'to_receive',
          statusColor: Color(0xFFEA580C),
          progress: 0.75,
          etaText: 'Delivery attempt unsuccessful • Will retry or return to hub',
          etaTime: 'Pending re-delivery',
        );
      case 'delivered':
        return const OrderStatusPresentation(
          statusText: 'Delivered',
          tabBucket: 'completed',
          statusColor: Color(0xFF059669),
          progress: 1.0,
          etaText: 'Delivered to recipient • Confirm receipt when checked',
          etaTime: 'Delivered',
        );
      case 'completed':
        return const OrderStatusPresentation(
          statusText: 'Completed',
          tabBucket: 'completed',
          statusColor: Color(0xFF10B981),
          progress: 1.0,
          etaText: 'Order completed',
          etaTime: 'Received by recipient',
        );
      case 'cancelled':
        return const OrderStatusPresentation(
          statusText: 'Cancelled',
          tabBucket: 'cancelled',
          statusColor: Color(0xFFEF4444),
          progress: 0.0,
          etaText: 'Order cancelled',
          etaTime: '-',
        );
      case 'returned':
      case 'return_to_sender':
      case 'returned_to_sender':
        return OrderStatusPresentation(
          statusText: s == 'return_to_sender' || s == 'returned_to_sender'
              ? 'Returned to Seller'
              : 'Return / Refund',
          tabBucket: 'return_refund',
          statusColor: const Color(0xFF7C3AED),
          progress: 0.0,
          etaText: s == 'return_to_sender' || s == 'returned_to_sender'
              ? 'Parcel is returning to the seller'
              : 'Return / refund processed',
          etaTime: '-',
        );
      default:
        return OrderStatusPresentation(
          statusText: s.isEmpty
              ? 'Unknown'
              : s
                  .split('_')
                  .where((w) => w.isNotEmpty)
                  .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                  .join(' '),
          tabBucket: 'to_ship',
          statusColor: const Color(0xFF64748B),
          progress: 0.2,
          etaText: 'Order status updated',
          etaTime: '-',
        );
    }
  }

  OrderItemModel copyWith({
    int? serverId,
    String? orderId,
    String? rawStatus,
    String? tabBucket,
    int? sellerId,
    String? storeName,
    String? trackingNumber,
    String? deliveryOtp,
    String? cancellationReason,
    String? currentHubName,
    String? originHubName,
    String? destinationHubName,
    bool? canBeCancelled,
    bool? canBeReturned,
    bool? canBeReviewed,
    bool? hasDispute,
    bool? hasReview,
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
    String? courierPhone,
    String? courierVehicle,
    String? courierPlateNumber,
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
    List<OrderStatusHistoryEntry>? statusHistory,
    OrderDisputeInfo? dispute,
    OrderReviewInfo? review,
  }) {
    return OrderItemModel(
      serverId: serverId ?? this.serverId,
      orderId: orderId ?? this.orderId,
      rawStatus: rawStatus ?? this.rawStatus,
      tabBucket: tabBucket ?? this.tabBucket,
      sellerId: sellerId ?? this.sellerId,
      storeName: storeName ?? this.storeName,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      currentHubName: currentHubName ?? this.currentHubName,
      originHubName: originHubName ?? this.originHubName,
      destinationHubName: destinationHubName ?? this.destinationHubName,
      canBeCancelled: canBeCancelled ?? this.canBeCancelled,
      canBeReturned: canBeReturned ?? this.canBeReturned,
      canBeReviewed: canBeReviewed ?? this.canBeReviewed,
      hasDispute: hasDispute ?? this.hasDispute,
      hasReview: hasReview ?? this.hasReview,
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
      courierPhone: courierPhone ?? this.courierPhone,
      courierVehicle: courierVehicle ?? this.courierVehicle,
      courierPlateNumber: courierPlateNumber ?? this.courierPlateNumber,
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
      statusHistory: statusHistory ?? this.statusHistory,
      dispute: dispute ?? this.dispute,
      review: review ?? this.review,
    );
  }

  factory OrderItemModel.fromApiJson(Map<String, dynamic> json) {
    final parsedId = int.tryParse((json['id'] ?? '').toString()) ?? 0;
    final rawStatus = (json['status'] as String? ?? 'placed').toLowerCase().trim();

    final sellerObj = json['seller'] is Map<String, dynamic>
        ? json['seller'] as Map<String, dynamic>
        : null;
    final resolvedSellerId = int.tryParse(
      (json['seller_id'] ?? sellerObj?['id'] ?? '').toString(),
    );
    final resolvedSellerName = (json['seller_name'] ??
            sellerObj?['name'] ??
            sellerObj?['store_name'] ??
            'Seller')
        .toString()
        .trim();

    final currentHubName = (json['current_hub_name'] ??
            (json['current_hub'] is Map ? json['current_hub']['name'] : null))
        ?.toString()
        .trim();
    final originHubName = (json['origin_hub_name'] ??
            (json['origin_hub'] is Map ? json['origin_hub']['name'] : null))
        ?.toString()
        .trim();
    final destinationHubName = (json['destination_hub_name'] ??
            (json['destination_hub'] is Map
                ? json['destination_hub']['name']
                : null))
        ?.toString()
        .trim();

    final dispute = json['dispute'] is Map<String, dynamic>
        ? OrderDisputeInfo.fromJson(json['dispute'] as Map<String, dynamic>)
        : null;
    final review = json['review'] is Map<String, dynamic>
        ? OrderReviewInfo.fromJson(json['review'] as Map<String, dynamic>)
        : null;
    final hasDispute =
        (json['has_dispute'] as bool?) ?? (dispute != null);
    final hasReview =
        (json['has_review'] as bool?) ?? (review != null);

    final statusDesc = describeStatus(
      rawStatus,
      hasDispute: hasDispute,
      currentHubName: currentHubName,
    );

    final rawItems = json['items'] as List? ?? const [];
    final itemsList = <CartItemModel>[];

    if (rawItems.isNotEmpty) {
      for (int idx = 0; idx < rawItems.length; idx++) {
        final rawItem = rawItems[idx];
        if (rawItem is Map<String, dynamic>) {
          final rawV = rawItem['variant'];
          final variantStr = VariantHelper.formatVariantDisplay(rawV);
          itemsList.add(
            CartItemModel(
              id: rawItem['id']?.toString() ?? '${parsedId}_$idx',
              productId: rawItem['product_id']?.toString(),
              sellerId: resolvedSellerId,
              storeName: resolvedSellerName,
              title: rawItem['product_name']?.toString() ??
                  rawItem['name']?.toString() ??
                  rawItem['title']?.toString() ??
                  'Product',
              variant: variantStr,
              variantData: rawV,
              imageUrl: ImageUrlHelper.resolve(
                rawItem['image'] ?? rawItem['image_url'] ?? '',
              ),
              price: (rawItem['price'] as num?)?.toDouble() ??
                  (rawItem['unit_price'] as num?)?.toDouble() ??
                  0.0,
              quantity: (rawItem['quantity'] as num?)?.toInt() ?? 1,
            ),
          );
        }
      }
    } else if (json['first_item'] is Map<String, dynamic>) {
      final f = json['first_item'] as Map<String, dynamic>;
      itemsList.add(
        CartItemModel(
          id: 'fi_$parsedId',
          productId: f['product_id']?.toString(),
          sellerId: resolvedSellerId,
          storeName: resolvedSellerName,
          title: f['name']?.toString() ?? 'Product',
          variant: VariantHelper.formatVariantDisplay(f['variant']),
          variantData: f['variant'],
          imageUrl: ImageUrlHelper.resolve(f['image'] ?? ''),
          price: (f['price'] as num?)?.toDouble() ?? 0.0,
          quantity: (f['quantity'] as num?)?.toInt() ?? 1,
        ),
      );
    }

    final shippingAddr = json['address_snapshot'] ?? json['shipping_address'];
    String recipientName = '';
    String recipientPhone = '';
    String addressStr = '';
    if (shippingAddr is Map<String, dynamic>) {
      recipientName = (shippingAddr['recipient_name'] ?? '').toString().trim();
      recipientPhone = (shippingAddr['recipient_phone'] ??
              shippingAddr['phone'] ??
              '')
          .toString()
          .trim();
      final explicitFull =
          (shippingAddr['full_address'] ?? '').toString().trim();
      if (explicitFull.isNotEmpty) {
        addressStr = explicitFull;
      } else {
        addressStr = [
          shippingAddr['street'],
          shippingAddr['barangay_name'] ?? shippingAddr['barangay'],
          shippingAddr['municipality_name'] ?? shippingAddr['city'],
          shippingAddr['province_name'] ?? shippingAddr['province'],
        ]
            .map((e) => (e ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .join(', ');
      }
    } else if (shippingAddr is String) {
      addressStr = shippingAddr.trim();
    }

    final courier = json['courier'] is Map<String, dynamic>
        ? json['courier'] as Map<String, dynamic>
        : null;
    final courierName = (courier?['name'] ?? '').toString().trim();
    final courierPhone = courier?['contact_number']?.toString().trim();
    final courierVehicle = courier?['vehicle_type']?.toString().trim();
    final courierPlate = courier?['plate_number']?.toString().trim();

    final placedRaw = (json['placed_at'] ?? json['created_at'] ?? '').toString().trim();
    final dateOnly = placedRaw.isNotEmpty
        ? placedRaw.split(RegExp(r'[T ]')).first
        : '';

    final historyList = (json['status_history'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderStatusHistoryEntry.fromJson)
        .toList();

    final orderNumber = json['order_number']?.toString().trim();
    final displayOrderId = (orderNumber != null && orderNumber.isNotEmpty)
        ? orderNumber
        : '#$parsedId';

    final rawPm = (json['payment_method'] ?? 'cod').toString().trim().toLowerCase();
    final displayPm = rawPm == 'cod'
        ? 'Cash on Delivery'
        : rawPm.toUpperCase();

    return OrderItemModel(
      serverId: parsedId,
      orderId: displayOrderId,
      rawStatus: rawStatus,
      tabBucket: statusDesc.tabBucket,
      sellerId: resolvedSellerId,
      storeName: resolvedSellerName,
      trackingNumber: (json['tracking_number'] ?? '').toString().trim(),
      deliveryOtp: (json['delivery_otp'] ?? '').toString().trim(),
      cancellationReason: (json['cancellation_reason'] ?? '').toString().trim(),
      currentHubName: currentHubName?.isNotEmpty == true ? currentHubName : null,
      originHubName: originHubName?.isNotEmpty == true ? originHubName : null,
      destinationHubName:
          destinationHubName?.isNotEmpty == true ? destinationHubName : null,
      canBeCancelled: json['can_be_cancelled'] as bool? ??
          (rawStatus == 'placed' || rawStatus == 'confirmed'),
      canBeReturned: json['can_be_returned'] as bool? ?? false,
      canBeReviewed: json['can_be_reviewed'] as bool? ?? false,
      hasDispute: hasDispute,
      hasReview: hasReview,
      dateText: dateOnly.isNotEmpty ? dateOnly : 'Today',
      orderDateTimeText: placedRaw.isNotEmpty ? placedRaw : dateOnly,
      statusText: statusDesc.statusText,
      statusColor: statusDesc.statusColor,
      etaText: statusDesc.etaText,
      etaTime: statusDesc.etaTime,
      progress: statusDesc.progress,
      items: itemsList,
      totalPrice: (json['total'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ??
          (json['discount_amount'] as num?)?.toDouble() ??
          0.0,
      paymentMethod: displayPm,
      courierName: courierName,
      courierPhone: courierPhone?.isNotEmpty == true ? courierPhone : null,
      courierVehicle: courierVehicle?.isNotEmpty == true ? courierVehicle : null,
      courierPlateNumber: courierPlate?.isNotEmpty == true ? courierPlate : null,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      shippingAddress: addressStr,
      isRiderAccepted: courierName.isNotEmpty ||
          const {
            'assigned',
            'picked_up',
            'assigned_to_rider',
            'out_for_delivery',
            'delivered',
            'completed',
          }.contains(rawStatus),
      isRated: hasReview || review != null,
      statusHistory: historyList,
      dispute: dispute,
      review: review,
    );
  }
}

class OrderService extends ChangeNotifier {
  static final OrderService instance = OrderService._internal();
  Timer? _pollingTimer;

  OrderService._internal() {
    BuyerAccountService.instance.addListener(_onBuyerAccountChanged);
  }

  final Map<String, List<OrderItemModel>> _userActiveOrders = {};
  final Map<String, List<OrderItemModel>> _userPastOrders = {};
  final Map<String, OrderTabCounts> _userCounts = {};

  bool _isLoading = false;
  String? _ordersError;
  bool _isFetching = false;
  bool _queuedFetch = false;

  bool get isLoading => _isLoading;
  String? get ordersError => _ordersError;

  String? get _activeSessionKey {
    if (!ApiClient.instance.hasToken) return null;
    final buyer = BuyerAccountService.instance.currentBuyer;
    if (buyer != null && buyer.email.trim().isNotEmpty) {
      return buyer.email.toLowerCase().trim();
    }
    return '_token_session';
  }

  List<OrderItemModel> get activeOrders {
    final key = _activeSessionKey;
    if (key == null) return const [];
    return List.unmodifiable(_userActiveOrders[key] ?? const []);
  }

  List<OrderItemModel> get pastOrders {
    final key = _activeSessionKey;
    if (key == null) return const [];
    return List.unmodifiable(_userPastOrders[key] ?? const []);
  }

  List<OrderItemModel> get allOrders {
    final combined = <OrderItemModel>[...activeOrders, ...pastOrders];
    final seenIds = <int>{};
    final result = <OrderItemModel>[];
    for (final order in combined) {
      if (order.serverId > 0) {
        if (seenIds.add(order.serverId)) {
          result.add(order);
        }
      } else {
        result.add(order);
      }
    }
    return List.unmodifiable(result);
  }

  List<OrderItemModel> ordersForTab(String tab) {
    return allOrders.where((o) => o.matchesTab(tab)).toList(growable: false);
  }

  OrderTabCounts get tabCounts {
    final key = _activeSessionKey;
    if (key != null && _userCounts.containsKey(key)) {
      return _userCounts[key]!;
    }
    final all = allOrders;
    return OrderTabCounts(
      all: all.length,
      toPay: 0,
      toShip: all.where((o) => o.matchesTab('to_ship')).length,
      toReceive: all.where((o) => o.matchesTab('to_receive')).length,
      completed: all.where((o) => o.matchesTab('completed')).length,
      cancelled: all.where((o) => o.matchesTab('cancelled')).length,
      returnRefund: all.where((o) => o.matchesTab('return_refund')).length,
    );
  }

  OrderItemModel? get latestActiveOrder {
    final list = activeOrders;
    return list.isNotEmpty ? list.first : null;
  }

  int get totalOrderCount => allOrders.length;

  OrderItemModel? findOrderByServerId(int serverId) {
    if (serverId <= 0) return null;
    for (final o in allOrders) {
      if (o.serverId == serverId) return o;
    }
    return null;
  }

  OrderItemModel? findOrderById(String orderId) {
    final clean = orderId.replaceAll('#', '').trim().toLowerCase();
    for (final o in allOrders) {
      if (o.orderId.replaceAll('#', '').trim().toLowerCase() == clean ||
          o.serverId.toString() == clean) {
        return o;
      }
    }
    return null;
  }

  bool enablePolling = true;

  void startPolling() {
    if (!enablePolling ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test') ||
        (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      return;
    }
    if (!ApiClient.instance.hasToken) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return;
    }
    if (_pollingTimer?.isActive == true) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final currentLifecycle = WidgetsBinding.instance.lifecycleState;
      if (!ApiClient.instance.hasToken ||
          (currentLifecycle != null &&
              currentLifecycle != AppLifecycleState.resumed)) {
        stopPolling();
        return;
      }
      fetchOrdersRemote();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void cancelPeriodicTimer() => stopPolling();

  void _onBuyerAccountChanged() {
    if (!ApiClient.instance.hasToken) {
      stopPolling();
      clearAllOrders();
      return;
    }
    final key = _activeSessionKey;
    if (key != null && key != '_token_session') {
      _userActiveOrders.remove('_token_session');
      _userPastOrders.remove('_token_session');
      _userCounts.remove('_token_session');
    }
    notifyListeners();
  }

  /// Fetch orders from Laravel backend API (server = sole source of truth).
  Future<void> fetchOrdersRemote([String tab = 'all']) async {
    final sessionKey = _activeSessionKey;
    if (sessionKey == null) {
      clearAllOrders();
      return;
    }

    if (_isFetching) {
      _queuedFetch = true;
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _ordersError = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get(
        tab == 'all'
            ? ApiConstants.buyerOrders
            : '${ApiConstants.buyerOrders}?tab=$tab',
      );

      final data = res['data'];
      final List list = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] as List : []);

      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromApiJson)
          .toList();

      final newActive = <OrderItemModel>[];
      final newPast = <OrderItemModel>[];
      for (final o in parsed) {
        if (o.isPastOrder) {
          newPast.add(o);
        } else {
          newActive.add(o);
        }
      }

      _userActiveOrders[sessionKey] = newActive;
      _userPastOrders[sessionKey] = newPast;

      final countsJson = res.raw?['counts'];
      if (countsJson is Map<String, dynamic>) {
        _userCounts[sessionKey] = OrderTabCounts.fromJson(countsJson);
      } else {
        _userCounts.remove(sessionKey);
      }
      _ordersError = null;
    } on ApiException catch (e) {
      _ordersError = e.message;
      debugPrint('fetchOrdersRemote ApiException: ${e.message}');
    } catch (e) {
      _ordersError = 'Unable to load orders right now.';
      debugPrint('fetchOrdersRemote error: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();

      if (_queuedFetch && ApiClient.instance.hasToken) {
        _queuedFetch = false;
        unawaited(fetchOrdersRemote(tab));
      } else {
        _queuedFetch = false;
      }
    }
  }

  /// Fetch full order details by numeric serverId (includes status_history, hub info, courier, OTP, dispute, review).
  Future<OrderItemModel> fetchOrderDetailRemote(int serverId) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        message: 'Please sign in to view order details.',
        statusCode: 401,
      );
    }
    if (serverId <= 0) {
      throw const ApiException(
        message: 'Invalid order identifier.',
        statusCode: 400,
      );
    }

    final res = await ApiClient.instance.get(ApiConstants.orderDetail(serverId));
    final payload = res.data;
    if (payload is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Unexpected server response when loading order details.',
        statusCode: 500,
      );
    }
    final updated = OrderItemModel.fromApiJson(payload);
    _upsertOrder(updated);
    notifyListeners();
    return updated;
  }

  /// Place order on Laravel backend API (`POST /api/mobile/v1/buyer/checkout`).
  Future<List<Map<String, dynamic>>> placeOrderRemote({
    required int addressId,
    String paymentMethod = 'cod',
    String? idempotencyKey,
    List<int>? cartItemIds,
    int? platformVoucherId,
    int? shippingVoucherId,
    int? storeVoucherId,
  }) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        message: 'Please sign in to place an order.',
        statusCode: 401,
      );
    }

    final key = (idempotencyKey != null && idempotencyKey.trim().isNotEmpty)
        ? idempotencyKey.trim()
        : 'chk_${DateTime.now().millisecondsSinceEpoch}';

    final res = await ApiClient.instance.post(
      ApiConstants.buyerCheckout,
      idempotencyKey: key,
      body: <String, dynamic>{
        'address_id': addressId,
        'shipping_address_id': addressId,
        'payment_method': paymentMethod,
        if (cartItemIds != null && cartItemIds.isNotEmpty)
          'cart_item_ids': cartItemIds,
        'platform_voucher_id': ?platformVoucherId,
        'shipping_voucher_id': ?shippingVoucherId,
        'store_voucher_id': ?storeVoucherId,
      },
    );

    final data = res['data'];
    if (data is Map && data['orders'] is List && (data['orders'] as List).isNotEmpty) {
      final orders = (data['orders'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      await fetchOrdersRemote();
      return orders;
    }

    throw const ApiException(
      message: 'Checkout did not return any created orders.',
      statusCode: 500,
    );
  }

  /// Cancel order via Laravel backend API FIRST (no unconfirmed optimistic mutation).
  Future<OrderItemModel> cancelOrderRemote(
    int serverId, {
    required String reason,
  }) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        message: 'Please sign in to cancel this order.',
        statusCode: 401,
      );
    }
    if (serverId <= 0) {
      throw const ApiException(
        message: 'Cannot cancel order: missing numeric server order ID.',
        statusCode: 400,
      );
    }

    final res = await ApiClient.instance.post(
      ApiConstants.buyerOrderCancel(serverId),
      body: {'reason': reason.trim()},
    );

    final payload = res.data;
    if (payload is Map<String, dynamic>) {
      final updated = OrderItemModel.fromApiJson(payload);
      _upsertOrder(updated);
      _userCounts.remove(_activeSessionKey);
      notifyListeners();
      unawaited(fetchOrdersRemote());
      return updated;
    }

    await fetchOrdersRemote();
    final refetched = findOrderByServerId(serverId);
    if (refetched != null) return refetched;
    throw const ApiException(
      message: 'Order cancelled, but response payload was incomplete.',
      statusCode: 500,
    );
  }

  /// Confirm delivery receipt via Laravel backend API FIRST.
  Future<OrderItemModel> confirmReceiptRemote(int serverId) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        message: 'Please sign in to confirm delivery.',
        statusCode: 401,
      );
    }
    if (serverId <= 0) {
      throw const ApiException(
        message: 'Cannot confirm receipt: missing numeric server order ID.',
        statusCode: 400,
      );
    }

    final res = await ApiClient.instance.post(
      ApiConstants.buyerOrderConfirmReceipt(serverId),
    );

    final payload = res.data;
    if (payload is Map<String, dynamic>) {
      final updated = OrderItemModel.fromApiJson(payload);
      _upsertOrder(updated);
      _userCounts.remove(_activeSessionKey);
      notifyListeners();
      unawaited(fetchOrdersRemote());
      return updated;
    }

    await fetchOrdersRemote();
    final refetched = findOrderByServerId(serverId);
    if (refetched != null) return refetched;
    throw const ApiException(
      message: 'Receipt confirmed, but response payload was incomplete.',
      statusCode: 500,
    );
  }

  /// Submit return/refund request with multipart evidence via Laravel backend API.
  Future<OrderItemModel> submitReturnRemote(
    int serverId, {
    required String reason,
    required String details,
    List<http.MultipartFile> mediaFiles = const [],
  }) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        message: 'Please sign in to submit a return request.',
        statusCode: 401,
      );
    }
    if (serverId <= 0) {
      throw const ApiException(
        message: 'Cannot request return: missing numeric server order ID.',
        statusCode: 400,
      );
    }

    final res = await ApiClient.instance.multipart(
      'POST',
      ApiConstants.buyerOrderReturn(serverId),
      fields: {
        'reason': reason.trim(),
        'details': details.trim(),
      },
      files: mediaFiles,
    );

    final rawData = res.data;
    final orderMap = (rawData is Map && rawData['order'] is Map<String, dynamic>)
        ? rawData['order'] as Map<String, dynamic>
        : (rawData is Map<String, dynamic> ? rawData : null);

    if (orderMap != null) {
      final updated = OrderItemModel.fromApiJson(orderMap);
      _upsertOrder(updated);
      _userCounts.remove(_activeSessionKey);
      notifyListeners();
      unawaited(fetchOrdersRemote());
      return updated;
    }

    await fetchOrdersRemote();
    final refetched = findOrderByServerId(serverId);
    if (refetched != null) return refetched;
    throw const ApiException(
      message: 'Return submitted, but order details were missing.',
      statusCode: 500,
    );
  }

  /// Submit or edit product review via Laravel backend API.
  Future<OrderItemModel> submitReviewRemote(
    int serverId, {
    required int rating,
    String? comment,
    List<http.MultipartFile> photoFiles = const [],
  }) async {
    if (!ApiClient.instance.hasToken) {
      throw const ApiException(
        message: 'Please sign in to submit a review.',
        statusCode: 401,
      );
    }
    if (serverId <= 0) {
      throw const ApiException(
        message: 'Cannot submit review: missing numeric server order ID.',
        statusCode: 400,
      );
    }

    final fields = <String, String>{
      'rating': rating.toString(),
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    };

    final ApiResponse<dynamic> res;
    if (photoFiles.isNotEmpty) {
      res = await ApiClient.instance.multipart(
        'POST',
        ApiConstants.buyerOrderReview(serverId),
        fields: fields,
        files: photoFiles,
      );
    } else {
      res = await ApiClient.instance.post(
        ApiConstants.buyerOrderReview(serverId),
        body: {
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );
    }

    final rawData = res.data;
    final orderMap = (rawData is Map && rawData['order'] is Map<String, dynamic>)
        ? rawData['order'] as Map<String, dynamic>
        : (rawData is Map<String, dynamic> ? rawData : null);

    if (orderMap != null) {
      final updated = OrderItemModel.fromApiJson(orderMap);
      _upsertOrder(updated);
      notifyListeners();
      unawaited(fetchOrdersRemote());
      return updated;
    }

    await fetchOrdersRemote();
    final refetched = findOrderByServerId(serverId);
    if (refetched != null) return refetched;
    throw const ApiException(
      message: 'Review submitted, but order details were missing.',
      statusCode: 500,
    );
  }

  void _upsertOrder(OrderItemModel order) {
    final key = _activeSessionKey;
    if (key == null) return;
    final active = _userActiveOrders.putIfAbsent(key, () => []);
    final past = _userPastOrders.putIfAbsent(key, () => []);

    bool matches(OrderItemModel existing) =>
        (order.serverId > 0 && existing.serverId == order.serverId) ||
        (order.serverId == 0 && existing.orderId == order.orderId);

    final oldActiveIdx = active.indexWhere(matches);
    final oldPastIdx = past.indexWhere(matches);

    active.removeWhere(matches);
    past.removeWhere(matches);

    if (order.isPastOrder) {
      final insertIdx = (oldPastIdx >= 0 && oldPastIdx <= past.length)
          ? oldPastIdx
          : 0;
      past.insert(insertIdx, order);
    } else {
      final insertIdx = (oldActiveIdx >= 0 && oldActiveIdx <= active.length)
          ? oldActiveIdx
          : 0;
      active.insert(insertIdx, order);
    }
  }

  void clearActiveUserOrders() {
    final key = _activeSessionKey;
    if (key == null) return;
    _userActiveOrders.remove(key);
    _userPastOrders.remove(key);
    _userCounts.remove(key);
    _ordersError = null;
    notifyListeners();
  }

  void clearAllOrders() {
    _userActiveOrders.clear();
    _userPastOrders.clear();
    _userCounts.clear();
    _ordersError = null;
    _isLoading = false;
    notifyListeners();
  }

  // =========================================================================
  // Phase-2 disabled compatibility no-ops (retained per Rule 4 so unreachable
  // Phase-2 screens still compile without deleting files).
  // =========================================================================

  static String normalizeRemoteStatus(String raw) => raw.trim().toLowerCase();

  Map<String, double>? getLiveRiderLocation(String orderId) => null;

  void updateLiveRiderLocation(Map<String, dynamic> payload) {}

  void requestRiderLocation(String orderId) {}

  double getLiveCourierRating(String courierName, {double fallback = 0.0}) =>
      fallback;

  bool syncOrderFromRemoteStatus(
    String orderId,
    String rawStatus, {
    String? courierName,
    double? courierRating,
    bool? riderAccepted,
    Map<String, dynamic>? rowData,
  }) =>
      false;

  Future<void> updateOrderDeliveryPin({
    required String orderId,
    required double lat,
    required double lng,
    required String address,
  }) async {}

  /// Deprecated compatibility helper; B5 rewires RateProductPage directly to submitReviewRemote.
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
    final order = findOrderById(orderId);
    if (order == null || order.serverId <= 0) {
      throw const ApiException(
        message: 'Cannot submit review: numeric order ID unavailable.',
        statusCode: 400,
      );
    }
    await submitReviewRemote(
      order.serverId,
      rating: productRating > 0 ? productRating : 5,
      comment: productReview,
    );
    return 0.0;
  }
}
