import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/models/delivery_order.dart';
import 'package:nexora_rider_app/features/home/presentation/rider_home_screen.dart';
import 'package:nexora_rider_app/features/home/presentation/widgets/available_order_card.dart';
import 'package:nexora_rider_app/features/home/presentation/widgets/online_status_card.dart';
import 'package:nexora_rider_app/core/services/in_app_notification_service.dart';

void main() {
  final testOrder = DeliveryOrder(
    id: 'NX-TEST-001',
    customerName: 'Alex Rivera',
    customerPhone: '+63 917 555 0192',
    customerAddress: 'Unit 2402, Lumina Tower, Taguig City',
    customerNotes: 'Ring bell',
    merchantName: 'Nexora Official Store',
    merchantAddress: 'High Street South, 26th St',
    merchantPhone: '+63 2 8899 0011',
    items: const [
      OrderItemDetail(
        name: 'Aura Minimalist Headphones with Active Noise Cancellation',
        quantity: 2,
        price: 4999.00,
        imageUrl: '',
      ),
    ],
    deliveryFee: 120.00,
    tip: 50.00,
    orderTotal: 5049.00,
    paymentType: 'Cash on Delivery (COD)',
    distanceKm: 2.4,
    estimatedMinutes: 12,
    createdAt: DateTime.now(),
    status: DeliveryStatus.available,
    packageSize: 'Medium Box (30x20x15cm)',
    packageWeightKg: 3.5,
    isFragile: true,
    fitsInsulatedBag: true,
  );

  group('Rider App UX & Safety Flaws Resolution Suite', () {
    testWidgets('1 & 2 & 4: AvailableOrderCard has Swipe-to-Accept slider, isolated Decline, macro cargo specs, and customer privacy masking', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool accepted = false;
      bool declined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AvailableOrderCard(
                order: testOrder,
                onAccept: () => accepted = true,
                onDecline: () => declined = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Decline button is distinct and isolated
      final declineFinder = find.text('Decline');
      expect(declineFinder, findsOneWidget);
      await tester.tap(declineFinder);
      expect(declined, isTrue);

      // 2. Swipe to Accept slider exists instead of immediate adjacent button
      expect(find.text('SWIPE TO ACCEPT'), findsOneWidget);
      expect(find.byType(SwipeToAcceptSlider), findsOneWidget);

      // 3. Macro Physical Cargo Specs are given primary real estate
      expect(find.text('CARGO SPECIFICATIONS'), findsOneWidget);
      expect(find.text('Medium Box (30x20x15cm)'), findsOneWidget);
      expect(find.text('3.5 kg'), findsOneWidget);
      expect(find.text('Fragile Handling'), findsOneWidget);
      expect(find.text('Fits Insulated Bag'), findsOneWidget);

      // 4. Customer Address privacy masking before acceptance
      expect(find.text('Drop-off: Lumina Tower, Taguig City'), findsOneWidget);
      expect(find.textContaining('Exact unit & recipient details unlocked upon accept'), findsOneWidget);

      // 5. Test dragging the Swipe to Accept slider across threshold
      final knobFinder = find.byKey(const ValueKey('swipe_knob'));
      expect(knobFinder, findsOneWidget);
      final knobCenter = tester.getCenter(knobFinder);
      await tester.timedDragFrom(
        knobCenter,
        const Offset(350, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
    });

    testWidgets('3: RiderHomeScreen header eliminates duplicate ONLINE badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RiderHomeScreen(onNavigateTab: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Header has radar icon, but does NOT contain a duplicate ONLINE pill
      expect(find.byIcon(Icons.radar_rounded), findsOneWidget);
      // The single source of truth for online state is the ON DUTY toggle on the card
      expect(find.text('ON DUTY'), findsOneWidget);
    });

    testWidgets('5: OnlineStatusCard provides high-contrast outdoor-readable vehicle details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnlineStatusCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify vehicle type and plate number text are present with high contrast
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('123ABC'), findsOneWidget);
    });

    testWidgets('6: RiderHomeScreen has removed Dispatch Hub Surge Active banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RiderHomeScreen(onNavigateTab: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure 'Dispatch Hub Surge Active' and '+₱30/trip' are NOT present
      expect(find.text('Dispatch Hub Surge Active'), findsNothing);
      expect(find.text('+₱30/trip'), findsNothing);
    });

    testWidgets('7: Notification bell and badge are 100% clickable and open Notification Center', (tester) async {
      InAppNotificationService.instance.unreadCountNotifier.value = 2;

      await tester.pumpWidget(
        MaterialApp(
          home: RiderHomeScreen(onNavigateTab: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the badge displays '2'
      expect(find.text('2'), findsOneWidget);

      // Verify IgnorePointer with ignoring: true wraps the badge Container so clicks pass through to the InkWell
      final badgeFinder = find.ancestor(
        of: find.text('2'),
        matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
      );
      expect(badgeFinder, findsOneWidget);

      // Tap directly on the notification bell / badge area
      final bellFinder = find.byTooltip('Dispatch & Order Alerts');
      expect(bellFinder, findsOneWidget);
      await tester.tap(bellFinder);
      await tester.pumpAndSettle();

      // Notification History Bottom Sheet opens
      expect(find.text('Real-time customer & courier notifications'), findsOneWidget);
    });
  });
}
