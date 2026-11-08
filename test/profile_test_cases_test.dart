import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/rider_service.dart';
import 'package:nexora_rider_app/features/profile/presentation/rider_profile_screen.dart';

void main() {
  setUp(() {
    // Reset to Rider 1 before each test
    RiderService.instance.switchRider('NX-RD-001');
  });

  group('Profile, Vehicle & Documents Test Suite (RID-PROF-001 to 007)', () {
    testWidgets(
        'RID-PROF-001: View profile, vehicle, and verification status with opening documents',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Rider 1 details
      expect(find.text('Pedro Jose Garcia'), findsOneWidget);
      expect(find.text('NX-RD-001 • Bilis Hatid Express Inc.'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('123ABC'), findsOneWidget);
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(
          find.textContaining('License: N01-23-456789 (Exp: 03/22/2030)'),
          findsOneWidget);

      // Open Driver's License document
      final licenseItem = find.text("Professional Driver's License");
      await tester.ensureVisible(licenseItem);
      await tester.pumpAndSettle();
      await tester.tap(licenseItem);
      await tester.pumpAndSettle();

      // Verify License document modal opened
      expect(find.text('✓ Active & Verified'), findsOneWidget);
      expect(find.textContaining('driver_license_front.jpg'), findsNWidgets(2));
      expect(find.text('Close Document Preview'), findsOneWidget);
      await tester.tap(find.text('Close Document Preview'));
      await tester.pumpAndSettle();

      // Open OR/CR document
      final orCrItem = find.text('Vehicle Registration (OR/CR)');
      await tester.ensureVisible(orCrItem);
      await tester.pumpAndSettle();
      await tester.tap(orCrItem);
      await tester.pumpAndSettle();

      // Verify OR/CR modal opened
      expect(find.text('LAND TRANSPORTATION OFFICE (LTO)'), findsOneWidget);
      expect(find.textContaining('or_cr_receipt.pdf'), findsNWidgets(3));
      await tester.tap(find.text('Close Document Preview'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'RID-PROF-002: Update vehicle details with new plate and new OR/CR (flagged for re-verification)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('123ABC'), findsOneWidget);

      // Open Edit Vehicle Details
      final editBtn = find.text('Edit Vehicle Details');
      await tester.ensureVisible(editBtn);
      await tester.pumpAndSettle();
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Enter valid plate 789GHI
      final plateInput = find.byType(TextField);
      await tester.enterText(plateInput, '789GHI');
      await tester.pumpAndSettle();

      // Submit changes
      final saveBtn = find.text('Save & Submit for Re-verification');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Old plate 123ABC is no longer shown; new plate 789GHI is shown
      expect(find.text('789GHI'), findsOneWidget);
      expect(find.text('123ABC'), findsNothing);

      // Flagged for re-verification
      expect(find.text('Pending Re-verification'), findsOneWidget);
      expect(find.text('Flagged for Logistics 1'), findsOneWidget);
    });

    testWidgets(
        'RID-PROF-003: Plate number already used (ABC1234, abc1234) is blocked',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open Edit Vehicle Details
      final editBtn = find.text('Edit Vehicle Details');
      await tester.ensureVisible(editBtn);
      await tester.pumpAndSettle();
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      final plateInput = find.byType(TextField);

      // Case 1: Try duplicate uppercase ABC1234
      await tester.enterText(plateInput, 'ABC1234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Submit for Re-verification'));
      await tester.pumpAndSettle();

      // Blocked with duplicate message
      expect(
        find.textContaining('already registered to another active fleet vehicle'),
        findsOneWidget,
      );

      // Case 2: Try duplicate lowercase abc1234
      await tester.enterText(plateInput, 'abc1234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save & Submit for Re-verification'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('already registered to another active fleet vehicle'),
        findsOneWidget,
      );

      // Close modal without saving invalid plate
      Navigator.pop(tester.element(find.byType(TextField)));
      await tester.pumpAndSettle();

      // Plate remains 123ABC
      expect(find.text('123ABC'), findsOneWidget);
      expect(find.text('ABC1234'), findsNothing);
    });

    test('RID-PROF-004: License expiry boundary (Yesterday vs Today)', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final today = DateTime(now.year, now.month, now.day);

      // Yesterday is rejected with expiry message
      final resYesterday =
          RiderService.instance.updateLicenseExpiry(yesterday);
      expect(resYesterday.success, isFalse);
      expect(resYesterday.message, contains('expired'));

      // Today is accepted
      final resToday = RiderService.instance.updateLicenseExpiry(today);
      expect(resToday.success, isTrue);
      expect(resToday.message, contains('successfully updated'));
    });

    test('RID-PROF-005: Document upload rules (Size and format boundary)', () {
      // 1. size_5.0MB.jpg is accepted
      final res5Mb = RiderService.instance.uploadDriverLicense(
        fileName: 'size_5.0MB.jpg',
        fileSizeMb: 5.0,
      );
      expect(res5Mb.success, isTrue);
      expect(RiderService.instance.profile.licenseDocName, 'size_5.0MB.jpg');

      // 2. size_5.1MB.jpg is rejected (> 5.0MB), previous kept
      final res51Mb = RiderService.instance.uploadDriverLicense(
        fileName: 'size_5.1MB.jpg',
        fileSizeMb: 5.1,
      );
      expect(res51Mb.success, isFalse);
      expect(res51Mb.message, contains('exceeds the 5.0 MB limit'));
      expect(RiderService.instance.profile.licenseDocName, 'size_5.0MB.jpg');

      // 3. price_list.docx is rejected (invalid format), previous kept
      final resDocx = RiderService.instance.uploadDriverLicense(
        fileName: 'price_list.docx',
        fileSizeMb: 1.2,
      );
      expect(resDocx.success, isFalse);
      expect(resDocx.message, contains('Invalid file format'));
      expect(RiderService.instance.profile.licenseDocName, 'size_5.0MB.jpg');

      // 4. renamed_exe.jpg is rejected (executable name), previous kept
      final resExe = RiderService.instance.uploadDriverLicense(
        fileName: 'renamed_exe.jpg',
        fileSizeMb: 1.0,
      );
      expect(resExe.success, isFalse);
      expect(resExe.message, contains('Invalid file format'));
      expect(RiderService.instance.profile.licenseDocName, 'size_5.0MB.jpg');

      // 5. OR/CR Document upload test
      final resOrCrOk = RiderService.instance.uploadOrCrDocument(
        fileName: 'my_or_cr.pdf',
        fileSizeMb: 2.5,
      );
      expect(resOrCrOk.success, isTrue);
      expect(RiderService.instance.profile.orCrDocName, 'my_or_cr.pdf');
      expect(RiderService.instance.profile.vehicleReverificationStatus,
          'Pending Re-verification');

      final resOrCrTooBig = RiderService.instance.uploadOrCrDocument(
        fileName: 'huge_or_cr.pdf',
        fileSizeMb: 5.5,
      );
      expect(resOrCrTooBig.success, isFalse);
      expect(resOrCrTooBig.message, contains('exceeds the 5.0 MB limit'));
      expect(RiderService.instance.profile.orCrDocName, 'my_or_cr.pdf');

      // 6. Test validateUploadedDocument function
      final valJpg = validateUploadedDocument(fileName: 'license.jpg', sizeMb: 3.2);
      expect(valJpg.isValid, isTrue);
      expect(valJpg.fileTypeLabel, 'JPEG Image');

      final valPdf = validateUploadedDocument(fileName: 'doc.pdf', sizeMb: 4.8);
      expect(valPdf.isValid, isTrue);
      expect(valPdf.fileTypeLabel, 'PDF Document');

      final valPng = validateUploadedDocument(fileName: 'photo.png', sizeMb: 2.0);
      expect(valPng.isValid, isTrue);
      expect(valPng.fileTypeLabel, 'PNG Image');

      final valTooLarge = validateUploadedDocument(fileName: 'scan.pdf', sizeMb: 5.2);
      expect(valTooLarge.isValid, isFalse);
      expect(valTooLarge.errorMessage, contains('exceeds the 5.0 MB limit'));

      final valDocx = validateUploadedDocument(fileName: 'contract.docx', sizeMb: 1.0);
      expect(valDocx.isValid, isFalse);
      expect(valDocx.errorMessage, contains('Invalid file format'));
    });

    testWidgets('RID-PROF-006: Suspended rider cannot work or go online',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Switch to Rider 3 (Suspended)
      RiderService.instance.switchRider('NX-RD-003');

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUSPENDED'), findsOneWidget);
      expect(find.text('Account Suspended'), findsOneWidget);

      // Try to go Online
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // Suspension notice dialog appears and rider remains offline
      expect(find.text('Suspension Notice'), findsOneWidget);
      expect(
        find.textContaining('You cannot go online or accept deliveries'),
        findsOneWidget,
      );
      expect(RiderService.instance.profile.isOnline, isFalse);
    });

    testWidgets('RID-PROF-007: Rider cannot see another rider\'s profile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Simulate unauthorized request to Rider 2's profile while logged in as Rider 1
      await tester.pumpWidget(
        const MaterialApp(
          home: RiderProfileScreen(initialRiderId: 'NX-RD-002'),
        ),
      );
      await tester.pumpAndSettle();

      // Access Denied screen appears; no Rider 2 data is exposed
      expect(find.text('Access Denied (RID-PROF-007)'), findsOneWidget);
      expect(
        find.textContaining('is not permitted to view Rider 2'),
        findsOneWidget,
      );

      // Return to own profile
      await tester.tap(find.text('Return to My Verified Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Pedro Jose Garcia'), findsOneWidget);
    });
  });
}
