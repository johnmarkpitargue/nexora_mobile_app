import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/features/orders/presentation/orders_page.dart';

final List<int> _transparentPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
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
  int get statusCode => HttpStatus.ok;

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
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('User-Specific Order Isolation & Clean State Test Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      OrderService.instance.enablePolling = false;
      BuyerAccountService.instance.resetState();
      OrderService.instance.clearAllOrders();
      ApiClient.instance.client = http.Client();
    });

    tearDown(() {
      OrderService.instance.stopPolling();
    });

    test('1. Every new registered user starts with exactly 0 orders', () {
      const emailA = 'alice.newcomer@example.com';
      final regA = BuyerAccountService.instance.registerBuyer(
        firstName: 'Alice',
        lastName: 'Wonder',
        email: emailA,
        mobileNumber: '09181234567',
        dateOfBirth: DateTime(1995, 3, 10),
        password: 'Password@123',
        confirmPassword: 'Password@123',
        agreeTerms: true,
      );
      expect(regA.success, isTrue);
      expect(regA.otp, isNotNull);

      BuyerAccountService.instance.verifyOtp(
        email: emailA,
        inputOtp: regA.otp!,
      );
      BuyerAccountService.instance.loginBuyer(
        emailOrPhone: emailA,
        password: 'Password@123',
      );

      expect(BuyerAccountService.instance.currentBuyer?.email, equals(emailA));
      expect(OrderService.instance.activeOrders.length, equals(0));
      expect(OrderService.instance.pastOrders.length, equals(0));
      expect(OrderService.instance.totalOrderCount, equals(0));
    });

    test(
      '2. Server orders for User A do not leak into User B account',
      () async {
        // Step A: Login User A and fetch orders from mock server
        const emailA = 'user.a@example.com';
        BuyerAccountService.instance.registerBuyer(
          firstName: 'UserA',
          lastName: 'Nexora',
          email: emailA,
          mobileNumber: '09181112222',
          dateOfBirth: DateTime(1994, 5, 20),
          password: 'Password@123',
          confirmPassword: 'Password@123',
          agreeTerms: true,
        );
        BuyerAccountService.instance.loginBuyer(
          emailOrPhone: emailA,
          password: 'Password@123',
        );
        await ApiClient.instance.saveToken('token_a');

        ApiClient.instance.client = MockClient((req) async {
          if (req.url.path.contains('/orders')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 101,
                    'order_number': 'NX-101-AAA',
                    'status': 'placed',
                    'subtotal': 1500.0,
                    'shipping_fee': 50.0,
                    'discount': 0.0,
                    'total': 1550.0,
                    'items': [
                      {
                        'id': 1,
                        'product_id': 12,
                        'product_name': 'Wireless Keyboard',
                        'price': 1500.0,
                        'quantity': 1,
                        'variant': 'Dark Slate',
                        'image': '',
                      },
                    ],
                  },
                ],
                'counts': {
                  'all': 1,
                  'to_pay': 0,
                  'to_ship': 1,
                  'to_receive': 0,
                  'completed': 0,
                  'cancelled': 0,
                  'return_refund': 0,
                },
              }),
              200,
            );
          }
          return http.Response('{}', 404);
        });

        await OrderService.instance.fetchOrdersRemote();
        expect(OrderService.instance.activeOrders.length, equals(1));
        expect(
          OrderService.instance.activeOrders.first.items.first.title,
          equals('Wireless Keyboard'),
        );

        // Step B: Logout -> orders must immediately be wiped
        BuyerAccountService.instance.logout();
        await ApiClient.instance.clearToken();
        expect(OrderService.instance.activeOrders.length, equals(0));
        expect(OrderService.instance.totalOrderCount, equals(0));

        // Step C: Login User B (returns 0 orders from server)
        const emailB = 'user.b@example.com';
        BuyerAccountService.instance.registerBuyer(
          firstName: 'UserB',
          lastName: 'Nexora',
          email: emailB,
          mobileNumber: '09183334444',
          dateOfBirth: DateTime(1996, 8, 14),
          password: 'Password@123',
          confirmPassword: 'Password@123',
          agreeTerms: true,
        );
        BuyerAccountService.instance.loginBuyer(
          emailOrPhone: emailB,
          password: 'Password@123',
        );
        await ApiClient.instance.saveToken('token_b');

        ApiClient.instance.client = MockClient((req) async {
          return http.Response(
            jsonEncode({
              'data': [],
              'counts': {
                'all': 0,
                'to_pay': 0,
                'to_ship': 0,
                'to_receive': 0,
                'completed': 0,
                'cancelled': 0,
                'return_refund': 0,
              },
            }),
            200,
          );
        });

        await OrderService.instance.fetchOrdersRemote();
        expect(OrderService.instance.activeOrders.length, equals(0));
        expect(OrderService.instance.pastOrders.length, equals(0));
      },
    );

    testWidgets(
      '3. OrdersPage renders clean empty state without fake newcomer hub',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const email = 'clara.new@example.com';
        BuyerAccountService.instance.registerBuyer(
          firstName: 'Clara',
          lastName: 'Oswald',
          email: email,
          mobileNumber: '09185556666',
          dateOfBirth: DateTime(1993, 11, 23),
          password: 'Password@123',
          confirmPassword: 'Password@123',
          agreeTerms: true,
        );
        BuyerAccountService.instance.loginBuyer(
          emailOrPhone: email,
          password: 'Password@123',
        );
        await ApiClient.instance.saveToken('token_clara');

        ApiClient.instance.client = MockClient((req) async {
          return http.Response(
            jsonEncode({
              'data': [],
              'counts': {
                'all': 0,
                'to_pay': 0,
                'to_ship': 0,
                'to_receive': 0,
                'completed': 0,
                'cancelled': 0,
                'return_refund': 0,
              },
            }),
            200,
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: OrdersPage(isActiveTab: true)),
        );
        await tester.pumpAndSettle();

        // Verify no fake newcomer hub banner
        expect(find.text('NEWCOMER PRIVILEGE'), findsNothing);
        expect(find.text('NEXORAFIRST'), findsNothing);

        // Verify clean real empty state
        expect(find.text('No Orders Yet'), findsOneWidget);
        expect(find.text('Discover Products'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Return/Refund tab displays clean empty state without mock orders for new user',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const email = 'david.new@example.com';
        BuyerAccountService.instance.registerBuyer(
          firstName: 'David',
          lastName: 'Tennant',
          email: email,
          mobileNumber: '09187778888',
          dateOfBirth: DateTime(1991, 10, 10),
          password: 'Password@123',
          confirmPassword: 'Password@123',
          agreeTerms: true,
        );
        BuyerAccountService.instance.loginBuyer(
          emailOrPhone: email,
          password: 'Password@123',
        );
        await ApiClient.instance.saveToken('token_david');

        ApiClient.instance.client = MockClient((req) async {
          return http.Response(
            jsonEncode({
              'data': [],
              'counts': {
                'all': 0,
                'to_pay': 0,
                'to_ship': 0,
                'to_receive': 0,
                'completed': 0,
                'cancelled': 0,
                'return_refund': 0,
              },
            }),
            200,
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: OrdersPage(isActiveTab: true)),
        );
        await tester.pumpAndSettle();

        // Switch to Return/Refund tab
        await tester.tap(find.text('Return/Refund'));
        await tester.pumpAndSettle();

        // Must NOT show old dummy mock items
        expect(find.text('Nexora Ergonomic Precision Mouse'), findsNothing);
        expect(find.text('Minimalist Canvas Commuter Tote...'), findsNothing);

        // Must show guarantee banner and empty state
        expect(find.text('Return & Refund Guarantee'), findsOneWidget);
        expect(find.text('No Return or Refund Requests'), findsOneWidget);
      },
    );
  });
}
