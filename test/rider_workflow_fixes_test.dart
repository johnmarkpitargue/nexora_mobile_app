import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/models/delivery_order.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/core/services/rider_service.dart';
import 'package:nexora_rider_app/features/home/presentation/widgets/earnings_summary_card.dart';

void main() {
  test('DeliveryOrder.fromApiOrder uses authoritative expected_pay and task fields instead of hardcoded 50', () {
    final pickupTask = DeliveryOrder.fromApiOrder({
      'id': 42,
      'order_number': 'ORD-42',
      'tracking_number': 'NX-TRK-42',
      'status': 'picked_up',
      'task_type': 'pickup',
      'task_status': 'completed',
      'task_outcome': 'picked_up',
      'compensation_amount': 30.0,
      'expected_pay': 30.0,
      'seller_name': 'San Pablo Crafts',
      'counterparty_name': 'San Pablo Crafts',
      'completed_at': '2026-11-16T10:15:00Z',
      'total': 1285.0,
      'payment_method': 'cod',
    });

    expect(pickupTask.deliveryFee, 30.0);
    expect(pickupTask.riderEarnings, 30.0);
    expect(pickupTask.taskType, 'pickup');
    expect(pickupTask.taskStatus, 'completed');
    expect(pickupTask.taskOutcome, 'picked_up');
    expect(pickupTask.counterpartyName, 'San Pablo Crafts');
    expect(pickupTask.status, DeliveryStatus.delivered);
  });

  test('DeliveryOrder.fromApiOrder resolves Cavite buyer coordinates instead of Liliw default', () {
    final caviteOrder = DeliveryOrder.fromApiOrder({
      'id': 99,
      'order_number': 'NX-USPKZL2VCK',
      'status': 'assigned_to_rider',
      'dropoff_address': '123sd, San Agustin, Magallanes, Cavite',
      'total': 346.40,
      'payment_method': 'cod',
    });

    expect(caviteOrder.customerLat, closeTo(14.1872, 0.001));
    expect(caviteOrder.customerLng, closeTo(120.7478, 0.001));
  });

  testWidgets('EarningsSummaryCard displays EarningsService todayPay when fetched remotely', (tester) async {
    RiderService.instance.updateProfileFromApi(
      id: '10',
      name: 'Test Rider',
      email: 'rider@nexora.test',
      phone: '09170000000',
      plateNumber: 'MC-10',
      vehicleType: 'Motorcycle',
      todayEarnings: 30.0,
      walletBalance: 30.0,
    );
    EarningsService.instance.resetForTest(earningsBalance: 30.0, availableForPayout: 30.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarningsSummaryCard(onSeeWallet: () {}),
        ),
      ),
    );

    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.text('30.00'), findsOneWidget);
  });
}
