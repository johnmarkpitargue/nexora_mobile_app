import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/models/delivery_order.dart';
import 'package:nexora_rider_app/features/delivery/presentation/active_delivery_screen.dart';
import 'package:nexora_rider_app/features/delivery/presentation/widgets/route_progress_widget.dart';

void main() {
  final testOrder = DeliveryOrder(
    id: 'NX-89244',
    customerName: 'Juan Dela Cruz',
    customerPhone: '+63 917 555 1234',
    customerAddress: 'Tower 1, High Street South, 26th St, Taguig City',
    customerNotes: 'Please call before arrival',
    merchantName: 'Nexora Official Flagship Store',
    merchantAddress: 'Nexora Central Fulfillment Center',
    merchantPhone: '+63 2 8888 1234',
    merchantLat: 14.5500,
    merchantLng: 121.0500,
    customerLat: 14.5520,
    customerLng: 121.0520,
    items: const [
      OrderItemDetail(
        name: 'Medium Sealed Box',
        quantity: 1,
        price: 2499.00,
        imageUrl: '',
      ),
      OrderItemDetail(
        name: 'Express Courier Pouch',
        quantity: 1,
        price: 799.00,
        imageUrl: '',
      ),
    ],
    deliveryFee: 120.00,
    tip: 25.00,
    orderTotal: 3443.00,
    paymentType: 'Prepaid',
    distanceKm: 2.8,
    estimatedMinutes: 15,
    createdAt: DateTime.now(),
    status: DeliveryStatus.accepted,
    packageSize: 'Medium Box + Pouch',
    packageWeightKg: 1.05,
    isFragile: true,
    fitsInsulatedBag: true,
  );

  group('Active Order Details Fixes Verification Suite', () {
    testWidgets('RouteProgressWidget: Stage 0 shows To Store active, At Store pending (not checked); Stage 1 shows green checkmark on To Store', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteProgressWidget(currentStageIndex: 0),
          ),
        ),
      );

      // Stage 0: Headed to store
      expect(find.text('HEADED TO STORE'), findsOneWidget);
      expect(find.text('To Store'), findsOneWidget);
      expect(find.text('At Store'), findsOneWidget);

      // In Stage 0, no checkmark should be rendered in the stepper nodes
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Now pump Stage 1 (Arrived at Store)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteProgressWidget(currentStageIndex: 1),
          ),
        ),
      );

      expect(find.text('AT STORE'), findsOneWidget);
      // Completed "To Store" step should now display a green checkmark
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('ActiveDeliveryScreen: Renders Dark Hero Card, Barcode Manifest, and Passive Navigation CTA without clipping', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: testOrder),
        ),
      );
      await tester.pump();

      // 1. Web Layout: Dark hero card text displays with proper height and padding
      expect(find.textContaining('In 350m, arrive at Nexora Official Flagship Store'), findsOneWidget);
      expect(find.text('Pickup Point: Main Mall Ground Entrance'), findsOneWidget);

      // 2. Status Consistency: Stage 0 has passive Google Maps navigation as primary and arrival declaration as secondary
      expect(find.text('NAVIGATE TO STORE (GOOGLE MAPS)'), findsOneWidget);
      expect(find.text('I HAVE ARRIVED AT STORE'), findsOneWidget);

      // 3. Logistics Protocol: Package Manifest uses barcode/camera scanner buttons with SCAN badge, NOT static checkboxes
      expect(find.text('PACKAGE MANIFEST'), findsOneWidget);
      expect(find.text('Parcel #NX8942-A'), findsOneWidget);
      expect(find.text('Parcel #NX8942-B'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsWidgets);
      expect(find.text('SCAN'), findsNWidgets(2));

      // 4. Scroll to and tap "I HAVE ARRIVED AT STORE" advances to Stage 1
      final arrivalBtn = find.text('I HAVE ARRIVED AT STORE');
      await tester.ensureVisible(arrivalBtn);
      await tester.pumpAndSettle();
      await tester.tap(arrivalBtn);
      await tester.pumpAndSettle();

      // Scroll back up to inspect top hero and stepper
      final topHero = find.textContaining('GPS ARRIVAL CONFIRMED');
      await tester.ensureVisible(topHero);
      await tester.pumpAndSettle();

      // In Stage 1, top hero updates to GPS Arrival Confirmed
      expect(topHero, findsOneWidget);
      // Stepper shows Step 0 with green checkmark
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      // Bottom CTA transitions to scanning
      expect(find.textContaining('START SCANNING PARCELS'), findsOneWidget);
    });

    testWidgets('ActiveDeliveryScreen: Camera Barcode Scan modal authenticates parcel', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: testOrder),
        ),
      );
      await tester.pump();

      // Tap first parcel SCAN button
      final scanButtons = find.text('SCAN');
      expect(scanButtons, findsWidgets);
      await tester.tap(scanButtons.first);
      await tester.pumpAndSettle();

      // Viewfinder modal displays
      expect(find.text('PARCEL SCAN VERIFICATION'), findsOneWidget);
      expect(find.text('ALIGN PARCEL BARCODE WITHIN FRAME'), findsOneWidget);

      // Tap SIMULATE CAMERA BARCODE SCAN
      await tester.tap(find.text('SIMULATE CAMERA BARCODE SCAN'));
      await tester.pumpAndSettle();

      // Parcel is now verified
      expect(find.text('VERIFIED'), findsOneWidget);
    });

    testWidgets('ActiveDeliveryScreen: Manual barcode typing fall-back authenticates parcel', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: testOrder),
        ),
      );
      await tester.pump();

      // Tap first parcel SCAN button
      final scanButtons = find.text('SCAN');
      expect(scanButtons, findsWidgets);
      await tester.tap(scanButtons.first);
      await tester.pumpAndSettle();

      // Viewfinder modal displays
      expect(find.text('PARCEL SCAN VERIFICATION'), findsOneWidget);
      expect(find.text('CANNOT SCAN? ENTER MANUALLY'), findsOneWidget);

      // Verify empty submission shows warning message
      final verifyBtn = find.widgetWithText(ElevatedButton, 'VERIFY');
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();
      expect(find.text('Please enter barcode or tracking number.'), findsOneWidget);

      // Enter manual code and verify
      final inputField = find.byType(TextFormField);
      await tester.enterText(inputField, 'NX-7829-01');
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Parcel is now verified
      expect(find.text('VERIFIED'), findsOneWidget);
    });

    testWidgets('ActiveDeliveryScreen: Stage 1 Handover Code Verification and Show My QR modal', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: testOrder),
        ),
      );
      await tester.pump();

      // Advance to Stage 1
      final arrivalBtn = find.text('I HAVE ARRIVED AT STORE');
      await tester.ensureVisible(arrivalBtn);
      await tester.tap(arrivalBtn);
      await tester.pumpAndSettle();

      // Check Handover Security Protocol: Card asks for attendant handover code
      expect(find.text('ASK ATTENDANT FOR HANDOVER CODE'), findsOneWidget);
      expect(find.text('Show My QR'), findsOneWidget);

      // Tap Show My QR
      final showMyQr = find.text('Show My QR');
      await tester.ensureVisible(showMyQr);
      await tester.tap(showMyQr);
      await tester.pumpAndSettle();

      expect(find.text('Show My Pickup QR to Merchant'), findsOneWidget);
      expect(find.text('Attendant Scanned & Handed Over'), findsOneWidget);

      // Attendant scans rider QR badge
      await tester.tap(find.text('Attendant Scanned & Handed Over'));
      await tester.pumpAndSettle();

      // Verified state
      expect(find.text('HANDOVER CODE VERIFIED'), findsOneWidget);
      expect(find.textContaining('Code Authenticated: NX-8942-S'), findsOneWidget);

      // Verify that Package 2 is scrollable and visible
      final pkg2 = find.text('NX-PKG-8942-02');
      await tester.ensureVisible(pkg2);
      await tester.pumpAndSettle();
      expect(pkg2, findsOneWidget);
    });

    testWidgets('ActiveDeliveryScreen: Stage 3 Masked Phone Privacy and Clean Map without Redundant Zoom Buttons', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Initialize with status pickedUp to be in transit stage (Stage 3)
      final transitOrder = testOrder.copyWith(status: DeliveryStatus.pickedUp);
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: transitOrder),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Phone Number Privacy: Raw phone '+63 917 555 1234' must NOT appear raw; must be masked
      expect(find.text('📞 +63 917 555 1234'), findsNothing);
      expect(find.textContaining('***'), findsWidgets);
      expect(find.text('MASKED'), findsOneWidget);

      // 2. Map Clean Workspace: Floating zoom in (+) and zoom out (-) buttons must be removed
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.remove), findsNothing);
      // Recenter button remains present
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      // 3. Bottom margin: Dispatch link has breathing room and is visible
      final dispatchLink = find.textContaining('Contact Dispatch');
      await tester.ensureVisible(dispatchLink);
      await tester.pump();
      expect(dispatchLink, findsOneWidget);
    });

    testWidgets('ActiveDeliveryScreen: Stage 5 Completion Time Format, Stable Distance & Clean Geotag POD', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final completedOrder = testOrder.copyWith(status: DeliveryStatus.delivered);
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: completedOrder),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Time Paradox: 14:38 PM must NEVER appear; must be 12-hour standard time e.g. 2:38 PM
      expect(find.textContaining('14:38 PM'), findsNothing);
      expect(find.textContaining('2:38 PM'), findsOneWidget);

      // 2. Distance Stability: Distance box must match the 1.8 km navigation metric, NOT 3.8 km
      expect(find.text('3.8 km total'), findsNothing);
      expect(find.text('1.8 km total'), findsOneWidget);

      // 3. GPS Coordinate Placement: Address card has human-readable text; GPS moved to bottom margin / overlay
      expect(find.text('Signature on file: J. Dela Cruz'), findsOneWidget);
      expect(find.text('GPS'), findsOneWidget); // Thumbnail overlay badge
      expect(find.textContaining('Cryptographic Geotag • GPS: 14.5492° N, 121.0479° E'), findsOneWidget);
    });
  });
}
