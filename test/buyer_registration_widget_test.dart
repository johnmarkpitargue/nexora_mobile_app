import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/features/auth/presentation/register_page.dart';
import 'package:nexora_flutter_app/core/widgets/google_logo_icon.dart';

void main() {
  setUp(() {
    BuyerAccountService.instance.resetState();
  });

  testWidgets('RegisterPage renders all required fields and buttons per black-box spec', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Get ₱150 voucher + free shipping on 1st order!'), findsOneWidget);

    // Verify Fields
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Must be 18+'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Create Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Have a referral code? (Optional)'), findsOneWidget);

    // Verify Apple / iCloud is removed
    expect(find.byIcon(Icons.apple), findsNothing);
    expect(find.text('Apple'), findsNothing);

    // Verify authentic Google button exists
    expect(find.byType(GoogleLogoIcon), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    // Verify Register Button
    expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);
  });

  testWidgets('RegisterPage submits empty form and triggers all mandatory field errors (TC-BUY-002)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap submit button without entering any data
    final registerBtn = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    // Verify validation error messages
    expect(find.text('First Name is required'), findsOneWidget);
    expect(find.text('Last Name is required'), findsOneWidget);
    expect(find.text('Date of birth is required'), findsOneWidget);
    expect(find.text('Email Address is required'), findsOneWidget);
    expect(find.text('Mobile Number is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });
}
