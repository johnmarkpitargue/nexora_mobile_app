import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/courier_models.dart';
import 'courier_profile_service.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/services/rider_service.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/services/rider_location_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/laguna_places_service.dart';
import '../../../core/services/external_notification_service.dart';

class CourierService extends ChangeNotifier {
  static final CourierService instance = CourierService._();

  CourierService._() {
    _initSeededData();
    _initSupabaseSync();
  }

  bool get isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  late CourierHub _currentHub;
  CourierHub get currentHub => _currentHub;

  void resetToSeed() {
    _initSeededData();
    notifyListeners();
  }

  final List<CourierParcel> _parcels = [];
  final List<CourierRider> _riders = [];
  final List<CourierTrip> _trips = [];
  final List<String> _dispatchNotifications = [];

  List<CourierParcel> get parcels => List.unmodifiable(_parcels);
  List<CourierRider> get riders => List.unmodifiable(_riders);
  List<CourierTrip> get trips => List.unmodifiable(_trips);
  List<String> get dispatchNotifications =>
      List.unmodifiable(_dispatchNotifications);

  // Summary Metrics
  int get totalParcelsCount => _parcels.length;

  int get inHubSortingCount =>
      _parcels.where((p) => p.status == CourierParcelStatus.sorting).length;

  int get assignedCount =>
      _parcels.where((p) => p.status == CourierParcelStatus.assigned).length;

  int get outForDeliveryCount =>
      _parcels.where((p) => p.status == CourierParcelStatus.inTransit).length;

  int get deliveredTodayCount =>
      _parcels.where((p) => p.status == CourierParcelStatus.delivered).length;

  int get returnedCount =>
      _parcels.where((p) => p.status == CourierParcelStatus.returned).length;

  int get activeRidersCount => _riders.where((r) => r.isOnline).length;

  double get onTimeSuccessRate => 96.8;

  double get todayTotalCodCollected {
    return _parcels
        .where((p) => p.status == CourierParcelStatus.delivered && p.isCod)
        .fold(0.0, (sum, p) => sum + p.amountCod);
  }

