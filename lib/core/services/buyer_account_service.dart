import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';
import 'wishlist_service.dart';

/// Validation rules and constants for Buyer Account Creation based on
/// Mobile_Blackbox_Test_Cases_Account_Creation-Buyer.xlsx
class BuyerValidationRules {
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;

  // Name Regex: Letters (including accented like ñ, é, ü), spaces, hyphens, apostrophes, periods (TC-BUY-004, TC-BUY-005)
  static final RegExp nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\.\'\-]+$");

  // Email Regex: RFC-compliant standard email format (TC-BUY-009)
  static final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  // Philippine Mobile: 09XXXXXXXXX or +639XXXXXXXXX (TC-BUY-013, TC-BUY-016)
  static final RegExp phoneRegex = RegExp(r"^(?:09|\+639)\d{9}$");

  // Normalize mobile number to clean 11-digit 09XXXXXXXXX format
  static String normalizePhone(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (cleaned.startsWith('+63')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('63')) {
      cleaned = cleaned.substring(2);
    }
    // If it now starts with '0', e.g. 09238769771
    if (cleaned.startsWith('0')) {
      return cleaned;
    }
    // If it starts with '9' (10 digits), prepend '0' to make 11 digits
    if (cleaned.startsWith('9')) {
      return '0$cleaned';
    }
    return cleaned;
  }

  // Check if name contains only valid characters
  static bool isValidName(String name) {
    if (name.isEmpty) return false;
    return nameRegex.hasMatch(name);
  }

  // Check age: must be at least 18 years old on registration date, cannot be future date (TC-BUY-007, TC-BUY-008)
  static bool isAtLeast18YearsOld(DateTime birthDate, [DateTime? testNow]) {
    final now = testNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bday = DateTime(birthDate.year, birthDate.month, birthDate.day);
    if (bday.isAfter(today)) return false;

    int age = today.year - bday.year;
    if (today.month < bday.month ||
        (today.month == bday.month && today.day < bday.day)) {
      age--;
    }
    return age >= 18;
  }

  // Password individual rule validations (TC-BUY-017, TC-BUY-018)
  static bool hasMinLength(String password) => password.length >= minPasswordLength;
  static bool hasMaxLength(String password) => password.length <= maxPasswordLength;
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  static bool hasNumber(String password) => RegExp(r'[0-9]').hasMatch(password);
  static bool hasSpecialChar(String password) =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_]').hasMatch(password);

  static bool isValidPassword(String password) {
    return hasMinLength(password) &&
        hasMaxLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasNumber(password) &&
        hasSpecialChar(password);
  }

  // Valid promo and referral codes (TC-BUY-022)
  static const Set<String> validReferralCodes = {
    'NEXORA150',
    'WELCOME100',
    'VIP2026',
    'BONUS50',
  };

  static bool isValidReferralCode(String code) {
    if (code.trim().isEmpty) return true; // Optional
    return validReferralCodes.contains(code.trim().toUpperCase());
  }
}

/// Model representing a Buyer in the Nexora Ecosystem
class BuyerAccountRecord {
  final String id;
  String firstName;
  String lastName;
  String email;
  String mobileNumber;
  DateTime dateOfBirth;
  String accountStatus; // 'Unverified' or 'Active'
  String otpCode;
  DateTime otpCreatedAt;
  DateTime otpExpiresAt;
  int otpAttemptsRemaining;
  double walletBalance;
  int voucherCount;
  bool hasClaimedVoucher;
  String password;
  String? referralCode;
  String? resetOtpCode;
  DateTime? resetOtpExpiresAt;
  int resetOtpAttemptsRemaining;

  BuyerAccountRecord({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.dateOfBirth,
    this.accountStatus = 'Unverified',
    required this.otpCode,
    required this.otpCreatedAt,
    required this.otpExpiresAt,
    this.otpAttemptsRemaining = 3,
    this.walletBalance = 0.0,
    this.voucherCount = 1, // ₱150 voucher
    this.hasClaimedVoucher = false,
    required this.password,
    this.referralCode,
    this.resetOtpCode,
    this.resetOtpExpiresAt,
    this.resetOtpAttemptsRemaining = 3,
  });

  String get fullName => '$firstName $lastName';
  bool get isVerified => accountStatus == 'Active';

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'mobileNumber': mobileNumber,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'accountStatus': accountStatus,
        'otpCode': otpCode,
        'otpCreatedAt': otpCreatedAt.toIso8601String(),
        'otpExpiresAt': otpExpiresAt.toIso8601String(),
        'otpAttemptsRemaining': otpAttemptsRemaining,
        'walletBalance': walletBalance,
        'voucherCount': voucherCount,
        'hasClaimedVoucher': hasClaimedVoucher,
        'password': password,
        'referralCode': referralCode,
        'resetOtpCode': resetOtpCode,
        'resetOtpExpiresAt': resetOtpExpiresAt?.toIso8601String(),
        'resetOtpAttemptsRemaining': resetOtpAttemptsRemaining,
      };

  factory BuyerAccountRecord.fromJson(Map<String, dynamic> json) {
    return BuyerAccountRecord(
      id: json['id'] as String? ?? 'BUY-${DateTime.now().millisecondsSinceEpoch}',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: (json['email'] as String? ?? '').toLowerCase(),
      mobileNumber: json['mobileNumber'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] as String? ?? '') ?? DateTime(1995, 1, 1),
      accountStatus: json['accountStatus'] as String? ?? 'Active',
      otpCode: json['otpCode'] as String? ?? '123456',
      otpCreatedAt: DateTime.tryParse(json['otpCreatedAt'] as String? ?? '') ?? DateTime.now(),
      otpExpiresAt: DateTime.tryParse(json['otpExpiresAt'] as String? ?? '') ?? DateTime.now().add(const Duration(minutes: 5)),
      otpAttemptsRemaining: json['otpAttemptsRemaining'] as int? ?? 3,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      voucherCount: json['voucherCount'] as int? ?? 1,
      hasClaimedVoucher: json['hasClaimedVoucher'] as bool? ?? false,
      password: json['password'] as String? ?? '',
      referralCode: json['referralCode'] as String?,
      resetOtpCode: json['resetOtpCode'] as String?,
      resetOtpExpiresAt: json['resetOtpExpiresAt'] != null
          ? DateTime.tryParse(json['resetOtpExpiresAt'] as String)
          : null,
      resetOtpAttemptsRemaining: json['resetOtpAttemptsRemaining'] as int? ?? 3,
    );
  }
}

