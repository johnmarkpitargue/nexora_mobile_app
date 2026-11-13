import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/features/auth/presentation/email_verification_page.dart';
import 'package:nexora_flutter_app/features/auth/presentation/forgot_password_page.dart';
import 'package:nexora_flutter_app/features/auth/presentation/landing_page.dart';
import 'package:nexora_flutter_app/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('landing stays usable at compact width and 200 percent text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));

    await tester.pumpWidget(
      _authApp(
        const LandingPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Good finds, without the noise.'), findsOneWidget);
    expect(find.text('Studio Pro headphones'), findsOneWidget);
    expect(find.text('Explore the shop'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('landing carousel communicates position and supports swiping', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(
      _authApp(const LandingPage(), disableAnimations: true),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Featured product 1 of 3'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('landing-product-stories')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Featured product 2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('landing actions open their real destinations', (tester) async {
    await tester.pumpWidget(
      _authApp(const LandingPage(), disableAnimations: true),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('landing-sign-in-action')));
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);

    Navigator.of(tester.element(find.text('Login destination'))).pop();
    await tester.pumpAndSettle();
    final registerAction = find.byKey(
      const ValueKey('landing-register-action'),
    );
    await tester.ensureVisible(registerAction);
    await tester.pumpAndSettle();
    await tester.tap(registerAction);
    await tester.pumpAndSettle();
    expect(find.text('Register destination'), findsOneWidget);

    Navigator.of(tester.element(find.text('Register destination'))).pop();
    await tester.pumpAndSettle();
    final exploreAction = find.byKey(const ValueKey('landing-explore-action'));
    await tester.ensureVisible(exploreAction);
    await tester.pumpAndSettle();
    await tester.tap(exploreAction);
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
  });

  testWidgets('sign in exposes clear fields and accessible password action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 760));

    await tester.pumpWidget(_authApp(const LoginPage()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email or Mobile'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('password recovery shows progress and honors reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _authApp(const ForgotPasswordPage(), disableAnimations: true),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Send verification code'), findsOneWidget);
  });

  testWidgets('verification code fields fit compact screens', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 720));

    await tester.pumpWidget(
      _authApp(
        const EmailVerificationPage(email: 'shopper@example.com'),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Verify your email'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Six digit verification code'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(6));
    semantics.dispose();
  });
}

Widget _authApp(
  Widget home, {
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: NexoraTheme.lightTheme,
    routes: {
      AppRoutes.login: (_) => const Scaffold(body: Text('Login destination')),
      AppRoutes.register: (_) =>
          const Scaffold(body: Text('Register destination')),
      AppRoutes.home: (_) => const Scaffold(body: Text('Home destination')),
    },
    home: Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: home,
        );
      },
    ),
  );
}
