import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/external_notification_service.dart';
import 'package:nexora_rider_app/core/services/rider_service.dart';
import 'package:nexora_rider_app/features/courier/models/courier_models.dart';
import 'package:nexora_rider_app/features/courier/presentation/trip_details_screen.dart';
import 'package:nexora_rider_app/features/courier/services/courier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CourierService.instance.resetToSeed();
    RiderService.instance.setOnlineStatus(true);
    RiderService.instance.hasActiveTripCallback = null;
  });

  group('Courier Trip Assignment Test Suite (COU-TRIP-001 to COU-TRIP-008)', () {
    // -------------------------------------------------------------------------
    // COU-TRIP-001: View an assigned trip
    // -------------------------------------------------------------------------
    testWidgets('COU-TRIP-001: View an assigned trip details and specs', (tester) async {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1');

      expect(trip, isNotNull);
      expect(trip!.id, 'TRIP-1');
      expect(trip.originHubId, 'HUB-QC');
      expect(trip.originAddress, contains('Quezon City'));
      expect(trip.destinationHubId, 'HUB-PSG');
      expect(trip.destinationHubName, contains('Kapitolyo, Pasig'));
      expect(trip.destinationAddress, contains('Kapitolyo, Pasig City'));
      expect(trip.parcelsCount, 5);
      expect(trip.weightKg, 3.6);
      expect(trip.payAmount, 1000.00);
      expect(trip.status, CourierTripStatus.assigned);
      expect(trip.scheduledDeparture, isNotNull);

      // Verify UI displays all required fields
      await tester.pumpWidget(
        const MaterialApp(
          home: TripDetailsScreen(tripId: 'TRIP-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TRIP-1'), findsWidgets);
      expect(find.textContaining('HUB-QC'), findsWidgets);
      expect(find.textContaining('HUB-PSG'), findsWidgets);
      expect(find.text('5 parcels'), findsOneWidget); // Parcels count
      expect(find.text('3.6 kg'), findsOneWidget); // Weight
      expect(find.textContaining('1000'), findsWidgets); // Scheduled pay
      expect(find.text('Accept Trip'), findsOneWidget);
      expect(find.text('Decline Trip'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // COU-TRIP-002: Accept the trip
    // -------------------------------------------------------------------------
    test('COU-TRIP-002: Accept trip -> status Accepted, Start Loading available, Logistics 1 notified', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      expect(trip.status, CourierTripStatus.assigned);
      expect(trip.acceptedAt, isNull);

      // 1. Courier 1 accepts the trip
      final acceptResult = service.acceptTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        companyId: 'LOGISTICS-1',
        expectedVersion: trip.version,
      );

      expect(acceptResult.success, isTrue);
      expect(trip.status, CourierTripStatus.accepted);
      expect(trip.acceptedAt, isNotNull);

      // Logistics 1 sees Courier 1 accepted it, with the time
      expect(service.dispatchNotifications.first, contains('[Trip Accepted]'));
      expect(service.dispatchNotifications.first, contains('accepted TRIP-1'));
      expect(service.dispatchNotifications.first, contains('Start Loading is now available'));

      // 2. Start Loading is now available
      final loadingResult = service.startLoadingTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
      );
      expect(loadingResult.success, isTrue);
      expect(trip.status, CourierTripStatus.loading);
      expect(service.dispatchNotifications.first, contains('[Trip Loading]'));
    });

    // -------------------------------------------------------------------------
    // COU-TRIP-003: Decline a trip with a reason
    // -------------------------------------------------------------------------
    test('COU-TRIP-003: Decline trip without reason is blocked; confirm with reason sets Unassigned and ₱0.00 payout', () {
      final service = CourierService.instance;

      // 1. Tap Decline and confirm without a reason -> blocked
      final blockedResult = service.declineTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        reason: '   ',
      );
      expect(blockedResult.success, isFalse);
      expect(blockedResult.message, contains('reason is required'));

      final tripBefore = service.getTripById('TRIP-1')!;
      expect(tripBefore.status, CourierTripStatus.assigned);

      // 2. Choose 'Vehicle problem' and confirm
      final confirmResult = service.declineTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        reason: 'Vehicle problem',
      );
      expect(confirmResult.success, isTrue);

      // 3. As Logistics 1, open trip list: TRIP-1 is back to Unassigned with reason shown, payout ₱0.00
      final tripAfter = service.getTripById('TRIP-1')!;
      expect(tripAfter.status, CourierTripStatus.unassigned);
      expect(tripAfter.assignedCourierId, isNull);
      expect(tripAfter.declinedReason, 'Vehicle problem');

      final latestLog = service.dispatchNotifications.first;
      expect(latestLog, contains('[Trip Declined]'));
      expect(latestLog, contains('Vehicle problem'));
      expect(latestLog, contains('Trip returned to Unassigned'));
      expect(latestLog, contains('Courier payout: ₱0.00'));
    });

    // -------------------------------------------------------------------------
    // COU-TRIP-004: Only one active trip per courier
    // -------------------------------------------------------------------------
    test('COU-TRIP-004: Courier 1 with accepted TRIP-1 cannot be assigned TRIP-2', () {
      final service = CourierService.instance;

      // Precondition: Courier 1 has accepted TRIP-1
      service.acceptTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        companyId: 'LOGISTICS-1',
      );

      expect(service.getActiveTripForCourier('NX-RD-001')?.id, 'TRIP-1');

      // 1. As Logistics 1, try to assign TRIP-2 to Courier 1
      final assignResult = service.assignTripToCourier(
        tripId: 'TRIP-2',
        courierId: 'NX-RD-001',
      );

      // Assignment is blocked with a message that the courier already has a trip
      expect(assignResult.success, isFalse);
      expect(assignResult.message, contains('already has an active trip'));
      expect(assignResult.message, contains('TRIP-1'));

      final trip2 = service.getTripById('TRIP-2')!;
      expect(trip2.status, CourierTripStatus.unassigned);
      expect(trip2.assignedCourierId, isNull);
    });

    // -------------------------------------------------------------------------
    // COU-TRIP-005: Accept and reassignment at the same moment
    // -------------------------------------------------------------------------
    test('COU-TRIP-005: Concurrency race condition - accept rejected if reassigned to Courier 2', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;
      final originalVersion = trip.version;

      // Simulate simultaneous action: Logistics 1 reassigns TRIP-1 to Courier 2 (NX-RD-002)
      final reassignResult = service.assignTripToCourier(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-002',
      );
      expect(reassignResult.success, isTrue);
      expect(trip.assignedCourierId, 'NX-RD-002');
      expect(trip.version, greaterThan(originalVersion));

      // Courier 1 tries to accept with the stale version / old assignment
      final acceptResult = service.acceptTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        companyId: 'LOGISTICS-1',
        expectedVersion: originalVersion,
      );

      // Exactly one courier has TRIP-1, other side gets already assigned message
      expect(acceptResult.success, isFalse);
      expect(acceptResult.message, contains('already been reassigned'));
      expect(trip.assignedCourierId, 'NX-RD-002');
    });

    // -------------------------------------------------------------------------
    // COU-TRIP-006: Cannot accept another company's trip
    // -------------------------------------------------------------------------
    test('COU-TRIP-006: Accept request for another company trip is rejected with 403 Forbidden', () {
      final service = CourierService.instance;

      // Seed a trip belonging to another logistics company (LOGISTICS-2)
      service.addTrip(
        CourierTrip(
          id: 'TRIP-LOG2-99',
          companyId: 'LOGISTICS-2',
          originHubId: 'HUB-MAKATI',
          originHubName: 'Makati Central Hub',
          originAddress: 'Ayala Ave, Makati City',
          destinationHubId: 'HUB-BGC',
          destinationHubName: 'BGC Hub',
          destinationAddress: '5th Ave, BGC, Taguig City',
          destinationLatitude: 14.5547,
          destinationLongitude: 121.0244,
          parcelsCount: 3,
          weightKg: 2.1,
          scheduledDeparture: DateTime.now().add(const Duration(hours: 1)),
          payAmount: 750.00,
          status: CourierTripStatus.assigned,
          assignedCourierId: 'NX-RD-001',
        ),
      );

      // Courier 1 belongs to LOGISTICS-1 and tries to accept TRIP-LOG2-99
      final acceptResult = service.acceptTrip(
        tripId: 'TRIP-LOG2-99',
        courierId: 'NX-RD-001',
        companyId: 'LOGISTICS-1',
      );

      // Rejected: 403 Forbidden. The trip is unchanged.
      expect(acceptResult.success, isFalse);
      expect(acceptResult.message, contains('403 Forbidden'));
      expect(acceptResult.message, contains('another logistics company'));

      final otherTrip = service.getTripById('TRIP-LOG2-99')!;
      expect(otherTrip.status, CourierTripStatus.assigned);
    });

    // -------------------------------------------------------------------------
    // COU-TRIP-007: [Mobile] Trip notification while the phone is locked
    // -------------------------------------------------------------------------
    test('COU-TRIP-007: Logistics 1 assigns trip -> external push notification dispatches with trip payload', () {
      final service = CourierService.instance;

      // Unassign TRIP-1 first to re-trigger assignment
      final trip = service.getTripById('TRIP-1')!;
      trip.status = CourierTripStatus.unassigned;
      trip.assignedCourierId = null;

      // Logistics 1 assigns TRIP-1 to Courier 1
      final res = service.assignTripToCourier(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
      );
      expect(res.success, isTrue);

      // External notification is triggered with sound and payload
      final notifications = ExternalNotificationService.simulatedNotifications;
      expect(notifications.isNotEmpty, isTrue);

      final latest = notifications.last;
      expect(latest.title, contains('New Trip Assigned: TRIP-1'));
      expect(latest.body, contains('HUB-QC → HUB-PSG'));
      expect(latest.payload, 'trip:TRIP-1');

      // Tapping notification payload maps to TRIP-1
      final tappedTripId = latest.payload?.replaceFirst('trip:', '');
      expect(tappedTripId, 'TRIP-1');
      final fetchedTrip = service.getTripById(tappedTripId!);
      expect(fetchedTrip, isNotNull);
      expect(fetchedTrip!.id, 'TRIP-1');
    });

    // -------------------------------------------------------------------------
    // COU-TRIP-008: [Mobile] Navigate to the destination hub
    // -------------------------------------------------------------------------
    test('COU-TRIP-008: Destination hub navigation coordinates & state preservation', () {
      final service = CourierService.instance;
      final trip = service.getTripById('TRIP-1')!;

      // Precondition: Courier 1 with TRIP-1 accepted
      service.acceptTrip(
        tripId: 'TRIP-1',
        courierId: 'NX-RD-001',
        companyId: 'LOGISTICS-1',
      );
      expect(trip.status, CourierTripStatus.accepted);

      // 1. Check coordinates for HUB-PSG (Kapitolyo, Pasig)
      expect(trip.destinationHubName, contains('Kapitolyo, Pasig'));
      expect(trip.destinationLatitude, 14.5738);
      expect(trip.destinationLongitude, 121.0594);

      // 2. Validate Google Maps navigation URL
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${trip.destinationLatitude},${trip.destinationLongitude}',
      );
      expect(googleMapsUrl.toString(), contains('destination=14.5738,121.0594'));

      // Validate Waze navigation URL
      final wazeUrl = Uri.parse(
        'https://waze.com/ul?ll=${trip.destinationLatitude},${trip.destinationLongitude}&navigate=yes',
      );
      expect(wazeUrl.toString(), contains('ll=14.5738,121.0594'));

      // 3. Switch back to courier app: state is intact and shows same trip
      final reloadedTrip = service.getTripById('TRIP-1')!;
      expect(reloadedTrip.status, CourierTripStatus.accepted);
      expect(reloadedTrip.assignedCourierId, 'NX-RD-001');
      expect(reloadedTrip.payAmount, 1000.00);
    });
  });
}
