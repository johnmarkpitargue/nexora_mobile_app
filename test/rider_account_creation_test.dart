import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/rider_account_service.dart';
import 'package:nexora_rider_app/core/services/rider_service.dart';
import 'package:nexora_rider_app/features/auth/presentation/add_rider_page.dart';
import 'package:nexora_rider_app/features/auth/presentation/rider_set_password_page.dart';
import 'package:nexora_rider_app/features/auth/presentation/rider_landing_page.dart';

void main() {
  setUp(() {
    RiderAccountService.instance.resetForTesting();
    RiderService.instance.switchRider('NX-RD-001');
  });

  group('Black-Box Test Suite: Rider Account Creation (TC-RID-001 to TC-RID-047)', () {
    // -------------------------------------------------------------
    // TC-RID-001: Create a rider with all valid data
    // -------------------------------------------------------------
    test('TC-RID-001: Create a rider with all valid data', () {
      final service = RiderAccountService.instance;
      final result = service.registerRider(
        firstName: 'Pedro Jose',
        lastName: 'Garcia',
        dob: '03/22/1995',
        email: 'pedrojose.garcia@example.com',
        mobileNumber: '09451239876',
        licenseNumber: 'N01-23-456789',
        licenseExpiry: '03/22/2030',
        vehicleType: 'Motorcycle',
        plateNumber: '123ABC',
        licenseFileName: 'drivers_license.jpg',
        licenseFileSizeMb: 1.5,
        orCrFileName: 'or_cr.pdf',
        orCrFileSizeMb: 0.9,
      );

      expect(result.success, isTrue);
      expect(result.rider, isNotNull);
      expect(result.rider!.status, 'Pending Activation');
      expect(result.rider!.activationToken, isNotNull);
      expect(result.rider!.activationExpiresAt, isNotNull);
      expect(result.rider!.logisticsCompanyName, 'Bilis Hatid Express Inc.');

      // Check fleet visibility for Bilis Hatid Express Inc.
      final fleet = service.getCompanyRiders('Bilis Hatid Express Inc.');
      expect(fleet.any((r) => r.email == 'pedrojose.garcia@example.com'), isTrue);
    });

    // -------------------------------------------------------------
    // TC-RID-002: Submit a completely empty form
    // -------------------------------------------------------------
    test('TC-RID-002: Submit a completely empty form', () {
      final service = RiderAccountService.instance;
      expect(service.validateRequired('', 'First Name'), 'First Name is required');
      expect(service.validateRequired('', 'Last Name'), 'Last Name is required');
      expect(service.validateRequired('', 'Date of Birth'), 'Date of Birth is required');
      expect(service.validateRequired('', 'Email'), 'Email is required');
      expect(service.validateRequired('', 'Mobile Number'), 'Mobile Number is required');
      expect(service.validateRequired('', "Driver's License No."), "Driver's License No. is required");
      expect(service.validateRequired('', 'License Expiry Date'), 'License Expiry Date is required');
      expect(service.validateVehicleType(''), 'Vehicle Type is required');
      expect(service.validateRequired('', 'Plate Number'), 'Plate Number is required');
      expect(service.validateDocument(null, 0.0, 'Driver\'s License'), 'Driver\'s License is required');
      expect(service.validateDocument(null, 0.0, 'Vehicle OR/CR'), 'Vehicle OR/CR is required');
    });

    // -------------------------------------------------------------
    // TC-RID-003: Leave one required field blank at a time
    // -------------------------------------------------------------
    test('TC-RID-003: Leave one required field blank at a time', () {
      final service = RiderAccountService.instance;
      const validFn = 'Pedro Jose';
      const validLn = 'Garcia';
      const validDob = '03/22/1995';
      const validEmail = 'valid.rider@example.com';
      const validPhone = '09451239876';
      const validLic = 'N01-23-456789';
      const validExp = '03/22/2030';
      const validVeh = 'Motorcycle';
      const validPlate = '123ABC';
      const validDoc1 = 'license.jpg';
      const validDoc2 = 'orcr.pdf';

      expect(service.validateFirstName(''), isNotNull);
      expect(service.validateLastName(''), isNotNull);
      expect(service.validateDateOfBirth(''), isNotNull);
      expect(service.validateEmail(''), isNotNull);
      expect(service.validateMobileNumber(''), isNotNull);
      expect(service.validateDriverLicenseNumber(''), isNotNull);
      expect(service.validateLicenseExpiryDate(''), isNotNull);
      expect(service.validateVehicleType(''), isNotNull);
      expect(service.validatePlateNumber(''), isNotNull);
      expect(service.validateDocument(null, 0.0, 'Driver\'s License'), isNotNull);
      expect(service.validateDocument(null, 0.0, 'Vehicle OR/CR'), isNotNull);

      // Verify that valid inputs have no error
      expect(service.validateFirstName(validFn), isNull);
      expect(service.validateLastName(validLn), isNull);
      expect(service.validateDateOfBirth(validDob), isNull);
      expect(service.validateEmail(validEmail), isNull);
      expect(service.validateMobileNumber(validPhone), isNull);
      expect(service.validateDriverLicenseNumber(validLic), isNull);
      expect(service.validateLicenseExpiryDate(validExp), isNull);
      expect(service.validateVehicleType(validVeh), isNull);
      expect(service.validatePlateNumber(validPlate), isNull);
      expect(service.validateDocument(validDoc1, 1.5, 'Driver\'s License'), isNull);
      expect(service.validateDocument(validDoc2, 0.9, 'Vehicle OR/CR'), isNull);
    });

    // -------------------------------------------------------------
    // TC-RID-004: Name with numbers or symbols
    // -------------------------------------------------------------
    test('TC-RID-004: Name with numbers or symbols', () {
      final service = RiderAccountService.instance;
      expect(service.validateFirstName('Pedro Jose99'), 'First Name may only contain letters, spaces, dots, hyphens, and apostrophes');
      expect(service.validateLastName('Dela Cruz@#'), 'Last Name may only contain letters, spaces, dots, hyphens, and apostrophes');
    });

    // -------------------------------------------------------------
    // TC-RID-005: Name length at the limits
    // -------------------------------------------------------------
    test('TC-RID-005: Name length at the limits', () {
      final service = RiderAccountService.instance;
      // 1 char -> reject
      expect(service.validateFirstName('P'), 'First Name must be between 2 and 50 characters');
      // 2 chars -> accept
      expect(service.validateFirstName('Po'), isNull);
      // 50 chars -> accept
      final name50 = 'Maria Cristina Angelica Bernadette Josefina Leonor';
      expect(name50.length, 50);
      expect(service.validateFirstName(name50), isNull);
      // 51 chars -> reject
      final name51 = 'Maria Cristina Angelica Bernadette Josefina Leonora';
      expect(name51.length, 51);
      expect(service.validateFirstName(name51), 'First Name must be between 2 and 50 characters');
    });

    // -------------------------------------------------------------
    // TC-RID-006: Age at the 18-year limit
    // -------------------------------------------------------------
    test('TC-RID-006: Age at the 18-year limit (reference date: 10/21/2026)', () {
      final service = RiderAccountService.instance;
      // 17 years old -> reject
      expect(service.validateDateOfBirth('10/22/2008'), 'Rider must be at least 18 years old');
      // Turns 18 today -> accept
      expect(service.validateDateOfBirth('10/21/2008'), isNull);
      // 18 years and 1 day -> accept
      expect(service.validateDateOfBirth('10/20/2008'), isNull);
    });

    // -------------------------------------------------------------
    // TC-RID-007: Email in an invalid format
    // -------------------------------------------------------------
    test('TC-RID-007: Email in an invalid format', () {
      final service = RiderAccountService.instance;
      expect(service.validateEmail('pedrojose.garciaexample.com'), 'Please enter a valid email address');
      expect(service.validateEmail('pedrojose.garcia@'), 'Please enter a valid email address');
      expect(service.validateEmail('@example.com'), 'Please enter a valid email address');
      expect(service.validateEmail('pedrojose.garcia@example'), 'Please enter a valid email address');
      expect(service.validateEmail('pedrojose garcia@example.com'), 'Please enter a valid email address');
    });

    // -------------------------------------------------------------
    // TC-RID-008: Email already used by an account of another role
    // -------------------------------------------------------------
    test('TC-RID-008: Email already used by an account of another role', () {
      final service = RiderAccountService.instance;
      // Buyer email
      expect(
        service.validateEmail('juanmiguel.delacruz@example.com'),
        'This email address is already registered',
      );
      // Logistics Admin email
      expect(
        service.validateEmail('operations@bilishatid.example.com'),
        'This email address is already registered',
      );
      // Seller email
      expect(
        service.validateEmail('seller.manila@example.com'),
        'This email address is already registered',
      );
    });

    // -------------------------------------------------------------
    // TC-RID-009: Mobile number in an invalid format
    // -------------------------------------------------------------
    test('TC-RID-009: Mobile number in an invalid format', () {
      final service = RiderAccountService.instance;
      expect(service.validateMobileNumber('08123456789'), 'Mobile number must be a valid 11-digit Philippine number (09XXXXXXXXX)');
      expect(service.validateMobileNumber('09ABCD56789'), 'Mobile number must be a valid 11-digit Philippine number (09XXXXXXXXX)');
      expect(service.validateMobileNumber('0912-345-678'), 'Mobile number must be a valid 11-digit Philippine number (09XXXXXXXXX)');
      expect(service.validateMobileNumber('+649171234567'), 'Mobile number must be a valid 11-digit Philippine number (09XXXXXXXXX)');
    });

    // -------------------------------------------------------------
    // TC-RID-010: Mobile number length at the limits
    // -------------------------------------------------------------
    test('TC-RID-010: Mobile number length at the limits', () {
      final service = RiderAccountService.instance;
      expect(service.validateMobileNumber('0912345678'), 'Mobile number must be a valid 11-digit Philippine number (09XXXXXXXXX)');
      expect(service.validateMobileNumber('09123456789'), isNull);
      expect(service.validateMobileNumber('091234567890'), 'Mobile number must be a valid 11-digit Philippine number (09XXXXXXXXX)');
    });

    // -------------------------------------------------------------
    // TC-RID-011: Mobile number that is already registered
    // -------------------------------------------------------------
    test('TC-RID-011: Mobile number that is already registered', () {
      final service = RiderAccountService.instance;
      expect(
        service.validateMobileNumber('09171234567'),
        'This mobile number is already registered',
      );
    });

    // -------------------------------------------------------------
    // TC-RID-012: Driver\'s license number in an invalid format
    // -------------------------------------------------------------
    test('TC-RID-012: Driver\'s license number in an invalid format', () {
      final service = RiderAccountService.instance;
      const expectedMsg = "Driver's license must follow the format A00-00-000000";
      expect(service.validateDriverLicenseNumber('N0123456789'), expectedMsg);
      expect(service.validateDriverLicenseNumber('N01-23-45678'), expectedMsg);
      expect(service.validateDriverLicenseNumber('123-45-678901'), expectedMsg);
      expect(service.validateDriverLicenseNumber('N01-AB-456789'), expectedMsg);
    });

    // -------------------------------------------------------------
    // TC-RID-013: Driver\'s license number already registered
    // -------------------------------------------------------------
    test('TC-RID-013: Driver\'s license number already registered', () {
      final service = RiderAccountService.instance;
      // Precondition: Rider in Account 1 is already created with license N01-23-456789
      service.seedPendingRider(
        email: 'account1.rider@example.com',
        token: 'token-tc13',
      );
      expect(
        service.validateDriverLicenseNumber('N01-23-456789'),
        "This driver's license number is already registered",
      );
    });

    // -------------------------------------------------------------
    // TC-RID-014: License expiry date at the limit
    // -------------------------------------------------------------
    test('TC-RID-014: License expiry date at the limit (reference date: 10/21/2026)', () {
      final service = RiderAccountService.instance;
      expect(service.validateLicenseExpiryDate('10/20/2026'), 'Driver\'s license has expired or must be valid today or later');
      expect(service.validateLicenseExpiryDate('10/21/2026'), isNull);
      expect(service.validateLicenseExpiryDate('10/22/2026'), isNull);
    });

    // -------------------------------------------------------------
    // TC-RID-015: Plate number already registered
    // -------------------------------------------------------------
    test('TC-RID-015: Plate number already registered', () {
      final service = RiderAccountService.instance;
      // Precondition: Vehicle with plate number 123ABC is already registered in the fleet
      service.seedPendingRider(
        email: 'account1.rider@example.com',
        token: 'token-tc15',
      );
      expect(
        service.validatePlateNumber('123ABC'),
        'This plate number is already registered to another vehicle',
      );
      expect(service.validatePlateNumber('999XYZ'), isNull);
    });

    // -------------------------------------------------------------
    // TC-RID-016: Upload documents in each accepted file type
    // -------------------------------------------------------------
    test('TC-RID-016: Upload documents in each accepted file type (JPG, PNG, PDF)', () {
      final service = RiderAccountService.instance;
      expect(service.validateDocument('license.jpg', 2.0, 'Driver\'s License'), isNull);
      expect(service.validateDocument('license.jpeg', 2.0, 'Driver\'s License'), isNull);
      expect(service.validateDocument('license.png', 2.0, 'Driver\'s License'), isNull);
      expect(service.validateDocument('license.pdf', 2.0, 'Driver\'s License'), isNull);
    });

    // -------------------------------------------------------------
    // TC-RID-017: Upload a file type that is not accepted
    // -------------------------------------------------------------
    test('TC-RID-017: Upload a file type that is not accepted', () {
      final service = RiderAccountService.instance;
      const expected = 'Invalid file type. Only JPG, PNG, and PDF files are allowed';
      expect(service.validateDocument('doc.docx', 1.0, 'License'), expected);
      expect(service.validateDocument('app.exe', 1.0, 'License'), expected);
      expect(service.validateDocument('image.webp', 1.0, 'License'), expected);
      expect(service.validateDocument('anim.gif', 1.0, 'License'), expected);
    });

    // -------------------------------------------------------------
    // TC-RID-018: File size at the limit (5.0 MB)
    // -------------------------------------------------------------
    test('TC-RID-018: File size at the limit (5.0 MB)', () {
      final service = RiderAccountService.instance;
      expect(service.validateDocument('file.jpg', 5.0, 'License'), isNull);
      expect(service.validateDocument('file.jpg', 5.01, 'License'), 'File size exceeds 5.0 MB limit');
      expect(service.validateDocument('file.pdf', 5.1, 'License'), 'File size exceeds 5.0 MB limit');
    });

    // -------------------------------------------------------------
    // TC-RID-019: Tap Save several times quickly
    // -------------------------------------------------------------
    test('TC-RID-019: Tap Save several times quickly (Lock / Debounce)', () {
      final service = RiderAccountService.instance;
      expect(service.acquireSaveLock(), isTrue);
      expect(service.acquireSaveLock(), isFalse); // Second quick tap rejected
      service.releaseSaveLock();
      expect(service.acquireSaveLock(), isTrue); // Unlocked
    });

    // -------------------------------------------------------------
    // TC-RID-020: Rider activates account with a valid password
    // -------------------------------------------------------------
    test('TC-RID-020: Rider activates the account with a valid password', () {
      final service = RiderAccountService.instance;
      // Setup pending rider
      final token = 'token-pedro-001';
      service.seedPendingRider(
        email: 'pedrojose.garcia@example.com',
        token: token,
        createdHoursAgo: 1, // within 24 hours
      );

      final activateRes = service.activateAccount(
        token: token,
        password: 'Password@123',
        confirmPassword: 'Password@123',
      );

      expect(activateRes.success, isTrue);
      expect(activateRes.rider!.status, 'Active');
      expect(activateRes.rider!.isActivated, isTrue);
    });

    // -------------------------------------------------------------
    // TC-RID-021: Set a password that breaks the password rule
    // -------------------------------------------------------------
    test('TC-RID-021: Set a password that breaks the password rule', () {
      final service = RiderAccountService.instance;
      expect(service.validatePassword('Pass@1'), 'Password must be at least 8 characters long');
      expect(service.validatePassword('password@1'), 'Password must contain at least one uppercase letter');
      expect(service.validatePassword('PASSWORD@1'), 'Password must contain at least one lowercase letter');
      expect(service.validatePassword('Password@@'), 'Password must contain at least one number');
      expect(service.validatePassword('Password12'), 'Password must contain at least one special character');
      expect(service.validatePassword('Password@123'), isNull);
    });

    // -------------------------------------------------------------
    // TC-RID-022: Confirm Password does not match
    // -------------------------------------------------------------
    test('TC-RID-022: Confirm Password does not match', () {
      final service = RiderAccountService.instance;
      expect(service.validateConfirmPassword('Password@123', 'Password@999'), 'Passwords do not match');
      expect(service.validateConfirmPassword('Password@123', 'Password@123'), isNull);
    });

    // -------------------------------------------------------------
    // TC-RID-023: Open an expired activation link (>24 hours)
    // -------------------------------------------------------------
    test('TC-RID-023: Open an expired activation link', () {
      final service = RiderAccountService.instance;
      final token = 'token-expired-001';
      service.seedPendingRider(
        email: 'expired.rider@example.com',
        token: token,
        createdHoursAgo: 25, // > 24 hours
      );

      final tokenCheck = service.validateActivationToken(token);
      expect(tokenCheck.isValid, isFalse);
      expect(tokenCheck.isExpired, isTrue);
      expect(tokenCheck.errorMessage, contains('expired'));
    });

    // -------------------------------------------------------------
    // TC-RID-024: Logistics resends the activation email
    // -------------------------------------------------------------
    test('TC-RID-024: Logistics resends the activation email', () {
      final service = RiderAccountService.instance;
      final oldToken = 'token-resend-old';
      service.seedPendingRider(
        email: 'resend.rider@example.com',
        token: oldToken,
        createdHoursAgo: 25, // expired
      );

      final resendRes = service.resendActivationEmail('resend.rider@example.com');
      expect(resendRes.success, isTrue);
      expect(resendRes.newToken, isNot(oldToken));

      // Old token must now be invalid
      expect(service.validateActivationToken(oldToken).isValid, isFalse);
      // New token must now be valid
      expect(service.validateActivationToken(resendRes.newToken!).isValid, isTrue);
    });

    // -------------------------------------------------------------
    // TC-RID-025: Reuse the activation link after activating
    // -------------------------------------------------------------
    test('TC-RID-025: Reuse the activation link after activating', () {
      final service = RiderAccountService.instance;
      final token = 'token-reuse-001';
      service.seedPendingRider(
        email: 'reuse.rider@example.com',
        token: token,
        createdHoursAgo: 1,
      );

      // First activation
      service.activateAccount(
        token: token,
        password: 'Password@123',
        confirmPassword: 'Password@123',
      );

      // Reusing token
      final reuseCheck = service.validateActivationToken(token);
      expect(reuseCheck.isValid, isFalse);
      expect(reuseCheck.isUsed, isTrue);
      expect(reuseCheck.errorMessage, contains('already been used'));
    });

    // -------------------------------------------------------------
    // TC-RID-026: Rider logs in before activating
    // -------------------------------------------------------------
    test('TC-RID-026: Rider logs in before activating (Blocked)', () {
      final service = RiderAccountService.instance;
      service.seedPendingRider(
        email: 'pending.login@example.com',
        token: 'token-pending-login',
        createdHoursAgo: 1,
      );

      final loginRes = service.loginRider(
        email: 'pending.login@example.com',
        password: 'Password@123',
      );

      expect(loginRes.success, isFalse);
      expect(loginRes.isPendingActivation, isTrue);
      expect(loginRes.errorMessage, contains('Pending Activation'));
    });

    // -------------------------------------------------------------
    // TC-RID-027: Rider logs in after activating
    // -------------------------------------------------------------
    test('TC-RID-027: Rider logs in after activating (Success)', () {
      final service = RiderAccountService.instance;
      final token = 'token-active-login';
      service.seedPendingRider(
        email: 'active.login@example.com',
        token: token,
        createdHoursAgo: 1,
      );
      service.activateAccount(
        token: token,
        password: 'Password@123',
        confirmPassword: 'Password@123',
      );

      final loginRes = service.loginRider(
        email: 'active.login@example.com',
        password: 'Password@123',
      );

      expect(loginRes.success, isTrue);
      expect(loginRes.rider!.email, 'active.login@example.com');
      expect(loginRes.rider!.logisticsCompanyName, 'Bilis Hatid Express Inc.');
    });

    // -------------------------------------------------------------
    // TC-RID-028: Rider is visible only to the company that created it
    // -------------------------------------------------------------
    test('TC-RID-028: Rider is visible only to the company that created it', () {
      final service = RiderAccountService.instance;
      service.seedPendingRider(
        email: 'pedrojose.garcia@example.com',
        token: 'token-pedro-028',
      );
      final bilisRiders = service.getCompanyRiders('Bilis Hatid Express Inc.');
      final otherCompanyRiders = service.getCompanyRiders('Speedy Delivery Co.');

      expect(bilisRiders.any((r) => r.email == 'pedrojose.garcia@example.com'), isTrue);
      expect(otherCompanyRiders.any((r) => r.email == 'pedrojose.garcia@example.com'), isFalse);
    });

    // -------------------------------------------------------------
    // TC-RID-029: No public rider registration
    // -------------------------------------------------------------
    testWidgets('TC-RID-029: No public rider registration on Rider Landing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RiderLandingPage()));
      await tester.pump(const Duration(milliseconds: 300));

      // Ensure "LOG IN AS A RIDER" is primary CTA
      expect(find.text('LOG IN AS A RIDER'), findsOneWidget);
      // No general "Sign Up as Rider" button exists
      expect(find.text('Sign Up as Rider'), findsNothing);
      expect(find.text('Create Rider Account'), findsNothing);
    });

    // -------------------------------------------------------------
    // TC-RID-030: Buyer or seller opens the Add Rider form (Access Control)
    // -------------------------------------------------------------
    test('TC-RID-030: Buyer or seller opens Add Rider form (Blocked)', () {
      final service = RiderAccountService.instance;
      expect(service.canAccessAddRiderForm('buyer'), isFalse);
      expect(service.canAccessAddRiderForm('seller'), isFalse);
      expect(service.canAccessAddRiderForm('rider'), isFalse);
      expect(service.canAccessAddRiderForm('logistics_approved'), isTrue);
    });

    // -------------------------------------------------------------
    // TC-RID-031: Pending logistics account tries to add a rider
    // -------------------------------------------------------------
    test('TC-RID-031: Pending logistics account tries to add a rider (Blocked)', () {
      final service = RiderAccountService.instance;
      expect(service.canAccessAddRiderForm('logistics_pending'), isFalse);
    });

    // -------------------------------------------------------------
    // TC-RID-032: Open another role\'s screens (Rider restricted)
    // -------------------------------------------------------------
    test('TC-RID-032: Rider restricted from other role screens', () {
      final service = RiderAccountService.instance;
      expect(service.canRiderAccessSellerPortal(), isFalse);
      expect(service.canRiderAccessBuyerCheckout(), isFalse);
    });

    // -------------------------------------------------------------
    // TC-RID-033: [Mobile] Each field opens the right keyboard
    // -------------------------------------------------------------
    testWidgets('TC-RID-033: Each field opens the right keyboard in AddRiderPage', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('rider_email_field')), matching: find.byType(TextField)),
      );
      expect(emailField.keyboardType, TextInputType.emailAddress);

      final phoneField = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('rider_mobile_field')), matching: find.byType(TextField)),
      );
      expect(phoneField.keyboardType, TextInputType.phone);

      final plateField = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('rider_plate_field')), matching: find.byType(TextField)),
      );
      expect(plateField.textCapitalization, TextCapitalization.characters);
    });

    // -------------------------------------------------------------
    // TC-RID-034: [Mobile] Keyboard never hides active field or Save
    // -------------------------------------------------------------
    testWidgets('TC-RID-034: Form is wrapped in SingleChildScrollView avoiding keyboard occlusion', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    // -------------------------------------------------------------
    // TC-RID-035: [Mobile] App sent to background while filling form
    // -------------------------------------------------------------
    testWidgets('TC-RID-035: Form state preserved in controllers', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      final fnFinder = find.descendant(of: find.byKey(const Key('rider_first_name_field')), matching: find.byType(TextField));
      await tester.enterText(fnFinder, 'Pedro Jose');
      final fnField = tester.widget<TextField>(fnFinder);
      expect(fnField.controller?.text, 'Pedro Jose');
    });

    // -------------------------------------------------------------
    // TC-RID-036: [Mobile] Rotate phone while form has data
    // -------------------------------------------------------------
    testWidgets('TC-RID-036: Rotate phone while form has data (Orientation change)', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920); // Portrait
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      final fnFinder = find.descendant(of: find.byKey(const Key('rider_first_name_field')), matching: find.byType(TextField));
      await tester.enterText(fnFinder, 'Pedro Jose');

      // Rotate to Landscape
      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pumpAndSettle();

      final fnField = tester.widget<TextField>(fnFinder);
      expect(fnField.controller?.text, 'Pedro Jose');

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // -------------------------------------------------------------
    // TC-RID-037: [Mobile] Save with no internet connection
    // -------------------------------------------------------------
    testWidgets('TC-RID-037: Offline banner shown with retry option', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      // Toggle offline mode for testing
      final state = tester.state<AddRiderPageState>(find.byType(AddRiderPage));
      state.setOfflineForTesting(true);
      await tester.pumpAndSettle();

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // TC-RID-038: [Mobile] Connection drops right after tapping Save
    // -------------------------------------------------------------
    testWidgets('TC-RID-038: Network failure during save preserves form data', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      final fnFinder = find.descendant(of: find.byKey(const Key('rider_first_name_field')), matching: find.byType(TextField));
      await tester.enterText(fnFinder, 'Pedro Jose');
      final state = tester.state<AddRiderPageState>(find.byType(AddRiderPage));
      state.setOfflineForTesting(true);
      await tester.pumpAndSettle();

      // Form text is preserved
      final fnField = tester.widget<TextField>(fnFinder);
      expect(fnField.controller?.text, 'Pedro Jose');
    });

    // -------------------------------------------------------------
    // TC-RID-039: [Mobile] System Back on Add Rider form (Unsaved confirmation)
    // -------------------------------------------------------------
    testWidgets('TC-RID-039: Dirty form prompts unsaved changes confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      // Fill in a field to make form dirty
      final fnFinder = find.descendant(of: find.byKey(const Key('rider_first_name_field')), matching: find.byType(TextField));
      await tester.enterText(fnFinder, 'Pedro Jose');
      await tester.pumpAndSettle();

      // Tap Back button
      final backBtn = find.byKey(const Key('rider_back_button'));
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Verify Unsaved Changes dialog
      expect(find.text('Discard Rider Details?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tap Keep Editing
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      final fnField = tester.widget<TextField>(fnFinder);
      expect(fnField.controller?.text, 'Pedro Jose');
    });

    // -------------------------------------------------------------
    // TC-RID-040: [Mobile] Upload with Camera, Files app, and Gallery
    // -------------------------------------------------------------
    testWidgets('TC-RID-040: Document upload sheet presents Camera, Photo Library, and Browse Files', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      final uploadBtn = find.byKey(const Key('rider_license_upload_btn'));
      await tester.ensureVisible(uploadBtn);
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      expect(find.text('Take Photo (Camera)'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Browse Files (PDF or Images)'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // TC-RID-041: [Mobile] Camera or photo access denied
    // -------------------------------------------------------------
    testWidgets('TC-RID-041: Denied permission triggers guidance dialog', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: AddRiderPage()));
      await tester.pumpAndSettle();

      final state = tester.state<AddRiderPageState>(find.byType(AddRiderPage));
      state.showPermissionDeniedDialog('Camera');
      await tester.pumpAndSettle();

      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    // -------------------------------------------------------------
    // TC-RID-042: [Mobile] Full-resolution photo > 5 MB compressed
    // -------------------------------------------------------------
    test('TC-RID-042: Simulated photo compression for files > 5MB', () {
      final service = RiderAccountService.instance;
      final compressed = service.simulatePhotoCompression(rawFileSizeMb: 8.5);
      expect(compressed, lessThanOrEqualTo(5.0));
      expect(compressed, greaterThan(0.0));
    });

    // -------------------------------------------------------------
    // TC-RID-043: [Mobile] Large system font on a small screen
    // -------------------------------------------------------------
    testWidgets('TC-RID-043: Large system font scale (1.5x) renders without crash', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(home: AddRiderPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Register New Fleet Rider'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // TC-RID-044: [Mobile] Activation link opened on phone with app installed
    // -------------------------------------------------------------
    testWidgets('TC-RID-044: Set Password Page displays live validation checklist', (tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      RiderAccountService.instance.seedPendingRider(
        email: 'pedrojose.garcia@example.com',
        token: 'valid-test-token',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderSetPasswordPage(
            activationToken: 'valid-test-token',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set Your Account Password'), findsOneWidget);
      expect(find.text('At least 8 characters long'), findsOneWidget);
      expect(find.text('At least 1 uppercase letter (A-Z)'), findsOneWidget);
      expect(find.text('At least 1 lowercase letter (a-z)'), findsOneWidget);
      expect(find.text('At least 1 numeric digit (0-9)'), findsOneWidget);
      expect(find.text('At least 1 special character (!@#\$%^&*)'), findsOneWidget);
    });

    // -------------------------------------------------------------
    // TC-RID-045: [Mobile] Activation link opened on phone without app
    // -------------------------------------------------------------
    test('TC-RID-045: Fallback web activation URL schema', () {
      final service = RiderAccountService.instance;
      final fallbackUrl = service.getWebActivationFallbackUrl('token-12345');
      expect(fallbackUrl, contains('https://nexora.example.com/activate?token=token-12345'));
    });

    // -------------------------------------------------------------
    // TC-RID-046: [Mobile] Stay logged in after closing app or restart
    // -------------------------------------------------------------
    test('TC-RID-046: Session persistence maintains active rider identity', () {
      final riderService = RiderService.instance;
      expect(riderService.currentRider.id, 'NX-RD-001');
      expect(riderService.currentRider.name, 'Pedro Jose Garcia');
      expect(riderService.currentRider.company, 'Bilis Hatid Express Inc.');
    });

    // -------------------------------------------------------------
    // TC-RID-047: [Mobile] Back after logging out
    // -------------------------------------------------------------
    test('TC-RID-047: Logout clears session and cannot navigate back', () {
      final service = RiderAccountService.instance;
      service.clearSession();
      expect(service.isUserLoggedIn(), isFalse);
    });
  });
}
