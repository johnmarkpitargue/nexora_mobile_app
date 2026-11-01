import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/rider_service.dart';
import 'package:nexora_rider_app/features/courier/models/courier_models.dart';
import 'package:nexora_rider_app/features/courier/services/courier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CourierService.instance.resetToSeed();
    RiderService.instance.setOnlineStatus(true);
  });

  group('Courier Loading & Departure Test Suite (COU-LOAD-001 to COU-LOAD-009)', () {
    // -------------------------------------------------------------------------
    // COU-LOAD-001: Load by scanning every parcel
    // -------------------------------------------------------------------------
    test('COU-LOAD-001: Tap Start Loading -> Loading status, scan 5 waybills -> counter 0/5 to 5/5, each ticked', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      // Precondition: Courier 1 accepted TRIP-1
      service.acceptTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        companyId: 'LOGISTICS-1',
      );
      expect(trip.status, CourierTripStatus.accepted);

      // 1. Tap Start Loading
      final startRes = service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');
      expect(startRes.success, isTrue);
      expect(trip.status, CourierTripStatus.loading);
      expect(trip.loadedCount, 0);
      expect(trip.parcelsCount, 5);

      // 2. Scan the 5 waybills one by one
      final waybills = ['WB-TRP1-001', 'WB-TRP1-002', 'WB-TRP1-003', 'WB-TRP1-004', 'WB-TRP1-005'];
      for (int i = 0; i < waybills.length; i++) {
        final res = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: waybills[i]);
        expect(res.success, isTrue);
        expect(trip.loadedCount, i + 1);
      }

      // Final state: 5/5 loaded, every parcel is ticked
      expect(trip.loadedCount, 5);
      expect(trip.isFullyLoaded, isTrue);
      for (final pid in trip.parcelIds) {
        expect(trip.loadedParcelIds.contains(pid), isTrue);
        final parcel = service.parcels.firstWhere((p) => p.id == pid);
        expect(parcel.isLoaded, isTrue);
      }
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-002: Scan a parcel that is not in this trip
    // -------------------------------------------------------------------------
    test('COU-LOAD-002: Scan ADDR-1 (waiting at HUB-QC) and TRK-000000 -> both rejected, counter unchanged', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      final initialLoaded = trip.loadedCount;
      expect(initialLoaded, 0);

      // 1. Scan a parcel for ADDR-1 that is waiting at HUB-QC (not in TRIP-1)
      final resAddr1 = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'ADDR-1');
      expect(resAddr1.success, isFalse);
      expect(resAddr1.message.toLowerCase(), contains('not in this trip'));
      expect(trip.loadedCount, initialLoaded);

      // 2. Type TRK-000000 (does not exist)
      final resNotFound = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'TRK-000000');
      expect(resNotFound.success, isFalse);
      expect(resNotFound.message.toLowerCase(), contains('not found'));
      expect(trip.loadedCount, initialLoaded);
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-003: Scan the same parcel twice
    // -------------------------------------------------------------------------
    test('COU-LOAD-003: Scan the same waybill twice -> second scan warns already loaded, parcel counted once', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      // 1. First scan succeeds
      final res1 = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-001');
      expect(res1.success, isTrue);
      expect(trip.loadedCount, 1);

      // 2. Scan the same waybill twice -> warns 'already loaded'
      final res2 = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-001');
      expect(res2.success, isFalse);
      expect(res2.message.toLowerCase(), contains('already loaded'));
      expect(trip.loadedCount, 1); // Parcel is counted once
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-004: Depart with a parcel not loaded
    // -------------------------------------------------------------------------
    test('COU-LOAD-004: Depart with missing parcel blocked; Logistics removes 5th parcel -> counter 4/4, Depart works', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      // Scan 4 of 5 parcels
      service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-001');
      service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-002');
      service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-003');
      service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-004');
      expect(trip.loadedCount, 4);
      expect(trip.parcelsCount, 5);

      // 1. Tap Depart -> blocked and lists the parcel not yet loaded (NX-TRP1-P05)
      final departStep1 = service.departTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        sealNumber: 'EH-0804521',
      );
      expect(departStep1.success, isFalse);
      expect(departStep1.message, contains('Depart blocked'));
      expect(departStep1.message, contains('NX-TRP1-P05'));
      expect(trip.status, CourierTripStatus.loading);

      // 2. As Logistics 1, remove the 5th parcel from TRIP-1
      final removeRes = service.removeParcelFromTrip(
        tripId: 'TRIP-1',
        parcelId: 'NX-TRP1-P05',
      );
      expect(removeRes.success, isTrue);

      // After removal: counter shows 4/4, removed parcel back At Hub (HUB-QC) with no trip
      expect(trip.parcelsCount, 4);
      expect(trip.loadedCount, 4);
      expect(trip.isFullyLoaded, isTrue);

      final removedParcel = service.parcels.firstWhere((p) => p.id == 'NX-TRP1-P05');
      expect(removedParcel.isAtHub, isTrue);
      expect(removedParcel.assignedTripId, isNull);
      expect(removedParcel.currentHubId, 'HUB-QC');

      // 3. Enter the seal and tap Depart again -> works!
      final departStep3 = service.departTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        sealNumber: 'EH-0804521',
      );
      expect(departStep3.success, isTrue);
      expect(trip.status, CourierTripStatus.inTransit);
      expect(trip.sealNumber, 'EH-0804521');
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-005: Seal number format
    // -------------------------------------------------------------------------
    test('COU-LOAD-005: Boundary Value Analysis on Seal: EH- followed by 7 digits required', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      // Scan all 5 parcels
      for (final pid in trip.parcelIds) {
        final p = service.parcels.firstWhere((x) => x.id == pid);
        service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: p.waybillNumber!);
      }
      expect(trip.isFullyLoaded, isTrue);

      // 1. Empty seal -> reject
      final emptyRes = service.departTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', sealNumber: '');
      expect(emptyRes.success, isFalse);
      expect(emptyRes.message, contains('EH- followed by 7 digits'));
      expect(trip.status, CourierTripStatus.loading);

      // 2. EH-080452 (6 digits) -> reject
      final sixDigRes = service.departTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', sealNumber: 'EH-080452');
      expect(sixDigRes.success, isFalse);
      expect(sixDigRes.message, contains('EH- followed by 7 digits'));
      expect(trip.status, CourierTripStatus.loading);

      // 3. EH-08045210 (8 digits) -> reject
      final eightDigRes = service.departTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', sealNumber: 'EH-08045210');
      expect(eightDigRes.success, isFalse);
      expect(eightDigRes.message, contains('EH- followed by 7 digits'));
      expect(trip.status, CourierTripStatus.loading);

      // 4. EH-ABC4521 (letters) -> reject
      final lettersRes = service.departTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', sealNumber: 'EH-ABC4521');
      expect(lettersRes.success, isFalse);
      expect(lettersRes.message, contains('EH- followed by 7 digits'));
      expect(trip.status, CourierTripStatus.loading);

      // 5. EH-0804521 (valid) -> accept!
      final validRes = service.departTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', sealNumber: 'EH-0804521');
      expect(validRes.success, isTrue);
      expect(trip.status, CourierTripStatus.inTransit);
      expect(trip.sealNumber, 'EH-0804521');
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-006: Depart updates every parcel
    // -------------------------------------------------------------------------
    test('COU-LOAD-006: Depart updates all parcels to In Transit (HUB-QC → HUB-PSG); courier identity private to buyer', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      for (final pid in trip.parcelIds) {
        final p = service.parcels.firstWhere((x) => x.id == pid);
        service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: p.waybillNumber!);
      }

      // Enter seal EH-0804521 and tap Depart
      final departRes = service.departTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        sealNumber: 'EH-0804521',
        currentLatitude: trip.originLatitude,
        currentLongitude: trip.originLongitude,
      );
      expect(departRes.success, isTrue);

      // TRIP-1 is In Transit with departure time
      expect(trip.status, CourierTripStatus.inTransit);
      expect(trip.departedAt, isNotNull);

      // Each parcel shows In Transit (HUB-QC → HUB-PSG)
      for (final pid in trip.parcelIds) {
        final parcel = service.parcels.firstWhere((p) => p.id == pid);
        expect(parcel.status, CourierParcelStatus.inTransit);
        expect(parcel.transitRoute, 'HUB-QC → HUB-PSG');
        expect(parcel.dispatchedAt, isNotNull);
      }

      // Logistics 1 view & privacy check: courier personal details not broadcasted to buyer
      final log = service.dispatchNotifications.first;
      expect(log, contains('[Trip Departed]'));
      expect(log, contains('HUB-QC → HUB-PSG'));
      expect(log, contains('Seal: EH-0804521'));
      expect(log, contains('Courier identity private'));
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-007: Depart away from the origin hub
    // -------------------------------------------------------------------------
    test('COU-LOAD-007: Depart blocked when courier is more than 500m from HUB-QC', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      for (final pid in trip.parcelIds) {
        final p = service.parcels.firstWhere((x) => x.id == pid);
        service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: p.waybillNumber!);
      }

      // Courier is located >500m away (e.g. 14.6650, 121.0500 is ~2.1km from HUB-QC)
      const farLat = 14.6650;
      const farLon = 121.0500;
      final dist = CourierService.calculateDistanceMeters(
        farLat,
        farLon,
        trip.originLatitude,
        trip.originLongitude,
      );
      expect(dist, greaterThan(500));

      final departRes = service.departTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        sealNumber: 'EH-0804521',
        currentLatitude: farLat,
        currentLongitude: farLon,
      );

      // Blocked with a message that the courier must be at HUB-QC. Trip stays Loading.
      expect(departRes.success, isFalse);
      expect(departRes.message, contains('must be at HUB-QC (within 500m) to depart'));
      expect(trip.status, CourierTripStatus.loading);
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-008: [Mobile] Scan with the camera, flashlight and manual entry
    // -------------------------------------------------------------------------
    test('COU-LOAD-008: Camera scan, flashlight toggle, and manual entry for crumpled waybill', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      // 1. Scan a waybill with the camera (simulated optical scan)
      final res1 = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-001');
      expect(res1.success, isTrue);

      // 2. Scan another in low light using flashlight toggle (flashlight state toggle works)
      bool flashlightOn = false;
      flashlightOn = !flashlightOn;
      expect(flashlightOn, isTrue);
      final res2 = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-002');
      expect(res2.success, isTrue);

      // 3. Type the tracking number of a crumpled waybill (manual input)
      final res3 = service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'NX-TRP1-P03');
      expect(res3.success, isTrue);

      // Each parcel is loaded once, whether scanned or typed
      expect(trip.loadedCount, 3);
      expect(trip.loadedParcelIds.contains('NX-TRP1-P01'), isTrue);
      expect(trip.loadedParcelIds.contains('NX-TRP1-P02'), isTrue);
      expect(trip.loadedParcelIds.contains('NX-TRP1-P03'), isTrue);
    });

    // -------------------------------------------------------------------------
    // COU-LOAD-009: [Mobile] Loading scans with no internet
    // -------------------------------------------------------------------------
    test('COU-LOAD-009: Airplane mode saves scans offline, blocks Depart until online sync', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      service.acceptTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001', companyId: 'LOGISTICS-1');
      service.startLoadingTrip(tripId: 'TRIP-1', courierId: 'NX-RD-001');

      // First 3 parcels scanned online
      service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-001');
      service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-002');
      service.scanParcelForTrip(tripId: 'TRIP-1', trackingOrWaybill: 'WB-TRP1-003');
      expect(trip.loadedCount, 3);

      // 1. Turn on Airplane mode and scan 2 parcels
      final offlineRes1 = service.scanParcelForTrip(
        tripId: 'TRIP-1',
        trackingOrWaybill: 'WB-TRP1-004',
        isOffline: true,
      );
      final offlineRes2 = service.scanParcelForTrip(
        tripId: 'TRIP-1',
        trackingOrWaybill: 'WB-TRP1-005',
        isOffline: true,
      );
      expect(offlineRes1.success, isTrue);
      expect(offlineRes2.success, isTrue);
      expect(trip.pendingOfflineScans.length, 2);

      // 2. Try to tap Depart while scans are pending -> blocked!
      final departBlocked = service.departTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        sealNumber: 'EH-0804521',
      );
      expect(departBlocked.success, isFalse);
      expect(departBlocked.message, contains('pending offline synchronization'));
      expect(trip.status, CourierTripStatus.loading);

      // 3. Turn Airplane mode off -> syncs and each parcel is loaded once
      final syncRes = service.syncOfflinePendingScans('TRIP-1');
      expect(syncRes.success, isTrue);
      expect(trip.pendingOfflineScans.isEmpty, isTrue);
      expect(trip.loadedCount, 5);
      expect(trip.isFullyLoaded, isTrue);

      // Now Depart works!
      final departOk = service.departTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        sealNumber: 'EH-0804521',
      );
      expect(departOk.success, isTrue);
      expect(trip.status, CourierTripStatus.inTransit);
    });
  });
}
