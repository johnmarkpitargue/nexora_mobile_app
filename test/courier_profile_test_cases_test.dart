import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/features/courier/presentation/courier_profile_screen.dart';
import 'package:nexora_rider_app/features/courier/services/courier_profile_service.dart';

void main() {
  setUp(() {
    CourierProfileService.instance.resetState();
    CourierProfileService.instance.switchCourier('NX-CR-001');
  });

  group('Profile, Vehicle & Documents Test Suite (COU-PROF-001 to COU-PROF-008)', () {
    testWidgets('COU-PROF-001: View profile, vehicle and documents',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CourierProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Courier 1 details
      expect(find.text('Ernesto Villareal'), findsOneWidget);
      expect(find.text('N02-15-345678'), findsOneWidget);
      expect(find.text('Professional; codes B, B2, C'), findsOneWidget);
      expect(find.text('07/15/2029'), findsOneWidget);
      expect(find.text('4-Wheeler Closed Van Truck'), findsOneWidget);
      expect(find.text('NAB4521'), findsOneWidget);
      expect(find.text('3,000 kg'), findsOneWidget);
      expect(find.textContaining('HUB-QC'), findsNWidgets(2));
      expect(find.textContaining('Bilis Hatid Express Inc.'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // 1. Open Professional Driver's License
      final licenseDocItem = find.text("Professional Driver's License");
      await tester.ensureVisible(licenseDocItem);
      await tester.pumpAndSettle();
      await tester.tap(licenseDocItem);
      await tester.pumpAndSettle();

      expect(find.text('✓ Active & Verified'), findsOneWidget);
      expect(find.text('driver_license_ernesto.jpg'), findsWidgets);
      expect(find.text('Close Document Preview'), findsOneWidget);
      await tester.tap(find.text('Close Document Preview'));
      await tester.pumpAndSettle();

      // 2. Open Vehicle Registration (OR/CR)
      final orCrDocItem = find.text('Vehicle Registration (OR/CR)');
      await tester.ensureVisible(orCrDocItem);
      await tester.pumpAndSettle();
      await tester.tap(orCrDocItem);
      await tester.pumpAndSettle();

      expect(find.text('LAND TRANSPORTATION OFFICE (LTO)'), findsOneWidget);
      expect(find.text('truck_or_cr.pdf'), findsWidgets);
      await tester.tap(find.text('Close Document Preview'));
      await tester.pumpAndSettle();

      // 3. Open NBI Clearance
      final nbiDocItem = find.text('NBI Clearance');
      await tester.ensureVisible(nbiDocItem);
      await tester.pumpAndSettle();
      await tester.tap(nbiDocItem);
      await tester.pumpAndSettle();

      expect(find.text('NATIONAL BUREAU OF INVESTIGATION (NBI)'), findsOneWidget);
      expect(find.text('nbi_clearance_ernesto.pdf'), findsWidgets);
      await tester.tap(find.text('Close Document Preview'));
      await tester.pumpAndSettle();
    });

    testWidgets('COU-PROF-002: Update load capacity and OR/CR',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CourierProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3,000 kg'), findsOneWidget);

      // Open Edit Vehicle Details
      final editBtn = find.text('Edit Vehicle Details');
      await tester.ensureVisible(editBtn);
      await tester.pumpAndSettle();
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Change Load Capacity to 2500
      final capacityField = find.byKey(const Key('courier_capacity_input'));
      expect(capacityField, findsOneWidget);
      await tester.enterText(capacityField, '2500');
      await tester.pumpAndSettle();

      // Save changes
      final saveBtn = find.text('Save & Submit for Re-verification');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // The change is saved: Logistics 1 sees 2,500 kg and new OR/CR, flagged for re-verification
      expect(find.text('2,500 kg'), findsOneWidget);
      expect(find.text('3,000 kg'), findsNothing);
      expect(find.text('Pending Re-verification'), findsOneWidget);
      expect(find.text('Flagged for Logistics 1 review.'), findsOneWidget);

      // Step 3 & 4: As Logistics 1, change capacity back to 3000
      CourierProfileService.instance.setLoadCapacityByLogistics(3000);
      await tester.pumpAndSettle();

      expect(find.text('3,000 kg'), findsOneWidget);
      expect(find.text('2,500 kg'), findsNothing);
    });

    testWidgets('COU-PROF-003: Plate number already used by a courier or a rider',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CourierProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NAB4521'), findsOneWidget);

      final editBtn = find.text('Edit Vehicle Details');
      await tester.ensureVisible(editBtn);
      await tester.pumpAndSettle();
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      final plateField = find.byKey(const Key('courier_plate_input'));
      expect(plateField, findsOneWidget);

      // 1. Try CAV7789 (Courier 2)
      await tester.enterText(plateField, 'CAV7789');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & Submit for Re-verification'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already registered to another courier or rider'),
        findsOneWidget,
      );

      // 2. Try cav7789 (Courier 2 lowercase)
      await tester.enterText(plateField, 'cav7789');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & Submit for Re-verification'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already registered to another courier or rider'),
        findsOneWidget,
      );

      // 3. Try 123ABC (Rider 1)
      await tester.enterText(plateField, '123ABC');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save & Submit for Re-verification'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already registered to another courier or rider'),
        findsOneWidget,
      );

      // Close modal
      Navigator.pop(tester.element(find.text('Save & Submit for Re-verification')));
      await tester.pumpAndSettle();

      // Plate stays NAB4521
      expect(find.text('NAB4521'), findsOneWidget);
      expect(find.text('CAV7789'), findsNothing);
      expect(find.text('123ABC'), findsNothing);
    });

    test('COU-PROF-004: License expiry boundary (Yesterday vs Today)', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final today = DateTime(now.year, now.month, now.day);

      // 1. Yesterday is rejected with expiry message
      final resYesterday = CourierProfileService.instance.updateLicenseExpiry(yesterday);
      expect(resYesterday.success, isFalse);
      expect(resYesterday.message, contains('expired'));

      // 2. Today is accepted
      final resToday = CourierProfileService.instance.updateLicenseExpiry(today);
      expect(resToday.success, isTrue);
      expect(resToday.message, contains('successfully updated'));

      // 3. Set it back to 07/15/2029
      final originalDate = DateTime(2029, 7, 15);
      final resOriginal = CourierProfileService.instance.updateLicenseExpiry(originalDate);
      expect(resOriginal.success, isTrue);
      expect(CourierProfileService.instance.profile.licenseExpiry, '07/15/2029');
    });

    test('COU-PROF-005: Document upload rules (NBI Clearance size and extension boundary)', () {
      // 1. size_5.0MB.jpg (accept)
      final res5Mb = CourierProfileService.instance.uploadNbiClearance(
        fileName: 'size_5.0MB.jpg',
        fileSizeMb: 5.0,
      );
      expect(res5Mb.success, isTrue);
      expect(CourierProfileService.instance.profile.nbiClearanceDocName, 'size_5.0MB.jpg');

      // 2. size_5.1MB.jpg (reject > 5.0 MB), previous document kept
      final res51Mb = CourierProfileService.instance.uploadNbiClearance(
        fileName: 'size_5.1MB.jpg',
        fileSizeMb: 5.1,
      );
      expect(res51Mb.success, isFalse);
      expect(res51Mb.message, contains('exceeds the 5.0 MB limit'));
      expect(CourierProfileService.instance.profile.nbiClearanceDocName, 'size_5.0MB.jpg');

      // 3. price_list.docx (reject invalid format), previous kept
      final resDocx = CourierProfileService.instance.uploadNbiClearance(
        fileName: 'price_list.docx',
        fileSizeMb: 1.2,
      );
      expect(resDocx.success, isFalse);
      expect(resDocx.message, contains('Invalid file format'));
      expect(CourierProfileService.instance.profile.nbiClearanceDocName, 'size_5.0MB.jpg');

      // 4. renamed_exe.jpg (reject executable), previous kept
      final resExe = CourierProfileService.instance.uploadNbiClearance(
        fileName: 'renamed_exe.jpg',
        fileSizeMb: 1.0,
      );
      expect(resExe.success, isFalse);
      expect(resExe.message, contains('Invalid file format'));
      expect(CourierProfileService.instance.profile.nbiClearanceDocName, 'size_5.0MB.jpg');
    });

    testWidgets('COU-PROF-006: Suspended courier cannot work',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Switch to Courier 3 (Suspended)
      CourierProfileService.instance.switchCourier('NX-CR-003');

      await tester.pumpWidget(
        const MaterialApp(
          home: CourierProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rodrigo Mendoza (Suspended)'), findsOneWidget);
      expect(find.text('SUSPENDED'), findsOneWidget);
      expect(find.text('OFF DUTY'), findsOneWidget);

      // Try to go On Duty
      final dutySwitch = find.byType(Switch);
      expect(dutySwitch, findsOneWidget);
      await tester.tap(dutySwitch);
      await tester.pumpAndSettle();

      // Suspension notice dialog appears and Courier 3 remains Off Duty
      expect(find.text('Suspension Notice'), findsOneWidget);
      expect(
        find.textContaining('Account Suspended: You cannot go On Duty or accept dispatches'),
        findsOneWidget,
      );
      expect(CourierProfileService.instance.profile.isOnDuty, isFalse);
    });

    testWidgets('COU-PROF-007: Courier cannot see another courier\'s profile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Logged in as Courier 1, but proxy tool on phone requests Courier 2's ID
      await tester.pumpWidget(
        const MaterialApp(
          home: CourierProfileScreen(initialCourierId: 'NX-CR-002'),
        ),
      );
      await tester.pumpAndSettle();

      // Denied. No Courier 2 data is shown.
      expect(find.text('Access Denied (COU-PROF-007)'), findsOneWidget);
      expect(find.textContaining('Denied. No Courier 2 data is shown.'), findsOneWidget);
      expect(find.text('Danilo Santos'), findsNothing);

      // Return to My Verified Profile
      await tester.tap(find.text('Return to My Verified Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Ernesto Villareal'), findsOneWidget);
    });

    testWidgets('COU-PROF-008: [Mobile] Update documents with the camera and the Files app',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CourierProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Replace Professional Driver's License using Take Photo (Camera)
      final replaceLicenseBtn = find.byTooltip('Upload / Replace Document').first;
      await tester.ensureVisible(replaceLicenseBtn);
      await tester.pumpAndSettle();
      await tester.tap(replaceLicenseBtn);
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(find.text('license_camera_capture.jpg'), findsOneWidget);
      expect(CourierProfileService.instance.profile.licenseDocName, 'license_camera_capture.jpg');
      expect(find.text('Pending Re-verification'), findsOneWidget);

      // 2. Replace OR/CR from Files
      final replaceOrCrBtn = find.byTooltip('Upload / Replace Document').at(1);
      await tester.ensureVisible(replaceOrCrBtn);
      await tester.pumpAndSettle();
      await tester.tap(replaceOrCrBtn);
      await tester.pumpAndSettle();

      expect(find.text('Choose from Files'), findsOneWidget);
      await tester.tap(find.text('Choose from Files'));
      await tester.pumpAndSettle();

      expect(CourierProfileService.instance.profile.orCrDocName, 'truck_or_cr.pdf');
      expect(CourierProfileService.instance.profile.vehicleReverificationStatus, 'Pending Re-verification');
      expect(find.text('Flagged for Logistics 1 review.'), findsOneWidget);
    });
  });
}
