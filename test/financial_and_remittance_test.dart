import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_rider_app/core/network/api_client.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/features/earnings/presentation/cash_out_screen.dart';
import 'package:nexora_rider_app/features/earnings/presentation/earnings_screen.dart';
import 'package:nexora_rider_app/features/transfer_courier/presentation/transfer_courier_shell.dart';
import 'package:nexora_rider_app/features/transfer_courier/services/transfer_courier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'nexora_rider_auth_token': 'financial_test_token',
    });
    await ApiClient.instance.init();
    EarningsService.instance.resetForTest();
    TransferCourierService.instance.clear();
  });

  group('Financial & Remittance Integrity Tests', () {
    testWidgets('Rider EarningsScreen separates COD Cash Accountability from Withdrawable Earnings', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiClient.instance.setMockClient(MockClient((req) async {
        if (req.url.path.endsWith('/rider/earnings')) {
          return http.Response(
            jsonEncode({
              'data': {
                'earnings_balance': 380.0,
                'available_for_payout': 280.0,
                'pending_payout_amount': 100.0,
                'total_paid_out': 500.0,
                'unremitted_cod_balance': 1250.0,
                'cod_wallet': {
                  'cod_on_hand_balance': 1250.0,
                  'pending_verification_amount': 450.0,
                  'available_for_new_remittance': 800.0,
                  'total_shortage_flagged': 50.0,
                  'open_collections': [
                    {
                      'order_id': 91,
                      'order_number': 'NX-COD-091',
                      'collected_amount': 800.0,
                      'remaining_balance': 800.0,
                      'status': 'collected_by_rider',
                    }
                  ],
                },
                'active_policy': {
                  'pickup_rate': 30.0,
                  'delivery_rate': 50.0,
                },
                'past_7_days': [],
                'recent_earnings': [],
                'recent_payouts': [],
              },
            }),
            200,
          );
        }
        if (req.url.path.endsWith('/rider/cod-collections')) {
          return http.Response(
            jsonEncode({
              'data': {
                'cod_on_hand_balance': 1250.0,
                'pending_verification_amount': 450.0,
                'available_for_new_remittance': 800.0,
                'total_shortage_flagged': 50.0,
                'open_collections': [
                  {
                    'order_id': 91,
                    'order_number': 'NX-COD-091',
                    'collected_amount': 800.0,
                    'remaining_balance': 800.0,
                    'status': 'collected_by_rider',
                  }
                ],
                'recent_remittances': [],
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': {'payouts': []}}), 200);
      }));

      await tester.pumpWidget(const MaterialApp(home: EarningsScreen()));
      await tester.pumpAndSettle();

      // Earnings section uses real available_for_payout (never mixed with COD 1250)
      expect(find.text('₱280.00'), findsOneWidget);
      expect(find.text('Pending Payout: ₱100.00'), findsOneWidget);
      expect(find.text('Paid Out: ₱500.00'), findsOneWidget);
      expect(find.text('Active Rate: Pickup ₱30.00 • Delivery ₱50.00'), findsOneWidget);

      // COD accountability displays separate balances & flagged shortage alert
      expect(find.text('COD CASH ACCOUNTABILITY'), findsOneWidget);
      expect(find.text('₱1250.00 Held'), findsOneWidget);
      expect(find.text('₱800.00'), findsOneWidget);
      expect(find.text('₱450.00'), findsOneWidget);
      expect(find.textContaining('Flagged Shortage Balance: ₱50.00'), findsOneWidget);
    });

    testWidgets('CashOutScreen submits real Payout Request as requested without fake JOHN MARK P. accounts', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      EarningsService.instance.resetForTest(
        earningsBalance: 400.0,
        availableForPayout: 400.0,
      );

      Map<String, dynamic>? submittedPayload;
      ApiClient.instance.setMockClient(MockClient((req) async {
        if (req.url.path.endsWith('/rider/payouts') && req.method == 'POST') {
          submittedPayload = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 77,
                'payout_number': 'CPY-2026-0077',
                'amount': submittedPayload!['amount'],
                'payout_method': submittedPayload!['payout_method'],
                'status': 'requested',
              },
              'message': 'Payout request submitted.',
            }),
            201,
          );
        }
        return http.Response(
          jsonEncode({
            'data': {
              'earnings_balance': 400.0,
              'available_for_payout': 0.0,
              'pending_payout_amount': 400.0,
              'payouts': [],
            }
          }),
          200,
        );
      }));

      await tester.pumpWidget(const MaterialApp(home: CashOutScreen()));
      await tester.pumpAndSettle();

      // Zero fake hardcoded accounts
      expect(find.textContaining('JOHN MARK'), findsNothing);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Maria Santos');
      await tester.enterText(fields.at(1), '09178889999');
      await tester.pumpAndSettle();

      final submitBtn = find.textContaining('SUBMIT PAYOUT REQUEST');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(submittedPayload, isNotNull);
      expect(submittedPayload!['account_name'], 'Maria Santos');
      expect(submittedPayload!['account_number'], '09178889999');
      expect(find.text('Payout Request Submitted'), findsOneWidget);
      expect(find.text('CPY-2026-0077'), findsOneWidget);
      expect(find.text('REQUESTED'), findsOneWidget);
    });

    testWidgets('TransferCourierShell Earnings tab shows trip pay and hides Rider COD UI', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiClient.instance.setMockClient(MockClient((req) async {
        if (req.url.path.endsWith('/transfer-courier/earnings')) {
          return http.Response(
            jsonEncode({
              'data': {
                'role': 'courier',
                'earnings_balance': 205.0,
                'available_for_payout': 205.0,
                'pending_payout_amount': 0.0,
                'total_paid_out': 0.0,
                'today_summary': {'transfer_trips': 1, 'total_pay': 205.0},
                'active_policy': {
                  'transfer_trip_base_rate': 150.0,
                  'transfer_per_parcel_rate': 5.0,
                },
                'recent_earnings': [
                  {
                    'id': 501,
                    'type': 'transfer_trip',
                    'amount': 205.0,
                    'description': 'Manifest MAN-001 Completed',
                  }
                ],
                'recent_payouts': [],
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({'data': {'payouts': [], 'active_manifests': 0, 'loading_manifests': 0, 'in_transit_manifests': 0, 'completed_manifests': 1, 'parcels_moved_today': 2, 'manifests': []}}),
          200,
        );
      }));

      await tester.pumpWidget(const MaterialApp(home: TransferCourierShell()));
      await tester.pumpAndSettle();

      // Switch to Earnings tab in TransferCourierShell
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();

      expect(find.text('Transfer Trip Earnings & Payouts'), findsOneWidget);
      expect(find.text('₱205.00'), findsOneWidget);
      expect(find.text('Manifest MAN-001 Completed'), findsOneWidget);

      // Transfer Couriers must NEVER see Rider COD remittance UI
      expect(find.text('COD CASH ACCOUNTABILITY'), findsNothing);
      expect(find.text('Submit COD Remittance'), findsNothing);
    });

    testWidgets('EarningsScreen handles backend cod_collections fields, explicit status badges, and error retry banner', (tester) async {
      tester.view.physicalSize = const Size(450, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool shouldFail = true;
      ApiClient.instance.setMockClient(MockClient((req) async {
        if (shouldFail) {
          return http.Response(jsonEncode({'message': 'Temporary network timeout'}), 500);
        }
        if (req.url.path.endsWith('/rider/earnings')) {
          return http.Response(
            jsonEncode({
              'data': {
                'earnings_balance': 80.0,
                'available_for_payout': 80.0,
                'pending_payout_amount': 0.0,
                'total_paid_out': 0.0,
                'unremitted_cod_balance': 500.0,
                'cod_wallet': {
                  'cod_on_hand_balance': 500.0,
                  'pending_verification_amount': 200.0,
                  'available_for_new_remittance': 300.0,
                  'total_shortage_flagged': 0.0,
                  'open_collections': [
                    {
                      'order_id': 102,
                      'order_number': 'NX-COD-102',
                      'actual_collected_amount': 500.0,
                      'outstanding_amount': 300.0,
                      'available_to_submit_amount': 300.0,
                      'pending_reserved_amount': 0.0,
                      'status': 'collected',
                    }
                  ],
                },
                'active_policy': {'pickup_rate': 30.0, 'delivery_rate': 50.0},
                'past_7_days': [],
                'recent_earnings': [],
                'recent_payouts': [
                  {
                    'id': 9,
                    'payout_number': 'CPY-09',
                    'amount': 80.0,
                    'payout_method': 'gcash',
                    'status': 'requested',
                  },
                ],
              },
            }),
            200,
          );
        }
        if (req.url.path.endsWith('/rider/cod-collections')) {
          return http.Response(
            jsonEncode({
              'data': {
                'cod_on_hand_balance': 500.0,
                'pending_verification_amount': 200.0,
                'available_for_new_remittance': 300.0,
                'total_shortage_flagged': 0.0,
                'open_collections': [
                  {
                    'order_id': 102,
                    'order_number': 'NX-COD-102',
                    'actual_collected_amount': 500.0,
                    'outstanding_amount': 300.0,
                    'available_to_submit_amount': 300.0,
                    'pending_reserved_amount': 0.0,
                    'status': 'collected',
                  }
                ],
                'recent_remittances': [
                  {
                    'id': 201,
                    'remittance_number': 'RMT-201',
                    'declared_amount': 200.0,
                    'verified_amount': 0.0,
                    'status': 'submitted',
                    'payment_method': 'gcash',
                  },
                  {
                    'id': 202,
                    'remittance_number': 'RMT-202',
                    'declared_amount': 300.0,
                    'verified_amount': 250.0,
                    'status': 'partially_verified',
                    'payment_method': 'bank_transfer',
                    'discrepancy_reason': 'Short PHP 50 coin',
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(jsonEncode({'data': {'payouts': []}}), 200);
      }));

      await tester.pumpWidget(const MaterialApp(home: EarningsScreen()));
      await tester.pumpAndSettle();

      // Error banner & Retry button must be visible on initial API error
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry after server recovers
      shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsNothing);
      expect(EarningsService.instance.recentRemittances, hasLength(2));
      await tester.ensureVisible(find.text('SUBMITTED'));
      expect(find.text('SUBMITTED'), findsOneWidget);
      expect(find.text('PARTIALLY VERIFIED'), findsOneWidget);

      // Open COD Remittance modal and ensure open_collections pre-fills ₱300.00 from available_to_submit_amount
      await tester.tap(find.text('Submit COD Remittance'));
      await tester.pumpAndSettle();
      expect(find.text('NX-COD-102 — ₱300.00'), findsOneWidget);
    });
  });
}
