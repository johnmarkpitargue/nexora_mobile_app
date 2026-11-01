import 'package:flutter/foundation.dart';
import '../models/courier_profile.dart';
import '../../../core/services/rider_service.dart' show OperationResult;

class CourierProfileService extends ChangeNotifier {
  static final CourierProfileService instance = CourierProfileService._();

  CourierProfileService._() {
    _resetData();
  }

  // Pre-configured Test Fixtures (COU-PROF-001 to COU-PROF-008)
  static const CourierProfile _courier1 = CourierProfile(
    id: 'NX-CR-001',
    name: 'Ernesto Villareal',
    phone: '+63 918 111 2233',
    email: 'ernesto.villareal@example.com',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    rating: 4.96,
    totalDeliveries: 1680,
    company: 'Bilis Hatid Express Inc.',
    homeHub: 'HUB-QC',
    accountStatus: 'Active',
    isOnDuty: false,
    vehicleType: '4-Wheeler Closed Van Truck',
    plateNumber: 'NAB4521',
    loadCapacityKg: 3000,
    vehicleReverificationStatus: 'Validated',
    licenseNumber: 'N02-15-345678',
    licenseType: 'Professional; codes B, B2, C',
    licenseExpiry: '07/15/2029',
    licenseDocName: 'driver_license_ernesto.jpg',
    orCrDocName: 'truck_or_cr.pdf',
    nbiClearanceDocName: 'nbi_clearance_ernesto.pdf',
  );

  static const CourierProfile _courier2 = CourierProfile(
    id: 'NX-CR-002',
    name: 'Danilo Santos',
    phone: '+63 919 222 3344',
    email: 'courier2@bilishatid.example.com',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    rating: 4.88,
    totalDeliveries: 940,
    company: 'Bilis Hatid Express Inc.',
    homeHub: 'HUB-QC',
    accountStatus: 'Active',
    isOnDuty: true,
    vehicleType: '4-Wheeler Closed Van Truck',
    plateNumber: 'CAV7789',
    loadCapacityKg: 3000,
    vehicleReverificationStatus: 'Validated',
    licenseNumber: 'N02-18-887766',
    licenseType: 'Professional; codes B, B2, C',
    licenseExpiry: '05/20/2028',
    licenseDocName: 'license_danilo.jpg',
    orCrDocName: 'or_cr_danilo.pdf',
    nbiClearanceDocName: 'nbi_danilo.pdf',
  );

  static const CourierProfile _courier3Suspended = CourierProfile(
    id: 'NX-CR-003',
    name: 'Rodrigo Mendoza (Suspended)',
    phone: '+63 917 333 4455',
    email: 'courier3@bilishatid.example.com',
    avatarUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
    rating: 4.10,
    totalDeliveries: 310,
    company: 'Bilis Hatid Express Inc.',
    homeHub: 'HUB-PSG',
    accountStatus: 'Suspended',
    isOnDuty: false,
    vehicleType: '4-Wheeler Closed Van Truck',
    plateNumber: 'XYZ4321',
    loadCapacityKg: 3000,
    vehicleReverificationStatus: 'Suspended',
    licenseNumber: 'N03-12-998877',
    licenseType: 'Professional; codes B, B2, C',
    licenseExpiry: '11/14/2027',
    licenseDocName: 'license_rodrigo.jpg',
    orCrDocName: 'or_cr_rodrigo.pdf',
    nbiClearanceDocName: 'nbi_rodrigo.pdf',
  );

  late CourierProfile _currentProfile;

  // Registered Plates Database (COU-PROF-003)
  final Set<String> _registeredPlates = {
    'CAV7789', // Courier 2
    '123ABC',  // Rider 1
    '456DEF',  // Rider 2
    'ABC1234',
    'XYZ9876',
  };

  void _resetData() {
    _currentProfile = _courier1;
  }

  void resetState() {
    _resetData();
    notifyListeners();
  }

