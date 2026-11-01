import 'package:flutter/material.dart';

enum CourierParcelStatus {
  sorting, // In Hub Sorting
  assigned, // Assigned to Courier/Rider
  inTransit, // Out for Delivery
  delivered, // Successfully Delivered
  returned, // Return to Hub / Failed
}

extension CourierParcelStatusExt on CourierParcelStatus {
  String get label {
    switch (this) {
      case CourierParcelStatus.sorting:
        return 'In Hub Sorting';
      case CourierParcelStatus.assigned:
        return 'Assigned to Rider';
      case CourierParcelStatus.inTransit:
        return 'Out for Delivery';
      case CourierParcelStatus.delivered:
        return 'Delivered';
      case CourierParcelStatus.returned:
        return 'Return to Hub';
    }
  }

  Color get color {
    switch (this) {
      case CourierParcelStatus.sorting:
        return const Color(0xFFF59E0B); // Amber Orange
      case CourierParcelStatus.assigned:
        return const Color(0xFF8B5CF6); // Purple
      case CourierParcelStatus.inTransit:
        return const Color(0xFF0066FF); // Electric Blue
      case CourierParcelStatus.delivered:
        return const Color(0xFF10B981); // Emerald Green
      case CourierParcelStatus.returned:
        return const Color(0xFFEF4444); // Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CourierParcelStatus.sorting:
        return const Color(0xFFFEF3C7);
      case CourierParcelStatus.assigned:
        return const Color(0xFFF3E8FF);
      case CourierParcelStatus.inTransit:
        return const Color(0xFFE0F2FE);
      case CourierParcelStatus.delivered:
        return const Color(0xFFDCFCE7);
      case CourierParcelStatus.returned:
        return const Color(0xFFFEE2E2);
    }
  }

  IconData get icon {
    switch (this) {
      case CourierParcelStatus.sorting:
        return Icons.inventory_2_outlined;
      case CourierParcelStatus.assigned:
        return Icons.assignment_ind_outlined;
      case CourierParcelStatus.inTransit:
        return Icons.two_wheeler_rounded;
      case CourierParcelStatus.delivered:
        return Icons.check_circle_outline_rounded;
      case CourierParcelStatus.returned:
        return Icons.replay_rounded;
    }
  }
}

class CourierParcel {
  final String id; // Tracking number (e.g. NX-PH-98214309)
  final String merchantName;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String city;
  final String itemsDescription;
  final double weightKg;
  final double amountCod;
  final bool isCod;
  CourierParcelStatus status;
  String? assignedRiderId;
  String? assignedRiderName;
  String? assignedTripId;
  String? waybillNumber;
  String? currentHubId;
  String? transitRoute;
  bool isLoaded;
  final DateTime createdAt;
  DateTime? dispatchedAt;
  DateTime? deliveredAt;
  final String? notes;
  double? customerLat;
  double? customerLng;

  CourierParcel({
    required this.id,
    required this.merchantName,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.city,
    required this.itemsDescription,
    required this.weightKg,
    required this.amountCod,
    this.isCod = true,
    this.status = CourierParcelStatus.sorting,
    this.assignedRiderId,
    this.assignedRiderName,
    this.assignedTripId,
    this.waybillNumber,
    this.currentHubId = 'HUB-QC',
    this.transitRoute,
    this.isLoaded = false,
    required this.createdAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.notes,
    this.customerLat,
    this.customerLng,
  });

  bool get isAssigned => assignedRiderId != null && assignedRiderId!.isNotEmpty;
  bool get isAtHub =>
      status == CourierParcelStatus.sorting &&
      (assignedTripId == null || assignedTripId!.isEmpty);
}

class CourierRider {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehicleModel;
  final String plateNumber;
  final String assignedZone;
  double rating;
  int assignedParcelsCount;
  int deliveredParcelsCount;
  bool isOnline;
  bool isAvailable;
  String currentLocation;
  DateTime? checklistCompletedAt;
  String? preTripIssue;
  String? preTripNote;
  DateTime? lastHeartbeat;
  bool isLocationUnknown;

  CourierRider({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleModel,
    required this.plateNumber,
    required this.assignedZone,
    this.rating = 4.9,
    this.assignedParcelsCount = 0,
    this.deliveredParcelsCount = 0,
    this.isOnline = true,
    this.isAvailable = true,
    this.currentLocation = 'HUB-QC',
    this.checklistCompletedAt,
    this.preTripIssue,
    this.preTripNote,
    this.lastHeartbeat,
    this.isLocationUnknown = false,
  });

  String get workloadSummary =>
      '$deliveredParcelsCount / ${assignedParcelsCount + deliveredParcelsCount} delivered';
}

class CourierHub {
  final String id;
  final String name;
  final String address;
  final String region;
  final String managerName;
  final String contactPhone;

  const CourierHub({
    required this.id,
    required this.name,
    required this.address,
    required this.region,
    required this.managerName,
    required this.contactPhone,
  });
}

