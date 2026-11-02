import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/models/delivery_order.dart';
import 'package:nexora_rider_app/core/services/delivery_service.dart';
import 'package:nexora_rider_app/features/delivery/presentation/active_delivery_screen.dart';
import 'package:nexora_rider_app/features/home/presentation/widgets/available_order_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  group('Continuous Delivery Progress & Slider State Tests', () {
    test('DeliveryService maintains stage and scan state continuously', () {
      final service = DeliveryService.instance;

      // 1. Accept first available order
      if (service.availableOrders.isEmpty) {
        service.addSimulatedNewDispatch();
      }
      final orderId = service.availableOrders.first.id;
      service.acceptOrder(orderId);
      expect(service.activeOrderStage, equals(0));
      expect(service.pkg1Scanned, isFalse);
      expect(service.pkg2Scanned, isFalse);

      // 2. Advance stage to 1 (At Store) & update scans
      service.updateActiveOrderStage(1);
      service.updateActiveOrderScanProgress(pkg1: true, pkg2: true);

      expect(service.activeOrderStage, equals(1));
      expect(service.pkg1Scanned, isTrue);
      expect(service.pkg2Scanned, isTrue);
      expect(service.activeOrder?.status, equals(DeliveryStatus.atMerchant));

      // 3. Advance stage to 3 (In Transit) & handover code
      service.updateActiveOrderStage(3);
      service.updateActiveOrderScanProgress(handoverVerified: true);

      expect(service.activeOrderStage, equals(3));
      expect(service.handoverCodeVerified, isTrue);
      expect(service.activeOrder?.status, equals(DeliveryStatus.atCustomer));

      // 4. Complete delivery cleans up state
      service.completeCurrentDelivery();
      expect(service.activeOrder, isNull);
      expect(service.activeOrderStage, equals(0));
      expect(service.pkg1Scanned, isFalse);
      expect(service.pkg2Scanned, isFalse);
      expect(service.handoverCodeVerified, isFalse);
    });

    testWidgets('ActiveDeliveryScreen restores continuous stage from DeliveryService after back navigation', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = DeliveryService.instance;
      // Ensure we have an available order to accept
      if (service.availableOrders.isEmpty) {
        service.addSimulatedNewDispatch();
      }
      final orderId = service.availableOrders.first.id;
      service.acceptOrder(orderId);
      service.updateActiveOrderStage(1); // Set to "At Store"
      service.updateActiveOrderScanProgress(pkg1: true, pkg2: true);

      // Mount screen with accepted order
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: service.activeOrder!),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must be at Stage 1 ("AT STORE")
      expect(find.text('AT STORE'), findsOneWidget);

      // Simulate rider pushing back button (unmounting screen)
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Home Screen'))));
      await tester.pump();

      // Verify that DeliveryService STILL holds Stage 1 and scanned flags!
      expect(service.activeOrderStage, equals(1));
      expect(service.pkg1Scanned, isTrue);
      expect(service.pkg2Scanned, isTrue);

      // Simulate rider re-opening trip from Home banner ("Open Trip Dashboard")
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveDeliveryScreen(order: service.activeOrder!),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must STILL be at Stage 1 ("AT STORE") and NOT reset to Stage 0 ("HEADED TO STORE")!
      expect(find.text('AT STORE'), findsOneWidget);
      expect(find.text('CONFIRM PICKUP & PROCEED'), findsOneWidget);

      // Clean up
      service.completeCurrentDelivery();
    });

    testWidgets('SwipeToAcceptSlider automatically resets and never remains stuck', (tester) async {
      bool accepted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: SwipeToAcceptSlider(
                  key: const ValueKey('test_slider'),
                  onAccept: () {
                    accepted = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify initial state
      expect(find.text('SWIPE TO ACCEPT'), findsOneWidget);

      // Drag slider knob past 75% threshold
      final knobFinder = find.byKey(const ValueKey('swipe_knob'));
      await tester.drag(knobFinder, const Offset(300, 0));
      await tester.pump();

      expect(accepted, isTrue);

      // Advance clock past the 1.2s auto-reset safety window
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();

      // Slider must auto-reset and show SWIPE TO ACCEPT again, rather than remaining stuck!
      expect(find.text('SWIPE TO ACCEPT'), findsOneWidget);
    });
  });
}
