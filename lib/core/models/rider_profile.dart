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
  final String vehicleReverificationStatus; // 'Validated', 'Pending Re-verification'

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
    required this.vehicleModel,
    this.vehicleSub = 'Liquid Cooled • 2023 Edition',
    required this.plateNumber,
    required this.assignedHub,
    this.inspectionStatus = 'Pasig Hub Validated',
    this.inspectionExpiry = 'Expires Dec 2025',
    this.thermalBag = 'Verified 65L Heavy-Duty',
    this.thermalBagSub = 'Cold-Chain Approved',
    this.maintenanceSchedule = 'In 1,240 km',
    required this.walletBalance,
    required this.todayEarnings,
    required this.todayDeliveries,
    required this.onlineHoursToday,
    required this.isOnline,
    this.company = 'Bilis Hatid Express Inc.',
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
    };
  }

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: json['id'] as String? ?? 'NX-RD-001',
      name: json['name'] as String? ?? 'Pedro Jose Garcia',
      phone: json['phone'] as String? ?? '+63 918 555 0192',
      email: json['email'] as String? ?? 'pedro.garcia@bilishatid.ph',
      avatarUrl: json['avatarUrl'] as String? ??
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.98,
      totalDeliveries: json['totalDeliveries'] as int? ?? 1248,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 99.4,
      tier: json['tier'] as String? ?? 'Tier 1 Rider',
      vehicleType: json['vehicleType'] as String? ?? 'Motorcycle',
      vehicleModel: json['vehicleModel'] as String? ?? 'Honda Click 150i',
      vehicleSub:
          json['vehicleSub'] as String? ?? 'Liquid Cooled • 2023 Edition',
      plateNumber: json['plateNumber'] as String? ?? '123ABC',
      assignedHub: json['assignedHub'] as String? ??
          'Pasig Central Sorting Hub (Cluster 4B)',
      inspectionStatus:
          json['inspectionStatus'] as String? ?? 'Pasig Hub Validated',
      inspectionExpiry:
          json['inspectionExpiry'] as String? ?? 'Expires Dec 2025',
      thermalBag:
          json['thermalBag'] as String? ?? 'Verified 65L Heavy-Duty',
      thermalBagSub:
          json['thermalBagSub'] as String? ?? 'Cold-Chain Approved',
      maintenanceSchedule:
          json['maintenanceSchedule'] as String? ?? 'In 1,240 km',
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 2840.50,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 1420.00,
      todayDeliveries: json['todayDeliveries'] as int? ?? 9,
      onlineHoursToday:
          (json['onlineHoursToday'] as num?)?.toDouble() ?? 5.2,
      isOnline: json['isOnline'] as bool? ?? true,
      company: json['company'] as String? ?? 'Bilis Hatid Express Inc.',
      accountStatus: json['accountStatus'] as String? ?? 'Active',
      licenseNumber: json['licenseNumber'] as String? ?? 'N01-23-456789',
      licenseExpiry: json['licenseExpiry'] as String? ?? '03/22/2030',
      licenseDocName:
          json['licenseDocName'] as String? ?? 'license_front.jpg',
      orCrDocName: json['orCrDocName'] as String? ?? 'or_cr_receipt.pdf',
      vehicleReverificationStatus:
          json['vehicleReverificationStatus'] as String? ?? 'Validated',
      preferredNavigation:
          json['preferredNavigation'] as String? ?? 'Google',
      audioPromptsEnabled: json['audioPromptsEnabled'] as bool? ?? true,
      waybillAiActive: json['waybillAiActive'] as bool? ?? true,
      dialingMode: json['dialingMode'] as String? ?? 'VoIP Masked',
    );
  }
}