enum CourierTripStatus {
  unassigned, // Trip created in Logistics 1, waiting for courier assignment
  assigned, // Assigned to Courier (Status Assigned in COU-TRIP-001)
  accepted, // Accepted by Courier (Start Loading available in COU-TRIP-002)
  loading, // Parcels being loaded at origin hub
  inTransit, // En route to destination hub
  completed, // Successfully arrived and handed over
  declined, // Declined by courier with a reason
}

extension CourierTripStatusExt on CourierTripStatus {
  String get label {
    switch (this) {
      case CourierTripStatus.unassigned:
        return 'Unassigned';
      case CourierTripStatus.assigned:
        return 'Assigned';
      case CourierTripStatus.accepted:
        return 'Accepted';
      case CourierTripStatus.loading:
        return 'Loading';
      case CourierTripStatus.inTransit:
        return 'In Transit';
      case CourierTripStatus.completed:
        return 'Completed';
      case CourierTripStatus.declined:
        return 'Declined';
    }
  }

  Color get color {
    switch (this) {
      case CourierTripStatus.unassigned:
        return const Color(0xFF94A3B8);
      case CourierTripStatus.assigned:
        return const Color(0xFFF59E0B);
      case CourierTripStatus.accepted:
        return const Color(0xFF0066FF);
      case CourierTripStatus.loading:
        return const Color(0xFF8B5CF6);
      case CourierTripStatus.inTransit:
        return const Color(0xFF0284C7);
      case CourierTripStatus.completed:
        return const Color(0xFF10B981);
      case CourierTripStatus.declined:
        return const Color(0xFFEF4444);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CourierTripStatus.unassigned:
        return const Color(0xFFF1F5F9);
      case CourierTripStatus.assigned:
        return const Color(0xFFFEF3C7);
      case CourierTripStatus.accepted:
        return const Color(0xFFE0F2FE);
      case CourierTripStatus.loading:
        return const Color(0xFFF3E8FF);
      case CourierTripStatus.inTransit:
        return const Color(0xFFE0F2FE);
      case CourierTripStatus.completed:
        return const Color(0xFFDCFCE7);
      case CourierTripStatus.declined:
        return const Color(0xFFFEE2E2);
    }
  }
}

class CourierTrip {
  final String id; // e.g. TRIP-1, TRIP-2
  final String companyId; // e.g. LOGISTICS-1 (COU-TRIP-006 protection)
  final String originHubId; // e.g. HUB-QC
  final String originHubName;
  final String originAddress;
  final double originLatitude; // e.g. 14.6507 for HUB-QC
  final double originLongitude; // e.g. 121.0365
  final String destinationHubId; // e.g. HUB-PSG
  final String destinationHubName;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final int _initialParcelsCount;
  final double weightKg;
  final DateTime scheduledDeparture;
  final double payAmount; // e.g. 1000.00
  CourierTripStatus status;
  String? assignedCourierId;
  String? assignedCourierName;
  DateTime? acceptedAt;
  DateTime? departedAt;
  String? declinedReason;
  String? sealNumber;
  int version; // Optimistic locking for COU-TRIP-005

  final List<String> parcelIds;
  final Set<String> loadedParcelIds;
  final List<String> pendingOfflineScans;

  CourierTrip({
    required this.id,
    this.companyId = 'LOGISTICS-1',
    required this.originHubId,
    required this.originHubName,
    required this.originAddress,
    this.originLatitude = 14.6507,
    this.originLongitude = 121.0365,
    required this.destinationHubId,
    required this.destinationHubName,
    required this.destinationAddress,
    this.destinationLatitude = 14.5738,
    this.destinationLongitude = 121.0594,
    required int parcelsCount,
    required this.weightKg,
    required this.scheduledDeparture,
    required this.payAmount,
    this.status = CourierTripStatus.unassigned,
    this.assignedCourierId,
    this.assignedCourierName,
    this.acceptedAt,
    this.departedAt,
    this.declinedReason,
    this.sealNumber,
    this.version = 1,
    List<String>? parcelIds,
    Set<String>? loadedParcelIds,
    List<String>? pendingOfflineScans,
  }) : _initialParcelsCount = parcelsCount,
       parcelIds = parcelIds ?? [],
       loadedParcelIds = loadedParcelIds ?? {},
       pendingOfflineScans = pendingOfflineScans ?? [];

  int get parcelsCount =>
      parcelIds.isNotEmpty ? parcelIds.length : _initialParcelsCount;
  int get loadedCount => loadedParcelIds.length;
  bool get isFullyLoaded => parcelsCount > 0 && loadedCount >= parcelsCount;

  bool get isAssigned =>
      assignedCourierId != null && assignedCourierId!.isNotEmpty;
  bool get isActive =>
      status == CourierTripStatus.accepted ||
      status == CourierTripStatus.loading ||
      status == CourierTripStatus.inTransit;
}