  CourierProfile get profile => _currentProfile;
  CourierProfile get currentCourier => _currentProfile;

  // Switcher to simulate different logged in couriers
  void switchCourier(String courierId) {
    if (courierId == 'NX-CR-001') {
      _currentProfile = _courier1;
    } else if (courierId == 'NX-CR-002') {
      _currentProfile = _courier2;
    } else if (courierId == 'NX-CR-003') {
      _currentProfile = _courier3Suspended;
    }
    notifyListeners();
  }

  // COU-PROF-007: Courier cannot see another courier's profile
  bool canViewCourierProfile(String targetCourierId) {
    return _currentProfile.id == targetCourierId;
  }

  // COU-PROF-006: Suspended courier cannot work / go on duty
  OperationResult toggleDutyStatus() {
    if (_currentProfile.accountStatus.toLowerCase() == 'suspended') {
      _currentProfile = _currentProfile.copyWith(isOnDuty: false);
      notifyListeners();
      return OperationResult.fail(
        'Account Suspended: You cannot go On Duty or accept dispatches. Please contact Hub Dispatch.',
      );
    }

    final newStatus = !_currentProfile.isOnDuty;
    _currentProfile = _currentProfile.copyWith(isOnDuty: newStatus);
    notifyListeners();
    return OperationResult.ok(
      newStatus ? 'You are now ON DUTY.' : 'You are now OFF DUTY.',
    );
  }

  // COU-PROF-002: Update load capacity and OR/CR (flagged for re-verification)
  OperationResult updateLoadCapacityAndOrCr({
    required int newCapacityKg,
    required String newOrCrName,
    double orCrSizeMb = 1.0,
  }) {
    if (newCapacityKg <= 0) {
      return OperationResult.fail('Load capacity must be greater than 0 kg.');
    }

    final lower = newOrCrName.toLowerCase();
    final isAllowed = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.pdf');

    if (!isAllowed || lower.contains('docx') || lower.contains('exe')) {
      return OperationResult.fail(
        'File rejected: Invalid file format ($newOrCrName). Only JPG, PNG, and PDF up to 5.0 MB are accepted.',
      );
    }

    if (orCrSizeMb > 5.0) {
      return OperationResult.fail(
        'OR/CR document exceeds maximum size of 5.0 MB (${orCrSizeMb.toStringAsFixed(1)} MB).',
      );
    }

    _currentProfile = _currentProfile.copyWith(
      loadCapacityKg: newCapacityKg,
      orCrDocName: newOrCrName,
      vehicleReverificationStatus: 'Pending Re-verification',
      flaggedNotes: 'Flagged for Logistics 1',
    );
    notifyListeners();
    return OperationResult.ok(
      'Load capacity updated to $newCapacityKg kg with new OR/CR ($newOrCrName). Flagged for Logistics 1.',
    );
  }

  // COU-PROF-002 step 4: Logistics 1 resets or modifies capacity
  void setLoadCapacityByLogistics(int capacityKg) {
    _currentProfile = _currentProfile.copyWith(
      loadCapacityKg: capacityKg,
      vehicleReverificationStatus: 'Validated',
      flaggedNotes: null,
    );
    notifyListeners();
  }

  // COU-PROF-003: Plate number already used by a courier or a rider
  OperationResult updatePlateNumber(String newPlate) {
    final cleanPlate =
        newPlate.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

    if (cleanPlate.isEmpty) {
      return OperationResult.fail('Please enter a valid vehicle plate number.');
    }

    final currentPlateClean = _currentProfile.plateNumber
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\-]'), '');

    if (_registeredPlates.contains(cleanPlate) && cleanPlate != currentPlateClean) {
      return OperationResult.fail(
        'Plate $newPlate is already registered to another courier or rider.',
      );
    }

