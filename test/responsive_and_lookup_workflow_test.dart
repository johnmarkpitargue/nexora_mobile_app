import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_rider_app/core/models/delivery_order.dart';
import 'package:nexora_rider_app/core/network/api_client.dart';
import 'package:nexora_rider_app/core/services/delivery_service.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/core/services/in_app_notification_service.dart';
import 'package:nexora_rider_app/core/widgets/parcel_barcode_scanner.dart';
import 'package:nexora_rider_app/features/delivery/presentation/delivery_history_screen.dart';
import 'package:nexora_rider_app/features/earnings/presentation/earnings_screen.dart';
import 'package:nexora_rider_app/features/earnings/presentation/widgets/weekly_chart_widget.dart';
import 'package:nexora_rider_app/features/home/presentation/rider_home_screen.dart';
import 'package:nexora_rider_app/features/profile/presentation/rider_profile_screen.dart';
import 'package:nexora_rider_app/features/transfer_courier/presentation/transfer_courier_shell.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.setMockClient(
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/notifications')) {
          return http.Response(
            jsonEncode({'status': 'success', 'data': <dynamic>[]}),
            200,
          );
        }
        if (path.endsWith('/rider/orders/available')) {
          return http.Response(
            jsonEncode({'status': 'success', 'data': <dynamic>[]}),
            200,
          );
        }
        if (path.endsWith('/rider/orders/active') ||
            path.endsWith('/rider/orders/history') ||
            path.endsWith('/rider/payouts') ||
            path.endsWith('/rider/cod') ||
            path.endsWith('/courier/manifests') ||
            path.endsWith('/courier/inventory') ||
            path.endsWith('/courier/payouts')) {
          return http.Response(
            jsonEncode({'status': 'success', 'data': <dynamic>[]}),
            200,
          );
        }
        if (path.endsWith('/rider/earnings') ||
            path.endsWith('/courier/earnings')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'today_earnings': 0,
                'week_earnings': 0,
                'month_earnings': 0,
                'available_balance': 0,
                'pending_cod': 0,
                'transactions': <dynamic>[],
                'daily_breakdown': <dynamic>[],
              },
            }),
            200,
          );
        }
        if (path.endsWith('/rider/profile')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 1,
                'name': 'Test Rider',
                'is_online': false,
                'assigned_hub': '',
              },
            }),
            200,
          );
        }
        if (path.endsWith('/courier/dashboard')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'courier_name': 'Test Transfer Courier',
                'company_name': 'Nexora Logistics',
                'total_assigned_parcels': 0,
                'total_loaded_parcels': 0,
                'completed_transfers': 0,
                'reported_exceptions': 0,
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'status': 'success', 'data': {}}), 200);
      }),
    );
    await ApiClient.instance.saveToken('test-rider-token', 'rider');
    await DeliveryService.instance
        .fetchActiveDeliveriesRemote()
        .catchError((_) => <DeliveryOrder>[]);
    await DeliveryService.instance
        .fetchDeliveryHistoryRemote()
        .catchError((_) => <DeliveryOrder>[]);
    EarningsService.instance.clear();
    InAppNotificationService.instance.clearHistory();
  });

  tearDown(() async {
    await ApiClient.instance.clearToken();
  });

  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    final ex = tester.takeException();
    expect(ex, isNull, reason: 'Overflow or error on ${child.runtimeType} at $size: $ex');
  }

  group('Rider & Courier Responsive & API Workflow Tests', () {
    const viewports = <Size>[
      Size(320, 640),
      Size(360, 740),
      Size(412, 915),
      Size(840, 1180),
    ];

    testWidgets('Rider Home, History, Earnings, Profile & TransferCourierShell fit cleanly across phones and tablets', (tester) async {
      for (final viewport in viewports) {
        await pumpAtSize(
          tester,
          viewport,
          RiderHomeScreen(onNavigateTab: (_) {}),
        );
        await pumpAtSize(tester, viewport, const DeliveryHistoryScreen());
        await pumpAtSize(tester, viewport, const EarningsScreen());
        await pumpAtSize(tester, viewport, const RiderProfileScreen());
        await pumpAtSize(tester, viewport, const TransferCourierShell());
      }
    });

    testWidgets('WeeklyChartWidget shows honest empty state when earnings history is empty', (tester) async {
      await pumpAtSize(
        tester,
        const Size(390, 844),
        const Scaffold(body: WeeklyChartWidget(data: [])),
      );
      expect(find.text('Past 7 Days Payouts'), findsOneWidget);
      expect(find.text('Past 7 Days'), findsOneWidget);
      expect(find.textContaining('₱0'), findsWidgets);
      expect(find.textContaining('October Payouts'), findsNothing);
      expect(find.textContaining('+18%'), findsNothing);
    });

    testWidgets('ParcelBarcodeScanner in parcelLookup mode invokes DeliveryService.lookupParcelRemote', (tester) async {
      ApiClient.instance.setMockClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/rider/lookup')) {
            expect(request.url.queryParameters['tracking_number'], 'NX-LOOK-77');
            return http.Response(
              jsonEncode({
                'status': 'success',
                'data': {
                  'order_id': 77,
                  'tracking_number': 'NX-LOOK-77',
                  'status': 'picked_up',
                  'recipient_name': 'Maria Clara',
                  'cod_amount': 450,
                  'payment_method': 'cod',
                },
              }),
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      );

      Map<String, dynamic>? fetched;
      bool? poppedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  poppedResult = await ParcelBarcodeScanner.open(
                    context,
                    mode: ParcelScanMode.parcelLookup,
                    title: 'Scan Parcel Waybill',
                    subtitle: 'Test Lookup',
                    scannerPreviewOverride: (ctx, emitBarcode) => ElevatedButton(
                      onPressed: () => emitBarcode('NX-LOOK-77'),
                      child: const Text('EMIT LOOKUP BARCODE'),
                    ),
                    onBarcodeSubmitted: (code) async {
                      fetched = await DeliveryService.instance.lookupParcelRemote(code);
                      return ParcelScanSubmissionResult(
                        success: true,
                        message: 'Parcel ${fetched!['tracking_number']} found',
                      );
                    },
                  );
                },
                child: const Text('OPEN SCANNER'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN SCANNER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EMIT LOOKUP BARCODE'));
      await tester.pumpAndSettle();

      expect(fetched, isNotNull);
      expect(fetched!['tracking_number'], 'NX-LOOK-77');
      expect(poppedResult, isTrue);
    });

    test('InAppNotificationService.fetchNotificationsRemote hydrates notifications & unread count', () async {
      ApiClient.instance.setMockClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/notifications')) {
            return http.Response(
              jsonEncode({
                'status': 'success',
                'data': [
                  {
                    'id': 11,
                    'title': 'New Dispatch Assigned',
                    'message': 'Order NX-101 is ready for pickup.',
                    'order_id': 'NX-101',
                    'read_at': null,
                    'created_at': '2026-11-16T08:00:00Z',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }),
      );

      await InAppNotificationService.instance.fetchNotificationsRemote();
      expect(InAppNotificationService.instance.history.length, 1);
      expect(InAppNotificationService.instance.history.first.orderId, 'NX-101');
      expect(InAppNotificationService.instance.unreadCountNotifier.value, 1);

      await InAppNotificationService.instance.markAllAsReadRemote();
      expect(InAppNotificationService.instance.unreadCountNotifier.value, 0);
    });
  });
}
