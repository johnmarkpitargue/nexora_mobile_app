import 'package:flutter/foundation.dart';
import '../models/rider_profile.dart';

class OperationResult {
  final bool success;
  final String message;

  const OperationResult({required this.success, required this.message});

  factory OperationResult.ok([String message = 'Success']) =>
      OperationResult(success: true, message: message);

  factory OperationResult.fail(String message) =>
      OperationResult(success: false, message: message);
}

class RiderService extends ChangeNotifier {
  static final RiderService instance = RiderService._();
  RiderService._() {
    _profile = _rider1;
  }

  // Pre-configured Test Fixtures
  static const RiderProfile _rider1 = RiderProfile(
    id: 'NX-RD-001',
    name: 'Pedro Jose Garcia',
    phone: '+63 918 555 0192',
    email: 'pedro.garcia@bilishatid.ph',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    rating: 4.98,
    totalDeliveries: 1248,
    completionRate: 99.4,
    tier: 'Tier 1 Rider',
    vehicleType: 'Motorcycle',
    vehicleModel: 'Honda Click 150i',
    vehicleSub: 'Liquid Cooled • 2023 Edition',
    plateNumber: '123ABC',
    assignedHub: 'Pasig Central Sorting Hub (Cluster 4B)',
    company: 'Bilis Hatid Express Inc.',
    accountStatus: 'Active',
    licenseNumber: 'N01-23-456789',
    licenseExpiry: '03/22/2030',
    licenseDocName: 'driver_license_front.jpg',
    orCrDocName: 'or_cr_receipt.pdf',
    inspectionStatus: 'Pasig Hub Validated',
    inspectionExpiry: 'Expires Dec 2025',
    vehicleReverificationStatus: 'Validated',
    thermalBag: 'Verified 65L Heavy-Duty',
    thermalBagSub: 'Cold-Chain Approved',
    maintenanceSchedule: 'In 1,240 km',
    walletBalance: 3035.50,
    todayEarnings: 1420.00,
    todayDeliveries: 9,
    onlineHoursToday: 5.2,
    isOnline: true,
    preferredNavigation: 'Google',
    audioPromptsEnabled: true,
    waybillAiActive: true,
    dialingMode: 'VoIP Masked',
  );

  static const RiderProfile _rider2 = RiderProfile(
    id: 'NX-RD-002',
    name: 'Juan Carlos Ramos',
    phone: '+63 920 888 1234',
    email: 'jc.ramos@bilishatid.ph',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    rating: 4.85,
    totalDeliveries: 840,
    completionRate: 98.2,
    tier: 'Tier 2 Rider',
    vehicleType: 'Motorcycle',
    vehicleModel: 'Yamaha Aerox 155',
    vehicleSub: 'Sport Scooter • 2022 Edition',
    plateNumber: '456DEF',
    assignedHub: 'Makati Central Hub #4',
    company: 'Bilis Hatid Express Inc.',
    accountStatus: 'Active',
    licenseNumber: 'N02-21-987654',
    licenseExpiry: '08/15/2029',
    licenseDocName: 'license_front_jc.jpg',
    orCrDocName: 'or_cr_aerox.pdf',
    inspectionStatus: 'Makati Hub Validated',
    inspectionExpiry: 'Expires Nov 2025',
    vehicleReverificationStatus: 'Validated',
    walletBalance: 1450.00,
    todayEarnings: 680.00,
    todayDeliveries: 4,
    onlineHoursToday: 3.1,
    isOnline: false,
  );

