import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/external_notification_service.dart';
import 'package:nexora_flutter_app/features/profile/presentation/new_address_page.dart';

void main() {
  group('Task 1 & Task 2: Shopee Map Pinpoint & Outside Notification Tests', () {
    testWidgets('NewAddressPage: Clean AppBar without Laguna Places buttons & has Delivery Pinpoint card', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testAddress = AddressModel(
        id: 'addr_test_1',
        fullName: 'John Mark Pitargue',
        phone: '09759632035',
        region: 'Region IV-A (CALABARZON)',
        city: 'Liliw, Laguna',
        barangay: 'Tuy-Baanan',
        regionCity: 'Region IV-A (CALABARZON)',
        streetBuilding: '192 Tuy-Baanan',
        postalCode: '4004',
        label: 'Home',
        latitude: 14.1332,
        longitude: 121.4367,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NewAddressPage(editAddress: testAddress),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Clean AppBar: No "Laguna Places" or "Use Location" text buttons on top
      expect(find.text('Laguna Places'), findsNothing);
      expect(find.text('Use Location'), findsNothing);
      expect(find.text('Edit Address'), findsOneWidget);

      // Verify Shopee-style "Delivery Pinpoint on Map" Card
      expect(find.text('Delivery Pinpoint on Map'), findsOneWidget);
      expect(find.text('Set / Adjust Delivery Pin on Map'), findsOneWidget);
      expect(find.textContaining('14.1332° N, 121.4367° E'), findsOneWidget);

      // Tap "Set / Adjust Delivery Pin on Map" button to open modal
      final mapButton = find.text('Set / Adjust Delivery Pin on Map');
      await tester.ensureVisible(mapButton);
      await tester.tap(mapButton);
      await tester.pumpAndSettle();

      // Verify Modal displays Shopee Doorstep Pin
      expect(find.text('Pinpoint Delivery Location'), findsOneWidget);
      expect(find.text('Delivery Doorstep Pin'), findsOneWidget);
      expect(find.text('Confirm Pinpoint Location'), findsOneWidget);
    });

    test('ExternalNotificationService show handles execution gracefully', () {
      // Must not throw exception even in headless test environment
      expect(
        () => ExternalNotificationService.show(
          title: 'New Message from Rider',
          body: 'I have arrived at your doorstep!',
        ),
        returnsNormally,
      );
    });
  });
}