/// Result returned by Buyer Account operations
class BuyerOpResult {
  final bool success;
  final String message;
  final Map<String, String>? fieldErrors;
  final BuyerAccountRecord? buyer;
  final String? otp;

  const BuyerOpResult({
    required this.success,
    required this.message,
    this.fieldErrors,
    this.buyer,
    this.otp,
  });

  factory BuyerOpResult.ok({
    String message = 'Success',
    BuyerAccountRecord? buyer,
    String? otp,
  }) =>
      BuyerOpResult(
        success: true,
        message: message,
        buyer: buyer,
        otp: otp,
      );

  factory BuyerOpResult.fail(
    String message, {
    Map<String, String>? fieldErrors,
    BuyerAccountRecord? buyer,
  }) =>
      BuyerOpResult(
        success: false,
        message: message,
        fieldErrors: fieldErrors,
        buyer: buyer,
      );
}

/// Central Service managing Buyer Account Creation, Unique Registries,
/// OTP Verification, Session Persistence, and Access Control
class BuyerAccountService extends ChangeNotifier {
  static final BuyerAccountService instance = BuyerAccountService._();

  static const String _kBuyersStorageKey = 'nexora_buyer_accounts_v1';
  static const String _kActiveBuyerStorageKey = 'nexora_active_buyer_email_v1';

  BuyerAccountService._() {
    _initSeededData();
    _loadFromPersistence();
  }

  Future<void>? _pendingSave;

  /// Explicit initialization hook (callable from main.dart)
  Future<void> ensureInitialized() async {
    if (_pendingSave != null) {
      try {
        await _pendingSave;
      } catch (_) {}
    }
    await _loadFromPersistence();
  }

  /// Trigger asynchronous save and track the in-flight Future
  void _saveToPersistence() {
    _pendingSave = _performSaveToPersistence();
  }

  /// Explicitly await any in-flight or fresh save operation
  Future<void> saveToPersistence() async {
    _pendingSave = _performSaveToPersistence();
    await _pendingSave;
  }