  static const RiderProfile _rider3Suspended = RiderProfile(
    id: 'NX-RD-003',
    name: 'Alex Santos (Suspended)',
    phone: '+63 917 444 9900',
    email: 'alex.santos@bilishatid.ph',
    avatarUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
    rating: 4.12,
    totalDeliveries: 312,
    completionRate: 88.5,
    tier: 'Probationary',
    vehicleType: 'Motorcycle',
    vehicleModel: 'Suzuki Smash 115',
    vehicleSub: 'Air Cooled Underbone',
    plateNumber: '345XYZ',
    assignedHub: 'Pasig Central Sorting Hub (Cluster 4B)',
    company: 'Bilis Hatid Express Inc.',
    accountStatus: 'Suspended',
    licenseNumber: 'N03-19-112233',
    licenseExpiry: '11/10/2027',
    licenseDocName: 'license_front_alex.jpg',
    orCrDocName: 'or_cr_smash.pdf',
    inspectionStatus: 'Account Under Review',
    inspectionExpiry: 'Suspended by Hub Logistics',
    vehicleReverificationStatus: 'Flagged',
    walletBalance: 120.00,
    todayEarnings: 0.0,
    todayDeliveries: 0,
    onlineHoursToday: 0.0,
    isOnline: false,
  );

  late RiderProfile _profile;

  // Registered Plates Database (Simulation for Equivalence Partitioning Test RID-PROF-003)
  final Set<String> _registeredPlates = {
    'ABC1234',
    'XYZ9876',
    '456DEF',
  };

  RiderProfile get profile => _profile;
  RiderProfile get currentRider => _profile;

  int? _acceptedOrdersCountVal;
  int? _declinedOrdersCountVal;
  int get _acceptedOrdersCount => _acceptedOrdersCountVal ??= 48;
  set _acceptedOrdersCount(int v) => _acceptedOrdersCountVal = v;
  int get _declinedOrdersCount => _declinedOrdersCountVal ??= 1;
  set _declinedOrdersCount(int v) => _declinedOrdersCountVal = v;

