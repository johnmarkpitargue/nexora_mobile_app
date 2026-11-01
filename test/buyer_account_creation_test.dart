import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';

void main() {
  group('Buyer Account Creation Blackbox Test Suite (TC-BUY-001 to TC-BUY-043)', () {
    late BuyerAccountService service;

    setUp(() {
      service = BuyerAccountService.instance;
      service.resetState();
    });

    test('TC-BUY-001: Register with all valid data succeeds and creates unverified account', () {
      final result = service.registerBuyer(
        firstName: 'Juan Miguel',
        lastName: 'Dela Cruz',
        email: 'juanmiguel.brandnew@example.com',
        mobileNumber: '09170001122',
        dateOfBirth: DateTime(1998, 10, 24),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
        referralCode: 'NEXORA150',
      );

      expect(result.success, isTrue);
      expect(result.buyer, isNotNull);
      expect(result.buyer!.accountStatus, equals('Unverified'));
      expect(result.buyer!.voucherCount, equals(1));
      expect(result.otp, isNotNull);
      expect(result.otp!.length, equals(6));
    });

    test('TC-BUY-002: Submit a completely empty form blocks registration with field errors', () {
      final result = service.registerBuyer(
        firstName: '',
        lastName: '',
        email: '',
        mobileNumber: '',
        dateOfBirth: null,
        password: '',
        confirmPassword: '',
        agreeTerms: false,
      );

      expect(result.success, isFalse);
      expect(result.fieldErrors, isNotNull);
      expect(result.fieldErrors!['firstName'], contains('required'));
      expect(result.fieldErrors!['lastName'], contains('required'));
      expect(result.fieldErrors!['email'], contains('required'));
      expect(result.fieldErrors!['mobile'], contains('required'));
      expect(result.fieldErrors!['dob'], contains('required'));
      expect(result.fieldErrors!['password'], contains('required'));
      expect(result.fieldErrors!['confirmPassword'], contains('confirm'));
      expect(result.fieldErrors!['terms'], contains('agree'));
    });

    test('TC-BUY-003: Leave one required field blank at a time preserves other inputs', () {
      // Leave only First Name blank
      final res1 = service.registerBuyer(
        firstName: '',
        lastName: 'Dela Cruz',
        email: 'unique.test1@example.com',
        mobileNumber: '09179990011',
        dateOfBirth: DateTime(1998, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );
      expect(res1.success, isFalse);
      expect(res1.fieldErrors!['firstName'], contains('required'));
      expect(res1.fieldErrors!.containsKey('lastName'), isFalse);
      expect(res1.fieldErrors!.containsKey('email'), isFalse);

      // Leave only Email blank
      final res2 = service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: '',
        mobileNumber: '09179990011',
        dateOfBirth: DateTime(1998, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );
      expect(res2.success, isFalse);
      expect(res2.fieldErrors!['email'], contains('required'));
      expect(res2.fieldErrors!.containsKey('firstName'), isFalse);
    });

    test('TC-BUY-004: Name with numbers or symbols is rejected', () {
      expect(BuyerValidationRules.isValidName('Juan Miguel 123'), isFalse);
      expect(BuyerValidationRules.isValidName('Dela Cruz#\$'), isFalse);
      expect(BuyerValidationRules.isValidName('@lex'), isFalse);
    });

    test('TC-BUY-005: Name with accented letters, ñ, hyphens, and periods is accepted', () {
      expect(BuyerValidationRules.isValidName('Niña Maria'), isTrue);
      expect(BuyerValidationRules.isValidName('Peña-Reyes'), isTrue);
      expect(BuyerValidationRules.isValidName("O'Connor"), isTrue);
      expect(BuyerValidationRules.isValidName('St. John'), isTrue);
      expect(BuyerValidationRules.isValidName('José-Maria'), isTrue);
    });

    test('TC-BUY-006: Name length at the limits (1, 2, 50, 51 chars)', () {
      const name1 = 'J';
      const name2 = 'Jo';
      const name50 = 'Maria Cristina Angelina Santa Maria Santos Dela Cr'; // exactly 50 chars
      const name51 = 'Maria Cristina Angelina Santa Maria Santos Dela Cru'; // exactly 51 chars

      expect(name1.length, equals(1));
      expect(name2.length, equals(2));
      expect(name50.length, equals(50));
      expect(name51.length, equals(51));

      expect(name1.length >= BuyerValidationRules.minNameLength, isFalse);
      expect(name2.length >= BuyerValidationRules.minNameLength, isTrue);
      expect(name50.length <= BuyerValidationRules.maxNameLength, isTrue);
      expect(name51.length <= BuyerValidationRules.maxNameLength, isFalse);
    });

    test('TC-BUY-007: Age at the 18-year boundary', () {
      final today = DateTime.now();
      // 17 years old (born exactly 17 years ago) -> rejected
      final age17 = DateTime(today.year - 17, today.month, today.day);
      expect(BuyerValidationRules.isAtLeast18YearsOld(age17), isFalse);

      // 18 years old today -> accepted
      final age18 = DateTime(today.year - 18, today.month, today.day);
      expect(BuyerValidationRules.isAtLeast18YearsOld(age18), isTrue);

      // 18 years and 1 day old -> accepted
      final age18Plus = DateTime(today.year - 18, today.month, today.day).subtract(const Duration(days: 1));
      expect(BuyerValidationRules.isAtLeast18YearsOld(age18Plus), isTrue);
    });

    test('TC-BUY-008: Date of birth in the future is rejected', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(BuyerValidationRules.isAtLeast18YearsOld(tomorrow), isFalse);
    });

    test('TC-BUY-009: Invalid email formats are rejected', () {
      expect(BuyerValidationRules.emailRegex.hasMatch('user-agent-domain.com'), isFalse);
      expect(BuyerValidationRules.emailRegex.hasMatch('user@.com'), isFalse);
      expect(BuyerValidationRules.emailRegex.hasMatch('user@domain'), isFalse);
      expect(BuyerValidationRules.emailRegex.hasMatch('@domain.com'), isFalse);
    });

    test('TC-BUY-010 & 011: Registered duplicate email is rejected (case-insensitive)', () {
      final res1 = service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'juan.miguel.delacruz@gmail.com', // Seeded duplicate
        mobileNumber: '09179998811',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );
      expect(res1.success, isFalse);
      expect(res1.fieldErrors!['email'], contains('already exists'));

      // Test capital letters (TC-BUY-011)
      final res2 = service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'JUAN.MIGUEL.DELACRUZ@GMAIL.COM',
        mobileNumber: '09179998811',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );
      expect(res2.success, isFalse);
      expect(res2.fieldErrors!['email'], contains('already exists'));
    });

    test('TC-BUY-012: Email with leading and trailing spaces is trimmed', () {
      final result = service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: '  juan.trimmed@example.com  ',
        mobileNumber: '09179997766',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );
      expect(result.success, isTrue);
      expect(result.buyer!.email, equals('juan.trimmed@example.com'));
    });

    test('TC-BUY-013 & 014: Mobile number format and boundary length validation', () {
      // 10 digits
      expect(BuyerValidationRules.normalizePhone('0917123456').length, equals(10));
      // 12 digits
      expect(BuyerValidationRules.normalizePhone('091712345678').length, equals(12));
      // 11 digits
      expect(BuyerValidationRules.normalizePhone('09171234567').length, equals(11));
      expect(BuyerValidationRules.phoneRegex.hasMatch('09171234567'), isTrue);
    });

    test('TC-BUY-015 & 016: Registered mobile number is rejected and +63 is normalized', () {
      expect(BuyerValidationRules.normalizePhone('+639171234567'), equals('09171234567'));

      final result = service.registerBuyer(
        firstName: 'Maria',
        lastName: 'Santos',
        email: 'maria.new@example.com',
        mobileNumber: '+63 917 123 4567', // Matches seeded 09171234567
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );
      expect(result.success, isFalse);
      expect(result.fieldErrors!['mobile'], contains('already registered'));
    });

    test('TC-BUY-017 & 018: Password complexity rules and boundary lengths', () {
      expect(BuyerValidationRules.isValidPassword('Pass1@'), isFalse); // Length 6 (< 8)
      expect(BuyerValidationRules.isValidPassword('passw0rd!'), isFalse); // No uppercase
      expect(BuyerValidationRules.isValidPassword('PASSW0RD!'), isFalse); // No lowercase
      expect(BuyerValidationRules.isValidPassword('Password!'), isFalse); // No number
      expect(BuyerValidationRules.isValidPassword('Passw0rd1'), isFalse); // No special char
      expect(BuyerValidationRules.isValidPassword('Passw0rd!'), isTrue); // All satisfied
    });

    test('TC-BUY-019: Confirm password mismatch is rejected', () {
      final result = service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'mismatch@example.com',
        mobileNumber: '09179995544',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Password1@',
        confirmPassword: 'Password2@',
        agreeTerms: true,
      );
      expect(result.success, isFalse);
      expect(result.fieldErrors!['confirmPassword'], contains('do not match'));
    });

    test('TC-BUY-021: Register without Terms and Privacy Policy acceptance is rejected', () {
      final result = service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'noterms@example.com',
        mobileNumber: '09179994433',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: false,
      );
      expect(result.success, isFalse);
      expect(result.fieldErrors!['terms'], contains('agree'));
    });

    test('TC-BUY-022: Valid and invalid referral codes', () {
      expect(BuyerValidationRules.isValidReferralCode('NEXORA150'), isTrue);
      expect(BuyerValidationRules.isValidReferralCode('WELCOME100'), isTrue);
      expect(BuyerValidationRules.isValidReferralCode('INVALID999'), isFalse);
      expect(BuyerValidationRules.isValidReferralCode(''), isTrue); // Optional
    });

    test('TC-BUY-023: Verify with correct OTP activates account and claims ₱150 voucher', () {
      service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'otp.verify@example.com',
        mobileNumber: '09179993322',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );

      final verifyResult = service.verifyOtp(
        email: 'otp.verify@example.com',
        inputOtp: '123456',
      );

      expect(verifyResult.success, isTrue);
      expect(verifyResult.buyer!.accountStatus, equals('Active'));
      expect(verifyResult.buyer!.hasClaimedVoucher, isTrue);
      expect(verifyResult.buyer!.walletBalance, equals(150.0));
      expect(service.currentBuyerSession, equals(verifyResult.buyer));
    });

    test('TC-BUY-024: Verify with incorrect OTP decrements attempts and rejects', () {
      service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'otp.fail@example.com',
        mobileNumber: '09179992211',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );

      final verifyResult = service.verifyOtp(
        email: 'otp.fail@example.com',
        inputOtp: '999999',
      );

      expect(verifyResult.success, isFalse);
      expect(verifyResult.message, contains('Invalid verification code'));
      expect(verifyResult.message, contains('Attempts remaining: 2'));
    });

    test('TC-BUY-025: OTP in wrong format is rejected', () {
      final verifyResult = service.verifyOtp(
        email: 'otp.fail@example.com',
        inputOtp: 'ABC12', // Not 6 numeric digits
      );
      expect(verifyResult.success, isFalse);
      expect(verifyResult.message, contains('must be exactly 6 digits'));
    });

    test('TC-BUY-026: Expired OTP is rejected', () {
      service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'otp.expired@example.com',
        mobileNumber: '09179991100',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );

      // Force expiration
      final buyer = service.currentUnverifiedBuyer!;
      buyer.otpExpiresAt = DateTime.now().subtract(const Duration(minutes: 1));

      final verifyResult = service.verifyOtp(
        email: 'otp.expired@example.com',
        inputOtp: '123456',
      );

      expect(verifyResult.success, isFalse);
      expect(verifyResult.message, contains('expired'));
    });

    test('TC-BUY-027: Resend OTP generates new code and invalidates previous one', () {
      service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'otp.resend@example.com',
        mobileNumber: '09179990099',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );

      final resendResult = service.resendOtp(email: 'otp.resend@example.com');
      expect(resendResult.success, isTrue);
      expect(resendResult.otp, isNotNull);
      expect(resendResult.otp!.length, equals(6));

      // Old code 123456 should now fail
      final oldVerify = service.verifyOtp(
        email: 'otp.resend@example.com',
        inputOtp: '123456',
      );
      expect(oldVerify.success, isFalse);

      // New code should succeed
      final newVerify = service.verifyOtp(
        email: 'otp.resend@example.com',
        inputOtp: resendResult.otp!,
      );
      expect(newVerify.success, isTrue);
    });

    test('TC-BUY-036: Register with no internet connection returns offline message', () {
      service.setNetworkConnected(false);

      final result = service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'offline@example.com',
        mobileNumber: '09179990088',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );

      expect(result.success, isFalse);
      expect(result.message, contains('No internet connection'));
    });

    test('TC-BUY-040 & 043: Unverified account blocked at login, and logout terminates session', () {
      // 1. Unverified account blocked at login
      service.registerBuyer(
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        email: 'unverified.login@example.com',
        mobileNumber: '09179990077',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        agreeTerms: true,
      );

      final loginRes = service.loginBuyer(
        emailOrPhone: 'unverified.login@example.com',
        password: 'Passw0rd!',
      );
      expect(loginRes.success, isFalse);
      expect(loginRes.message, contains('Account unverified'));

      // 2. Active account login succeeds
      final activeLogin = service.loginBuyer(
        emailOrPhone: 'juanmiguel.delacruz@example.com',
        password: 'Passw0rd!',
      );
      expect(activeLogin.success, isTrue);
      expect(service.currentBuyerSession, isNotNull);

      // 3. Logout terminates session
      service.logout();
      expect(service.currentBuyerSession, isNull);
    });
  });
}
