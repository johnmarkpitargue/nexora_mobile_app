import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/notification_feed_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/features/checkout/presentation/checkout_page.dart';
import 'package:nexora_flutter_app/features/home/presentation/homepage.dart';
import 'package:nexora_flutter_app/features/notifications/presentation/notifications_page.dart';
import 'package:nexora_flutter_app/features/orders/presentation/orders_page.dart';
import 'package:nexora_flutter_app/features/profile/presentation/profile_page.dart';

final List<int> _transparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentPng.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance.setMockClient(
      MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/buyer/home')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'flash_sales': <dynamic>[],
                'categories': <dynamic>[],
                'recommended': <dynamic>[],
                'new_arrivals': <dynamic>[],
                'featured_stores': <dynamic>[],
              },
            }),
            200,
          );
        }
        if (path.endsWith('/notifications')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {'notifications': <dynamic>[], 'unread_count': 0},
            }),
            200,
          );
        }
        if (path.endsWith('/buyer/orders')) {
          return http.Response(
            jsonEncode({'status': 'success', 'data': <dynamic>[]}),
            200,
          );
        }
        return http.Response(jsonEncode({'status': 'success', 'data': {}}), 200);
      }),
    );
    OrderService.instance.enablePolling = false;
    await ApiClient.instance.saveToken('test-buyer-token');
    BuyerAccountService.instance.resetState();
    OrderService.instance.clearAllOrders();
    await NotificationFeedService.instance.fetchNotificationsRemote();
  });

  tearDown(() async {
    OrderService.instance.stopPolling();
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

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: child,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  }

  group('Buyer App Responsive & DB Workflow Tests', () {
    const viewports = <Size>[
      Size(320, 640),
      Size(360, 740),
      Size(412, 915),
      Size(840, 1180),
    ];

    testWidgets('Home, Checkout, Orders, Notifications & Profile fit cleanly across phone and tablet widths', (tester) async {
      for (final viewport in viewports) {
        await pumpAtSize(tester, viewport, const NexoraHomePage());
        await pumpAtSize(tester, viewport, const CheckoutPage());
        await pumpAtSize(tester, viewport, const OrdersPage());
        await pumpAtSize(tester, viewport, const NotificationsPage());
        await pumpAtSize(tester, viewport, const ProfilePage());
      }
    });

    testWidgets('NotificationsPage displays clean empty state when DB returns no notifications', (tester) async {
      await pumpAtSize(tester, const Size(390, 844), const NotificationsPage());
      expect(find.textContaining('caught up'), findsOneWidget);
    });

    test('OrderService.fetchCheckoutSummaryRemote parses server fees, discounts, and vouchers', () async {
      ApiClient.instance.setMockClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/buyer/checkout/summary')) {
            expect(request.url.queryParameters['platform_voucher_id'], '10');
            return http.Response(
              jsonEncode({
                'status': 'success',
                'data': {
                  'stores': [
                    {
                      'seller_id': 7,
                      'store_name': 'Tech Garage PH',
                      'subtotal': 1250.0,
                      'shipping_fee': 65.0,
                      'total_weight_grams': 500,
                    },
                  ],
                  'available_vouchers': [
                    {
                      'id': 10,
                      'code': 'SAVE100',
                      'voucher_scope': 'platform',
                      'type': 'fixed',
                      'value': 100,
                      'min_spend': 500,
                      'is_claimed': true,
                      'is_used': false,
                    },
                  ],
                  'total_subtotal': 1250.0,
                  'total_shipping': 65.0,
                  'platform_discount': 100.0,
                  'shipping_discount': 0.0,
                  'store_discount': 0.0,
                  'total_discount': 100.0,
                  'voucher_errors': <dynamic>[],
                  'estimated_total': 1215.0,
                },
              }),
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      );

      final summary = await OrderService.instance.fetchCheckoutSummaryRemote(
        platformVoucherId: 10,
      );
      expect(summary.totalSubtotal, 1250.0);
      expect(summary.totalShipping, 65.0);
      expect(summary.totalDiscount, 100.0);
      expect(summary.estimatedTotal, 1215.0);
      expect(summary.availableVouchers.length, 1);
      expect(summary.availableVouchers.first.code, 'SAVE100');
    });

    test('OrderService.submitReturnShipmentRemote sends tracking number to Laravel', () async {
      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      ApiClient.instance.setMockClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/return-shipment')) {
            capturedPath = request.url.path;
            capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'status': 'success',
                'message': 'Return shipment recorded.',
                'data': {
                  'order': {
                    'id': 42,
                    'order_number': 'NX-42',
                    'status': 'return_requested',
                    'total_price': 500,
                    'created_at': '2026-11-16T08:00:00Z',
                    'items': <dynamic>[],
                  },
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({'status': 'success', 'data': <dynamic>[]}),
            200,
          );
        }),
      );

      final updated = await OrderService.instance.submitReturnShipmentRemote(
        42,
        returnTrackingNumber: 'RET-NX-9901',
      );

      expect(updated.serverId, 42);
      expect(capturedPath, '/api/mobile/v1/buyer/orders/42/return-shipment');
      expect(capturedBody?['return_tracking_number'], 'RET-NX-9901');
    });
  });
}
