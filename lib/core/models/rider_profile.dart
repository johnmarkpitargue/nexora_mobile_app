class RiderReview {
  final String orderId;
  final String customerName;
  final int driverRating;
  final int deliveryRating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  const RiderReview({
    required this.orderId,
    required this.customerName,
    required this.driverRating,
    required this.deliveryRating,
    this.comment = '',
    this.tags = const [],
    required this.createdAt,
  });

  factory RiderReview.fromApiJson(Map<String, dynamic> json) {
    final rating = (json['rating'] as num?)?.toInt() ?? 5;
    return RiderReview(
      orderId: (json['order_number'] ?? json['order_id'] ?? '').toString(),
      customerName: (json['buyer_name'] ?? json['customer_name'] ?? 'Customer')
          .toString(),
      driverRating: rating,
      deliveryRating: rating,
      comment: (json['comment'] ?? '').toString(),
      tags: const [],
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  double get averageScore => (driverRating * 0.7) + (deliveryRating * 0.3);
}

class RiderProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String avatarUrl;
  final double rating;
  final int totalDeliveries;
  final double completionRate;
  final String tier;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleSub;
  final String plateNumber;
  final String assignedHub;
  final String inspectionStatus;
  final String inspectionExpiry;
  final String thermalBag;
  final String thermalBagSub;
  final String maintenanceSchedule;
  final double walletBalance;
  final double todayEarnings;
  final int todayDeliveries;
  final double onlineHoursToday;
  final bool isOnline;

  // New fields for verification & company compliance
  final String company;
  final String accountStatus; // 'Active', 'Suspended', 'Pending Review'
  final String licenseNumber;
  final String licenseExpiry;
  final String licenseDocName;
  final String orCrDocName;
  final String
  vehicleReverificationStatus; // 'Validated', 'Pending Re-verification'
  final int reviewsCount;

  // Tools & Hardware settings
  final String preferredNavigation; // 'Google Maps'
  final bool audioPromptsEnabled;
  final bool waybillAiActive;
  final String dialingMode; // 'VoIP Masked'

  const RiderProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.rating,
    required this.totalDeliveries,
    required this.completionRate,
    this.tier = 'Tier 1 Rider',
    required this.vehicleType,
    this.vehicleModel = '',
    this.vehicleSub = '',
    required this.plateNumber,
    required this.assignedHub,
    this.inspectionStatus = 'Hub Validated',
    this.inspectionExpiry = 'Expires Dec 2026',
    this.thermalBag = 'Verified 65L Heavy-Duty',
    this.thermalBagSub = 'Cold-Chain Approved',
    this.maintenanceSchedule = 'In 1,240 km',
    required this.walletBalance,
    required this.todayEarnings,
    required this.todayDeliveries,
    required this.onlineHoursToday,
    required this.isOnline,
    this.company = 'Logistics Partner',
    this.accountStatus = 'Active',
    this.licenseNumber = 'N01-23-456789',
    this.licenseExpiry = '03/22/2030',
    this.licenseDocName = 'license_front.jpg',
    this.orCrDocName = 'or_cr_receipt.pdf',
    this.vehicleReverificationStatus = 'Validated',
    this.preferredNavigation = 'Google',
    this.audioPromptsEnabled = true,
    this.waybillAiActive = true,
    this.dialingMode = 'VoIP Masked',
    this.reviewsCount = 0,
  });

  RiderProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    double? rating,
    int? totalDeliveries,
    double? completionRate,
    String? tier,
    String? vehicleType,
    String? vehicleModel,
    String? vehicleSub,
    String? plateNumber,
    String? assignedHub,
    String? inspectionStatus,
    String? inspectionExpiry,
    String? thermalBag,
    String? thermalBagSub,
    String? maintenanceSchedule,
    double? walletBalance,
    double? todayEarnings,
    int? todayDeliveries,
    double? onlineHoursToday,
    bool? isOnline,
    String? company,
    String? accountStatus,
    String? licenseNumber,
    String? licenseExpiry,
    String? licenseDocName,
    String? orCrDocName,
    String? vehicleReverificationStatus,
    String? preferredNavigation,
    bool? audioPromptsEnabled,
    bool? waybillAiActive,
    String? dialingMode,
    int? reviewsCount,
  }) {
    return RiderProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completionRate: completionRate ?? this.completionRate,
      tier: tier ?? this.tier,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleSub: vehicleSub ?? this.vehicleSub,
      plateNumber: plateNumber ?? this.plateNumber,
      assignedHub: assignedHub ?? this.assignedHub,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      inspectionExpiry: inspectionExpiry ?? this.inspectionExpiry,
      thermalBag: thermalBag ?? this.thermalBag,
      thermalBagSub: thermalBagSub ?? this.thermalBagSub,
      maintenanceSchedule: maintenanceSchedule ?? this.maintenanceSchedule,
      walletBalance: walletBalance ?? this.walletBalance,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      onlineHoursToday: onlineHoursToday ?? this.onlineHoursToday,
      isOnline: isOnline ?? this.isOnline,
      company: company ?? this.company,
      accountStatus: accountStatus ?? this.accountStatus,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      licenseDocName: licenseDocName ?? this.licenseDocName,
      orCrDocName: orCrDocName ?? this.orCrDocName,
      vehicleReverificationStatus:
          vehicleReverificationStatus ?? this.vehicleReverificationStatus,
      preferredNavigation: preferredNavigation ?? this.preferredNavigation,
      audioPromptsEnabled: audioPromptsEnabled ?? this.audioPromptsEnabled,
      waybillAiActive: waybillAiActive ?? this.waybillAiActive,
      dialingMode: dialingMode ?? this.dialingMode,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'completionRate': completionRate,
      'tier': tier,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleSub': vehicleSub,
      'plateNumber': plateNumber,
      'assignedHub': assignedHub,
      'inspectionStatus': inspectionStatus,
      'inspectionExpiry': inspectionExpiry,
      'thermalBag': thermalBag,
      'thermalBagSub': thermalBagSub,
      'maintenanceSchedule': maintenanceSchedule,
      'walletBalance': walletBalance,
      'todayEarnings': todayEarnings,
      'todayDeliveries': todayDeliveries,
      'onlineHoursToday': onlineHoursToday,
      'isOnline': isOnline,
      'company': company,
      'accountStatus': accountStatus,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry,
      'licenseDocName': licenseDocName,
      'orCrDocName': orCrDocName,
      'vehicleReverificationStatus': vehicleReverificationStatus,
      'preferredNavigation': preferredNavigation,
      'audioPromptsEnabled': audioPromptsEnabled,
      'waybillAiActive': waybillAiActive,
      'dialingMode': dialingMode,
      'reviewsCount': reviewsCount,
    };
  }

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: json['id'] as String? ?? 'NX-RD-001',
      name: json['name'] as String? ?? 'Rider',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalDeliveries: json['totalDeliveries'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 100.0,
      tier: json['tier'] as String? ?? 'Standard Rider',
      vehicleType: json['vehicleType'] as String? ?? 'Motorcycle',
      vehicleModel: json['vehicleModel'] as String? ?? '',
      vehicleSub: json['vehicleSub'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      assignedHub: json['assignedHub'] as String? ?? '',
      inspectionStatus: json['inspectionStatus'] as String? ?? 'Hub Validated',
      inspectionExpiry:
          json['inspectionExpiry'] as String? ?? 'Expires Dec 2026',
      thermalBag: json['thermalBag'] as String? ?? 'Verified 65L Heavy-Duty',
      thermalBagSub: json['thermalBagSub'] as String? ?? 'Cold-Chain Approved',
      maintenanceSchedule:
          json['maintenanceSchedule'] as String? ?? 'In 1,240 km',
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      todayDeliveries: json['todayDeliveries'] as int? ?? 0,
      onlineHoursToday: (json['onlineHoursToday'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['isOnline'] as bool? ?? false,
      company: json['company'] as String? ?? 'Logistics Partner',
      accountStatus: json['accountStatus'] as String? ?? 'Active',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      licenseExpiry: json['licenseExpiry'] as String? ?? '',
      licenseDocName: json['licenseDocName'] as String? ?? 'license_front.jpg',
      orCrDocName: json['orCrDocName'] as String? ?? 'or_cr_receipt.pdf',
      vehicleReverificationStatus:
          json['vehicleReverificationStatus'] as String? ?? 'Validated',
      preferredNavigation: json['preferredNavigation'] as String? ?? 'Google',
      audioPromptsEnabled: json['audioPromptsEnabled'] as bool? ?? true,
      waybillAiActive: json['waybillAiActive'] as bool? ?? true,
      dialingMode: json['dialingMode'] as String? ?? 'VoIP Masked',
      reviewsCount: json['reviewsCount'] as int? ?? 0,
    );
  }
}
