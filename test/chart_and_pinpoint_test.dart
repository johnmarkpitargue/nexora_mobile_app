import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/models/earning_record.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/features/earnings/presentation/widgets/weekly_chart_widget.dart';
import 'package:nexora_rider_app/features/delivery/presentation/widgets/rider_live_navigation_map.dart';

void main() {
  setUp(() {
    EarningsService.instance.setTestChartData(
      weekly: const [
        DayEarnings(dayName: 'Mon', amount: 1620.00, ordersCount: 6, hoursWorked: 4.2, tipsAmount: 0, dateLabel: 'Monday'),
        DayEarnings(dayName: 'Tue', amount: 1410.00, ordersCount: 5, hoursWorked: 3.8, tipsAmount: 0, dateLabel: 'Tuesday'),
        DayEarnings(dayName: 'Wed', amount: 1940.00, ordersCount: 8, hoursWorked: 5.0, tipsAmount: 0, dateLabel: 'Wednesday'),
        DayEarnings(dayName: 'Thu', amount: 1510.00, ordersCount: 6, hoursWorked: 4.0, tipsAmount: 0, dateLabel: 'Thursday'),
        DayEarnings(dayName: 'Fri', amount: 2150.00, ordersCount: 8, hoursWorked: 5.2, tipsAmount: 0, dateLabel: 'Friday'),
        DayEarnings(dayName: 'Sat', amount: 2520.00, ordersCount: 10, hoursWorked: 5.8, tipsAmount: 0, dateLabel: 'Saturday'),
        DayEarnings(dayName: 'Sun', amount: 1420.00, ordersCount: 5, hoursWorked: 4.5, tipsAmount: 0, dateLabel: 'Sunday', isCurrent: true),
      ],
      monthly: const [
        DayEarnings(dayName: 'W1', amount: 11400.00, ordersCount: 46, hoursWorked: 31.0, tipsAmount: 0, dateLabel: 'Week 1'),
        DayEarnings(dayName: 'W2', amount: 12200.00, ordersCount: 48, hoursWorked: 32.5, tipsAmount: 0, dateLabel: 'Week 2'),
        DayEarnings(dayName: 'W3', amount: 12570.00, ordersCount: 48, hoursWorked: 32.5, tipsAmount: 0, dateLabel: 'Week 3', isCurrent: true),
        DayEarnings(dayName: 'W4', amount: 9800.00, ordersCount: 38, hoursWorked: 26.0, tipsAmount: 0, dateLabel: 'Week 4'),
      ],
    );
  });

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
      expect(find.text('This Month Payouts'), findsOneWidget);
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