  void _initSeededData() {
    _currentHub = const CourierHub(
      id: 'NX-HUB-LAG-01',
      name: 'Nexora Central Dispatch Hub',
      address: 'Laguna Technopark, Santa Rosa, Laguna',
      region: 'CALABARZON South Cluster #4',
      managerName: 'Engr. Ronaldo Dela Cruz',
      contactPhone: '+63 49 544 8800',
    );

    _riders.clear();
    _riders.addAll([
      CourierRider(
        id: 'NX-RD-001',
        name: 'Pedro Jose Garcia',
        phone: '+63 918 555 0192',
        vehicleType: 'Motorcycle',
        vehicleModel: 'Honda Click 150i',
        plateNumber: '123ABC',
        assignedZone: 'Santa Rosa & Biñan Corridor',
        rating: 4.98,
        assignedParcelsCount: 4,
        deliveredParcelsCount: 14,
        isOnline: true,
      ),
      CourierRider(
        id: 'NX-RD-002',
        name: 'Juan Carlos Ramos',
        phone: '+63 920 888 1234',
        vehicleType: 'Motorcycle',
        vehicleModel: 'Yamaha Aerox 155',
        plateNumber: '456DEF',
        assignedZone: 'Nuvali & Cabuyao Central',
        rating: 4.88,
        assignedParcelsCount: 3,
        deliveredParcelsCount: 11,
        isOnline: true,
      ),
      CourierRider(
        id: 'NX-RD-004',
        name: 'Michael Bryan Santos',
        phone: '+63 919 777 3344',
        vehicleType: 'L300 Cargo Van',
        vehicleModel: 'Mitsubishi L300 FB Ex',
        plateNumber: 'VAN-7890',
        assignedZone: 'Calamba Commercial District',
        rating: 4.92,
        assignedParcelsCount: 5,
        deliveredParcelsCount: 18,
        isOnline: true,
      ),
      CourierRider(
        id: 'NX-RD-005',
        name: 'Christian Jay Alcantara',
        phone: '+63 928 444 8899',
        vehicleType: 'Motorcycle',
        vehicleModel: 'Suzuki Raider 150',
        plateNumber: 'XYZ-5678',
        assignedZone: 'San Pedro & Muntinlupa Border',
        rating: 4.85,
        assignedParcelsCount: 2,
        deliveredParcelsCount: 9,
        isOnline: true,
      ),
    ]);

    _parcels.clear();
    final now = DateTime.now();

    _parcels.addAll([
      CourierParcel(
        id: 'NX-PH-98214309',
        merchantName: 'Nexora Official Audio Store',
        customerName: 'Alex Rivera',
        customerPhone: '+63 917 555 0192',
        customerAddress: 'Unit 2402, Lumina Tower, Taguig City',
        city: 'Taguig City',
        itemsDescription: 'Nexora Studio Pro Wireless ANC Headphones',
        weightKg: 0.85,
        amountCod: 4999.00,
        isCod: true,
        status: CourierParcelStatus.inTransit,
        assignedRiderId: 'NX-RD-001',
        assignedRiderName: 'Pedro Jose Garcia',
        createdAt: now.subtract(const Duration(hours: 3)),
        dispatchedAt: now.subtract(const Duration(hours: 1)),
        notes: 'Ring doorbell or leave with building concierge.',
      ),
      CourierParcel(
        id: 'NX-PH-84912034',
        merchantName: 'Acoustic Sound Philippines',
        customerName: 'Maria Clara Santos',
        customerPhone: '+63 918 987 6543',
        customerAddress: 'Block 12 Lot 8, Solenad 3, Nuvali, Santa Rosa',
        city: 'Santa Rosa, Laguna',
        itemsDescription: 'Tribit StormBox Micro 2 Portable Bluetooth Speaker',
        weightKg: 0.45,
        amountCod: 1850.00,
        isCod: true,
        status: CourierParcelStatus.sorting,
        createdAt: now.subtract(const Duration(minutes: 45)),
        notes: 'Customer requested delivery before 5:00 PM.',
      ),
      CourierParcel(
        id: 'NX-PH-71239841',
        merchantName: 'Nexora Gear & Keyboards',
        customerName: 'Juan Miguel Dela Cruz',
        customerPhone: '+63 917 123 4567',
        customerAddress: 'Phase 2, Bel-Air Village, Santa Rosa City',
        city: 'Santa Rosa, Laguna',
        itemsDescription: 'Keychron K2 V2 Wireless Mechanical Keyboard',
        weightKg: 1.20,
        amountCod: 3290.00,
        isCod: true,
        status: CourierParcelStatus.delivered,
        assignedRiderId: 'NX-RD-001',
        assignedRiderName: 'Pedro Jose Garcia',
        createdAt: now.subtract(const Duration(hours: 5)),
        dispatchedAt: now.subtract(const Duration(hours: 3)),
        deliveredAt: now.subtract(const Duration(minutes: 30)),
        notes: 'Signed and received by buyer with OTP verification.',
      ),
      CourierParcel(
        id: 'NX-PH-64920194',
        merchantName: 'TechGadgets PH',
        customerName: 'Andrea Nicole Tan',
        customerPhone: '+63 927 333 4455',
        customerAddress: 'House 88, Laguna Bel-Air 2, Don Jose',
        city: 'Santa Rosa, Laguna',
        itemsDescription: 'Amazfit GTR 4 Smart Sports Watch (Grey)',
        weightKg: 0.35,
        amountCod: 2150.00,
        isCod: true,
        status: CourierParcelStatus.sorting,
        createdAt: now.subtract(const Duration(minutes: 30)),
        notes: 'Handle with care - fragile electronics.',
      ),
      CourierParcel(
        id: 'NX-PH-51298492',
        merchantName: 'Barista Home Manila',
        customerName: 'Gabriel Luis Ramos',
        customerPhone: '+63 908 222 1199',
        customerAddress: 'Commercial Unit 4, Paseo de Santa Rosa, Greenfield',
        city: 'Santa Rosa, Laguna',
        itemsDescription: 'DeLonghi Dedica Deluxe Espresso Machine',
        weightKg: 4.80,
        amountCod: 4450.00,
        isCod: true,
        status: CourierParcelStatus.inTransit,
        assignedRiderId: 'NX-RD-002',
        assignedRiderName: 'Juan Carlos Ramos',
        createdAt: now.subtract(const Duration(hours: 2)),
        dispatchedAt: now.subtract(const Duration(minutes: 50)),
        notes: 'Bulky parcel - heavy box.',
      ),
      CourierParcel(
        id: 'NX-PH-49201824',
        merchantName: 'ErgoComfort Philippines',
        customerName: 'Sofia Beatriz Lim',
        customerPhone: '+63 919 666 0011',
        customerAddress: 'Block 4 Lot 15, South Lake Village, Eton City',
        city: 'Santa Rosa, Laguna',
        itemsDescription: 'Sihoo M57 Ergonomic Mesh High-Back Office Chair',
        weightKg: 16.50,
        amountCod: 6890.00,
        isCod: true,
        status: CourierParcelStatus.inTransit,
        assignedRiderId: 'NX-RD-004',
        assignedRiderName: 'Michael Bryan Santos',
        createdAt: now.subtract(const Duration(hours: 4)),
        dispatchedAt: now.subtract(const Duration(hours: 1)),
        notes: 'Dispatched via L300 Cargo Van due to weight & size.',
      ),
      CourierParcel(
        id: 'NX-PH-38910294',
        merchantName: 'ActiveStride Athletics',
        customerName: 'Diego Alonzo Cruz',
        customerPhone: '+63 916 444 7722',
        customerAddress: 'Pavilion Mall Commercial Hub, San Antonio',
        city: 'Biñan City, Laguna',
        itemsDescription: 'Nike Air Zoom Pegasus 40 Road Running Shoes (US 10)',
        weightKg: 0.95,
        amountCod: 3490.00,
        isCod: true,
        status: CourierParcelStatus.delivered,
        assignedRiderId: 'NX-RD-005',
        assignedRiderName: 'Christian Jay Alcantara',
        createdAt: now.subtract(const Duration(hours: 6)),
        dispatchedAt: now.subtract(const Duration(hours: 4)),
        deliveredAt: now.subtract(const Duration(hours: 1)),
      ),
      CourierParcel(
        id: 'NX-PH-29103948',
        merchantName: 'GlowOrganics Skincare',
        customerName: 'Bea Alonzo',
        customerPhone: '+63 921 555 3344',
        customerAddress: 'Greenfield City, Villa Del Monte, Santa Rosa',
        city: 'Santa Rosa, Laguna',
        itemsDescription: 'Natural Vitamin C Brightening Serum + Night Cream',
        weightKg: 0.40,
        amountCod: 1250.00,
        isCod: false,
        status: CourierParcelStatus.sorting,
        createdAt: now.subtract(const Duration(minutes: 15)),
        notes: 'Prepaid order via GCash. No cash collection required.',
      ),
      CourierParcel(
        id: 'NX-PH-19284729',
        merchantName: 'Culinary Master PH',
        customerName: 'Marco Rossi',
        customerPhone: '+63 917 888 4422',
        customerAddress: 'Nuvali Ridge Estates, Canlubang Area',
        city: 'Calamba, Laguna',
        itemsDescription:
            'Japanese Damascus 8-Piece Chef Knife Set in Walnut Block',
        weightKg: 2.30,
        amountCod: 2890.00,
        isCod: true,
        status: CourierParcelStatus.assigned,
        assignedRiderId: 'NX-RD-001',
        assignedRiderName: 'Pedro Jose Garcia',
        createdAt: now.subtract(const Duration(hours: 1)),
        notes: 'Fragile cutlery packaging.',
      ),
      // Seed 5 specific parcels for TRIP-1 (COU-LOAD-001 to 009)
      CourierParcel(
        id: 'NX-TRP1-P01',
        waybillNumber: 'WB-TRP1-001',
        merchantName: 'Metro Logistics Store QC',
        customerName: 'Pasig Distribution Centre A',
        customerPhone: '+63 917 111 0001',
        customerAddress: 'HUB-PSG Bay 1, Kapitolyo, Pasig',
        city: 'Pasig City',
        itemsDescription: 'Office Logistics Hub Supplies',
        weightKg: 0.8,
        amountCod: 0.0,
        isCod: false,
        status: CourierParcelStatus.sorting,
        assignedTripId: 'TRIP-1',
        currentHubId: 'HUB-QC',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      CourierParcel(
        id: 'NX-TRP1-P02',
        waybillNumber: 'WB-TRP1-002',
        merchantName: 'Apex Electronics Manila',
        customerName: 'Pasig Distribution Centre B',
        customerPhone: '+63 917 111 0002',
        customerAddress: 'HUB-PSG Bay 2, Kapitolyo, Pasig',
        city: 'Pasig City',
        itemsDescription: 'Electronics Inter-hub Cargo',
        weightKg: 0.5,
        amountCod: 0.0,
        isCod: false,
        status: CourierParcelStatus.sorting,
        assignedTripId: 'TRIP-1',
        currentHubId: 'HUB-QC',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      CourierParcel(
        id: 'NX-TRP1-P03',
        waybillNumber: 'WB-TRP1-003',
        merchantName: 'Zenith Apparel PH',
        customerName: 'Buyer 1 (ADDR-2)',
        customerPhone: '+63 917 111 0003',
        customerAddress: 'ADDR-2, Kapitolyo, Pasig City',
        city: 'Pasig City',
        itemsDescription: 'Textiles & Uniform Apparel (Seller 1)',
        weightKg: 0.7,
        amountCod: 1200.0,
        isCod: true,
        status: CourierParcelStatus.sorting,
        assignedTripId: 'TRIP-1',
        currentHubId: 'HUB-QC',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      CourierParcel(
        id: 'NX-TRP1-P04',
        waybillNumber: 'WB-TRP1-004',
        merchantName: 'Precision Tools QC',
        customerName: 'Pasig Distribution Centre D',
        customerPhone: '+63 917 111 0004',
        customerAddress: 'HUB-PSG Bay 3, Kapitolyo, Pasig',
        city: 'Pasig City',
        itemsDescription: 'Hardware Equipment Parts',
        weightKg: 0.9,
        amountCod: 0.0,
        isCod: false,
        status: CourierParcelStatus.sorting,
        assignedTripId: 'TRIP-1',
        currentHubId: 'HUB-QC',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      CourierParcel(
        id: 'NX-TRP1-P05',
        waybillNumber: 'WB-TRP1-005',
        merchantName: 'Paper & Print Supplies',
        customerName: 'Pasig Distribution Centre E',
        customerPhone: '+63 917 111 0005',
        customerAddress: 'HUB-PSG Bay 4, Kapitolyo, Pasig',
        city: 'Pasig City',
        itemsDescription: 'Stationery & Consumables',
        weightKg: 0.7,
        amountCod: 0.0,
        isCod: false,
        status: CourierParcelStatus.sorting,
        assignedTripId: 'TRIP-1',
        currentHubId: 'HUB-QC',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      // Seed a waiting parcel at HUB-QC for ADDR-1 not in TRIP-1 (COU-LOAD-002)
      CourierParcel(
        id: 'NX-PARCEL-ADDR-1',
        waybillNumber: 'ADDR-1',
        merchantName: 'Quezon City Central Depot',
        customerName: 'Local Customer QC',
        customerPhone: '+63 917 999 0000',
        customerAddress: 'ADDR-1, Diliman, Quezon City',
        city: 'Quezon City',
        itemsDescription: 'Local Parcel Waiting at HUB-QC',
        weightKg: 1.0,
        amountCod: 500.0,
        isCod: true,
        status: CourierParcelStatus.sorting,
        assignedTripId: null,
        currentHubId: 'HUB-QC',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ]);

    _trips.clear();
    _trips.addAll([
      CourierTrip(
        id: 'TRIP-1',
        companyId: 'LOGISTICS-1',
        originHubId: 'HUB-QC',
        originHubName: 'HUB-QC (Quezon City Hub)',
        originAddress: '128 EDSA, Diliman, Quezon City',
        originLatitude: 14.6507,
        originLongitude: 121.0365,
        destinationHubId: 'HUB-PSG',
        destinationHubName: 'HUB-PSG (Kapitolyo, Pasig)',
        destinationAddress: 'Shaw Blvd cor Pioneer St, Kapitolyo, Pasig City',
        destinationLatitude: 14.5738,
        destinationLongitude: 121.0594,
        parcelsCount: 5,
        parcelIds: [
          'NX-TRP1-P01',
          'NX-TRP1-P02',
          'NX-TRP1-P03',
          'NX-TRP1-P04',
          'NX-TRP1-P05',
        ],
        weightKg: 3.6,
        scheduledDeparture: now.add(const Duration(minutes: 45)),
        payAmount: 1000.00,
        status: CourierTripStatus.assigned,
        assignedCourierId: 'NX-RD-001',
        assignedCourierName: 'Pedro Jose Garcia',
        version: 1,
      ),
      CourierTrip(
        id: 'TRIP-2',
        companyId: 'LOGISTICS-1',
        originHubId: 'HUB-QC',
        originHubName: 'HUB-QC (Quezon City Hub)',
        originAddress: '128 EDSA, Diliman, Quezon City',
        destinationHubId: 'HUB-PSG',
        destinationHubName: 'HUB-PSG (Kapitolyo, Pasig)',
        destinationAddress: 'Shaw Blvd cor Pioneer St, Kapitolyo, Pasig City',
        destinationLatitude: 14.5738,
        destinationLongitude: 121.0594,
        parcelsCount: 8,
        weightKg: 5.2,
        scheduledDeparture: now.add(const Duration(hours: 2)),
        payAmount: 1450.00,
        status: CourierTripStatus.unassigned,
        version: 1,
      ),
    ]);
  }

  /// Add a trip to the registry
  void addTrip(CourierTrip trip) {
    _trips.add(trip);
    notifyListeners();
  }

  /// Create a new inbound parcel received at the hub
  CourierParcel addInboundParcel({
    required String merchantName,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String city,
    required String itemsDescription,
    required double weightKg,
    required double amountCod,
    bool isCod = true,
    String? notes,
    String? assignedRiderId,
  }) {
    final now = DateTime.now();
    final newId = 'NX-PH-${now.millisecondsSinceEpoch.toString().substring(5)}';

    String? riderName;
    CourierParcelStatus initialStatus = CourierParcelStatus.sorting;

    if (assignedRiderId != null) {
      final r = _riders.firstWhere(
        (r) => r.id == assignedRiderId,
        orElse: () => _riders.first,
      );
      riderName = r.name;
      initialStatus = CourierParcelStatus.inTransit;
      r.assignedParcelsCount++;
    }

    final newParcel = CourierParcel(
      id: newId,
      merchantName: merchantName.trim(),
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      customerAddress: customerAddress.trim(),
      city: city.trim(),
      itemsDescription: itemsDescription.trim(),
      weightKg: weightKg,
      amountCod: amountCod,
      isCod: isCod,
      status: initialStatus,
      assignedRiderId: assignedRiderId,
      assignedRiderName: riderName,
      createdAt: now,
      dispatchedAt: assignedRiderId != null ? now : null,
      notes: notes?.trim(),
    );

    _parcels.insert(0, newParcel);
    notifyListeners();
    return newParcel;
  }

  /// Assign an existing parcel to a specific rider
  bool assignParcelToRider({
    required String parcelId,
    required String riderId,
  }) {
    final parcelIndex = _parcels.indexWhere((p) => p.id == parcelId);
    if (parcelIndex == -1) return false;

    final rider = _riders.firstWhere(
      (r) => r.id == riderId,
      orElse: () => _riders.first,
    );

    // COU-SHIFT-002, COU-SHIFT-005, COU-SHIFT-007: Only online couriers can be assigned
    if (!rider.isOnline) {
      debugPrint('⚠️ Cannot assign parcel to offline rider: ${rider.name}');
      return false;
    }

    final parcel = _parcels[parcelIndex];
    parcel.assignedRiderId = rider.id;
    parcel.assignedRiderName = rider.name;
    parcel.status = CourierParcelStatus.inTransit;
    parcel.dispatchedAt = DateTime.now();

    rider.assignedParcelsCount++;
    notifyListeners();

    _syncParcelToSupabaseAndRider(parcel, 'to_deliver');
    return true;
  }

  void recordPreTripInspectionPassed({
    required String riderId,
    required String location,
    required DateTime timestamp,
  }) {
    final riderIndex = _riders.indexWhere((r) => r.id == riderId);
    if (riderIndex != -1) {
      final r = _riders[riderIndex];
      r.isOnline = true;
      r.currentLocation = location;
      r.checklistCompletedAt = timestamp;
      r.preTripIssue = null;
      r.preTripNote = null;
      r.isLocationUnknown = false;
      _dispatchNotifications.insert(
        0,
        '[Pre-Trip Passed] ${r.name} is ON DUTY at $location with verified checklist at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}.',
      );
      notifyListeners();
    }
  }

  void recordPreTripInspectionFailed({
    required String riderId,
    required String flaggedItem,
    required String note,
  }) {
    final riderIndex = _riders.indexWhere((r) => r.id == riderId);
    if (riderIndex != -1) {
      final r = _riders[riderIndex];
      r.isOnline = false;
      r.preTripIssue = flaggedItem;
      r.preTripNote = note;
      _dispatchNotifications.insert(
        0,
        '[Safety Incident] ${r.name} reported $flaggedItem Not OK: "$note". Courier remains OFF DUTY.',
      );
      notifyListeners();
    }
  }

  void setRiderDutyStatus({
    required String riderId,
    required bool isOnline,
    String? location,
    bool isLocationUnknown = false,
  }) {
    final riderIndex = _riders.indexWhere((r) => r.id == riderId);
    if (riderIndex != -1) {
      final r = _riders[riderIndex];
      r.isOnline = isOnline;
      if (location != null) r.currentLocation = location;
      r.isLocationUnknown = isLocationUnknown;
      if (!isOnline) {
        _dispatchNotifications.insert(
          0,
          '[Duty Status] ${r.name} is now OFF DUTY and not listed for new trip assignments.',
        );
      }
      notifyListeners();
    }
  }

  void clearDispatchNotifications() {
    _dispatchNotifications.clear();
    notifyListeners();
  }

  void evaluateHeartbeats() {
    final now = DateTime.now();
    bool changed = false;
    for (final rider in _riders) {
      if (rider.isOnline && rider.lastHeartbeat != null) {
        if (now.difference(rider.lastHeartbeat!).inMinutes >= 5) {
          rider.isOnline = false;
          rider.isLocationUnknown = true;
          _dispatchNotifications.insert(
            0,
            '[Heartbeat Timeout] ${rider.name} missed telemetry updates for >5 minutes. Status marked OFFLINE (Location Unknown).',
          );
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  /// Update the status of a parcel
  bool updateParcelStatus({
    required String parcelId,
    required CourierParcelStatus newStatus,
  }) {
    final parcelIndex = _parcels.indexWhere((p) => p.id == parcelId);
    if (parcelIndex == -1) return false;

    final parcel = _parcels[parcelIndex];
    final oldStatus = parcel.status;
    parcel.status = newStatus;

    String statusStr = 'pending';
    if (newStatus == CourierParcelStatus.delivered) {
      statusStr = 'delivered';
      parcel.deliveredAt = DateTime.now();
      if (parcel.assignedRiderId != null) {
        final r = _riders.firstWhere(
          (r) => r.id == parcel.assignedRiderId,
          orElse: () => _riders.first,
        );
        r.deliveredParcelsCount++;
        if (r.assignedParcelsCount > 0) {
          r.assignedParcelsCount--;
        }
      }
    } else if (newStatus == CourierParcelStatus.inTransit) {
      statusStr = 'in_transit';
      if (oldStatus != CourierParcelStatus.inTransit) {
        parcel.dispatchedAt = DateTime.now();
      }
    } else if (newStatus == CourierParcelStatus.assigned) {
      statusStr = 'to_deliver';
    } else if (newStatus == CourierParcelStatus.returned) {
      statusStr = 'cancelled';
    }

    notifyListeners();
    _syncParcelToSupabaseAndRider(parcel, statusStr);
    return true;
  }

  /// Interactive waybill scanner processor
  CourierParcel? scanInboundWaybill(String trackingNumber) {
    final clean = trackingNumber.trim().toUpperCase();
    final index = _parcels.indexWhere((p) => p.id.toUpperCase() == clean);

    if (index != -1) {
      final parcel = _parcels[index];
      String statusStr = 'to_deliver';
      if (parcel.status == CourierParcelStatus.sorting) {
        // Auto assign to Pedro or top available rider
        final rider = _riders.first;
        parcel.assignedRiderId = rider.id;
        parcel.assignedRiderName = rider.name;
        parcel.status = CourierParcelStatus.inTransit;
        parcel.dispatchedAt = DateTime.now();
        rider.assignedParcelsCount++;
        statusStr = 'in_transit';
      } else if (parcel.status == CourierParcelStatus.inTransit) {
        parcel.status = CourierParcelStatus.delivered;
        parcel.deliveredAt = DateTime.now();
        statusStr = 'delivered';
      }
      notifyListeners();
      _syncParcelToSupabaseAndRider(parcel, statusStr);
      return parcel;
    }

    // If not found in mock list, generate and accept into hub!
    final newParcel = addInboundParcel(
      merchantName: 'Nexora Laguna Logistics Hub',
      customerName: 'Verified Nexora Buyer',
      customerPhone: '+63 917 555 0192',
      customerAddress: 'Nuvali Commercial District, Santa Rosa, Laguna',
      city: 'Santa Rosa, Laguna',
      itemsDescription: 'Express Priority Waybill Shipment',
      weightKg: 1.0,
      amountCod: 1500.00,
      isCod: true,
      notes: 'Scanned via Hub High-Speed Barcode Terminal',
    );
    return newParcel;
  }

  /// Batch dispatch parcels to a rider
  int batchDispatch({
    required String riderId,
    required List<String> parcelIds,
  }) {
    int dispatched = 0;
    for (final id in parcelIds) {
      if (assignParcelToRider(parcelId: id, riderId: riderId)) {
        dispatched++;
      }
    }
    return dispatched;
  }

  // ===========================================================================
  // Courier Trip Assignment Management (COU-TRIP-001 through COU-TRIP-008)
  // ===========================================================================

  CourierTrip? getTripById(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  CourierTrip? getActiveTripForCourier(String courierId) {
    try {
      return _trips.firstWhere(
        (t) =>
            t.assignedCourierId == courierId &&
            (t.status == CourierTripStatus.accepted ||
                t.status == CourierTripStatus.loading ||
                t.status == CourierTripStatus.inTransit),
      );
    } catch (_) {
      return null;
    }
  }

  List<CourierTrip> getTripsForCourier(String courierId) {
    return _trips.where((t) => t.assignedCourierId == courierId).toList();
  }

  /// Assign trip to courier (COU-TRIP-004, COU-TRIP-007)
  OperationResult assignTripToCourier({
    required String tripId,
    required String courierId,
    String logisticsCompanyId = 'LOGISTICS-1',
  }) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail('Trip $tripId not found.');
    }

    if (trip.companyId != logisticsCompanyId) {
      return OperationResult.fail(
        '403 Forbidden: Cannot assign trip from another company.',
      );
    }

    // COU-TRIP-004: Only one active trip per courier
    final existingActive = getActiveTripForCourier(courierId);
    if (existingActive != null) {
      return OperationResult.fail(
        'Assignment blocked: Courier already has an active trip (${existingActive.id}).',
      );
    }

    final courierIndex = _riders.indexWhere((r) => r.id == courierId);
    if (courierIndex == -1) {
      return OperationResult.fail('Courier not found.');
    }
    final courier = _riders[courierIndex];
    if (!courier.isOnline) {
      return OperationResult.fail('Cannot assign trip to offline courier.');
    }

    trip.assignedCourierId = courier.id;
    trip.assignedCourierName = courier.name;
    trip.status = CourierTripStatus.assigned;
    trip.declinedReason = null;
    trip.version++;

    // COU-TRIP-007: Trip notification while the phone is locked
    ExternalNotificationService.instance.showNotification(
      id: 7001,
      title: 'New Trip Assigned: ${trip.id}',
      body:
          'Origin: ${trip.originHubId} → ${trip.destinationHubId} (${trip.parcelsCount} parcels, ${trip.weightKg} kg). Scheduled Pay: ₱${trip.payAmount.toStringAsFixed(2)}',
      payload: 'trip:${trip.id}',
    );

    _dispatchNotifications.insert(
      0,
      '[Trip Assigned] ${trip.id} assigned to ${courier.name}. Route: ${trip.originHubId} -> ${trip.destinationHubId}. Pay: ₱${trip.payAmount.toStringAsFixed(2)}.',
    );

    notifyListeners();
    return OperationResult.ok(
      'Trip ${trip.id} successfully assigned to ${courier.name}.',
    );
  }

  /// Accept an assigned trip (COU-TRIP-002, COU-TRIP-005, COU-TRIP-006)
  OperationResult acceptTrip({
    required String tripId,
    required String courierId,
    required String companyId,
    int? expectedVersion,
  }) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail(
        '404 Not Found: Trip $tripId does not exist.',
      );
    }

    // COU-TRIP-006: Cannot accept another company's trip
    if (trip.companyId != companyId) {
      return OperationResult.fail(
        '403 Forbidden: Cannot accept a trip belonging to another logistics company.',
      );
    }

    // COU-TRIP-005: Concurrency check - accept and reassignment at the same moment
    if ((expectedVersion != null && trip.version != expectedVersion) ||
        trip.assignedCourierId != courierId) {
      return OperationResult.fail(
        'Trip has already been reassigned to another courier.',
      );
    }

    final now = DateTime.now();
    trip.status = CourierTripStatus.accepted;
    trip.acceptedAt = now;
    trip.version++;

    // Protect shift availability during active trip (COU-SHIFT-004)
    RiderService.instance.hasActiveTripCallback = () => true;

    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _dispatchNotifications.insert(
      0,
      '[Trip Accepted] ${trip.assignedCourierName ?? 'Courier'} accepted ${trip.id} at $timeStr. Start Loading is now available.',
    );

    notifyListeners();
    return OperationResult.ok(
      'Trip ${trip.id} accepted! Start Loading is now available.',
    );
  }

  /// Decline an assigned trip with a mandatory reason (COU-TRIP-003)
  OperationResult declineTrip({
    required String tripId,
    required String courierId,
    required String reason,
  }) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail('Trip $tripId not found.');
    }

    // COU-TRIP-003 Step 1: Confirmation without a reason is blocked
    if (reason.trim().isEmpty) {
      return OperationResult.fail(
        'A reason is required to decline this trip assignment.',
      );
    }

    final prevCourierName = trip.assignedCourierName ?? 'Courier';
    trip.status = CourierTripStatus.unassigned;
    trip.assignedCourierId = null;
    trip.assignedCourierName = null;
    trip.declinedReason = reason.trim();
    trip.version++;

    // Reset active trip callback if courier has no other active trips
    if (getActiveTripForCourier(courierId) == null) {
      RiderService.instance.hasActiveTripCallback = null;
    }

    // Logistics 1 is notified with the reason, TRIP-1 back to Unassigned, Courier gets ₱0.00
    _dispatchNotifications.insert(
      0,
      '[Trip Declined] $prevCourierName declined ${trip.id} (Reason: ${trip.declinedReason}). Trip returned to Unassigned. Courier payout: ₱0.00.',
    );

    notifyListeners();
    return OperationResult.ok('Trip declined. Returned to Unassigned.');
  }

  /// Start loading parcels for an accepted trip (COU-TRIP-002)
  OperationResult startLoadingTrip({
    required String tripId,
    required String courierId,
  }) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail('Trip not found.');
    }
    if (trip.assignedCourierId != courierId) {
      return OperationResult.fail('Courier not assigned to this trip.');
    }

    trip.status = CourierTripStatus.loading;
    trip.version++;

    _dispatchNotifications.insert(
      0,
      '[Trip Loading] ${trip.assignedCourierName} started loading parcels for ${trip.id} at ${trip.originHubId}.',
    );

    notifyListeners();
    return OperationResult.ok('Loading initiated for ${trip.id}.');
  }

  /// Scan a parcel waybill for an active loading trip (COU-LOAD-001, COU-LOAD-002, COU-LOAD-003, COU-LOAD-008, COU-LOAD-009)
  OperationResult scanParcelForTrip({
    required String tripId,
    required String trackingOrWaybill,
    bool isOffline = false,
  }) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail('Trip $tripId not found.');
    }
    if (trip.status != CourierTripStatus.loading) {
      return OperationResult.fail('Trip ${trip.id} is not in Loading status.');
    }

    final query = trackingOrWaybill.trim().toLowerCase();
    if (query.isEmpty) {
      return OperationResult.fail(
        'Rejected: Waybill or tracking number cannot be empty.',
      );
    }

    // Match parcel by ID or waybill
    final matchedParcel = _parcels.cast<CourierParcel?>().firstWhere(
      (p) =>
          p != null &&
          (p.id.toLowerCase() == query ||
              (p.waybillNumber != null &&
                  p.waybillNumber!.toLowerCase() == query)),
      orElse: () => null,
    );

    // COU-LOAD-002: Scan a parcel that is not in this trip or not found
    if (matchedParcel == null) {
      return OperationResult.fail(
        'Rejected: Parcel "$trackingOrWaybill" not found in inventory.',
      );
    }

    if (!trip.parcelIds.contains(matchedParcel.id)) {
      return OperationResult.fail(
        'Rejected: Parcel ${matchedParcel.id} (${matchedParcel.customerAddress}) is waiting at ${trip.originHubId} and is not in this trip.',
      );
    }

    // COU-LOAD-009: Offline / Airplane mode handling
    if (isOffline) {
      if (!trip.pendingOfflineScans.contains(matchedParcel.id)) {
        trip.pendingOfflineScans.add(matchedParcel.id);
      }
      notifyListeners();
      return OperationResult.ok(
        'Scan saved offline. Parcel ${matchedParcel.id} pending synchronization.',
      );
    }

    // COU-LOAD-003: Scan the same parcel twice warns 'already loaded'
    if (trip.loadedParcelIds.contains(matchedParcel.id)) {
      return OperationResult.fail(
        'Warning: Parcel ${matchedParcel.id} is already loaded.',
      );
    }

    // COU-LOAD-001: Counter goes up and parcel is ticked
    trip.loadedParcelIds.add(matchedParcel.id);
    matchedParcel.isLoaded = true;

    _dispatchNotifications.insert(
      0,
      '[Loading Scan] ${matchedParcel.id} verified and loaded into ${trip.id} (${trip.loadedCount}/${trip.parcelsCount}).',
    );

    notifyListeners();
    return OperationResult.ok(
      '✓ Parcel ${matchedParcel.id} loaded (${trip.loadedCount}/${trip.parcelsCount}).',
    );
  }

  /// Synchronize pending offline scans when internet connectivity returns (COU-LOAD-009)
  OperationResult syncOfflinePendingScans(String tripId) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail('Trip not found.');
    }