    _currentProfile = _currentProfile.copyWith(
      plateNumber: newPlate.trim().toUpperCase(),
      vehicleReverificationStatus: 'Pending Re-verification',
      flaggedNotes: 'Flagged for Logistics 1',
    );
    notifyListeners();
    return OperationResult.ok(
      'Vehicle plate updated to ${newPlate.trim().toUpperCase()}! Flagged for Logistics 1.',
    );
  }

  // COU-PROF-004: License expiry boundary (Yesterday vs Today)
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
    _currentProfile = _currentProfile.copyWith(licenseExpiry: formatted);
    notifyListeners();
    return OperationResult.ok(
      'License expiry successfully updated to $formatted.',
    );
  }

  // COU-PROF-005: Document upload rules (Size <= 5.0 MB, file type rules)
  OperationResult uploadNbiClearance({
    required String fileName,
    required double fileSizeMb,
  }) {
    if (fileSizeMb > 5.0) {
      return OperationResult.fail(
        'File rejected: ${fileSizeMb.toStringAsFixed(1)} MB exceeds the 5.0 MB limit. Previous document kept.',
      );
    }

    final lower = fileName.toLowerCase();
    final isAllowed = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.pdf');

    if (!isAllowed || lower.contains('docx') || lower.contains('exe')) {
      return OperationResult.fail(
        'File rejected: Invalid file format ($fileName). Only JPG, PNG, and PDF up to 5.0 MB are accepted. Previous document kept.',
      );
    }

    _currentProfile = _currentProfile.copyWith(nbiClearanceDocName: fileName);
    notifyListeners();
    return OperationResult.ok('NBI Clearance "$fileName" accepted and updated.');
  }

  // COU-PROF-008: Update documents with camera ("Take Photo") and Files app
  OperationResult uploadDriverLicense({
    required String fileName,
    required double fileSizeMb,
    String source = 'Camera',
  }) {
    if (fileSizeMb > 5.0) {
      return OperationResult.fail(
        'File rejected: ${fileSizeMb.toStringAsFixed(1)} MB exceeds the 5.0 MB limit. Previous document kept.',
      );
    }

    final lower = fileName.toLowerCase();
    final isAllowed = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.pdf');

    if (!isAllowed || lower.contains('docx') || lower.contains('exe')) {
      return OperationResult.fail(
        'File rejected: Invalid file format ($fileName). Only JPG, PNG, and PDF up to 5.0 MB are accepted. Previous document kept.',
      );
    }

    _currentProfile = _currentProfile.copyWith(
      licenseDocName: fileName,
      vehicleReverificationStatus: 'Pending Re-verification',
      flaggedNotes: 'Flagged for Logistics 1',
    );
    notifyListeners();
    return OperationResult.ok(
      'Driver\'s License ($source) "$fileName" accepted. Flagged for Logistics 1.',
    );
  }

  OperationResult uploadOrCrDocument({
    required String fileName,
    required double fileSizeMb,
    String source = 'Files',
  }) {
    if (fileSizeMb > 5.0) {
      return OperationResult.fail(
        'File rejected: ${fileSizeMb.toStringAsFixed(1)} MB exceeds the 5.0 MB limit. Previous document kept.',
      );
    }

    final lower = fileName.toLowerCase();
    final isAllowed = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.pdf');

    if (!isAllowed || lower.contains('docx') || lower.contains('exe')) {
      return OperationResult.fail(
        'File rejected: Invalid file format ($fileName). Only JPG, PNG, and PDF up to 5.0 MB are accepted. Previous document kept.',
      );
    }

    _currentProfile = _currentProfile.copyWith(
      orCrDocName: fileName,
      vehicleReverificationStatus: 'Pending Re-verification',
      flaggedNotes: 'Flagged for Logistics 1',
    );
    notifyListeners();
    return OperationResult.ok(
      'Vehicle OR/CR ($source) "$fileName" accepted. Flagged for Logistics 1.',
    );
  }
}
