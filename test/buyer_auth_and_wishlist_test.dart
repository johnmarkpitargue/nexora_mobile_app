import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';

void main() {
  group('Buyer Auth & Guest Wishlist Verification Suite', () {
    setUp(() {
      BuyerAccountService.instance.resetState();
      WishlistService.instance.clearWishlist();
    });

    test('1. Guest Mode has 0 items on Wishlist by default', () {
      BuyerAccountService.instance.enterGuestMode();
      expect(BuyerAccountService.instance.isGuest, isTrue);

      // Wishlist must start completely empty for guests
      expect(WishlistService.instance.itemCount, equals(0));
      expect(WishlistService.instance.items, isEmpty);
    });

    test('2. Guest can add and remove items, and wishlist clears upon logout/guest reset', () {
      const sampleProduct = ProductModel(
        title: 'Nexora Studio Pro Wireless ANC Headphone System',
        imageUrl: 'https://example.com/headphone.jpg',
        category: 'Tech & Gadgets',
        price: '₱2,450.00',
        originalPrice: '₱3,500',
        rating: 4.9,
        soldCount: '1.8k',
        shippingTag: '2-3 Days',
      );

      // Add to wishlist
      WishlistService.instance.addToWishlist(sampleProduct);
      expect(WishlistService.instance.itemCount, equals(1));
      expect(WishlistService.instance.isInWishlist(sampleProduct.title), isTrue);

      // Toggle off
      WishlistService.instance.toggleWishlist(sampleProduct);
      expect(WishlistService.instance.itemCount, equals(0));

      // Toggle back on
      WishlistService.instance.toggleWishlist(sampleProduct);
      expect(WishlistService.instance.itemCount, equals(1));

      // Logout or entering guest mode resets wishlist
      BuyerAccountService.instance.logout();
      expect(WishlistService.instance.itemCount, equals(0));
    });

    test('3. Buyer Registration -> OTP Verification -> Login lifecycle succeeds', () {
      const email = 'newbuyer.test@example.com';
      const phone = '09179998877';
      const pass = 'Nexora@2026';

      // 1. Register
      final regResult = BuyerAccountService.instance.registerBuyer(
        firstName: 'Elena',
        lastName: 'Reyes',
        email: email,
        mobileNumber: phone,
        dateOfBirth: DateTime(1995, 6, 15),
        password: pass,
        confirmPassword: pass,
        agreeTerms: true,
      );

      expect(regResult.success, isTrue);
      expect(regResult.buyer, isNotNull);
      expect(regResult.buyer!.accountStatus, equals('Unverified'));

      // 2. Attempt login before OTP verification -> blocked
      final blockedLogin = BuyerAccountService.instance.loginBuyer(
        emailOrPhone: email,
        password: pass,
      );
      expect(blockedLogin.success, isFalse);
      expect(blockedLogin.message, contains('unverified'));

      // 3. Verify OTP
      final otp = regResult.otp!;
      final verifyResult = BuyerAccountService.instance.verifyOtp(
        email: email,
        inputOtp: otp,
      );
      expect(verifyResult.success, isTrue);
      expect(verifyResult.buyer!.accountStatus, equals('Active'));

      // 4. Login after verification -> succeeds
      final loginResult = BuyerAccountService.instance.loginBuyer(
        emailOrPhone: email,
        password: pass,
      );
      expect(loginResult.success, isTrue);
      expect(loginResult.buyer!.fullName, equals('Elena Reyes'));
      expect(BuyerAccountService.instance.isLoggedIn, isTrue);
    });

    test('4. Seeded accounts (Alex Rivera & Juan Miguel) login successfully', () {
      // Login with Alex Rivera email
      final alexLogin = BuyerAccountService.instance.loginBuyer(
        emailOrPhone: 'alex.rivera@nexora.io',
        password: 'Passw0rd!',
      );
      expect(alexLogin.success, isTrue);
      expect(alexLogin.buyer!.fullName, equals('Alex Rivera'));

      // Login with mobile number
      final mobileLogin = BuyerAccountService.instance.loginBuyer(
        emailOrPhone: '09175550192',
        password: 'Passw0rd!',
      );
      expect(mobileLogin.success, isTrue);
      expect(mobileLogin.buyer!.fullName, equals('Alex Rivera'));

      // Login with Juan Miguel
      final juanLogin = BuyerAccountService.instance.loginBuyer(
        emailOrPhone: 'juanmiguel.delacruz@example.com',
        password: 'Passw0rd!',
      );
      expect(juanLogin.success, isTrue);
      expect(juanLogin.buyer!.fullName, equals('Juan Miguel Dela Cruz'));
    });
  });
}
