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
import 'package:nexora_flutter_app/features/home/presentation/widgets/floating_nav_dock.dart';
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
        if (path.endsWith('/buyer/catalog')) {
          return http.Response(
            jsonEncode({'status': 'success', 'data': <dynamic>[]}),
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
    Widget child, {
    EdgeInsets viewInsets = EdgeInsets.zero,
    EdgeInsets viewPadding = const EdgeInsets.only(bottom: 16),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = FakeViewPadding(
      bottom: viewInsets.bottom,
      top: viewInsets.top,
      left: viewInsets.left,
      right: viewInsets.right,
    );
    tester.view.padding = FakeViewPadding(
      bottom: viewPadding.bottom,
      top: viewPadding.top,
      left: viewPadding.left,
      right: viewPadding.right,
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.view.resetPadding();
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

  void assertDockPinnedToBottom(
    WidgetTester tester,
    Size viewport, {
    double safeBottom = 16,
  }) {
    final dockFinder = find.byType(FloatingNavDock);
    expect(dockFinder, findsOneWidget);

    final dockRect = tester.getRect(dockFinder);
    // Must stay pinned at the bottom, never around the vertical center
    expect(
      dockRect.bottom,
      closeTo(viewport.height, 2.0),
      reason: 'FloatingNavDock should sit at screen bottom ($viewport)',
    );
    expect(
      dockRect.top,
      greaterThan(viewport.height * 0.72),
      reason: 'FloatingNavDock must not float near vertical center ($viewport)',
    );
    expect(dockRect.height, lessThan(120));

    // All 5 nav tabs visible without overlap/overflow
    for (int i = 0; i < 5; i++) {
      final tabFinder = find.byKey(ValueKey('nav-item-$i'));
      expect(tabFinder, findsOneWidget);
      final tabRect = tester.getRect(tabFinder);
      expect(tabRect.top, greaterThanOrEqualTo(dockRect.top));
      expect(tabRect.bottom, lessThanOrEqualTo(dockRect.bottom - safeBottom));
    }
  }

  group('Buyer App Responsive, Dock Position & DB Workflow Tests', () {
    const viewports = <Size>[
      Size(320, 640),
      Size(360, 740),
      Size(390, 844),
      Size(412, 915),
      Size(497, 750),
      Size(840, 1180),
    ];

    testWidgets(
      'FloatingNavDock stays anchored at bottom and Home renders cleanly across all 6 viewport sizes',
      (tester) async {
        for (final viewport in viewports) {
          await pumpAtSize(tester, viewport, const NexoraHomePage());
          assertDockPinnedToBottom(tester, viewport);
          expect(find.text('Recommended for you'), findsOneWidget);
          expect(find.text('No products available right now'), findsOneWidget);

          await pumpAtSize(tester, viewport, const CheckoutPage());
          await pumpAtSize(tester, viewport, const OrdersPage());
          await pumpAtSize(tester, viewport, const NotificationsPage());
          await pumpAtSize(tester, viewport, const ProfilePage());
        }
      },
    );

    testWidgets(
      'Switching all 5 bottom navigation tabs keeps FloatingNavDock fixed at the exact bottom position',
      (tester) async {
        const viewport = Size(390, 844);
        await pumpAtSize(tester, viewport, const NexoraHomePage());
        final initialRect = tester.getRect(find.byType(FloatingNavDock));
        assertDockPinnedToBottom(tester, viewport);

        for (int tab = 1; tab < 5; tab++) {
          await tester.tap(find.byKey(ValueKey('nav-item-$tab')));
          await tester.pumpAndSettle(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);

          final currentRect = tester.getRect(find.byType(FloatingNavDock));
          expect(currentRect.top, closeTo(initialRect.top, 0.5));
          expect(currentRect.bottom, closeTo(initialRect.bottom, 0.5));
          assertDockPinnedToBottom(tester, viewport);
        }

        // Switch back to Home
        await tester.tap(find.byKey(ValueKey('nav-item-0')));
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        expect(tester.getRect(find.byType(FloatingNavDock)).top,
            closeTo(initialRect.top, 0.5));
      },
    );

    testWidgets(
      'Keyboard appearance and dismissal does not permanently displace FloatingNavDock',
      (tester) async {
        const viewport = Size(390, 844);
        await pumpAtSize(
          tester,
          viewport,
          const NexoraHomePage(),
          viewInsets: const EdgeInsets.only(bottom: 300),
        );
        expect(tester.takeException(), isNull);

        await pumpAtSize(
          tester,
          viewport,
          const NexoraHomePage(),
          viewInsets: EdgeInsets.zero,
        );
        assertDockPinnedToBottom(tester, viewport);
      },
    );

    testWidgets(
      'HomePage displays loading, error+retry, and populated product states cleanly',
      (tester) async {
        final completer = Completer<http.Response>();
        ApiClient.instance.setMockClient(
          MockClient((request) async {
            if (request.url.path.endsWith('/buyer/catalog')) {
              return completer.future;
            }
            return http.Response(
              jsonEncode({
                'status': 'success',
                'data': {
                  'flash_sales': <dynamic>[],
                  'categories': [
                    {'id': 1, 'name': 'Audio', 'slug': 'audio'},
                  ],
                  'recommended': <dynamic>[],
                  'new_arrivals': <dynamic>[],
                  'featured_stores': <dynamic>[],
                },
              }),
              200,
            );
          }),
        );

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(theme: NexoraTheme.lightTheme, home: const NexoraHomePage()),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        assertDockPinnedToBottom(tester, const Size(390, 844), safeBottom: 0);

        // Complete with server error first
        completer.complete(
          http.Response(jsonEncode({'message': 'Backend unavailable'}), 500),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        expect(find.text('Try again'), findsOneWidget);

        // Now return real products on retry
        ApiClient.instance.setMockClient(
          MockClient((request) async {
            if (request.url.path.endsWith('/buyer/catalog')) {
              return http.Response(
                jsonEncode({
                  'status': 'success',
                  'data': [
                    {
                      'id': 501,
                      'name': 'Nexora USB-C Hub',
                      'price': 899,
                      'stock': 12,
                      'seller': {'id': 2, 'store_name': 'GearLab'},
                    },
                  ],
                }),
                200,
              );
            }
            return http.Response(jsonEncode({'status': 'success', 'data': {}}), 200);
          }),
        );

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        expect(find.text('Nexora USB-C Hub'), findsWidgets);
        expect(find.text('1 product'), findsOneWidget);
        assertDockPinnedToBottom(tester, const Size(390, 844), safeBottom: 0);
      },
    );

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
