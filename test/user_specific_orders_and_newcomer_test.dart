import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/features/orders/presentation/orders_page.dart';

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

class _MockHttpClientResponse extends StreamView<List<int>> with Fake implements HttpClientResponse {
  _MockHttpClientResponse() : super(Stream<List<int>>.fromIterable([_transparentPng]));

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('User-Specific Order Isolation & Newcomer Hub Test Suite', () {
    setUp(() {
      BuyerAccountService.instance.resetState();
      OrderService.instance.clearAllOrders();
    });

    test('1. Every new registered user starts with exactly 0 orders', () {
      // Register newcomer A with a unique phone
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

      BuyerAccountService.instance.verifyOtp(email: emailA, inputOtp: regA.otp!);
      BuyerAccountService.instance.loginBuyer(emailOrPhone: emailA, password: 'Password@123');

      expect(BuyerAccountService.instance.currentBuyer?.email, equals(emailA));
      expect(OrderService.instance.activeOrders.length, equals(0));
      expect(OrderService.instance.pastOrders.length, equals(0));
      expect(OrderService.instance.totalOrderCount, equals(0));
    });

    test('2. Orders placed by User A do not leak into newly registered User B account', () {
      // Step A: Login User A and place an order
      const emailA = 'user.a@example.com';
      final regA = BuyerAccountService.instance.registerBuyer(
        firstName: 'UserA',
        lastName: 'Nexora',
        email: emailA,
        mobileNumber: '09181112222',
        dateOfBirth: DateTime(1994, 5, 20),
        password: 'Password@123',
        confirmPassword: 'Password@123',
        agreeTerms: true,
      );
      expect(regA.success, isTrue);
      BuyerAccountService.instance.verifyOtp(email: emailA, inputOtp: regA.otp!);
      BuyerAccountService.instance.loginBuyer(emailOrPhone: emailA, password: 'Password@123');

      OrderService.instance.placeOrder(
        items: [
          CartItemModel(
            id: 'item_tech_1',
            storeName: 'Nexora Mall',
            storeBadge: 'MALL',
            title: 'Wireless Keyboard',
            variant: 'Dark Slate',
            price: 1500.0,
            imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3',
          ),
        ],
        totalPrice: 1500.0,
        paymentMethod: 'Cash on Delivery',
      );

      expect(OrderService.instance.activeOrders.length, equals(1));
      expect(OrderService.instance.activeOrders.first.items.first.title, equals('Wireless Keyboard'));

      // Step B: Logout and register User B
      BuyerAccountService.instance.logout();
      expect(OrderService.instance.activeOrders.length, equals(0));

      const emailB = 'user.b@example.com';
      final regB = BuyerAccountService.instance.registerBuyer(
        firstName: 'UserB',
        lastName: 'Nexora',
        email: emailB,
        mobileNumber: '09183334444',
        dateOfBirth: DateTime(1996, 8, 14),
        password: 'Password@123',
        confirmPassword: 'Password@123',
        agreeTerms: true,
      );
      expect(regB.success, isTrue);
      BuyerAccountService.instance.verifyOtp(email: emailB, inputOtp: regB.otp!);
      BuyerAccountService.instance.loginBuyer(emailOrPhone: emailB, password: 'Password@123');

      // User B MUST have 0 orders
      expect(OrderService.instance.activeOrders.length, equals(0));
      expect(OrderService.instance.pastOrders.length, equals(0));

      // Step C: Log back in as User A -> their order is safely isolated and intact
      BuyerAccountService.instance.loginBuyer(emailOrPhone: emailA, password: 'Password@123');
      expect(OrderService.instance.activeOrders.length, equals(1));
      expect(OrderService.instance.activeOrders.first.items.first.title, equals('Wireless Keyboard'));
    });

    testWidgets('3. OrdersPage renders Newcomer Hub with welcome banner, voucher, and checklist for new user', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const email = 'clara.new@example.com';
      final reg = BuyerAccountService.instance.registerBuyer(
        firstName: 'Clara',
        lastName: 'Oswald',
        email: email,
        mobileNumber: '09185556666',
        dateOfBirth: DateTime(1993, 11, 23),
        password: 'Password@123',
        confirmPassword: 'Password@123',
        agreeTerms: true,
      );
      expect(reg.success, isTrue);
      BuyerAccountService.instance.verifyOtp(email: email, inputOtp: reg.otp!);
      BuyerAccountService.instance.loginBuyer(emailOrPhone: email, password: 'Password@123');

      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Newcomer Privilege and Personalized greeting
      expect(find.text('NEWCOMER PRIVILEGE'), findsOneWidget);
      expect(find.text('Welcome to Nexora, Clara!'), findsOneWidget);

      // Verify Welcome Voucher & Code
      expect(find.text('₱150 Welcome Voucher'), findsOneWidget);
      expect(find.text('Valid on any first order • Code: NEXORAFIRST'), findsOneWidget);
      expect(find.text('Claim Voucher'), findsOneWidget);

      // Verify Action Guide & Checklist
      expect(find.text('What should you do next?'), findsOneWidget);
      expect(find.text('Claim your ₱150 Welcome Voucher'), findsOneWidget);
      expect(find.text('Set up your Delivery Address'), findsOneWidget);
      expect(find.text('Start Shopping with ₱150 OFF'), findsOneWidget);

      // Tap Claim Voucher
      await tester.tap(find.text('Claim Voucher'));
      await tester.pump();
      expect(find.text('Claimed ✓'), findsOneWidget);
    });

    testWidgets('4. Return/Refund tab displays clean empty state without mock orders for new user', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const email = 'david.new@example.com';
      final reg = BuyerAccountService.instance.registerBuyer(
        firstName: 'David',
        lastName: 'Tennant',
        email: email,
        mobileNumber: '09187778888',
        dateOfBirth: DateTime(1991, 10, 10),
        password: 'Password@123',
        confirmPassword: 'Password@123',
        agreeTerms: true,
      );
      expect(reg.success, isTrue);
      BuyerAccountService.instance.verifyOtp(email: email, inputOtp: reg.otp!);
      BuyerAccountService.instance.loginBuyer(emailOrPhone: email, password: 'Password@123');

      await tester.pumpWidget(
        const MaterialApp(
          home: OrdersPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Return/Refund tab (index 5)
      await tester.tap(find.text('Return/Refund'));
      await tester.pumpAndSettle();

      // Must NOT show old dummy mock items
      expect(find.text('Nexora Ergonomic Precision Mouse'), findsNothing);
      expect(find.text('Minimalist Canvas Commuter Tote...'), findsNothing);

      // Must show guarantee banner and empty state
      expect(find.text('Return & Refund Guarantee'), findsOneWidget);
      expect(find.text('No Return or Refund Requests'), findsOneWidget);
    });
  });
}