    int syncedCount = 0;
    for (final parcelId in List<String>.from(trip.pendingOfflineScans)) {
      if (!trip.loadedParcelIds.contains(parcelId)) {
        trip.loadedParcelIds.add(parcelId);
        final p = _parcels.cast<CourierParcel?>().firstWhere(
          (x) => x?.id == parcelId,
          orElse: () => null,
        );
        if (p != null) p.isLoaded = true;
        syncedCount++;
      }
    }

    trip.pendingOfflineScans.clear();
    _dispatchNotifications.insert(
      0,
      '[Sync Online] $syncedCount offline scans synchronized for ${trip.id}. Current progress: ${trip.loadedCount}/${trip.parcelsCount}.',
    );

    notifyListeners();
    return OperationResult.ok('Synchronized $syncedCount offline scan(s).');
  }

  /// Remove a parcel from trip as Logistics 1 (COU-LOAD-004)
  OperationResult removeParcelFromTrip({
    required String tripId,
    required String parcelId,
  }) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail('Trip not found.');
    }

    if (!trip.parcelIds.contains(parcelId)) {
      return OperationResult.fail(
        'Parcel $parcelId is not in trip ${trip.id}.',
      );
    }

    trip.parcelIds.remove(parcelId);
    trip.loadedParcelIds.remove(parcelId);
    trip.pendingOfflineScans.remove(parcelId);

    // Removed parcel returns to At Hub (HUB-QC) with no trip
    final parcel = _parcels.cast<CourierParcel?>().firstWhere(
      (p) => p?.id == parcelId,
      orElse: () => null,
    );
    if (parcel != null) {
      parcel.assignedTripId = null;
      parcel.status = CourierParcelStatus.sorting;
      parcel.isLoaded = false;
    }

    _dispatchNotifications.insert(
      0,
      '[Logistics 1] Removed parcel $parcelId from ${trip.id}. Parcel returned to ${trip.originHubId} inventory with no trip. Trip counter is now ${trip.loadedCount}/${trip.parcelsCount}.',
    );

    notifyListeners();
    return OperationResult.ok(
      'Parcel $parcelId removed from ${trip.id} and returned to ${trip.originHubId}.',
    );
  }

  /// Validate seal number format: EH- followed by 7 digits (COU-LOAD-005)
  static bool validateSealNumber(String seal) {
    return RegExp(r'^EH-\d{7}$').hasMatch(seal.trim());
  }

  /// Calculate distance between two coordinate points in meters
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(a));
  }

  /// Depart hub transfer trip (COU-LOAD-004, COU-LOAD-005, COU-LOAD-006, COU-LOAD-007, COU-LOAD-009)
  OperationResult departTrip({
    required String tripId,
    required String courierId,
    required String sealNumber,
    double? currentLatitude,
    double? currentLongitude,
    bool isOffline = false,
  }) {
    final trip = getTripById(tripId);
    if (trip == null) {
      return OperationResult.fail('Trip not found.');
    }

    // COU-LOAD-009: Depart is not possible while scans are pending
    if (trip.pendingOfflineScans.isNotEmpty) {
      return OperationResult.fail(
        'Depart blocked: ${trip.pendingOfflineScans.length} scan(s) are pending offline synchronization. Reconnect to internet before departing.',
      );
    }

    // COU-LOAD-004 Step 1: Depart with a parcel not loaded is blocked and lists unloaded parcels
    if (!trip.isFullyLoaded) {
      final missing = trip.parcelIds
          .where((id) => !trip.loadedParcelIds.contains(id))
          .toList();
      return OperationResult.fail(
        'Depart blocked: ${missing.length} parcel(s) not yet loaded (${missing.join(", ")}). All parcels must be scanned or removed by Logistics before departing.',
      );
    }

    // COU-LOAD-005: Seal number format check
    final cleanSeal = sealNumber.trim();
    if (!validateSealNumber(cleanSeal)) {
      return OperationResult.fail(
        'Invalid Seal: Seal must follow the format EH- followed by 7 digits (e.g. EH-0804521).',
      );
    }

    // COU-LOAD-007: Depart away from the origin hub (more than 500m)
    if (currentLatitude != null && currentLongitude != null) {
      final distance = calculateDistanceMeters(
        currentLatitude,
        currentLongitude,
        trip.originLatitude,
        trip.originLongitude,
      );
      if (distance > 500) {
        return OperationResult.fail(
          'Depart blocked: Courier must be at ${trip.originHubId} (within 500m) to depart. Current distance: ${distance.toStringAsFixed(0)}m.',
        );
      }
    }

    // COU-LOAD-006: Depart updates every parcel to In Transit
    final now = DateTime.now();
    trip.status = CourierTripStatus.inTransit;
    trip.sealNumber = cleanSeal;
    trip.departedAt = now;
    trip.version++;

    for (final pid in trip.parcelIds) {
      final parcel = _parcels.cast<CourierParcel?>().firstWhere(
        (p) => p?.id == pid,
        orElse: () => null,
      );
      if (parcel != null) {
        parcel.status = CourierParcelStatus.inTransit;
        parcel.transitRoute = '${trip.originHubId} → ${trip.destinationHubId}';
        parcel.dispatchedAt = now;
        _syncParcelToSupabaseAndRider(parcel, 'in_transit');
      }
    }

    // Buyer 1's timeline, Seller 1's order, and Logistics 1's view updated
    // Privacy compliance: Courier's personal name and live coordinates are hidden from buyer
    _dispatchNotifications.insert(
      0,
      '[Trip Departed] ${trip.id} is In Transit at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}. Route: ${trip.originHubId} → ${trip.destinationHubId}. Seal: $cleanSeal. Courier identity private.',
    );

    notifyListeners();
    return OperationResult.ok(
      'Trip ${trip.id} departed successfully! All ${trip.parcelsCount} parcels are In Transit with Seal $cleanSeal.',
    );
  }

  /// Convert a CourierParcel to a DeliveryOrder for live navigation & stage tracking
  DeliveryOrder toDeliveryOrder(CourierParcel parcel) {
    double lat = parcel.customerLat ?? 0.0;
    double lng = parcel.customerLng ?? 0.0;
    if (lat == 0.0 || lng == 0.0) {
      final resolved = LagunaPlacesService.instance.resolveCoordinates(parcel.customerAddress);
      lat = resolved.latitude;
      lng = resolved.longitude;
    }

    DeliveryStatus deliveryStatus;
    switch (parcel.status) {
      case CourierParcelStatus.sorting:
        deliveryStatus = DeliveryStatus.available;
        break;
      case CourierParcelStatus.assigned:
        deliveryStatus = DeliveryStatus.accepted;
        break;
      case CourierParcelStatus.inTransit:
        deliveryStatus = DeliveryStatus.pickedUp;
        break;
      case CourierParcelStatus.delivered:
        deliveryStatus = DeliveryStatus.delivered;
        break;
      case CourierParcelStatus.returned:
        deliveryStatus = DeliveryStatus.cancelled;
        break;
    }

    return DeliveryOrder(
      id: parcel.id,
      customerName: parcel.customerName,
      customerPhone: parcel.customerPhone,
      customerAddress: parcel.customerAddress,
      customerLat: lat,
      customerLng: lng,
      customerNotes: parcel.notes ?? 'Hub Waybill Dispatch',
      merchantName: parcel.merchantName,
      merchantAddress: _currentHub.address,
      merchantPhone: _currentHub.contactPhone,
      items: [
        OrderItemDetail(
          name: parcel.itemsDescription,
          quantity: 1,
          price: parcel.amountCod > 0 ? parcel.amountCod : 1250.0,
          imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200',
        ),
      ],
      deliveryFee: 120.0,
      tip: 25.0,
      orderTotal: parcel.amountCod > 0 ? parcel.amountCod : 1250.0,
      paymentType: parcel.isCod ? 'Cash on Delivery' : 'Prepaid',
      distanceKm: 2.8,
      estimatedMinutes: 14,
      createdAt: parcel.createdAt,
      status: deliveryStatus,
    );
  }

  /// Sync status from DeliveryService so Rider and Courier views stay 100% unified
  void syncFromDeliveryOrder(String orderId, String statusStr, {String? riderName}) {
    final clean = orderId.replaceAll('#', '').trim().toLowerCase();
    final idx = _parcels.indexWhere(
      (p) => p.id.replaceAll('#', '').trim().toLowerCase() == clean,
    );
    if (idx == -1) return;

    final parcel = _parcels[idx];
    bool changed = false;

    if (riderName != null && riderName.isNotEmpty && parcel.assignedRiderName != riderName) {
      parcel.assignedRiderName = riderName;
      parcel.assignedRiderId ??= 'NX-RD-001';
      changed = true;
    }

    CourierParcelStatus? mapped;
    switch (statusStr.toLowerCase()) {
      case 'pending':
      case 'preparing':
      case 'ready':
      case 'at_store':
        mapped = CourierParcelStatus.assigned;
        break;
      case 'to_deliver':
      case 'picked_up':
      case 'in_transit':
      case 'out_for_delivery':
        mapped = CourierParcelStatus.inTransit;
        break;
      case 'delivered':
      case 'completed':
        mapped = CourierParcelStatus.delivered;
        parcel.deliveredAt ??= DateTime.now();
        break;
      case 'cancelled':
        mapped = CourierParcelStatus.returned;
        break;
    }

    if (mapped != null && parcel.status != mapped) {
      parcel.status = mapped;
      if (mapped == CourierParcelStatus.inTransit) {
        parcel.dispatchedAt ??= DateTime.now();
      }
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void _syncParcelToSupabaseAndRider(CourierParcel parcel, String statusStr) {
    final clean = parcel.id.replaceAll('#', '').trim();
    final activeCourierName = parcel.assignedRiderName ??
        (CourierProfileService.instance.profile.name.isNotEmpty
            ? CourierProfileService.instance.profile.name
            : RiderService.instance.profile.name);

    // 1. Update RiderLocationService live GPS broadcast for Buyer OrderTrackingScreen
    if (statusStr == 'to_deliver' || statusStr == 'in_transit' || statusStr == 'picked_up') {
      RiderLocationService.instance.startTracking(
        orderId: clean,
        riderName: activeCourierName,
        status: statusStr,
      );
      RiderLocationService.instance.updateOrderStatus(statusStr);
    } else if (statusStr == 'delivered' || statusStr == 'cancelled') {
      RiderLocationService.instance.updateOrderStatus(statusStr);
      if (RiderLocationService.instance.activeOrderId == clean) {
        RiderLocationService.instance.stopTracking();
      }
    }

    // 2. Subscribe RiderChatService so Courier receives Buyer chat messages for this parcel
    RiderChatService.instance.subscribeToOrder(clean, customerName: parcel.customerName);

    // 3. Sync with Supabase database and broadcast channels
    if (!isSupabaseReady) return;
    try {
      final isNum = int.tryParse(clean) != null;
      if (isNum) {
        Supabase.instance.client
            .from('orders')
            .update({'status': statusStr})
            .eq('id', int.parse(clean))
            .catchError((_) {});
      }
      Supabase.instance.client
          .from('orders')
          .update({'status': statusStr})
          .eq('order_id', clean)
          .catchError((_) {});
      Supabase.instance.client
          .from('orders')
          .update({'status': statusStr})
          .eq('id', clean)
          .catchError((_) {});

      // Broadcast on orders_dispatch for OrderService
      final dispatchCh = Supabase.instance.client.channel('orders_dispatch');
      dispatchCh.subscribe((status, [err]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          dispatchCh.sendBroadcastMessage(
            event: 'status_updated',
            payload: {
              'order_id': clean,
              'status': statusStr,
              'courier_name': activeCourierName,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      });

      // Broadcast on rider_tracking_$clean for OrderTrackingScreen
      final trackCh = Supabase.instance.client.channel('rider_tracking_$clean');
      trackCh.subscribe((status, [err]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          trackCh.sendBroadcastMessage(
            event: 'status_update',
            payload: {
              'order_id': clean,
              'status': statusStr,
              'courier_name': activeCourierName,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      });
    } catch (e) {
      debugPrint('⚠️ CourierService Supabase sync notice: $e');
    }
  }

  void _initSupabaseSync() {
    if (!isSupabaseReady) return;
    try {
      // Subscribe to chat for seeded parcels when Supabase is live
      for (final p in _parcels) {
        RiderChatService.instance.subscribeToOrder(p.id, customerName: p.customerName);
      }

      // Listen to orders_dispatch broadcast for new orders and customer pin updates
      final dispatchChannel = Supabase.instance.client.channel('orders_dispatch_courier');
      dispatchChannel
          .onBroadcast(
            event: 'order_created',
            callback: (payload) {
              final orderCode = (payload['order_id'] ?? '').toString().trim();
              if (orderCode.isEmpty) return;
              final clean = orderCode.replaceAll('#', '').trim();
              final exists = _parcels.any(
                (p) => p.id.replaceAll('#', '').trim().toLowerCase() == clean.toLowerCase(),
              );
              if (!exists) {
                final addressStr = (payload['delivery_address'] ?? 'Santa Rosa, Laguna').toString();
                final rawLat = (payload['delivery_lat'] as num?)?.toDouble();
                final rawLng = (payload['delivery_lng'] as num?)?.toDouble();
                final resolved = LagunaPlacesService.instance.resolveCoordinates(addressStr);
                final newParcel = CourierParcel(
                  id: clean,
                  merchantName: 'Nexora Official Flagship Store',
                  customerName: (payload['customer_id'] ?? 'Alex Rivera').toString(),
                  customerPhone: '+63 975 963 2035',
                  customerAddress: addressStr,
                  city: 'Laguna',
                  itemsDescription: DeliveryService.extractItemTitle(payload['item_details']),
                  weightKg: 0.9,
                  amountCod: (payload['total'] as num?)?.toDouble() ?? 444.0,
                  isCod: true,
                  status: CourierParcelStatus.sorting,
                  createdAt: DateTime.now(),
                  notes: 'Live Buyer Order synced from Nexora App',
                  customerLat: (rawLat != null && rawLat != 0.0) ? rawLat : resolved.latitude,
                  customerLng: (rawLng != null && rawLng != 0.0) ? rawLng : resolved.longitude,
                );
                _parcels.insert(0, newParcel);
                RiderChatService.instance.subscribeToOrder(clean, customerName: newParcel.customerName);
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'location_updated',
            callback: (payload) {
              final orderCode = (payload['order_id'] ?? '').toString().replaceAll('#', '').trim();
              if (orderCode.isEmpty) return;
              final rawLat = (payload['delivery_lat'] as num?)?.toDouble() ??
                  double.tryParse(payload['delivery_lat']?.toString() ?? '');
              final rawLng = (payload['delivery_lng'] as num?)?.toDouble() ??
                  double.tryParse(payload['delivery_lng']?.toString() ?? '');
              final addressStr = payload['delivery_address']?.toString();
              final idx = _parcels.indexWhere(
                (p) => p.id.replaceAll('#', '').trim().toLowerCase() == orderCode.toLowerCase(),
              );
              if (idx != -1 && rawLat != null && rawLng != null) {
                final old = _parcels[idx];
                _parcels[idx] = CourierParcel(
                  id: old.id,
                  merchantName: old.merchantName,
                  customerName: old.customerName,
                  customerPhone: old.customerPhone,
                  customerAddress: addressStr ?? old.customerAddress,
                  city: old.city,
                  itemsDescription: old.itemsDescription,
                  weightKg: old.weightKg,
                  amountCod: old.amountCod,
                  isCod: old.isCod,
                  status: old.status,
                  assignedRiderId: old.assignedRiderId,
                  assignedRiderName: old.assignedRiderName,
                  assignedTripId: old.assignedTripId,
                  waybillNumber: old.waybillNumber,
                  currentHubId: old.currentHubId,
                  transitRoute: old.transitRoute,
                  isLoaded: old.isLoaded,
                  createdAt: old.createdAt,
                  dispatchedAt: old.dispatchedAt,
                  deliveredAt: old.deliveredAt,
                  notes: old.notes,
                  customerLat: rawLat,
                  customerLng: rawLng,
                );
                notifyListeners();
              }
            },
          )
          .onBroadcast(
            event: 'rider_rated',
            callback: (payload) {
              final courierName = (payload['courier_name'] ?? RiderService.instance.profile.name).toString();
              final newRating = (payload['new_courier_rating'] as num?)?.toDouble() ??
                  double.tryParse(payload['new_courier_rating']?.toString() ?? '');
              if (newRating != null) {
                updateRiderRating(courierName, newRating);
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('⚠️ CourierService _initSupabaseSync notice: $e');
    }
  }

  void updateRiderRating(String riderName, double newRating) {
    final cleanTarget = riderName.trim().toLowerCase();
    bool updated = false;
    for (final rider in _riders) {
      if (rider.name.trim().toLowerCase() == cleanTarget ||
          rider.id == RiderService.instance.profile.id) {
        rider.rating = newRating;
        updated = true;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }
}