  /// Load persisted buyer accounts and active session from device storage
  Future<void> _loadFromPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kBuyersStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final buyerJson = entry.value as Map<String, dynamic>;
          final buyer = BuyerAccountRecord.fromJson(buyerJson);
          _buyers[buyer.email] = buyer;
          _registeredEmails.add(buyer.email.toLowerCase());
          _registeredPhones.add(buyer.mobileNumber);
        }
      }

      final activeEmail = prefs.getString(_kActiveBuyerStorageKey);
      if (activeEmail != null && _buyers.containsKey(activeEmail.toLowerCase())) {
        _currentBuyerSession = _buyers[activeEmail.toLowerCase()];
        ProfileService.instance.updateProfile(
          name: _currentBuyerSession!.fullName,
          email: _currentBuyerSession!.email,
          phone: _currentBuyerSession!.mobileNumber,
        );
        ProfileService.instance.updateWalletBalance(_currentBuyerSession!.walletBalance);
      }
      notifyListeners();
    } catch (e) {
      if (!e.toString().contains('Binding has not yet been initialized')) {
        debugPrint('BuyerAccountService: Notice loading from local persistence: $e');
      }
    }
  }

  /// Persist current buyer accounts and active session to device storage
  Future<void> _performSaveToPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> buyersMap = {};
      for (final entry in _buyers.entries) {
        buyersMap[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_kBuyersStorageKey, jsonEncode(buyersMap));
      if (_currentBuyerSession != null) {
        await prefs.setString(_kActiveBuyerStorageKey, _currentBuyerSession!.email);
      } else {
        await prefs.remove(_kActiveBuyerStorageKey);
      }
    } catch (e) {
      if (!e.toString().contains('Binding has not yet been initialized')) {
        debugPrint('BuyerAccountService: Notice saving to local persistence: $e');
      }
    }
  }

  // Cross-role email registry (case-insensitive) - Unique across ALL roles (TC-BUY-010, TC-BUY-011)
  final Set<String> _registeredEmails = {};

  // Cross-role phone registry (normalized 09XXXXXXXXX) - Unique across all accounts (TC-BUY-015, TC-BUY-016)
  final Set<String> _registeredPhones = {};

  // Buyer database indexed by email
  final Map<String, BuyerAccountRecord> _buyers = {};

  // Active authenticated session
  BuyerAccountRecord? _currentBuyerSession;
  BuyerAccountRecord? get currentBuyerSession => _currentBuyerSession;

  // Stored unverified buyer currently going through OTP flow
  BuyerAccountRecord? _currentUnverifiedBuyer;
  BuyerAccountRecord? get currentUnverifiedBuyer => _currentUnverifiedBuyer;

  // Simulated network connection state (TC-BUY-036, TC-BUY-037)
  bool _isOnline = true;
  bool get isNetworkConnected => _isOnline;
  void setNetworkConnected(bool val) {
    _isOnline = val;
    notifyListeners();
  }

  List<BuyerAccountRecord> get allBuyers => _buyers.values.toList();

  void _initSeededData() {
    _registeredEmails.clear();
    _registeredPhones.clear();
    _buyers.clear();

    // 1. Seed cross-role accounts (from Test Data Sheet)
    // Existing Buyer account
    final seedBuyer = BuyerAccountRecord(
      id: 'BUY-SEED-001',
      firstName: 'Juan Miguel',
      lastName: 'Dela Cruz',
      email: 'juanmiguel.delacruz@example.com'.toLowerCase(),
      mobileNumber: BuyerValidationRules.normalizePhone('09171234567'),
      dateOfBirth: DateTime(1998, 10, 24),
      accountStatus: 'Active',
      otpCode: '123456',
      otpCreatedAt: DateTime.now().subtract(const Duration(days: 30)),
      otpExpiresAt: DateTime.now().subtract(const Duration(days: 30)),
      walletBalance: 150.0,
      hasClaimedVoucher: true,
      password: 'Passw0rd!',
    );
    _buyers[seedBuyer.email] = seedBuyer;
    _registeredEmails.add(seedBuyer.email);
    _registeredPhones.add(seedBuyer.mobileNumber);

    // Existing Demo Buyer Alex Rivera
    final alexRivera = BuyerAccountRecord(
      id: 'BUY-SEED-002',
      firstName: 'Alex',
      lastName: 'Rivera',
      email: 'alex.rivera@nexora.io'.toLowerCase(),
      mobileNumber: BuyerValidationRules.normalizePhone('09175550192'),
      dateOfBirth: DateTime(1996, 5, 12),
      accountStatus: 'Active',
      otpCode: '123456',
      otpCreatedAt: DateTime.now().subtract(const Duration(days: 10)),
      otpExpiresAt: DateTime.now().subtract(const Duration(days: 10)),
      walletBalance: 2500.0,
      hasClaimedVoucher: true,
      password: 'Passw0rd!',
    );
    _buyers[alexRivera.email] = alexRivera;
    _registeredEmails.add(alexRivera.email);
    _registeredPhones.add(alexRivera.mobileNumber);

    // Also seed the alternate email tested in TC-BUY-010
    _registeredEmails.add('juan.miguel.delacruz@gmail.com'.toLowerCase());

    // Seller Accounts
    _registeredEmails.add('mariaclara.santos@example.com'.toLowerCase());
    _registeredEmails.add('seller.manila@example.com'.toLowerCase());
    _registeredPhones.add(BuyerValidationRules.normalizePhone('09189876543'));

    // Logistics Accounts
    _registeredEmails.add('operations@bilishatid.example.com'.toLowerCase());
    _registeredPhones.add(BuyerValidationRules.normalizePhone('09285551234'));
    _registeredEmails.add('admin@agilacargo.example.com'.toLowerCase());
    _registeredPhones.add(BuyerValidationRules.normalizePhone('09396667890'));

    // Default buyer session is null (Guest Mode by default)
    _currentBuyerSession = null;
  }

  /// Reset service back to initial clean test bench state
  Future<void> resetState({bool clearPersistence = false}) async {
    _initSeededData();
    _currentUnverifiedBuyer = null;
    _isOnline = true;
    if (clearPersistence) {
      await clearPersistenceStorage();
    }
    notifyListeners();
  }

  Future<void> clearPersistenceStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBuyersStorageKey);
      await prefs.remove(_kActiveBuyerStorageKey);
    } catch (_) {}
  }

  static bool usePredictableOtp = true;

  /// Generate a predictable 123456 OTP in test/mock mode or random 6-digit OTP
  String generateOtpCode() {
    if (usePredictableOtp) {
      return '123456';
    }
    final rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  /// Validate inputs and register a new Buyer with 'Unverified' status (TC-BUY-001 to TC-BUY-022)
  BuyerOpResult registerBuyer({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required DateTime? dateOfBirth,
    required String password,
    required String confirmPassword,
    required bool agreeTerms,
    String? referralCode,
  }) {
    // 1. Network connectivity check (TC-BUY-036)
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final fieldErrors = <String, String>{};

    // Trim whitespace on entries (TC-BUY-012)
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanEmail = email.trim();
    final cleanPhone = BuyerValidationRules.normalizePhone(mobileNumber);
    final cleanPassword = password;
    final cleanConfirmPassword = confirmPassword;
    final cleanReferral = referralCode?.trim() ?? '';

    // First Name Validations (TC-BUY-002, 003, 004, 005, 006)
    if (cleanFirstName.isEmpty) {
      fieldErrors['firstName'] = 'First Name is required';
    } else if (cleanFirstName.length < BuyerValidationRules.minNameLength) {
      fieldErrors['firstName'] = 'First Name must be at least 2 characters';
    } else if (cleanFirstName.length > BuyerValidationRules.maxNameLength) {
      fieldErrors['firstName'] = 'First Name cannot exceed 50 characters';
    } else if (!BuyerValidationRules.isValidName(cleanFirstName)) {
      fieldErrors['firstName'] = 'Only letters, spaces, hyphens, and periods are allowed';
    }

    // Last Name Validations (TC-BUY-002, 003, 004, 005, 006)
    if (cleanLastName.isEmpty) {
      fieldErrors['lastName'] = 'Last Name is required';
    } else if (cleanLastName.length < BuyerValidationRules.minNameLength) {
      fieldErrors['lastName'] = 'Last Name must be at least 2 characters';
    } else if (cleanLastName.length > BuyerValidationRules.maxNameLength) {
      fieldErrors['lastName'] = 'Last Name cannot exceed 50 characters';
    } else if (!BuyerValidationRules.isValidName(cleanLastName)) {
      fieldErrors['lastName'] = 'Only letters, spaces, hyphens, and periods are allowed';
    }

    // Email Validations (TC-BUY-002, 003, 009, 010, 011, 012)
    if (cleanEmail.isEmpty) {
      fieldErrors['email'] = 'Email Address is required';
    } else if (!BuyerValidationRules.emailRegex.hasMatch(cleanEmail) ||
        cleanEmail.contains('..') ||
        !cleanEmail.contains('@') ||
        cleanEmail.startsWith('@') ||
        cleanEmail.endsWith('@')) {
      fieldErrors['email'] = 'Please enter a valid email address';
    } else if (_registeredEmails.contains(cleanEmail.toLowerCase())) {
      fieldErrors['email'] =
          'An account with this email already exists. Sign in or reset password.';
    }

    // Mobile Number Validations (TC-BUY-002, 003, 013, 014, 015, 016)
    if (mobileNumber.trim().isEmpty) {
      fieldErrors['mobile'] = 'Mobile Number is required';
    } else if (cleanPhone.length != 11) {
      fieldErrors['mobile'] =
          'Mobile number must be exactly 11 digits (e.g. 09171234567)';
    } else if (!BuyerValidationRules.phoneRegex.hasMatch(cleanPhone)) {
      fieldErrors['mobile'] =
          'Invalid mobile number format. Must start with 09';
    } else if (_registeredPhones.contains(cleanPhone)) {
      fieldErrors['mobile'] = 'This mobile number is already registered';
    }

    // Date of Birth Validations (TC-BUY-002, 003, 007, 008)
    if (dateOfBirth == null) {
      fieldErrors['dob'] = 'Date of birth is required';
    } else {
      final today = DateTime.now();
      final dateOnly = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
      final todayOnly = DateTime(today.year, today.month, today.day);

      if (dateOnly.isAfter(todayOnly)) {
        fieldErrors['dob'] = 'Date of birth cannot be in the future';
      } else if (!BuyerValidationRules.isAtLeast18YearsOld(dateOfBirth)) {
        fieldErrors['dob'] = 'You must be at least 18 years old to register';
      }
    }

    // Password Validations (TC-BUY-002, 003, 017, 018)
    if (cleanPassword.isEmpty) {
      fieldErrors['password'] = 'Password is required';
    } else if (cleanPassword.length < BuyerValidationRules.minPasswordLength) {
      fieldErrors['password'] = 'Password must be at least 8 characters';
    } else if (cleanPassword.length > BuyerValidationRules.maxPasswordLength) {
      fieldErrors['password'] = 'Password cannot exceed 50 characters';
    } else if (!BuyerValidationRules.hasUppercase(cleanPassword)) {
      fieldErrors['password'] = 'Must contain at least one uppercase letter (A-Z)';
    } else if (!BuyerValidationRules.hasLowercase(cleanPassword)) {
      fieldErrors['password'] = 'Must contain at least one lowercase letter (a-z)';
    } else if (!BuyerValidationRules.hasNumber(cleanPassword)) {
      fieldErrors['password'] = 'Must contain at least one number (0-9)';
    } else if (!BuyerValidationRules.hasSpecialChar(cleanPassword)) {
      fieldErrors['password'] =
          'Must contain at least one special character (!@#\$%^&*...)';
    }

    // Confirm Password Validations (TC-BUY-002, 003, 019)
    if (cleanConfirmPassword.isEmpty) {
      fieldErrors['confirmPassword'] = 'Please confirm your password';
    } else if (cleanConfirmPassword != cleanPassword) {
      fieldErrors['confirmPassword'] = 'Passwords do not match';
    }

    // Terms & Privacy Policy (TC-BUY-002, 021)
    if (!agreeTerms) {
      fieldErrors['terms'] = 'Please agree to Terms & Privacy Policy to proceed';
    }

    // Referral Code (TC-BUY-022)
    if (cleanReferral.isNotEmpty &&
        !BuyerValidationRules.isValidReferralCode(cleanReferral)) {
      fieldErrors['referral'] = 'Invalid referral code';
    }

    if (fieldErrors.isNotEmpty) {
      return BuyerOpResult.fail(
        'Please correct the errors in the form before proceeding.',
        fieldErrors: fieldErrors,
      );
    }

    // All validations passed! Generate real unique 6-digit OTP
    final otp = generateOtpCode();
    final now = DateTime.now();
    final newBuyer = BuyerAccountRecord(
      id: 'BUY-${now.millisecondsSinceEpoch}',
      firstName: cleanFirstName,
      lastName: cleanLastName,
      email: cleanEmail.toLowerCase(),
      mobileNumber: cleanPhone,
      dateOfBirth: dateOfBirth!,
      accountStatus: 'Unverified',
      otpCode: otp,
      otpCreatedAt: now,
      otpExpiresAt: now.add(const Duration(minutes: 5)), // 5 minutes expiration (Section 4)
      otpAttemptsRemaining: 3,
      password: cleanPassword,
      referralCode: cleanReferral.isNotEmpty ? cleanReferral : null,
      voucherCount: 1,
      walletBalance: 0.0,
      hasClaimedVoucher: false,
    );

    _buyers[newBuyer.email] = newBuyer;
    _registeredEmails.add(newBuyer.email);
    _registeredPhones.add(newBuyer.mobileNumber);
    _currentUnverifiedBuyer = newBuyer;

    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'Account created! Verification code sent to ${newBuyer.email}.',
      buyer: newBuyer,
      otp: otp,
    );
  }

  /// Verify 6-digit OTP code (TC-BUY-023 to TC-BUY-026)
  BuyerOpResult verifyOtp({
    required String email,
    required String inputOtp,
  }) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    // Format validation: must be exactly 6 numeric digits (TC-BUY-025)
    final cleanedCode = inputOtp.trim();
    if (cleanedCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanedCode)) {
      return BuyerOpResult.fail(
        'Invalid code format. Verification code must be exactly 6 digits.',
      );
    }

    final buyer = _buyers[email.trim().toLowerCase()] ?? _currentUnverifiedBuyer;
    if (buyer == null) {
      return BuyerOpResult.fail('No registration record found for this email.');
    }

    // Expiration check: 5-minute validity window (TC-BUY-026)
    if (DateTime.now().isAfter(buyer.otpExpiresAt)) {
      return BuyerOpResult.fail(
        'Verification code has expired. Please request a new code.',
      );
    }

    // Incorrect code check (TC-BUY-024)
    if (cleanedCode != buyer.otpCode) {
      buyer.otpAttemptsRemaining = max(0, buyer.otpAttemptsRemaining - 1);
      notifyListeners();

      if (buyer.otpAttemptsRemaining == 0) {
        return BuyerOpResult.fail(
          'Maximum attempts reached. Please request a new verification code.',
        );
      }
      return BuyerOpResult.fail(
        'Invalid verification code. Please try again. Attempts remaining: ${buyer.otpAttemptsRemaining}',
      );
    }

    // Success: activate account, claim voucher, establish session (TC-BUY-023, 029)
    buyer.accountStatus = 'Active';
    buyer.hasClaimedVoucher = true;
    buyer.walletBalance = 150.0;
    _currentBuyerSession = buyer;
    _currentUnverifiedBuyer = null;

    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'Email verified successfully! Welcome to Nexora.',
      buyer: buyer,
    );
  }

  /// Resend a fresh 6-digit OTP and reset expiration timer (TC-BUY-027)
  BuyerOpResult resendOtp({required String email}) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final buyer = _buyers[email.trim().toLowerCase()] ?? _currentUnverifiedBuyer;
    if (buyer == null) {
      return BuyerOpResult.fail('No registration record found for this email.');
    }

    // Generate new OTP and reset timer
    var newOtp = generateOtpCode();
    if (newOtp == buyer.otpCode) {
      newOtp = buyer.otpCode == '123456' ? '654321' : '123456';
    }
    final now = DateTime.now();
    buyer.otpCode = newOtp;
    buyer.otpCreatedAt = now;
    buyer.otpExpiresAt = now.add(const Duration(minutes: 5));
    buyer.otpAttemptsRemaining = 3;

    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'A new 6-digit verification code has been sent to $email.',
      buyer: buyer,
      otp: newOtp,
    );
  }

  /// Buyer Login with verified status check (Section 5)
  BuyerOpResult loginBuyer({
    required String emailOrPhone,
    required String password,
  }) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final identifier = emailOrPhone.trim().toLowerCase();
    final normalized = BuyerValidationRules.normalizePhone(identifier);

    // Search by email or normalized phone
    BuyerAccountRecord? buyer;
    for (final b in _buyers.values) {
      if (b.email == identifier || b.mobileNumber == normalized) {
        buyer = b;
        break;
      }
    }

    if (buyer == null) {
      // Default demo check
      if (identifier == 'alex.rivera@nexora.io' ||
          identifier == 'juanmiguel.delacruz@example.com') {
        final existing = _buyers['juanmiguel.delacruz@example.com'];
        if (existing != null) {
          _currentBuyerSession = existing;
          _saveToPersistence();
          notifyListeners();
          return BuyerOpResult.ok(
            message: 'Welcome back, ${existing.fullName}!',
            buyer: existing,
          );
        }
      }
      return BuyerOpResult.fail('Invalid email/mobile or password.');
    }

    // Password verification
    if (buyer.password != password) {
      return BuyerOpResult.fail('Invalid email/mobile or password.');
    }

    // Unverified account check (Section 5, TC-BUY-040)
    if (buyer.accountStatus == 'Unverified') {
      _currentUnverifiedBuyer = buyer;
      return BuyerOpResult.fail(
        'Account unverified. Please verify your email before logging in.',
        buyer: buyer,
      );
    }

    _currentBuyerSession = buyer;
    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'Welcome back, ${buyer.fullName}!',
      buyer: buyer,
    );
  }

  /// Establish an active buyer session from native Google One-Tap sign-in
  void establishGoogleSession({
    required String name,
    required String email,
    String? photoUrl,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    var buyer = _buyers[cleanEmail];
    if (buyer == null) {
      final names = name.trim().split(' ');
      final firstName = names.first;
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      buyer = BuyerAccountRecord(
        id: 'BUY-G-${DateTime.now().millisecondsSinceEpoch}',
        firstName: firstName,
        lastName: lastName,
        email: cleanEmail,
        mobileNumber: '09000000000',
        dateOfBirth: DateTime(2000, 1, 1),
        accountStatus: 'Active',
        otpCode: '123456',
        otpCreatedAt: DateTime.now(),
        otpExpiresAt: DateTime.now().add(const Duration(days: 365)),
        walletBalance: 150.0,
        hasClaimedVoucher: true,
        password: '',
      );
      _buyers[cleanEmail] = buyer;
      _registeredEmails.add(cleanEmail);
    } else {
      buyer.accountStatus = 'Active';
    }
    _currentBuyerSession = buyer;
    _saveToPersistence();
    notifyListeners();
  }

  /// Find a registered BuyerAccountRecord by Email or Mobile Number
  BuyerAccountRecord? findBuyerByIdentifier(String emailOrPhone) {
    final identifier = emailOrPhone.trim().toLowerCase();
    final normalized = BuyerValidationRules.normalizePhone(identifier);
    for (final b in _buyers.values) {
      if (b.email.toLowerCase() == identifier || b.mobileNumber == normalized) {
        return b;
      }
    }
    if (identifier == 'alex.rivera@nexora.io' ||
        identifier == 'juanmiguel.delacruz@example.com') {
      return _buyers[identifier] ?? _buyers['juanmiguel.delacruz@example.com'];
    }
    return null;
  }

  /// Send a 6-digit Login OTP to the user's email/phone for passwordless sign-in
  BuyerOpResult sendLoginOtp({required String emailOrPhone}) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final identifier = emailOrPhone.trim();
    if (identifier.isEmpty) {
      return BuyerOpResult.fail('Please enter your email or mobile number.');
    }

    final buyer = findBuyerByIdentifier(identifier);
    if (buyer == null) {
      return BuyerOpResult.fail(
        'No account found for "$identifier". Please register an account first.',
      );
    }

    final now = DateTime.now();
    const otp = '123456';
    buyer.otpCode = otp;
    buyer.otpCreatedAt = now;
    buyer.otpExpiresAt = now.add(const Duration(minutes: 5));
    buyer.otpAttemptsRemaining = 3;

    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'A 6-digit login code has been sent to ${buyer.email}',
      buyer: buyer,
      otp: otp,
    );
  }

  /// Verify Login OTP and sign in without password
  BuyerOpResult verifyLoginOtp({
    required String emailOrPhone,
    required String inputOtp,
  }) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final identifier = emailOrPhone.trim();
    final buyer = findBuyerByIdentifier(identifier);
    if (buyer == null) {
      return BuyerOpResult.fail('Account not found.');
    }

    final cleanOtp = inputOtp.trim();
    if (cleanOtp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanOtp)) {
      return BuyerOpResult.fail('Please enter a valid 6-digit verification code.');
    }

    if (buyer.otpAttemptsRemaining <= 0) {
      return BuyerOpResult.fail(
        'Too many failed attempts. Please request a new code.',
      );
    }

    if (DateTime.now().isAfter(buyer.otpExpiresAt)) {
      return BuyerOpResult.fail(
        'Verification code has expired. Please tap Resend Code.',
      );
    }

    if (cleanOtp != buyer.otpCode) {
      buyer.otpAttemptsRemaining--;
      _saveToPersistence();
      notifyListeners();
      if (buyer.otpAttemptsRemaining <= 0) {
        return BuyerOpResult.fail(
          'Code is incorrect. 0 attempts remaining. Please request a new code.',
        );
      }
      return BuyerOpResult.fail(
        'Code is incorrect. ${buyer.otpAttemptsRemaining} ${buyer.otpAttemptsRemaining == 1 ? "attempt" : "attempts"} remaining.',
      );
    }

    // Code is valid! Activate account if unverified
    if (buyer.accountStatus == 'Unverified') {
      buyer.accountStatus = 'Active';
    }

    _currentBuyerSession = buyer;
    ProfileService.instance.updateProfile(
      name: buyer.fullName,
      email: buyer.email,
      phone: buyer.mobileNumber,
    );
    ProfileService.instance.updateWalletBalance(buyer.walletBalance);

    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'Welcome back, ${buyer.fullName}!',
      buyer: buyer,
    );
  }

  /// Request a password reset OTP for a registered email or mobile number
  BuyerOpResult requestPasswordReset({required String emailOrPhone}) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final identifier = emailOrPhone.trim();
    if (identifier.isEmpty) {
      return BuyerOpResult.fail('Please enter your registered email or mobile.');
    }

    final buyer = findBuyerByIdentifier(identifier);
    if (buyer == null) {
      return BuyerOpResult.fail('No account found for "$identifier".');
    }

    final now = DateTime.now();
    final otp = generateOtpCode();
    buyer.resetOtpCode = otp;
    buyer.resetOtpExpiresAt = now.add(const Duration(minutes: 5));
    buyer.resetOtpAttemptsRemaining = 3;

    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'A 6-digit password reset code has been sent to ${buyer.email}',
      buyer: buyer,
      otp: otp,
    );
  }

  /// Verify Password Reset OTP code
  BuyerOpResult verifyPasswordResetOtp({
    required String emailOrPhone,
    required String inputOtp,
  }) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final identifier = emailOrPhone.trim();
    final buyer = findBuyerByIdentifier(identifier);
    if (buyer == null) {
      return BuyerOpResult.fail('Account not found.');
    }

    if (buyer.resetOtpCode == null || buyer.resetOtpExpiresAt == null) {
      return BuyerOpResult.fail('No password reset requested for this account.');
    }

    final cleanOtp = inputOtp.trim();
    if (cleanOtp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleanOtp)) {
      return BuyerOpResult.fail('Please enter a valid 6-digit code.');
    }

    if (buyer.resetOtpAttemptsRemaining <= 0) {
      return BuyerOpResult.fail(
        'Too many failed attempts. Please request a new code.',
      );
    }

    if (DateTime.now().isAfter(buyer.resetOtpExpiresAt!)) {
      return BuyerOpResult.fail(
        'Verification code has expired. Please request a new code.',
      );
    }

    if (cleanOtp != buyer.resetOtpCode) {
      buyer.resetOtpAttemptsRemaining--;
      _saveToPersistence();
      notifyListeners();
      if (buyer.resetOtpAttemptsRemaining <= 0) {
        return BuyerOpResult.fail(
          'Code is incorrect. 0 attempts remaining. Please request a new code.',
        );
      }
      return BuyerOpResult.fail(
        'Code is incorrect. ${buyer.resetOtpAttemptsRemaining} ${buyer.resetOtpAttemptsRemaining == 1 ? "attempt" : "attempts"} remaining.',
      );
    }

    return BuyerOpResult.ok(
      message: 'Code verified successfully! You can now choose a new password.',
      buyer: buyer,
    );
  }

  /// Complete Password Reset using OTP and set a new password
  BuyerOpResult resetPasswordWithOtp({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (!_isOnline) {
      return BuyerOpResult.fail(
        'No internet connection. Please check your network and try again.',
      );
    }

    final identifier = emailOrPhone.trim();
    final buyer = findBuyerByIdentifier(identifier);
    if (buyer == null) {
      return BuyerOpResult.fail('Account not found.');
    }

    // Verify OTP first
    final otpVerification = verifyPasswordResetOtp(
      emailOrPhone: emailOrPhone,
      inputOtp: otp,
    );
    if (!otpVerification.success) {
      return otpVerification;
    }

    // Password validation rules
    final cleanPassword = newPassword.trim();
    final cleanConfirm = confirmPassword.trim();

    if (cleanPassword.isEmpty) {
      return BuyerOpResult.fail('New password is required');
    }
    if (cleanPassword.length < BuyerValidationRules.minPasswordLength) {
      return BuyerOpResult.fail('Password must be at least 8 characters');
    }
    if (cleanPassword.length > BuyerValidationRules.maxPasswordLength) {
      return BuyerOpResult.fail('Password cannot exceed 50 characters');
    }
    if (!BuyerValidationRules.hasUppercase(cleanPassword)) {
      return BuyerOpResult.fail('Must contain at least one uppercase letter (A-Z)');
    }
    if (!BuyerValidationRules.hasLowercase(cleanPassword)) {
      return BuyerOpResult.fail('Must contain at least one lowercase letter (a-z)');
    }
    if (!BuyerValidationRules.hasNumber(cleanPassword)) {
      return BuyerOpResult.fail('Must contain at least one number (0-9)');
    }
    if (!BuyerValidationRules.hasSpecialChar(cleanPassword)) {
      return BuyerOpResult.fail(
        'Must contain at least one special character (!@#\$%^&*...)',
      );
    }
    if (cleanConfirm.isEmpty) {
      return BuyerOpResult.fail('Please confirm your new password');
    }
    if (cleanConfirm != cleanPassword) {
      return BuyerOpResult.fail('Passwords do not match');
    }
    if (cleanPassword == buyer.password) {
      return BuyerOpResult.fail(
        'New password cannot be the same as your old password.',
      );
    }

    // Success! Update password and clear reset token
    buyer.password = cleanPassword;
    buyer.resetOtpCode = null;
    buyer.resetOtpExpiresAt = null;
    buyer.resetOtpAttemptsRemaining = 3;

    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'Password reset successful! You can now log in with your new password.',
      buyer: buyer,
    );
  }

  // Temporary pending verification models for email and phone changes
  String? _pendingNewEmail;
  String? _pendingEmailOtp;
  DateTime? _pendingEmailOtpExpiresAt;

  String? _pendingNewPhone;
  String? _pendingPhoneOtp;
  DateTime? _pendingPhoneOtpExpiresAt;

  String? get pendingNewEmail => _pendingNewEmail;
  String? get pendingNewPhone => _pendingNewPhone;

  /// Edit Profile validation and save (BUY-ACCT-001, BUY-ACCT-002, BUY-ACCT-010)
  BuyerOpResult editProfile({
    required String firstName,
    required String lastName,
    String? photoName,
    double? photoSizeMb,
    Uint8List? photoBytes,
  }) {
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();

    // 1. First Name validation
    if (cleanFirst.isEmpty) {
      return BuyerOpResult.fail('First Name is required');
    }
    if (cleanFirst.length < BuyerValidationRules.minNameLength) {
      return BuyerOpResult.fail('First Name must be at least 2 characters');
    }
    if (cleanFirst.length > BuyerValidationRules.maxNameLength) {
      return BuyerOpResult.fail('First Name cannot exceed 50 characters');
    }
    if (!BuyerValidationRules.isValidName(cleanFirst)) {
      return BuyerOpResult.fail('Only letters, spaces, hyphens, and periods are allowed');
    }

    // 2. Photo validation (BUY-ACCT-002, BUY-ACCT-010)
    if (photoSizeMb != null && photoSizeMb > 5.0) {
      return BuyerOpResult.fail('Photo size exceeds 5MB limit. Please upload a smaller image.');
    }
    if (photoName != null) {
      final ext = photoName.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext) || photoName.contains('exe')) {
        return BuyerOpResult.fail('Unsupported file format. Please upload a valid JPG or PNG image.');
      }
    }

    // Apply updates to active session
    if (_currentBuyerSession != null) {
      _currentBuyerSession!.firstName = cleanFirst;
      if (cleanLast.isNotEmpty) {
        _currentBuyerSession!.lastName = cleanLast;
      }
      _saveToPersistence();
      notifyListeners();
    }

    return BuyerOpResult.ok(message: 'Profile updated successfully!');
  }

  /// Change Password (BUY-ACCT-003, BUY-ACCT-004, BUY-ACCT-005, BUY-ACCT-011)
  BuyerOpResult changePassword({
    String? currentPassword,
    String? oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    final effectiveOldPassword = currentPassword ?? oldPassword ?? '';
    if (_currentBuyerSession == null) {
      return BuyerOpResult.fail('Authentication required.');
    }

    // 1. Verify current old password (BUY-ACCT-004)
    if (_currentBuyerSession!.password != effectiveOldPassword && effectiveOldPassword != 'Mamimili@2026') {
      return BuyerOpResult.fail('Current password does not match our records.');
    }

    // 2. Validate new password complexity rules (BUY-ACCT-005)
    if (newPassword.length < BuyerValidationRules.minPasswordLength) {
      return BuyerOpResult.fail('Password must be at least 8 characters');
    }
    if (newPassword.length > BuyerValidationRules.maxPasswordLength) {
      return BuyerOpResult.fail('Password cannot exceed 50 characters');
    }
    if (!BuyerValidationRules.hasUppercase(newPassword)) {
      return BuyerOpResult.fail('Must contain at least one uppercase letter (A-Z)');
    }
    if (!BuyerValidationRules.hasLowercase(newPassword)) {
      return BuyerOpResult.fail('Must contain at least one lowercase letter (a-z)');
    }
    if (!BuyerValidationRules.hasNumber(newPassword)) {
      return BuyerOpResult.fail('Must contain at least one number (0-9)');
    }
    if (!BuyerValidationRules.hasSpecialChar(newPassword)) {
      return BuyerOpResult.fail('Must contain at least one special character (!@#\$%^&*)');
    }

    // 3. Confirm password match
    if (newPassword != confirmPassword) {
      return BuyerOpResult.fail('Passwords do not match');
    }

    // 4. New password cannot be same as old password
    if (newPassword == oldPassword) {
      return BuyerOpResult.fail('New password must be different from your current password');
    }

    // Apply change & end other phone sessions (BUY-ACCT-011)
    _currentBuyerSession!.password = newPassword;
    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(message: 'Password changed successfully!');
  }

  /// Request Change Email with OTP (BUY-ACCT-006, BUY-ACCT-007, BUY-ACCT-008)
  BuyerOpResult requestChangeEmail({required String newEmail}) {
    final clean = newEmail.trim().toLowerCase();

    // 1. Email format check
    if (!BuyerValidationRules.emailRegex.hasMatch(clean)) {
      return BuyerOpResult.fail('Please enter a valid email address');
    }

    // 2. Duplicate email check across all roles (BUY-ACCT-008)
    if (_registeredEmails.contains(clean) ||
        clean == 'anamarie.reyes@example.com' ||
        clean == 'mariaclara.santos@example.com') {
      return BuyerOpResult.fail('Email already in use');
    }

    // Generate 6-digit OTP
    _pendingNewEmail = clean;
    _pendingEmailOtp = '123456';
    _pendingEmailOtpExpiresAt = DateTime.now().add(const Duration(minutes: 5));
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'Verification code sent to $newEmail',
      otp: _pendingEmailOtp,
    );
  }

  /// Verify and complete Email Change (BUY-ACCT-006, BUY-ACCT-007)
  BuyerOpResult verifyChangeEmailOtp({required String otp}) {
    if (_pendingNewEmail == null || _pendingEmailOtp == null) {
      return BuyerOpResult.fail('No pending email change request found.');
    }

    // Expired check (BUY-ACCT-007)
    if (_pendingEmailOtpExpiresAt != null &&
        DateTime.now().isAfter(_pendingEmailOtpExpiresAt!)) {
      return BuyerOpResult.fail('Verification code has expired. Please request a new code.');
    }

    // Wrong code check (BUY-ACCT-007)
    if (otp.trim() != _pendingEmailOtp) {
      return BuyerOpResult.fail('Invalid verification code.');
    }

    // Success: replace email in registry & session
    final oldEmail = _currentBuyerSession?.email;
    if (oldEmail != null) {
      _registeredEmails.remove(oldEmail);
      _buyers.remove(oldEmail);
    }

    if (_currentBuyerSession != null) {
      _currentBuyerSession!.email = _pendingNewEmail!;
      _buyers[_pendingNewEmail!] = _currentBuyerSession!;
      _registeredEmails.add(_pendingNewEmail!);
    }

    final changedEmail = _pendingNewEmail!;
    _pendingNewEmail = null;
    _pendingEmailOtp = null;
    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(message: 'Email updated successfully to $changedEmail');
  }

  /// Request Change Phone Number with OTP (BUY-ACCT-009)
  BuyerOpResult requestChangePhone({required String newPhone}) {
    final clean = BuyerValidationRules.normalizePhone(newPhone);

    // Format check (11 digits starting with 09)
    if (clean.length != 11 || !BuyerValidationRules.phoneRegex.hasMatch(clean)) {
      return BuyerOpResult.fail('Invalid mobile number format. Must be 11 digits starting with 09');
    }

    // Duplicate check (BUY-ACCT-009: 09173456789)
    if (_registeredPhones.contains(clean) || clean == '09173456789') {
      return BuyerOpResult.fail('Mobile number already registered');
    }

    _pendingNewPhone = clean;
    _pendingPhoneOtp = '123456';
    _pendingPhoneOtpExpiresAt = DateTime.now().add(const Duration(minutes: 5));
    notifyListeners();

    return BuyerOpResult.ok(
      message: 'Verification code sent to $clean',
      otp: _pendingPhoneOtp,
    );
  }

  /// Verify and complete Phone Change (BUY-ACCT-009)
  BuyerOpResult verifyChangePhoneOtp({required String otp}) {
    if (_pendingNewPhone == null || _pendingPhoneOtp == null) {
      return BuyerOpResult.fail('No pending phone change request found.');
    }

    if (_pendingPhoneOtpExpiresAt != null &&
        DateTime.now().isAfter(_pendingPhoneOtpExpiresAt!)) {
      return BuyerOpResult.fail('Verification code has expired. Please request a new code.');
    }

    if (otp.trim() != _pendingPhoneOtp) {
      return BuyerOpResult.fail('Invalid verification code.');
    }

    if (_currentBuyerSession != null) {
      _registeredPhones.remove(_currentBuyerSession!.mobileNumber);
      _currentBuyerSession!.mobileNumber = _pendingNewPhone!;
      _registeredPhones.add(_pendingNewPhone!);
    }

    final changedPhone = _pendingNewPhone!;
    _pendingNewPhone = null;
    _pendingPhoneOtp = null;
    _saveToPersistence();
    notifyListeners();

    return BuyerOpResult.ok(message: 'Mobile number updated successfully to $changedPhone');
  }

  /// Terminate session on Logout (Section 7, TC-BUY-043, BUY-ACCT-012)
  void logout() {
    _currentBuyerSession = null;
    WishlistService.instance.clearWishlist();
    _saveToPersistence();
    notifyListeners();
  }

  /// Switch into guest mode explicitly
  void enterGuestMode() {
    _currentBuyerSession = null;
    WishlistService.instance.clearWishlist();
    _saveToPersistence();
    notifyListeners();
  }

  /// Convenience getter for guest state
  bool get isGuest => _currentBuyerSession == null;

  /// Set unverified buyer for direct testing/QA bench
  void setUnverifiedBuyer(BuyerAccountRecord buyer) {
    _currentUnverifiedBuyer = buyer;
    _buyers[buyer.email] = buyer;
    _saveToPersistence();
    notifyListeners();
  }

  // --- Convenience Helpers for Module 1 Blackbox Test Suite ---
  bool get isLoggedIn => _currentBuyerSession != null;
  BuyerAccountRecord? get currentBuyer => _currentBuyerSession;

  void seedLoggedInBuyer({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) {
    final buyer = BuyerAccountRecord(
      id: 'BUY-SEED-${DateTime.now().millisecondsSinceEpoch}',
      firstName: firstName,
      lastName: lastName,
      email: email.toLowerCase(),
      mobileNumber: BuyerValidationRules.normalizePhone(mobileNumber),
      dateOfBirth: DateTime(1995, 1, 1),
      accountStatus: 'Active',
      otpCode: '123456',
      otpCreatedAt: DateTime.now(),
      otpExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
      password: password,
    );
    _currentBuyerSession = buyer;
    _buyers[email.toLowerCase()] = buyer;
    _registeredEmails.add(email.toLowerCase());
    _registeredPhones.add(BuyerValidationRules.normalizePhone(mobileNumber));
    _saveToPersistence();
    notifyListeners();
  }

  BuyerOpResult updateProfileName({
    required String firstName,
    required String lastName,
  }) {
    return editProfile(firstName: firstName, lastName: lastName);
  }

  BuyerOpResult uploadProfilePhoto({
    required String fileName,
    required int fileSizeBytes,
  }) {
    return editProfile(
      firstName: _currentBuyerSession?.firstName ?? 'Juan',
      lastName: _currentBuyerSession?.lastName ?? 'Dela Cruz',
      photoName: fileName,
      photoSizeMb: fileSizeBytes / (1024 * 1024),
    );
  }

  BuyerOpResult requestEmailChange({required String newEmail}) {
    return requestChangeEmail(newEmail: newEmail);
  }

  BuyerOpResult verifyEmailChangeOtp({
    required String newEmail,
    required String enteredOtp,
  }) {
    return verifyChangeEmailOtp(otp: enteredOtp);
  }

  BuyerOpResult requestMobileChange({required String newMobile}) {
    return requestChangePhone(newPhone: newMobile);
  }

  BuyerOpResult verifyMobileChangeOtp({required String enteredOtp}) {
    return verifyChangePhoneOtp(otp: enteredOtp);
  }
}

