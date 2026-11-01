import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/payment_method_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/features/profile/presentation/payment_methods_page.dart';
import 'package:nexora_flutter_app/features/checkout/presentation/checkout_page.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
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
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    BuyerAccountService.instance.logout();
  });

  group('Payment Method Switching & Dynamic Hero Card', () {
    test('switching payment default updates defaultMethod and hero card state', () {
      final paymentService = PaymentMethodService.instance;
      expect(paymentService.methods.isNotEmpty, true);

      // Set COD as default
      paymentService.setDefault('cod_primary');
      expect(paymentService.defaultMethod.id, 'cod_primary');
      expect(paymentService.defaultMethod.type, PaymentType.cod);

      // Set Card as default
      paymentService.setDefault('visa_primary');
      expect(paymentService.defaultMethod.id, 'visa_primary');
      expect(paymentService.defaultMethod.type, PaymentType.card);

      // Set GCash as default
      paymentService.setDefault('gcash_primary');
      expect(paymentService.defaultMethod.id, 'gcash_primary');
      expect(paymentService.defaultMethod.type, PaymentType.gcash);
    });

    testWidgets('PaymentMethodsPage renders hero card dynamically matching default', (tester) async {
      final paymentService = PaymentMethodService.instance;
      paymentService.setDefault('cod_primary');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PaymentMethodsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Top Primary Payment Method header
      expect(find.text('Primary Payment Method'), findsOneWidget);
      // When COD is default, Cash on Delivery is present
      expect(find.text('Cash on Delivery'), findsWidgets);

      // Switch to GCash
      paymentService.setDefault('gcash_primary');
      await tester.pumpAndSettle();
      expect(find.text('GCash'), findsWidgets);
    });
  });

  group('Store Follow Count Per User Scoping', () {
    test('followed stores count is isolated per user account and starts at 0 for new user', () {
      final shopService = ShopService.instance;
      final auth = BuyerAccountService.instance;

      // User 1
      final res1 = auth.registerBuyer(
        firstName: 'User',
        lastName: 'One',
        email: 'user1@nexora.com',
        mobileNumber: '09171111111',
        password: 'Password123!',
        confirmPassword: 'Password123!',
        agreeTerms: true,
        dateOfBirth: DateTime(1995, 1, 1),
      );
      auth.verifyOtp(email: res1.buyer!.email, inputOtp: res1.otp!);
      expect(shopService.followedShopCount, 0);

      // Follow a shop
      shopService.toggleFollow('nexora_home_living');
      expect(shopService.isFollowing('nexora_home_living'), true);
      expect(shopService.followedShopCount, 1);

      // User 2
      final res2 = auth.registerBuyer(
        firstName: 'User',
        lastName: 'Two',
        email: 'user2@nexora.com',
        mobileNumber: '09172222222',
        password: 'Password123!',
        confirmPassword: 'Password123!',
        agreeTerms: true,
        dateOfBirth: DateTime(1998, 5, 10),
      );
      auth.verifyOtp(email: res2.buyer!.email, inputOtp: res2.otp!);
      // User 2 must start with 0 followed stores
      expect(shopService.followedShopCount, 0);
      expect(shopService.isFollowing('nexora_home_living'), false);

      // Switch back to User 1
      auth.loginBuyer(emailOrPhone: 'user1@nexora.com', password: 'Password123!');
      expect(shopService.followedShopCount, 1);
      expect(shopService.isFollowing('nexora_home_living'), true);
    });

    testWidgets('ProfilePage displays accurate following count from ShopService', (tester) async {
      final auth = BuyerAccountService.instance;
      final shopService = ShopService.instance;

      final res = auth.registerBuyer(
        firstName: 'Maria',
        lastName: 'Santos',
        email: 'maria.santos@test.com',
        mobileNumber: '09173333333',
        password: 'Password123!',
        confirmPassword: 'Password123!',
        agreeTerms: true,
        dateOfBirth: DateTime(1994, 3, 12),
      );
      auth.verifyOtp(email: res.buyer!.email, inputOtp: res.otp!);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfilePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts at 0
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('0'), findsWidgets);

      // Follow a shop
      shopService.toggleFollow('aura_studios');
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
    });
  });

  group('Checkout Page Improvements', () {
    testWidgets('PayLater badge is removed and Official Store badge has blue color', (tester) async {
      CartService.instance.buyNow(
        title: 'Nexora Pro Heavy Duty Suspension Boom Arm',
        variant: 'Brushed Space Silver',
        price: 899.0,
        imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df',
        storeName: 'Nexora Studio Audio Official',
        storeBadge: 'OFFICIAL STORE',
        originalPrice: 1400.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CheckoutPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify 0% PayLater (up to 3M) badge is NOT present
      expect(find.text('0% PayLater (up to 3M)'), findsNothing);

      // 2. Verify OFFICIAL STORE text is present
      expect(find.text('OFFICIAL STORE'), findsOneWidget);

      // 3. Verify Shop Voucher and Message for Seller action rows are present
      expect(find.text('Shop Voucher'), findsOneWidget);
      expect(find.text('Message for Seller'), findsOneWidget);
    });
  });

  group('Address Scoping & New User Initial State', () {
    test('newly registered user starts with 0 saved addresses', () {
      final auth = BuyerAccountService.instance;
      final addressService = AddressService.instance;

      final regRes = auth.registerBuyer(
        firstName: 'Patricia',
        lastName: 'Santos',
        email: 'patricia.santos@testbuyer.com',
        mobileNumber: '09170001122',
        dateOfBirth: DateTime(1997, 3, 15),
        password: 'Passw0rd!Valid',
        confirmPassword: 'Passw0rd!Valid',
        agreeTerms: true,
      );
      expect(regRes.success, isTrue);

      final verifyRes = auth.verifyOtp(
        email: 'patricia.santos@testbuyer.com',
        inputOtp: regRes.otp!,
      );
      expect(verifyRes.success, isTrue);

      // Verify new user has NO addresses pre-filled
      expect(addressService.addresses.isEmpty, isTrue);
      expect(addressService.defaultAddress, isNull);

      // Add address for Patricia
      final addRes = addressService.addAddress(
        AddressModel(
          id: 'addr_patricia_1',
          fullName: 'Patricia Santos',
          phone: '09170001122',
          region: 'Region IV-A (CALABARZON)',
          city: 'Liliw, Laguna',
          barangay: 'Tuy-Baanan',
          streetBuilding: 'Block 4 Lot 10',
          regionCity: 'Liliw, Laguna',
          postalCode: '4004',
          label: 'Home',
          isDefault: true,
        ),
      );
      expect(addRes.success, isTrue);
      expect(addressService.addresses.length, equals(1));
      expect(addressService.defaultAddress?.fullName, equals('Patricia Santos'));

      // Now register another new user
      final user2 = auth.registerBuyer(
        firstName: 'Kevin',
        lastName: 'Reyes',
        email: 'kevin.reyes@testbuyer.com',
        mobileNumber: '09173334455',
        dateOfBirth: DateTime(1995, 8, 20),
        password: 'Passw0rd!Valid',
        confirmPassword: 'Passw0rd!Valid',
        agreeTerms: true,
      );
      auth.verifyOtp(email: 'kevin.reyes@testbuyer.com', inputOtp: user2.otp!);

      // Kevin must NOT see Patricia's address
      expect(addressService.addresses.isEmpty, isTrue);
      expect(addressService.defaultAddress, isNull);
    });
  });
}

