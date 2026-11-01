class CourierProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String avatarUrl;
  final double rating;
  final int totalDeliveries;
  final String company;
  final String homeHub;
  final String accountStatus; // 'Active', 'Suspended'
  final bool isOnDuty;

  // Vehicle Details
  final String vehicleType;
  final String plateNumber;
  final int loadCapacityKg;
  final String vehicleReverificationStatus; // 'Validated', 'Pending Re-verification'
  final String? flaggedNotes;

  // License Details
  final String licenseNumber;
  final String licenseType;
  final String licenseExpiry;

  // Documents
  final String licenseDocName;
  final String orCrDocName;
  final String nbiClearanceDocName;

  const CourierProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.rating = 4.95,
    this.totalDeliveries = 1420,
    this.company = 'Bilis Hatid Express Inc.',
    this.homeHub = 'HUB-QC',
    this.accountStatus = 'Active',
    this.isOnDuty = false,
    this.vehicleType = '4-Wheeler Closed Van Truck',
    this.plateNumber = 'NAB4521',
    this.loadCapacityKg = 3000,
    this.vehicleReverificationStatus = 'Validated',
    this.flaggedNotes,
    this.licenseNumber = 'N02-15-345678',
    this.licenseType = 'Professional; codes B, B2, C',
    this.licenseExpiry = '07/15/2029',
    this.licenseDocName = 'driver_license_ernesto.jpg',
    this.orCrDocName = 'truck_or_cr.pdf',
    this.nbiClearanceDocName = 'nbi_clearance_ernesto.pdf',
  });

  CourierProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    double? rating,
    int? totalDeliveries,
    String? company,
    String? homeHub,
    String? accountStatus,
    bool? isOnDuty,
    String? vehicleType,
    String? plateNumber,
    int? loadCapacityKg,
    String? vehicleReverificationStatus,
    String? flaggedNotes,
    String? licenseNumber,
    String? licenseType,
    String? licenseExpiry,
    String? licenseDocName,
    String? orCrDocName,
    String? nbiClearanceDocName,
  }) {
    return CourierProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      company: company ?? this.company,
      homeHub: homeHub ?? this.homeHub,
      accountStatus: accountStatus ?? this.accountStatus,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      loadCapacityKg: loadCapacityKg ?? this.loadCapacityKg,
      vehicleReverificationStatus:
          vehicleReverificationStatus ?? this.vehicleReverificationStatus,
      flaggedNotes: flaggedNotes ?? this.flaggedNotes,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseType: licenseType ?? this.licenseType,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      licenseDocName: licenseDocName ?? this.licenseDocName,
      orCrDocName: orCrDocName ?? this.orCrDocName,
      nbiClearanceDocName: nbiClearanceDocName ?? this.nbiClearanceDocName,
    );
  }
}