  List<RiderReview>? _reviewsList;
  List<RiderReview> get _reviews => _reviewsList ??= [
    RiderReview(
      orderId: 'NX-8819-ORD',
      customerName: 'Elena Gilbert',
      driverRating: 5,
      deliveryRating: 5,
      comment: 'Very polite rider and delivered ahead of schedule!',
      tags: const ['Polite & Friendly', 'Fast Delivery', 'Handled with Care'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    RiderReview(
      orderId: 'NX-8641-ORD',
      customerName: 'David Lee',
      driverRating: 5,
      deliveryRating: 5,
      comment: 'Followed condo drop-off instructions accurately.',
      tags: const ['Followed Instructions', 'Good Communication'],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  List<RiderReview> get reviews => List.unmodifiable(_reviews);

  void recordOrderAccepted() {
    _acceptedOrdersCount++;
    final total = _acceptedOrdersCount + _declinedOrdersCount;
    final newRate = double.parse((( _acceptedOrdersCount / total) * 100.0).clamp(0.0, 100.0).toStringAsFixed(1));
    _profile = _profile.copyWith(completionRate: newRate);
    notifyListeners();
  }

  void recordOrderDeclined() {
    _declinedOrdersCount++;
    final total = _acceptedOrdersCount + _declinedOrdersCount;
    final newRate = double.parse(((_acceptedOrdersCount / total) * 100.0).clamp(0.0, 100.0).toStringAsFixed(1));
    _profile = _profile.copyWith(completionRate: newRate);
    notifyListeners();
  }

  double applyBuyerRating({
    required String orderId,
    required int driverRating,
    required int deliveryRating,
    double? newCourierRating,
    String? comment,
    List<String>? tags,
    String? customerName,
  }) {
    final cleanId = orderId.replaceAll('#', '').trim();
    final combinedScore = (driverRating * 0.7) + (deliveryRating * 0.3);
    final updatedRating = newCourierRating ??
        double.parse(
          (((_profile.rating * 3.0) + combinedScore) / 4.0)
              .clamp(1.0, 5.0)
              .toStringAsFixed(2),
        );

    _profile = _profile.copyWith(rating: updatedRating);

    // Avoid duplicate entry for the same orderId, or replace existing
    _reviews.removeWhere((r) => r.orderId.replaceAll('#', '').trim() == cleanId);
    _reviews.insert(
      0,
      RiderReview(
        orderId: cleanId.isEmpty ? 'NX-ORDER' : cleanId,
        customerName: (customerName != null && customerName.isNotEmpty)
            ? customerName
            : 'Verified Buyer',
        driverRating: driverRating,
        deliveryRating: deliveryRating,
        comment: comment ?? '',
        tags: tags ?? const [],
        createdAt: DateTime.now(),
      ),
    );

    notifyListeners();
    return updatedRating;
  }

  // Test Switcher: Toggle between test fixtures (Rider 1, Rider 2, Rider 3)
  void switchRider(String riderId) {
    if (riderId == 'NX-RD-001') {
      _profile = _rider1;
    } else if (riderId == 'NX-RD-002') {
      _profile = _rider2;
    } else if (riderId == 'NX-RD-003') {
      _profile = _rider3Suspended;
    }
    notifyListeners();
  }

  // Security Check: RID-PROF-007 (Rider cannot see another rider's profile)
  bool canViewRiderProfile(String targetRiderId) {
    return _profile.id == targetRiderId;
  }

  bool Function()? hasActiveTripCallback;
  bool get hasActiveTrip => hasActiveTripCallback != null ? hasActiveTripCallback!() : false;

  void setOnlineStatus(bool online) {
    _profile = _profile.copyWith(isOnline: online);
    notifyListeners();
  }

  // RID-PROF-006 & COU-SHIFT-004 & COU-SHIFT-005
  OperationResult toggleOnlineStatus() {
    if (_profile.accountStatus.toLowerCase() == 'suspended') {
      _profile = _profile.copyWith(isOnline: false);
      notifyListeners();
      return OperationResult.fail(
        'Account Suspended: You cannot go online or accept deliveries. Please contact Hub Dispatch.',
      );
    }

    // COU-SHIFT-004: If rider is on duty and attempts to go off duty while on an active trip
    if (_profile.isOnline && hasActiveTrip) {
      return OperationResult.fail(
        'Cannot Go Off Duty: You have an active trip in transit. Complete the delivery or hand over the trip to dispatch first.',
      );
    }

    final newStatus = !_profile.isOnline;
    _profile = _profile.copyWith(isOnline: newStatus);
    notifyListeners();
    return OperationResult.ok(
      _profile.isOnline
          ? 'You are now ON DUTY and accepting dispatches.'
          : 'You are now OFF DUTY.',
    );
  }

  // RID-PROF-002 & RID-PROF-003: Update vehicle details & duplicate plate check
  OperationResult updateVehicleDetails({
    required String newPlate,
    required String newOrCrName,
    double orCrSizeMb = 0.9,
  }) {
    final cleanPlate =
        newPlate.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

    if (cleanPlate.isEmpty) {
      return OperationResult.fail('Please enter a valid vehicle plate number.');
    }

    // Check duplicate plate against existing fleet database
    if (_registeredPlates.contains(cleanPlate) &&
        cleanPlate !=
            _profile.plateNumber.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '')) {
      return OperationResult.fail(
        'Plate $newPlate is already registered to another active fleet vehicle.',
      );
    }

    // Check OR/CR document format
    final lowerOrCr = newOrCrName.toLowerCase();
    final isAllowed = lowerOrCr.endsWith('.jpg') ||
        lowerOrCr.endsWith('.jpeg') ||
        lowerOrCr.endsWith('.png') ||
        lowerOrCr.endsWith('.pdf');
    if (!isAllowed || lowerOrCr.contains('docx') || lowerOrCr.contains('exe')) {
      return OperationResult.fail(
        'OR/CR rejected: Invalid file format ($newOrCrName). Only JPG, PNG, and PDF up to 5.0 MB are accepted.',
      );
    }

    // Check OR/CR document size rule
    if (orCrSizeMb > 5.0) {
      return OperationResult.fail(
        'OR/CR document exceeds maximum size of 5.0 MB (${orCrSizeMb.toStringAsFixed(1)} MB).',
      );
    }

    // Save change, flag for re-verification, and remove old plate from view
    _profile = _profile.copyWith(
      plateNumber: newPlate.trim().toUpperCase(),
      orCrDocName: newOrCrName,
      vehicleReverificationStatus: 'Pending Re-verification',
    );
    notifyListeners();
    return OperationResult.ok(
      'Vehicle updated! Flagged for Logistics 1 re-verification.',
    );
  }

  // RID-PROF-004: License Expiry Boundary Analysis (Yesterday vs Today)
  OperationResult updateLicenseExpiry(DateTime selectedDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final chosenDateStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (chosenDateStart.isBefore(todayStart)) {
      return OperationResult.fail(
        'License rejected: Expiry date is in the past (expired). Must be currently valid.',
      );
    }

    final formatted =
        '${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.year}';
    _profile = _profile.copyWith(licenseExpiry: formatted);
    notifyListeners();
    return OperationResult.ok(
      'Driver\'s License expiry date successfully updated to $formatted.',
    );
  }

  // RID-PROF-005: Document Upload Rules (Size <= 5.0MB, file extension validation)
  OperationResult uploadDriverLicense({
    required String fileName,
    required double fileSizeMb,
  }) {
    // 1. File size boundary: Max 5.0 MB
    if (fileSizeMb > 5.0) {
      return OperationResult.fail(
        'File rejected: ${fileSizeMb.toStringAsFixed(1)} MB exceeds the 5.0 MB limit. Previous document kept.',
      );
    }

    // 2. Extension validation (reject docx and executable / renamed files)
    final lower = fileName.toLowerCase();
    final isAllowed =
        lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.pdf');

    if (!isAllowed || lower.contains('docx') || lower.contains('exe')) {
      return OperationResult.fail(
        'File rejected: Invalid file format ($fileName). Only JPG, PNG, and PDF up to 5.0 MB are accepted. Previous document kept.',
      );
    }

    // Accepted
    _profile = _profile.copyWith(licenseDocName: fileName);
    notifyListeners();
    return OperationResult.ok('Document "$fileName" accepted and updated.');
  }

  OperationResult uploadOrCrDocument({
    required String fileName,
    required double fileSizeMb,
  }) {
    // 1. File size boundary: Max 5.0 MB
    if (fileSizeMb > 5.0) {
      return OperationResult.fail(
        'File rejected: ${fileSizeMb.toStringAsFixed(1)} MB exceeds the 5.0 MB limit. Previous document kept.',
      );
    }

    // 2. Extension validation (reject docx and executable / renamed files)
    final lower = fileName.toLowerCase();
    final isAllowed =
        lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.pdf');

    if (!isAllowed || lower.contains('docx') || lower.contains('exe')) {
      return OperationResult.fail(
        'File rejected: Invalid file format ($fileName). Only JPG, PNG, and PDF up to 5.0 MB are accepted. Previous document kept.',
      );
    }

    // Accepted
    _profile = _profile.copyWith(
      orCrDocName: fileName,
      vehicleReverificationStatus: 'Pending Re-verification',
    );
    notifyListeners();
    return OperationResult.ok('Document "$fileName" accepted and updated.');
  }

  void setNavigation(String nav) {
    _profile = _profile.copyWith(preferredNavigation: nav);
    notifyListeners();
  }

  void toggleAudioPrompts(bool val) {
    _profile = _profile.copyWith(audioPromptsEnabled: val);
    notifyListeners();
  }

  void addEarnings(double amount) {
    _profile = _profile.copyWith(
      walletBalance: _profile.walletBalance + amount,
      todayEarnings: _profile.todayEarnings + amount,
      todayDeliveries: _profile.todayDeliveries + 1,
      totalDeliveries: _profile.totalDeliveries + 1,
    );
    notifyListeners();
  }

  void deductCashOut(double amount) {
    if (amount <= _profile.walletBalance) {
      _profile = _profile.copyWith(
        walletBalance: _profile.walletBalance - amount,
      );
      notifyListeners();
    }
  }

  void updateProfile({
    String? name,
    String? phone,
    String? vehicleModel,
    String? plateNumber,
    String? assignedHub,
  }) {
    _profile = _profile.copyWith(
      name: name,
      phone: phone,
      vehicleModel: vehicleModel,
      plateNumber: plateNumber,
      assignedHub: assignedHub,
    );
    notifyListeners();
  }
}
