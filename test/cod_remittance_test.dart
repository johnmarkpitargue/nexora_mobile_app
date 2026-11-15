import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_rider_app/core/network/api_client.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/features/earnings/presentation/earnings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'nexora_rider_auth_token': 'rider_test_token',
    });
    await ApiClient.instance.init();
    EarningsService.instance.resetForTest(
      codBalance: 640.00,
      earningsBalance: 240.00,
      availableForPayout: 240.00,
    );
  });

  group('COD Cash Remittance Pending Verification Flows Test', () {
    testWidgets('1. Non-cash GCash channel requires external reference and proof image', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiClient.instance.setMockClient(MockClient((req) async {
        if (req.url.path.endsWith('/earnings')) {
          return http.Response(
            jsonEncode({
              'data': {
                'earnings_balance': 240.0,
                'available_for_payout': 240.0,
                'pending_payout_amount': 0.0,
                'total_paid_out': 0.0,
                'unremitted_cod_balance': 640.0,
                'cod_wallet': {
                  'cod_on_hand_balance': 640.0,
                  'pending_verification_amount': 0.0,
                  'available_for_new_remittance': 640.0,
                  'open_collections': [],
                },
                'past_7_days': [],
                'recent_earnings': [],
                'recent_payouts': [],
              },
            }),
            200,
          );
        }
        if (req.url.path.endsWith('/cod-collections')) {
          return http.Response(
            jsonEncode({
              'data': {
                'cod_on_hand_balance': 640.0,
                'pending_verification_amount': 0.0,
                'available_for_new_remittance': 640.0,
                'open_collections': [],
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

      expect(find.text('COD CASH ACCOUNTABILITY'), findsOneWidget);
      expect(find.text('₱640.00 Held'), findsOneWidget);
      expect(find.text('Submit COD Remittance'), findsOneWidget);

      await tester.tap(find.text('Submit COD Remittance'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('GCash'));
      await tester.pumpAndSettle();

      expect(find.text('Upload Receipt / Proof Image *'), findsOneWidget);

      await tester.tap(find.text('SUBMIT FOR LOGISTICS VERIFICATION'));
      await tester.pumpAndSettle();

      // Remains un-cleared and shows validation error
      expect(
        find.textContaining('External reference number is required'),
        findsOneWidget,
      );
      expect(EarningsService.instance.codHeldBalance, 640.00);
    });

    testWidgets('2. Physical cash remittance submits as pending verification without clearing locally', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ApiClient.instance.setMockClient(MockClient((req) async {
        if (req.url.path.endsWith('/remittance') && req.method == 'POST') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 42,
                'remittance_number': 'REM-LIVE-042',
                'amount': 640.0,
                'payment_method': 'physical_cash',
                'status': 'submitted',
              },
              'message': 'Remittance submitted — pending verification.',
            }),
            201,
          );
        }
        if (req.url.path.endsWith('/earnings')) {
          return http.Response(
            jsonEncode({
              'data': {
                'earnings_balance': 240.0,
                'available_for_payout': 240.0,
                'pending_payout_amount': 0.0,
                'total_paid_out': 0.0,
                'unremitted_cod_balance': 640.0,
                'cod_wallet': {
                  'cod_on_hand_balance': 640.0,
                  'pending_verification_amount': 640.0,
                  'available_for_new_remittance': 0.0,
                  'open_collections': [],
                },
                'past_7_days': [],
                'recent_earnings': [],
                'recent_payouts': [],
              },
            }),
            200,
          );
        }
        if (req.url.path.endsWith('/cod-collections')) {
          return http.Response(
            jsonEncode({
              'data': {
                'cod_on_hand_balance': 640.0,
                'pending_verification_amount': 640.0,
                'available_for_new_remittance': 0.0,
                'open_collections': [],
                'recent_remittances': [
                  {
                    'id': 42,
                    'remittance_number': 'REM-LIVE-042',
                    'claimed_amount': 640.0,
                    'payment_method': 'physical_cash',
                    'status': 'submitted',
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': {'payouts': []}}), 200);
      }));

      await tester.pumpWidget(const MaterialApp(home: EarningsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit COD Remittance'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUBMIT FOR LOGISTICS VERIFICATION'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Pending Verification'),
        findsWidgets,
      );
      expect(EarningsService.instance.codHeldBalance, 640.00);
      expect(EarningsService.instance.codPendingVerificationAmount, 640.00);
    });
  });
}
