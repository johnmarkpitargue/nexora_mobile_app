import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Buyer Account Persistence & Login Suite', () {
    late BuyerAccountService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = BuyerAccountService.instance;
      await service.resetState(clearPersistence: true);
    });

    test('Registered and verified user persists and can login again after full app restart', () async {
      const email = 'persistent.user@example.com';
      const phone = '09175558899';
      const password = 'MySecurePass123!';

      // 1. User registers an account
      final regResult = service.registerBuyer(
        firstName: 'Sarah',
        lastName: 'Geronimo',
        email: email,
        mobileNumber: phone,
        dateOfBirth: DateTime(1997, 7, 25),
        password: password,
        confirmPassword: password,
        agreeTerms: true,
      );
      expect(regResult.success, isTrue);

      // 2. User verifies OTP
      final verifyResult = service.verifyOtp(
        email: email,
        inputOtp: regResult.otp ?? '123456',
      );
      expect(verifyResult.success, isTrue);
      expect(verifyResult.buyer!.isVerified, isTrue);

      // 3. User logs out
      service.logout();
      expect(service.isLoggedIn, isFalse);

      // Await pending async persistence save
      await service.saveToPersistence();

      // 4. Simulate App Restart / Browser Refresh:
      // In-memory state reset back to initial seed data
      await service.resetState(clearPersistence: false);
      expect(service.allBuyers.any((b) => b.email == email), isFalse);

      // App initializes from persistent storage on startup
      await service.ensureInitialized();

      // Verify account was restored from persistence
      expect(service.allBuyers.any((b) => b.email == email), isTrue);

      // 5. User logs in again using Email
      final loginWithEmail = service.loginBuyer(
        emailOrPhone: email,
        password: password,
      );
      expect(loginWithEmail.success, isTrue);
      expect(loginWithEmail.buyer!.fullName, equals('Sarah Geronimo'));
      expect(service.currentBuyerSession?.email, equals(email));

      // 6. User logs out and logs in using Mobile Number
      service.logout();
      final loginWithPhone = service.loginBuyer(
        emailOrPhone: phone,
        password: password,
      );
      expect(loginWithPhone.success, isTrue);
      expect(loginWithPhone.buyer!.email, equals(email));
    });

    test('Unverified registered account prompts verification on login after restart', () async {
      const email = 'unverified.persist@example.com';
      const phone = '09174443322';
      const password = 'UnverifiedPass1!';

      // 1. User registers but leaves before OTP verification
      final regResult = service.registerBuyer(
        firstName: 'Mark',
        lastName: 'Bautista',
        email: email,
        mobileNumber: phone,
        dateOfBirth: DateTime(1996, 3, 10),
        password: password,
        confirmPassword: password,
        agreeTerms: true,
      );
      expect(regResult.success, isTrue);

      await service.saveToPersistence();

      // 2. Simulate App Restart
      await service.resetState(clearPersistence: false);
      expect(service.allBuyers.any((b) => b.email == email), isFalse);

      await service.ensureInitialized();
      expect(service.allBuyers.any((b) => b.email == email), isTrue);

      // 3. User attempts to login
      final loginResult = service.loginBuyer(
        emailOrPhone: email,
        password: password,
      );
      expect(loginResult.success, isFalse);
      expect(loginResult.message, contains('unverified'));
      expect(loginResult.buyer?.accountStatus, equals('Unverified'));

      // 4. User completes OTP verification
      final verifyResult = service.verifyOtp(
        email: email,
        inputOtp: '123456',
      );
      expect(verifyResult.success, isTrue);
      expect(verifyResult.buyer!.accountStatus, equals('Active'));

      // 5. Now login succeeds
      final finalLogin = service.loginBuyer(
        emailOrPhone: email,
        password: password,
      );
      expect(finalLogin.success, isTrue);
    });
  });
}
