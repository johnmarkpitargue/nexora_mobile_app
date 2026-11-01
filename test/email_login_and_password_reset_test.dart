import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Passwordless Email Login & Password Reset Test Suite', () {
    late BuyerAccountService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = BuyerAccountService.instance;
      await service.resetState(clearPersistence: true);
    });

    test('Passwordless Email OTP Login: Send code and verify successfully logs in', () {
      const email = 'alex.rivera@nexora.io';

      // 1. Send Login OTP
      final sendResult = service.sendLoginOtp(emailOrPhone: email);
      expect(sendResult.success, isTrue);
      expect(sendResult.otp, equals('123456'));
      expect(sendResult.buyer, isNotNull);

      // 2. Incorrect OTP decrements attempts
      final wrongResult = service.verifyLoginOtp(
        emailOrPhone: email,
        inputOtp: '999999',
      );
      expect(wrongResult.success, isFalse);
      expect(wrongResult.message, contains('2 attempts remaining'));

      // 3. Correct OTP logs in successfully
      final verifyResult = service.verifyLoginOtp(
        emailOrPhone: email,
        inputOtp: '123456',
      );
      expect(verifyResult.success, isTrue);
      expect(service.isLoggedIn, isTrue);
      expect(service.currentBuyerSession?.email, equals(email));
    });

    test('Passwordless Login fails for unknown account', () {
      final result = service.sendLoginOtp(emailOrPhone: 'nonexistent.user@example.com');
      expect(result.success, isFalse);
      expect(result.message, contains('No account found'));
    });

    test('Passwordless Login activates Unverified account upon correct OTP', () {
      // Register new unverified buyer
      final reg = service.registerBuyer(
        firstName: 'Carlos',
        lastName: 'Yulo',
        email: 'carlos.yulo@example.com',
        mobileNumber: '09191234567',
        dateOfBirth: DateTime(2000, 2, 16),
        password: 'Passw0rd!123',
        confirmPassword: 'Passw0rd!123',
        agreeTerms: true,
      );
      expect(reg.success, isTrue);
      expect(reg.buyer!.accountStatus, equals('Unverified'));

      // Log out
      service.logout();

      // Request Login OTP
      final sendResult = service.sendLoginOtp(emailOrPhone: 'carlos.yulo@example.com');
      expect(sendResult.success, isTrue);

      // Verify Login OTP
      final verifyResult = service.verifyLoginOtp(
        emailOrPhone: 'carlos.yulo@example.com',
        inputOtp: '123456',
      );
      expect(verifyResult.success, isTrue);
      expect(service.isLoggedIn, isTrue);
      expect(service.currentBuyerSession!.accountStatus, equals('Active'));
    });

    test('Password Reset flow: Request -> Verify -> Set new password -> Login with new password', () {
      const email = 'alex.rivera@nexora.io';
      const newPassword = 'NewSecretPassword2026!';

      // 1. Request Password Reset OTP
      final reqResult = service.requestPasswordReset(emailOrPhone: email);
      expect(reqResult.success, isTrue);
      expect(reqResult.otp, equals('123456'));

      // 2. Verify Password Reset OTP
      final verifyResult = service.verifyPasswordResetOtp(
        emailOrPhone: email,
        inputOtp: '123456',
      );
      expect(verifyResult.success, isTrue);

      // 3. Reset Password with validation checks
      // 3a. Passwords do not match
      final mismatchResult = service.resetPasswordWithOtp(
        emailOrPhone: email,
        otp: '123456',
        newPassword: newPassword,
        confirmPassword: 'DifferentPassword!',
      );
      expect(mismatchResult.success, isFalse);
      expect(mismatchResult.message, contains('Passwords do not match'));

      // 3b. Same as old password
      final sameResult = service.resetPasswordWithOtp(
        emailOrPhone: email,
        otp: '123456',
        newPassword: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
      );
      expect(sameResult.success, isFalse);
      expect(sameResult.message, contains('cannot be the same'));

      // 3c. Valid new password
      final resetResult = service.resetPasswordWithOtp(
        emailOrPhone: email,
        otp: '123456',
        newPassword: newPassword,
        confirmPassword: newPassword,
      );
      expect(resetResult.success, isTrue);

      // 4. Old password no longer works
      final oldLogin = service.loginBuyer(
        emailOrPhone: email,
        password: 'Passw0rd!',
      );
      expect(oldLogin.success, isFalse);

      // 5. New password logs in successfully
      final newLogin = service.loginBuyer(
        emailOrPhone: email,
        password: newPassword,
      );
      expect(newLogin.success, isTrue);
      expect(service.isLoggedIn, isTrue);
    });

    test('Password Reset fails for non-existent account', () {
      final result = service.requestPasswordReset(emailOrPhone: 'unknown@example.com');
      expect(result.success, isFalse);
      expect(result.message, contains('No account found'));
    });
  });
}
