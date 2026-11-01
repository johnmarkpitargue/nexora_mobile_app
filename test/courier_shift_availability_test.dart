import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/rider_service.dart';
import 'package:nexora_rider_app/features/courier/services/courier_service.dart';
import 'package:nexora_rider_app/features/courier/services/pre_trip_inspection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CourierService.instance.resetToSeed();
    PreTripInspectionService.instance.reset();
    RiderService.instance.setOnlineStatus(false);
  });

  group('Courier Shift & Availability Test Suite (COU-SHIFT-001 to 007)', () {
    test('COU-SHIFT-001: Go On Duty after a passed pre-trip checklist', () {
      final inspectionService = PreTripInspectionService.instance;
      final courierService = CourierService.instance;
      final riderService = RiderService.instance;

      expect(riderService.profile.isOnline, isFalse);

      // 1. Mark all 5 checklist items OK (Tires, Lights, Brakes, Fuel, Cargo door lock)
      for (final item in PreTripInspectionService.checklistItems) {
        inspectionService.setAnswer(item.id, true);
      }

      // 2. Submit checklist
      final result = inspectionService.submitChecklist(
        riderId: riderService.profile.id,
        location: 'HUB-QC',
      );

      // Courier 1 is On Duty
      expect(result.success, isTrue);
      expect(riderService.profile.isOnline, isTrue);

      // Logistics 1 sees Courier 1 On Duty with current location and checklist time
      final courier = courierService.riders.firstWhere((r) => r.id == riderService.profile.id);
      expect(courier.isOnline, isTrue);
      expect(courier.currentLocation, 'HUB-QC');
      expect(courier.checklistCompletedAt, isNotNull);
      expect(courierService.dispatchNotifications.first, contains('Pre-Trip Passed'));
      expect(courierService.dispatchNotifications.first, contains('HUB-QC'));
    });

    test('COU-SHIFT-002: Checklist item marked Not OK requires note, blocks On Duty, notifies Logistics 1', () {
      final inspectionService = PreTripInspectionService.instance;
      final courierService = CourierService.instance;
      final riderService = RiderService.instance;

      // 1. Mark Brakes Not OK with no note and submit
      inspectionService.setAnswer('tires', true);
      inspectionService.setAnswer('lights', true);
      inspectionService.setAnswer('brakes', false);
      inspectionService.setAnswer('fuel', true);
      inspectionService.setAnswer('cargo_lock', true);

      final resStep1 = inspectionService.submitChecklist(
        riderId: riderService.profile.id,
        location: 'HUB-QC',
      );

      // Step 1 is blocked: a note is required
      expect(resStep1.success, isFalse);
      expect(resStep1.errorMessage, contains('note is required'));
      expect(riderService.profile.isOnline, isFalse);

      // 2. Add note: "Brake pedal feels soft, needs checking" and submit
      inspectionService.setNote('brakes', 'Brake pedal feels soft, needs checking');
      final resStep2 = inspectionService.submitChecklist(
        riderId: riderService.profile.id,
        location: 'HUB-QC',
      );

      // Step 2: Courier 1 stays Off Duty and cannot be assigned
      expect(resStep2.success, isFalse);
      expect(resStep2.isSafetyGrounded, isTrue);
      expect(riderService.profile.isOnline, isFalse);

      final courier = courierService.riders.firstWhere((r) => r.id == riderService.profile.id);
      expect(courier.isOnline, isFalse);
      expect(courier.preTripIssue, 'Brakes');
      expect(courier.preTripNote, 'Brake pedal feels soft, needs checking');

      // Attempting to assign parcel to offline rider fails
      final assignSuccess = courierService.assignParcelToRider(
        parcelId: courierService.parcels.first.id,
        riderId: courier.id,
      );
      expect(assignSuccess, isFalse);

      // Logistics 1 is notified with the item and the note
      expect(courierService.dispatchNotifications.first, contains('Safety Incident'));
      expect(courierService.dispatchNotifications.first, contains('Brakes Not OK'));
      expect(courierService.dispatchNotifications.first, contains('Brake pedal feels soft, needs checking'));
    });

    test('COU-SHIFT-003: Checklist not finished (unanswered item)', () {
      final inspectionService = PreTripInspectionService.instance;
      final riderService = RiderService.instance;

      // Answer 4 items and leave Fuel unanswered
      inspectionService.setAnswer('tires', true);
      inspectionService.setAnswer('lights', true);
      inspectionService.setAnswer('brakes', true);
      inspectionService.setAnswer('cargo_lock', true);
      // fuel left null

      final result = inspectionService.submitChecklist(
        riderId: riderService.profile.id,
        location: 'HUB-QC',
      );

      // Blocked with a message to answer every item; Courier 1 stays Off Duty
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('answer every inspection item'));
      expect(result.errorMessage, contains('Fuel is unanswered'));
      expect(riderService.profile.isOnline, isFalse);
    });

    test('COU-SHIFT-004: Off Duty is blocked during an active trip', () {
      final riderService = RiderService.instance;

      // Courier is On Duty
      riderService.setOnlineStatus(true);
      expect(riderService.profile.isOnline, isTrue);

      // Simulate TRIP-1 In Transit
      riderService.hasActiveTripCallback = () => true;

      // Tap Go Off Duty
      final result = riderService.toggleOnlineStatus();

      // Blocked with message that trip must be handed over/completed first
      expect(result.success, isFalse);
      expect(result.message, contains('Cannot Go Off Duty: You have an active trip in transit'));
      // Courier 1 stays On Duty
      expect(riderService.profile.isOnline, isTrue);

      // Clean up callback
      riderService.hasActiveTripCallback = null;
    });

    test('COU-SHIFT-005: Go Off Duty with no trip', () {
      final riderService = RiderService.instance;
      final courierService = CourierService.instance;

      // Courier 1 Active, On Duty, no active trip
      riderService.setOnlineStatus(true);
      courierService.setRiderDutyStatus(riderId: riderService.profile.id, isOnline: true);
      riderService.hasActiveTripCallback = () => false;

      // Tap Go Off Duty
      final result = riderService.toggleOnlineStatus();
      expect(result.success, isTrue);
      expect(riderService.profile.isOnline, isFalse);

      courierService.setRiderDutyStatus(riderId: riderService.profile.id, isOnline: false);

      // Logistics 1: Courier 1 is Off Duty and cannot be assigned
      final courier = courierService.riders.firstWhere((r) => r.id == riderService.profile.id);
      expect(courier.isOnline, isFalse);

      // Cannot be assigned
      final assignSuccess = courierService.assignParcelToRider(
        parcelId: courierService.parcels.first.id,
        riderId: courier.id,
      );
      expect(assignSuccess, isFalse);

      // Filtered out from assignment
      final assignableRiders = courierService.riders.where((r) => r.isOnline).toList();
      expect(assignableRiders.any((r) => r.id == courier.id), isFalse);
    });

    test('COU-SHIFT-007: Stale heartbeat / app force close marks rider offline (location unknown)', () {
      final courierService = CourierService.instance;
      final rider = courierService.riders.first;
      rider.isOnline = true;
      rider.lastHeartbeat = DateTime.now().subtract(const Duration(minutes: 6));

      courierService.evaluateHeartbeats();

      expect(rider.isOnline, isFalse);
      expect(rider.isLocationUnknown, isTrue);
      expect(courierService.dispatchNotifications.first, contains('Heartbeat Timeout'));
    });
  });
}
