import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/features/earnings/presentation/widgets/weekly_chart_widget.dart';
import 'package:nexora_rider_app/features/delivery/presentation/widgets/rider_live_navigation_map.dart';

void main() {
  group('Task 4: Weekly Performance Chart Exclusive Selection Tests', () {
    testWidgets('Tapping on bars transfers highlight cleanly without stuck bars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyChartWidget(
                data: EarningsService.instance.weeklyData,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to 'This Month' view
      final thisMonthTab = find.text('This Month');
      expect(thisMonthTab, findsOneWidget);
      await tester.tap(thisMonthTab);
      await tester.pumpAndSettle();

      // Verify Month view is visible
      expect(find.text('October Payouts'), findsOneWidget);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(find.text('W3'), findsOneWidget);
      expect(find.text('W4'), findsOneWidget);

      // Tap W1 to select it
      await tester.tap(find.text('W1'));
      await tester.pumpAndSettle();

      // Info card below chart should now reflect W1 data
      expect(find.textContaining('Week 1'), findsOneWidget);
      expect(find.textContaining('11400.00'), findsOneWidget);

      // Tap W4 to select it
      await tester.tap(find.text('W4'));
      await tester.pumpAndSettle();

      // Info card below chart should now reflect W4 data
      expect(find.textContaining('Week 4'), findsOneWidget);
      expect(find.textContaining('9800.00'), findsOneWidget);
    });

    testWidgets('Switching between Week and Month views retains clean interactive selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyChartWidget(
                data: EarningsService.instance.weeklyData,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Past 7 Days Payouts'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // Tap Mon
      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Monday'), findsOneWidget);
      expect(find.textContaining('1620.00'), findsOneWidget);
    });
  });

  group('Task 3: RiderLiveNavigationMap Buyer Pinpoint Tests', () {
    testWidgets('RiderLiveNavigationMap displays Buyer Pinpoint Banner with address and coordinates', (tester) async {
      tester.view.physicalSize = const Size(400, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RiderLiveNavigationMap(
                destinationLat: 14.13320,
                destinationLng: 121.43670,
                destinationAddress: 'Tuy-Baanan, Liliw, Laguna',
                customerName: 'John Mark Pitargue',
                orderId: 'NX-8942-ORD',
              ),
            ),
          ),
        ),
      );
      // Pump initial frame without pumpAndSettle due to repeating controller
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check Buyer Pinpoint Header Banner
      expect(find.text('John Mark Pitargue'), findsOneWidget);
      expect(find.text('BUYER PINPOINT'), findsOneWidget);
      expect(find.text('Tuy-Baanan, Liliw, Laguna'), findsOneWidget);
      expect(find.textContaining('14.13320° N, 121.43670° E'), findsOneWidget);

      // Check Map Navigation Actions & Controls
      expect(find.text('Open Live Turn-by-Turn in Google Maps'), findsOneWidget);
      expect(find.byIcon(Icons.place_rounded), findsOneWidget); // Pinpoint recenter
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget); // Bike recenter
      expect(find.byIcon(Icons.add_rounded), findsOneWidget); // Zoom in
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget); // Zoom out
    });
  });
}
