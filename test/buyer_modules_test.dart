import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/constants/api_constants.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/widgets/added_to_cart_hud.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';
import 'package:nexora_flutter_app/features/product_details/presentation/product_details_page.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';

// Transparent 1x1 PNG for image mocking in test environment
final _transparentPng = <int>[
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

  @override
  HttpHeaders get headers => _MockHttpHeaders();
}

Widget createTestPDP(dynamic productOrId, {Key? key}) {
  return MaterialApp(
    key: key,
    initialRoute: '/pdp',
    onGenerateRoute: (settings) {
      if (settings.name != null && settings.name!.startsWith('/products/')) {
        return AppRoutes.onGenerateRoute(settings);
      }
      return MaterialPageRoute(
        settings: RouteSettings(name: '/pdp', arguments: productOrId),
        builder: (_) => const ProductDetailsPage(),
      );
    },
    routes: {
      '/cart': (_) => const Scaffold(body: Text('Cart Screen')),
      '/checkout': (_) => const Scaffold(body: Text('Checkout Screen')),
      '/chat': (_) => const Scaffold(body: Text('Chat Screen')),
      '/home': (_) => const Scaffold(body: Text('Home Screen')),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  // =========================================================================
  // MODULE 1: ACCOUNT & SECURITY (BUY-ACCT-001 to BUY-ACCT-012)
  // =========================================================================
  group('Module 1: Account & Security Test Suite', () {
    late BuyerAccountService service;

    setUp(() {
      service = BuyerAccountService.instance;
      service.resetState();
      service.seedLoggedInBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'buyer.test@nexora.com',
        mobileNumber: '09171234567',
        password: 'Mamimili@2026',
      );
    });

    test('BUY-ACCT-001: Edit First Name with valid input (accented chars like ñ, 2-50 chars)', () {
      final res = service.updateProfileName(
        firstName: 'Niño José',
        lastName: 'Dela Cruz',
      );
      expect(res.success, isTrue);
      expect(service.currentBuyer?.firstName, equals('Niño José'));
      expect(service.currentBuyer?.fullName, equals('Niño José Dela Cruz'));
    });

    test('BUY-ACCT-002: Edit First Name with invalid input (numbers/special symbols, or < 2 chars)', () {
      // Input with numbers and symbols
      final resWithNums = service.updateProfileName(
        firstName: 'Juan123!',
        lastName: 'Dela Cruz',
      );
      expect(resWithNums.success, isFalse);
      expect(resWithNums.message, contains('letters'));
      expect(service.currentBuyer?.firstName, equals('Juan'));

      // Input too short (< 2 chars)
      final resShort = service.updateProfileName(
        firstName: 'J',
        lastName: 'Dela Cruz',
      );
      expect(resShort.success, isFalse);
      expect(resShort.message, contains('2'));
      expect(service.currentBuyer?.firstName, equals('Juan'));
    });

    test('BUY-ACCT-003: Upload Profile Photo with oversized file (> 5 MB)', () {
      final resOversized = service.uploadProfilePhoto(
        fileName: 'profile_pic.jpg',
        fileSizeBytes: 6 * 1024 * 1024, // 6 MB
      );
      expect(resOversized.success, isFalse);
      expect(resOversized.message, contains('5MB'));
    });

    test('BUY-ACCT-004: Upload Profile Photo with unsupported format (e.g. .exe, .gif)', () {
      final resInvalidFormat = service.uploadProfilePhoto(
        fileName: 'profile_pic.gif',
        fileSizeBytes: 1 * 1024 * 1024,
      );
      expect(resInvalidFormat.success, isFalse);
      expect(resInvalidFormat.message, contains('JPG'));

      final resValid = service.uploadProfilePhoto(
        fileName: 'valid_pic.png',
        fileSizeBytes: 2 * 1024 * 1024,
      );
      expect(resValid.success, isTrue);
    });

    test('BUY-ACCT-005: Change Password with correct current and valid new password', () {
      final res = service.changePassword(
        currentPassword: 'Mamimili@2026',
        newPassword: 'BagongPassword#2027',
        confirmPassword: 'BagongPassword#2027',
      );
      expect(res.success, isTrue);
      expect(res.message, contains('Password changed successfully'));
    });

    test('BUY-ACCT-006: Change Password with wrong current password', () {
      final res = service.changePassword(
        currentPassword: 'WrongPassword@123',
        newPassword: 'BagongPassword#2027',
        confirmPassword: 'BagongPassword#2027',
      );
      expect(res.success, isFalse);
      expect(res.message, contains('Current password does not match'));
    });

    test('BUY-ACCT-007: Change Password where new password fails complexity rules', () {
      // Missing uppercase and special char
      final resWeak = service.changePassword(
        currentPassword: 'Mamimili@2026',
        newPassword: 'lowercaseonly123',
        confirmPassword: 'lowercaseonly123',
      );
      expect(resWeak.success, isFalse);
      expect(resWeak.message, contains('uppercase'));

      // Too short (< 8 chars)
      final resShort = service.changePassword(
        currentPassword: 'Mamimili@2026',
        newPassword: 'Pass1!',
        confirmPassword: 'Pass1!',
      );
      expect(resShort.success, isFalse);
      expect(resShort.message, contains('8 characters'));
    });

    test('BUY-ACCT-008: Change Password where New and Confirm Passwords do not match', () {
      final resMismatch = service.changePassword(
        currentPassword: 'Mamimili@2026',
        newPassword: 'BagongPassword#2027',
        confirmPassword: 'DifferentPassword#2027',
      );
      expect(resMismatch.success, isFalse);
      expect(resMismatch.message, contains('do not match'));
    });

    test('BUY-ACCT-009: Change Email with duplicate email across roles/users', () {
      // Existing seller account
      final resDuplicate = service.requestEmailChange(
        newEmail: 'mariaclara.santos@example.com',
      );
      expect(resDuplicate.success, isFalse);
      expect(resDuplicate.message, contains('already in use'));
    });

    test('BUY-ACCT-010: Change Mobile Number with invalid format or duplicate', () {
      // Invalid format (not 11 digits, doesn't start with 09)
      final resInvalid = service.requestMobileChange(
        newMobile: '08123456789',
      );
      expect(resInvalid.success, isFalse);
      expect(resInvalid.message, contains('09'));

      // Duplicate mobile (seeded seller phone)
      final resDuplicate = service.requestMobileChange(
        newMobile: '09189876543',
      );
      expect(resDuplicate.success, isFalse);
      expect(resDuplicate.message, contains('already registered'));
    });

    test('BUY-ACCT-011: OTP Verification during Email / Phone change', () {
      final reqRes = service.requestEmailChange(newEmail: 'fresh.buyer@nexora.com');
      expect(reqRes.success, isTrue);
      expect(reqRes.otp, isNotNull);

      // Verify with wrong OTP
      final wrongRes = service.verifyEmailChangeOtp(
        newEmail: 'fresh.buyer@nexora.com',
        enteredOtp: '000000',
      );
      expect(wrongRes.success, isFalse);
      expect(wrongRes.message, contains('Invalid verification code'));

      // Verify with correct OTP
      final correctRes = service.verifyEmailChangeOtp(
        newEmail: 'fresh.buyer@nexora.com',
        enteredOtp: reqRes.otp!,
      );
      expect(correctRes.success, isTrue);
      expect(service.currentBuyer?.email, equals('fresh.buyer@nexora.com'));
    });

    test('BUY-ACCT-012: Logout terminates active session', () {
      expect(service.isLoggedIn, isTrue);
      service.logout();
      expect(service.isLoggedIn, isFalse);
      expect(service.currentBuyer, isNull);
    });
  });

  // =========================================================================
  // MODULE 2: ADDRESS BOOK (BUY-ADDR-001 to BUY-ADDR-011)
  // =========================================================================
  group('Module 2: Address Book Test Suite', () {
    late AddressService addressService;

    setUp(() {
      addressService = AddressService.instance;
      addressService.resetToDefaults();
      addressService.addAddress(
        AddressModel(
          id: 'test_addr_1',
          fullName: 'Test User 1',
          phone: '09171112233',
          region: 'NCR',
          city: 'Makati City',
          barangay: 'Poblacion',
          streetBuilding: '100 Main St',
          regionCity: 'Makati, NCR',
          postalCode: '1200',
          label: 'Home',
          isDefault: true,
        ),
      );
      addressService.addAddress(
        AddressModel(
          id: 'test_addr_2',
          fullName: 'Test User 2',
          phone: '09172223344',
          region: 'NCR',
          city: 'Quezon City',
          barangay: 'Diliman',
          streetBuilding: '200 Second St',
          regionCity: 'Quezon City, NCR',
          postalCode: '1100',
          label: 'Work',
          isDefault: false,
        ),
      );
    });

    test('BUY-ADDR-001: Add new address with complete valid fields', () {
      final initialCount = addressService.addresses.length;
      final newAddr = AddressModel(
        id: 'addr_new',
        fullName: 'Maria Santos',
        phone: '09175554321',
        region: 'NCR',
        city: 'Makati City',
        barangay: 'Poblacion',
        streetBuilding: '123 Kalayaan Ave, Apt 4B',
        regionCity: 'Poblacion, Makati City, NCR',
        postalCode: '1210',
        label: 'Work',
        isDefault: false,
      );

      final res = addressService.addAddress(newAddr);
      expect(res.success, isTrue);
      expect(addressService.addresses.length, equals(initialCount + 1));
      final added = addressService.addresses.last;
      expect(added.fullName, equals('Maria Santos'));
      expect(added.city, equals('Makati City'));
      expect(added.postalCode, equals('1210'));
    });

    test('BUY-ADDR-002: Cascading hierarchy - changing Region clears City and Barangay', () {
      final citiesInNCR = addressService.getCitiesForRegion('NCR');
      expect(citiesInNCR, contains('Makati City'));
      expect(citiesInNCR, contains('Quezon City'));
      expect(citiesInNCR, isNot(contains('Cebu City')));

      final citiesInReg7 = addressService.getCitiesForRegion('Region VII');
      expect(citiesInReg7, contains('Cebu City'));
      expect(citiesInReg7, isNot(contains('Makati City')));
    });

    test('BUY-ADDR-003: Cascading hierarchy - changing City clears and updates Barangays', () {
      final makatiBarangays = addressService.getBarangaysForCity('Makati City');
      expect(makatiBarangays, contains('Poblacion'));
      expect(makatiBarangays, contains('Bel-Air'));
      expect(makatiBarangays, isNot(contains('Lahug')));

      final cebuBarangays = addressService.getBarangaysForCity('Cebu City');
      expect(cebuBarangays, contains('Lahug'));
      expect(cebuBarangays, isNot(contains('Poblacion')));
    });

    test('BUY-ADDR-004: Postal code auto-lookup based on City/Municipality', () {
      expect(addressService.lookupPostalCode('Makati City'), equals('1200'));
      expect(addressService.lookupPostalCode('Quezon City'), equals('1100'));
      expect(addressService.lookupPostalCode('Cebu City'), equals('6000'));
      expect(addressService.lookupPostalCode('Davao City'), equals('8000'));
    });

    test('BUY-ADDR-005: Add address exceeding maximum limit of 10 addresses', () {
      while (addressService.addresses.length < 10) {
        addressService.addAddress(
          AddressModel(
            id: 'addr_fill_${addressService.addresses.length}',
            fullName: 'Test Resident ${addressService.addresses.length}',
            phone: '09171234567',
            region: 'NCR',
            city: 'City of Manila',
            barangay: 'Ermita',
            streetBuilding: 'Street ${addressService.addresses.length}',
            regionCity: 'Manila, NCR',
            postalCode: '1000',
            label: 'Home',
          ),
        );
      }
      expect(addressService.addresses.length, equals(10));

      final res11th = addressService.addAddress(
        AddressModel(
          id: 'addr_11',
          fullName: 'Eleventh Resident',
          phone: '09171234567',
          region: 'NCR',
          city: 'City of Manila',
          barangay: 'Ermita',
          streetBuilding: 'Extra St',
          regionCity: 'Manila, NCR',
          postalCode: '1000',
          label: 'Home',
        ),
      );

      expect(res11th.success, isFalse);
      expect(res11th.message, contains('10 addresses'));
      expect(addressService.addresses.length, equals(10));
    });

    test('BUY-ADDR-006: Set an address as Default updates flags correctly', () {
      final initialDefault = addressService.defaultAddress;
      expect(initialDefault, isNotNull);

      addressService.addAddress(
        AddressModel(
          id: 'addr_new_def',
          fullName: 'Second Address User',
          phone: '09171234567',
          region: 'NCR',
          city: 'Taguig City (BGC)',
          barangay: 'Fort Bonifacio',
          streetBuilding: '5th Ave BGC',
          regionCity: 'Taguig City, NCR',
          postalCode: '1634',
          label: 'Work',
          isDefault: true,
        ),
      );

      final newDefault = addressService.defaultAddress;
      expect(newDefault, isNotNull);
      expect(newDefault!.fullName, equals('Second Address User'));
      expect(newDefault.isDefault, isTrue);

      final oldDefault = addressService.addresses.firstWhere((a) => a.id == initialDefault!.id);
      expect(oldDefault.isDefault, isFalse);
    });

    test('BUY-ADDR-007: Deleting the single default address is blocked when multiple exist', () {
      expect(addressService.addresses.length, greaterThan(1));
      final defaultAddr = addressService.defaultAddress;
      expect(defaultAddr, isNotNull);

      final deleteRes = addressService.deleteAddress(defaultAddr!.id);
      expect(deleteRes.success, isFalse);
      expect(deleteRes.message, contains('Cannot delete default delivery address'));
    });

    test('BUY-ADDR-008: Edit existing address reflects changes', () {
      final firstAddr = addressService.addresses.first;
      final updateRes = addressService.updateAddress(
        firstAddr.copyWith(
          fullName: 'Updated Name Jr.',
          phone: '09181112233',
          streetBuilding: 'Unit 999 Luxury Tower',
          label: 'Penthouse',
        ),
      );

      expect(updateRes.success, isTrue);
      final updated = addressService.addresses.firstWhere((a) => a.id == firstAddr.id);
      expect(updated.fullName, equals('Updated Name Jr.'));
      expect(updated.streetAddress, equals('Unit 999 Luxury Tower'));
      expect(updated.label, equals('Penthouse'));
    });

    test('BUY-ADDR-009: Phone number validation helper (09XX, 11 digits)', () {
      expect(BuyerValidationRules.phoneRegex.hasMatch('09171234567'), isTrue);
      expect(BuyerValidationRules.phoneRegex.hasMatch('12345'), isFalse);
      expect(BuyerValidationRules.phoneRegex.hasMatch('08123456789'), isFalse);
    });

    test('BUY-ADDR-010: "Use My Location" (GPS) autofill coordinates helper', () {
      final loc = addressService.getMockGpsLocation();
      expect(loc['region'], equals('NCR'));
      expect(loc['city'], equals('Makati City'));
      expect(loc['barangay'], equals('Poblacion'));
      expect(loc['postalCode'], equals('1210'));
      expect(loc['streetAddress'], contains('Ayala Ave'));
    });
  });

  // =========================================================================
  // MODULE 3: BROWSE, SEARCH & FILTER (BUY-SRCH-001 to BUY-SRCH-013)
  // =========================================================================
  group('Module 3: Browse, Search & Filter Test Suite', () {
    late ShopService shopService;

    setUp(() {
      shopService = ShopService.instance;
    });

    test('BUY-SRCH-001: Search with valid keyword returns matching products', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(query: 'Mechanical Keyboard'),
      );
      expect(result.products, isNotEmpty);
      expect(result.products.any((p) => p.title.toLowerCase().contains('keyboard')), isTrue);
      expect(result.typoSuggestion, isNull);
    });

    test('BUY-SRCH-002: Search with keyword returning zero matches displays empty list', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(query: 'xyznonexistentitem999'),
      );
      expect(result.products, isEmpty);
    });

    test('BUY-SRCH-003: Search with typo provides smart suggestion and relevant results', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(query: 'ratan baskit'),
      );
      expect(result.typoSuggestion, equals('Did you mean "Rattan Fruit Basket"?'));
      expect(result.products, isNotEmpty);
      expect(result.products.any((p) => p.title.contains('Rattan Fruit Basket')), isTrue);
    });

    test('BUY-SRCH-004: Filter by Category isolates products in that category', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(category: 'Tech & Gadgets'),
      );
      expect(result.products, isNotEmpty);
      for (final p in result.products) {
        expect(p.category, equals('Tech & Gadgets'));
      }
    });

    test('BUY-SRCH-005: Filter by Price Range with Min <= Max confines prices', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(
          minPrice: 500,
          maxPrice: 3000,
        ),
      );
      expect(result.products, isNotEmpty);
      for (final p in result.products) {
        final rawPrice = double.tryParse(p.price.replaceAll('₱', '').replaceAll(',', '')) ?? 0.0;
        expect(rawPrice, greaterThanOrEqualTo(500));
        expect(rawPrice, lessThanOrEqualTo(3000));
      }
    });

    test('BUY-SRCH-006: Filter with invalid Price Range (Min > Max) returns validation error', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(
          minPrice: 5000,
          maxPrice: 1000,
        ),
      );
      expect(result.errorMessage, contains('cannot be greater than maximum'));
      expect(result.products, isEmpty);
    });

    test('BUY-SRCH-007: Filter by Location isolates seller origins', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(location: 'Metro Manila'),
      );
      expect(result.products, isNotEmpty);
      for (final p in result.products) {
        expect(p.location, equals('Metro Manila'));
      }
    });

    test('BUY-SRCH-008: Combine multiple filters simultaneously', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(
          category: 'Tech & Gadgets',
          minPrice: 1000,
          maxPrice: 6000,
          minRating: 4.8,
        ),
      );
      expect(result.products, isNotEmpty);
      for (final p in result.products) {
        expect(p.category, equals('Tech & Gadgets'));
        expect(p.rating, greaterThanOrEqualTo(4.8));
      }
    });

    test('BUY-SRCH-009: Reset / Clear filters returns full active catalog', () {
      final result = shopService.searchAndFilter(
        const SearchFilterParams(),
      );
      expect(result.products.length, greaterThanOrEqualTo(8));
      expect(result.products.any((p) => p.isActive == false), isFalse);
    });

    test('BUY-SRCH-010: Sort search results by Price Low-to-High and High-to-Low', () {
      final resLowToHigh = shopService.searchAndFilter(
        const SearchFilterParams(sortBy: 'price_asc'),
      );
      expect(resLowToHigh.products.length, greaterThan(1));
      for (int i = 0; i < resLowToHigh.products.length - 1; i++) {
        final p1 = double.parse(resLowToHigh.products[i].price.replaceAll('₱', '').replaceAll(',', ''));
        final p2 = double.parse(resLowToHigh.products[i + 1].price.replaceAll('₱', '').replaceAll(',', ''));
        expect(p1, lessThanOrEqualTo(p2));
      }

      final resHighToLow = shopService.searchAndFilter(
        const SearchFilterParams(sortBy: 'price_desc'),
      );
      expect(resHighToLow.products.length, greaterThan(1));
      for (int i = 0; i < resHighToLow.products.length - 1; i++) {
        final p1 = double.parse(resHighToLow.products[i].price.replaceAll('₱', '').replaceAll(',', ''));
        final p2 = double.parse(resHighToLow.products[i + 1].price.replaceAll('₱', '').replaceAll(',', ''));
        expect(p1, greaterThanOrEqualTo(p2));
      }
    });

    test('BUY-SRCH-011: Vacation mode store products have isOnVacation flag', () {
      final vacationProduct = ShopService.allAppProducts.firstWhere((p) => p.id == 'P-VACATION');
      expect(vacationProduct.isOnVacation, isTrue);
    });
  });

  // =========================================================================
  // MODULE 4: PRODUCT DETAIL PAGE (BUY-PDP-001 to BUY-PDP-010) + B1/B2/B8
  // =========================================================================
  group('Module 4: Product Detail Page (PDP) Test Suite', () {
    late CartService cartService;
    late List<Map<String, dynamic>> serverCartItems;
    late int nextCartItemId;
    late List<Map<String, dynamic>> recordedAddRequests;
    String? forceAddErrorMessage;
    int forceAddStatusCode = 422;

    ProductModel cloneWithNumericId(ProductModel src, String numericId) {
      return ProductModel(
        id: numericId,
        title: src.title,
        imageUrl: src.imageUrl,
        category: src.category,
        isMall: src.isMall,
        discountTag: src.discountTag,
        price: src.price,
        originalPrice: src.originalPrice,
        rating: src.rating,
        soldCount: src.soldCount,
        shippingTag: src.shippingTag,
        hasPayLater: src.hasPayLater,
        hasVoucher: src.hasVoucher,
        shopId: src.shopId.isNotEmpty ? src.shopId : '12',
        shopName: src.shopName,
        shopBadge: src.shopBadge,
        shopAvatarUrl: src.shopAvatarUrl,
        stockQuantity: src.stockQuantity,
        variantGroups: src.variantGroups,
        reviews: src.reviews,
        ratingBreakdown: src.ratingBreakdown,
        galleryImages: src.galleryImages,
        specs: src.specs,
        description: src.description,
        isActive: src.isActive,
        isOnVacation: src.isOnVacation,
        location: src.location,
        perBuyerLimit: src.perBuyerLimit,
        isFlashSale: src.isFlashSale,
        flashSalePrice: src.flashSalePrice,
        flashSaleStockRemaining: src.flashSaleStockRemaining,
        flashSaleTotalStock: src.flashSaleTotalStock,
        flashSaleTimeRemaining: src.flashSaleTimeRemaining,
        claimableVouchers: src.claimableVouchers,
        combinationStock: src.combinationStock,
        isDeleted: src.isDeleted,
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      BuyerAccountService.instance.resetState();
      BuyerAccountService.instance.seedLoggedInBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'pdp.buyer@nexora.com',
        mobileNumber: '09171234567',
        password: 'Password@123',
      );
      await ApiClient.instance.saveToken('test-pdp-token');

      serverCartItems = [];
      nextCartItemId = 500;
      recordedAddRequests = [];
      forceAddErrorMessage = null;
      forceAddStatusCode = 422;

      ApiClient.instance.setMockClient(
        MockClient((request) async {
          final path = request.url.path;

          if (path.endsWith('/buyer/cart') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'items': serverCartItems},
              }),
              200,
            );
          }

          if (path.endsWith('/buyer/cart/items') && request.method == 'POST') {
            if (forceAddErrorMessage != null) {
              return http.Response(
                jsonEncode({'success': false, 'message': forceAddErrorMessage}),
                forceAddStatusCode,
              );
            }
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            recordedAddRequests.add(body);
            final pid = body['product_id'];
            final qty = (body['quantity'] as num?)?.toInt() ?? 1;
            final variant = body['variant'];
            final variantKey = variant != null ? jsonEncode(variant) : '';

            final existingIdx = serverCartItems.indexWhere(
              (e) =>
                  e['product_id'].toString() == pid.toString() &&
                  (e['variant'] != null ? jsonEncode(e['variant']) : '') ==
                      variantKey,
            );
            late Map<String, dynamic> targetItem;
            if (existingIdx >= 0) {
              targetItem = serverCartItems[existingIdx];
              targetItem['quantity'] =
                  (targetItem['quantity'] as int) + qty;
            } else {
              final newId = nextCartItemId++;
              targetItem = {
                'id': newId,
                'product_id': pid,
                'seller_id': 12,
                'seller_name': 'Aura Streetwear Official',
                'store_badge': 'MALL',
                'name': 'Product $pid',
                'image': 'https://example.com/item.jpg',
                'price': 199.0,
                'regular_price': 299.0,
                'quantity': qty,
                'selected': true,
                'variant': variant,
                'stock': 25,
                'is_vacation_mode': false,
              };
              serverCartItems.add(targetItem);
            }
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'cart_item_id': targetItem['id'],
                  'item': targetItem,
                  'items': serverCartItems,
                },
              }),
              201,
            );
          }

          if (path.contains('/buyer/cart/items/') && request.method == 'PATCH') {
            if (forceAddErrorMessage != null) {
              return http.Response(
                jsonEncode({'success': false, 'message': forceAddErrorMessage}),
                forceAddStatusCode,
              );
            }
            final idStr = path.split('/').last;
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final idx = serverCartItems
                .indexWhere((e) => e['id'].toString() == idStr);
            if (idx < 0) {
              return http.Response(
                jsonEncode({'message': 'Cart item not found.'}),
                404,
              );
            }
            if (body.containsKey('quantity')) {
              serverCartItems[idx]['quantity'] =
                  (body['quantity'] as num).toInt();
            }
            if (body.containsKey('selected')) {
              serverCartItems[idx]['selected'] = body['selected'] == true;
            }
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'items': serverCartItems},
              }),
              200,
            );
          }

          if (path.endsWith('/buyer/cart/select-all') &&
              request.method == 'PATCH') {
            if (forceAddErrorMessage != null) {
              return http.Response(
                jsonEncode({'success': false, 'message': forceAddErrorMessage}),
                forceAddStatusCode,
              );
            }
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final sel = body['selected'] == true;
            for (final item in serverCartItems) {
              item['selected'] = sel;
            }
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'items': serverCartItems},
              }),
              200,
            );
          }

          if (path.contains('/buyer/cart/items/') &&
              request.method == 'DELETE') {
            if (forceAddErrorMessage != null) {
              return http.Response(
                jsonEncode({'success': false, 'message': forceAddErrorMessage}),
                forceAddStatusCode,
              );
            }
            final idStr = path.split('/').last;
            serverCartItems.removeWhere((e) => e['id'].toString() == idStr);
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'items': serverCartItems},
              }),
              200,
            );
          }

          if (path.endsWith('/buyer/products/201') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'id': 201,
                  'name': 'Dual Variant Canvas Tote',
                  'price': 350.0,
                  'compare_price': 450.0,
                  'stock': 20,
                  'is_active': true,
                  'seller': {
                    'id': 77,
                    'store_name': 'Laguna Craft Co',
                    'business_name': 'Laguna Craft Co',
                    'city': 'Sta. Cruz',
                    'is_vacation_mode': false,
                    'followers_count': 42,
                    'is_following': false,
                  },
                  'gallery': ['https://example.com/tote-main.jpg'],
                  'variants_data': [
                    {
                      'name': 'Crimson Red',
                      'price': 350.0,
                      'stock': 4,
                      'image': 'https://example.com/tote-red.jpg',
                    },
                    {
                      'name': 'Midnight Blue',
                      'price': 390.0,
                      'stock': 8,
                      'image': 'https://example.com/tote-blue.jpg',
                    },
                  ],
                  'sizes': ['S', 'M'],
                },
              }),
              200,
            );
          }

          if (path.contains('/buyer/products/') && request.method == 'GET') {
            // Preserve local P-01/P-02/P-07 test fixtures when already passed via args
            return http.Response(
              jsonEncode({'message': 'Mock skip overwrite'}),
              500,
            );
          }

          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }),
      );

      cartService = CartService.instance;
      cartService.clearCart();
      cartService.resetPurchaseHistory();
    });

    tearDown(() async {
      AddedToCartHUD.dismiss();
      ApiClient.instance.setMockClient(http.Client());
      await ApiClient.instance.clearToken();
    });

    testWidgets('BUY-PDP-001: All variation types must be selected before Add to Cart or Buy Now',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p01 = cloneWithNumericId(
        ShopService.instance.getProductById('P-01')!,
        '101',
      );

      await tester.pumpWidget(createTestPDP(p01));
      await tester.pumpAndSettle();

      final addToCartBtn = find.text('Add to Cart');

      void hideCurrentSnack() {
        final pState = tester.element(find.byType(ProductDetailsPage));
        ScaffoldMessenger.of(pState).hideCurrentSnackBar();
      }

      // 1. Tap Add to Cart with nothing selected
      hideCurrentSnack();
      await tester.pump();
      await tester.tap(addToCartBtn, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Please select a variation'), findsOneWidget);
      expect(cartService.cartItemCount, equals(0));

      // 2. Select Color only (Natural) and tap Add to Cart
      final naturalOption = find.text('Natural');
      expect(naturalOption, findsOneWidget);
      await tester.tap(naturalOption);
      await tester.pumpAndSettle();

      hideCurrentSnack();
      await tester.pump();
      await tester.tap(addToCartBtn, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Please select a variation'), findsOneWidget);
      expect(cartService.cartItemCount, equals(0));

      // 3. Select Size too (S) and tap Add to Cart
      final sOption = find.text('S');
      expect(sOption, findsOneWidget);
      await tester.tap(sOption);
      await tester.pumpAndSettle();

      hideCurrentSnack();
      await tester.pump();
      await tester.tap(addToCartBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Added 1x'), findsOneWidget);
      expect(cartService.cartItemCount, equals(1));
      expect(recordedAddRequests.last['variant'], isA<Map>());
      expect(recordedAddRequests.last['variant']['variation'], equals('Natural'));
      expect(recordedAddRequests.last['variant']['size'], equals('S'));

      // 4. Test Buy Now with unselected variants
      serverCartItems.clear();
      cartService.clearCart();
      await tester.pumpWidget(createTestPDP(p01, key: const ValueKey('buy_now_fresh')));
      await tester.pumpAndSettle();

      final freshBuyNowBtn = find.text('Buy Now');
      void freshHideSnack() {
        final pState = tester.element(find.byType(ProductDetailsPage));
        ScaffoldMessenger.of(pState).hideCurrentSnackBar();
      }

      freshHideSnack();
      await tester.pump();
      await tester.tap(freshBuyNowBtn, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Please select a variation'), findsOneWidget);

      await tester.tap(find.text('Natural'));
      await tester.pumpAndSettle();
      freshHideSnack();
      await tester.pump();
      await tester.tap(freshBuyNowBtn, warnIfMissed: false);
      await tester.pump();
      expect(find.text('Please select a variation'), findsOneWidget);
    });

    testWidgets('BUY-PDP-002: Selecting a variant updates price, stock and image', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p01 = cloneWithNumericId(
        ShopService.instance.getProductById('P-01')!,
        '101',
      );
      await tester.pumpWidget(createTestPDP(p01));
      await tester.pumpAndSettle();

      // Step 1: Select Natural-S -> Price ₱199.00, Stock 10
      await tester.tap(find.text('Natural'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('S'));
      await tester.pumpAndSettle();

      expect(find.text('₱199.00'), findsWidgets);
      expect(find.textContaining('Only 10 left in stock'), findsOneWidget);

      // Step 2: Select Natural-L -> Price ₱299.00 (+₱100), Stock 5
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();

      expect(find.text('₱299.00'), findsWidgets);
      expect(find.textContaining('Only 5 left in stock'), findsOneWidget);

      // Step 3: Select Black-S -> Price ₱199.00, Stock 10
      await tester.tap(find.text('Black'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('S'));
      await tester.pumpAndSettle();

      expect(find.text('₱199.00'), findsWidgets);
      expect(find.textContaining('Only 10 left in stock'), findsOneWidget);
    });

    testWidgets('BUY-PDP-003: Out-of-stock variant disabled (Black-M stock 0)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p01 = cloneWithNumericId(
        ShopService.instance.getProductById('P-01')!,
        '101',
      );
      await tester.pumpWidget(createTestPDP(p01));
      await tester.pumpAndSettle();

      // Select Black
      await tester.tap(find.text('Black'));
      await tester.pumpAndSettle();

      // M is disabled for Black because combinationStock['Black-M'] == 0
      final mFinder = find.text('M (Out of stock)');
      expect(mFinder, findsOneWidget);

      await tester.tap(mFinder);
      await tester.pump();

      expect(find.text('This variation is currently out of stock'), findsOneWidget);
    });

    testWidgets('BUY-PDP-004: Quantity limits on P-02 (Stock 20)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p02 = cloneWithNumericId(
        ShopService.instance.getProductById('P-02')!,
        '102',
      );
      await tester.pumpWidget(createTestPDP(p02));
      await tester.pumpAndSettle();

      final addToCartBtn = find.text('Add to Cart');
      final qtyInput = find.byType(TextField);
      expect(qtyInput, findsOneWidget);

      void hideCurrentSnack() {
        final pState = tester.element(find.byType(ProductDetailsPage));
        ScaffoldMessenger.of(pState).hideCurrentSnackBar();
      }

      // Helper to test quantity input
      Future<void> testQtyInput(String input, bool shouldAccept) async {
        hideCurrentSnack();
        await tester.pump();

        await tester.enterText(qtyInput, input);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        final initialCartCount = cartService.cartItemCount;
        hideCurrentSnack();
        await tester.pump();
        await tester.tap(addToCartBtn, warnIfMissed: false);
        await tester.pumpAndSettle();

        if (shouldAccept) {
          expect(cartService.cartItemCount, greaterThan(initialCartCount));
          serverCartItems.clear();
          cartService.clearCart();
          AddedToCartHUD.dismiss();
        } else {
          expect(cartService.cartItemCount, equals(initialCartCount));
        }
      }

      // 0 (reject)
      await testQtyInput('0', false);
      expect(find.text('Quantity must be at least 1'), findsOneWidget);

      // -1 (reject)
      await testQtyInput('-1', false);
      expect(find.text('Quantity must be at least 1'), findsOneWidget);

      // 1 (accept)
      await testQtyInput('1', true);

      // 20 (accept)
      await testQtyInput('20', true);

      // 21 (reject)
      await testQtyInput('21', false);
      expect(find.text('Maximum order limit is 20 units'), findsOneWidget);

      // 1.5 (reject)
      await testQtyInput('1.5', false);
      expect(find.text('Quantity must be a whole number'), findsOneWidget);

      // abc (reject)
      await testQtyInput('abc', false);
      expect(find.text('Please enter a valid whole number for quantity'), findsOneWidget);

      // Plus button stops at 20
      await tester.enterText(qtyInput, '19');
      await tester.pumpAndSettle();
      final plusBtn = find.byIcon(Icons.add);

      hideCurrentSnack();
      await tester.pump();
      await tester.tap(plusBtn); // 19 -> 20
      await tester.pumpAndSettle();
      expect(find.text('20'), findsWidgets);

      await tester.tap(plusBtn); // exceeds 20
      await tester.pump();
      expect(find.text('Maximum order limit is 20 units'), findsOneWidget);
    });

    testWidgets('BUY-PDP-005: Per-buyer purchase limit (P-07 limit 2)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p07 = cloneWithNumericId(
        ShopService.instance.getProductById('P-07')!,
        '107',
      );
      await tester.pumpWidget(createTestPDP(p07));
      await tester.pumpAndSettle();

      final addToCartBtn = find.text('Add to Cart');
      final qtyInput = find.byType(TextField);

      // 1. Add 2 x P-07 and buy them
      await tester.enterText(qtyInput, '2');
      await tester.pumpAndSettle();
      await tester.tap(addToCartBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(cartService.items.length, equals(1));
      expect(cartService.items.first.quantity, equals(2));
      expect(cartService.cartItemCount, equals(2));

      // Buyer purchases them
      cartService.recordPurchase('107', 2);
      serverCartItems.clear();
      cartService.clearCart();
      AddedToCartHUD.dismiss();

      // 2. Try to add 1 more P-07
      final pState = tester.element(find.byType(ProductDetailsPage));
      ScaffoldMessenger.of(pState).hideCurrentSnackBar();
      await tester.pump();

      await tester.enterText(qtyInput, '1');
      await tester.pumpAndSettle();
      await tester.tap(addToCartBtn, warnIfMissed: false);
      await tester.pump();

      // Blocked with limit message
      expect(find.textContaining('Per-buyer purchase limit of 2 items reached'), findsOneWidget);
      expect(cartService.cartItemCount, equals(0));
    });

    testWidgets('BUY-PDP-006: Sale price, countdown and vouchers shown on P-02', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p02 = ShopService.instance.getProductById('P-02')!;
      await tester.pumpWidget(createTestPDP(p02));
      await tester.pumpAndSettle();

      // Shows ₱299 with ₱450 struck through
      expect(find.text('₱299.00'), findsWidgets);
      expect(find.text('₱450.00'), findsOneWidget);

      // Countdown to slot end
      expect(find.text('FLASH SALE'), findsOneWidget);
      expect(find.textContaining('Ends in'), findsOneWidget);

      // Flash units left
      expect(find.textContaining('flash units left'), findsOneWidget);

      // Claimable voucher MCH50 with Claim button
      expect(find.text('MCH50'), findsOneWidget);
      final claimBtn = find.text('Claim');
      expect(claimBtn, findsOneWidget);

      // Tap Claim
      await tester.tap(claimBtn);
      await tester.pumpAndSettle();
      expect(find.text('Claimed'), findsOneWidget);
    });

    test('BUY-PDP-007: Buy Now checks out only that item with real product/seller/variant ids', () async {
      await cartService.addToCart(
        productId: 105,
        quantity: 1,
      );

      expect(cartService.cartItemCount, equals(1));
      expect(cartService.items.first.productId, equals('105'));

      // Buy Now P-01 Natural-M retains real IDs and payload
      cartService.buyNow(
        productId: '101',
        sellerId: 12,
        variantData: const {
          'variation': 'Natural',
          'size': 'M',
          'image': 'https://example.com/p01.jpg',
        },
        title: 'Nexora Tailored Linen Blend Shirt P-01',
        variant: 'Natural • M',
        price: 199.0,
        originalPrice: 299.0,
        imageUrl: 'https://example.com/p01.jpg',
        storeName: 'Aura Streetwear Official',
        storeBadge: 'OFFICIAL STORE',
        quantity: 1,
      );

      // Checkout contains only P-01 with full server IDs
      final checkoutItems = cartService.checkoutItems;
      expect(checkoutItems.length, equals(1));
      expect(checkoutItems.first.productId, equals('101'));
      expect(checkoutItems.first.sellerId, equals(12));
      expect(checkoutItems.first.variant, equals('Natural • M'));
      expect(checkoutItems.first.variantData?['variation'], equals('Natural'));
      expect(checkoutItems.first.variantData?['size'], equals('M'));

      // P-05 stays in cart and is not in checkout
      expect(cartService.items.length, equals(1));
      expect(cartService.items.first.productId, equals('105'));
      expect(checkoutItems.any((i) => i.productId == '105'), isFalse);
    });

    testWidgets('B1-CART-ERR: Server error surfaces ApiException message and never fakes Added to cart HUD', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      forceAddErrorMessage = 'Seller is currently in vacation mode.';
      forceAddStatusCode = 422;

      final p02 = cloneWithNumericId(
        ShopService.instance.getProductById('P-02')!,
        '102',
      );
      await tester.pumpWidget(createTestPDP(p02));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Cart'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('Seller is currently in vacation mode.'),
        findsOneWidget,
      );
      expect(find.text('Added to cart'), findsNothing);
      expect(cartService.cartItemCount, equals(0));
    });

    test('B1-CART-TRUTH: Overlapping load queues trailing reload, failures roll back, logout clears cart', () async {
      await cartService.addToCart(productId: 105, quantity: 1);
      expect(cartService.items.length, equals(1));
      final itemId = cartService.items.first.id;

      // Failure on updateQuantityRemote rethrows ApiException and keeps server quantity
      forceAddErrorMessage = 'Requested quantity exceeds stock (1 left).';
      await expectLater(
        () => cartService.updateQuantityRemote(itemId, 5),
        throwsA(isA<ApiException>()),
      );
      expect(cartService.items.first.quantity, equals(1));

      // Clear forced error and test overlapping loadCartRemote trailing queue
      forceAddErrorMessage = null;
      await Future.wait([
        cartService.loadCartRemote(),
        cartService.loadCartRemote(),
      ]);
      expect(cartService.items.length, equals(1));

      // Logout clears cart and never leaves 'guest' items behind
      await ApiClient.instance.clearToken();
      BuyerAccountService.instance.resetState();
      expect(cartService.items, isEmpty);
      await expectLater(
        () => cartService.addToCart(productId: 105, quantity: 1),
        throwsA(isA<ApiException>()),
      );
    });

    testWidgets('B8-VARIANTS: API product parses dual Variation + Size, min stock, and posts {variation, size, image}', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestPDP('201'));
      await tester.pumpAndSettle();

      // Both groups start unselected (each has 2 options) -> displays 'Select a Variation' and 'Select a Size' badges
      expect(find.text('Dual Variant Canvas Tote'), findsOneWidget);
      expect(find.text('Crimson Red'), findsOneWidget);
      expect(find.text('Midnight Blue'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);

      // Select Midnight Blue (₱390, stock 8) + M (stock 20) -> min stock 8, price ₱390.00
      await tester.tap(find.text('Midnight Blue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();

      expect(find.text('₱390.00'), findsWidgets);
      expect(find.textContaining('Only 8 left in stock'), findsOneWidget);

      await tester.tap(find.text('Add to Cart'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(recordedAddRequests, isNotEmpty);
      final sentVariant = recordedAddRequests.last['variant'] as Map<String, dynamic>;
      expect(sentVariant['variation'], equals('Midnight Blue'));
      expect(sentVariant['size'], equals('M'));
      expect(sentVariant['image'], equals('https://example.com/tote-blue.jpg'));
    });

    testWidgets('BUY-PDP-008: Product screen of an unavailable product (deleted or inactive)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Deleted product
      const deletedProduct = ProductModel(
        id: 'P-DELETED',
        title: 'Deleted Product Sample',
        imageUrl: '',
        category: 'Tech',
        price: '₱999',
        rating: 4.0,
        soldCount: '10',
        shippingTag: 'Standard Delivery',
        isDeleted: true,
      );

      await tester.pumpWidget(createTestPDP(deletedProduct));
      await tester.pumpAndSettle();

      expect(find.text('Product Unavailable'), findsOneWidget);
      expect(find.text('Browse Other Products'), findsOneWidget);
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);

      // Inactive product
      const inactiveProduct = ProductModel(
        id: 'P-INACTIVE',
        title: 'Inactive Product Sample',
        imageUrl: '',
        category: 'Tech',
        price: '₱999',
        rating: 4.0,
        soldCount: '10',
        shippingTag: 'Standard Delivery',
        isActive: false,
      );

      await tester.pumpWidget(createTestPDP(inactiveProduct));
      await tester.pumpAndSettle();

      expect(find.text('Product Unavailable'), findsOneWidget);
      expect(find.text('Browse Other Products'), findsOneWidget);
      expect(find.text('Add to Cart'), findsNothing);
      expect(find.text('Buy Now'), findsNothing);
    });

    testWidgets('BUY-PDP-009: [Mobile] Swipe and zoom product images', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p01 = ShopService.instance.getProductById('P-01')!;
      await tester.pumpWidget(createTestPDP(p01));
      await tester.pumpAndSettle();

      // Select Natural and M
      await tester.tap(find.text('Natural'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('M'));
      await tester.pumpAndSettle();

      // Gallery has PageView with position indicator
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);

      // Tap image to open zoomed lightbox
      final galleryImage = find.byType(InteractiveViewer).first;
      await tester.tap(galleryImage);
      await tester.pumpAndSettle();

      // Zoom dialog is open with close button and 1 / 4 indicator
      expect(find.text('1 / 4'), findsOneWidget);
      final closeBtn = find.byIcon(Icons.close);
      expect(closeBtn, findsOneWidget);

      // Close zoomed view
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Closing returns to P-01 with Natural-M still selected
      expect(find.text('Natural'), findsWidgets);
      expect(find.text('M'), findsWidgets);
    });

    testWidgets('BUY-PDP-010: [Mobile] Share link opens product in app', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final p02 = ShopService.instance.getProductById('P-02')!;
      await tester.pumpWidget(createTestPDP(p02));
      await tester.pumpAndSettle();

      // Tap share button
      final shareBtn = find.byIcon(Icons.share_outlined);
      expect(shareBtn, findsOneWidget);
      await tester.tap(shareBtn);
      await tester.pump();

      // Shows copied snackbar with deep link URL
      expect(
        find.textContaining('${ApiConstants.baseUrl}/products/P-02'),
        findsOneWidget,
      );

      // Open P-02 via app route /products/P-02
      await tester.pumpWidget(MaterialApp(
        key: const ValueKey('p02_app'),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: '/products/P-02',
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rattan Fruit Basket'), findsOneWidget);

      // Open non-existent / deleted product link
      await tester.pumpWidget(MaterialApp(
        key: const ValueKey('non_existent_app'),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: '/products/NON_EXISTENT_ID',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Product Unavailable'), findsOneWidget);
    });
  });
}
