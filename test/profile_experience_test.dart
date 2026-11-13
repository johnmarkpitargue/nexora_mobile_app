import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/features/profile/presentation/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BuyerAccountService.instance.resetState();
  });

  testWidgets('guest profile stays clear at compact width and large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));

    await tester.pumpWidget(
      _app(
        const ProfilePage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Welcome to Nexora'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-identity-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-logout-action')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'signed-in profile exposes essentials without duplicate dock actions',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 900));
      _seedBuyer();

      await tester.pumpWidget(
        _app(
          const ProfilePage(),
          textScaler: const TextScaler.linear(2),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(find.text('Phase Eleven'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
      expect(tester.takeException(), isNull);

      await _scrollProfileUntilVisible(tester, find.text('Payment methods'));
      expect(find.text('Payment methods'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile account rows open their real destinations', (
    tester,
  ) async {
    _seedBuyer();
    await tester.pumpWidget(_app(const ProfilePage()));
    await tester.pump();

    await _scrollProfileUntilVisible(tester, find.text('My addresses'));
    await tester.tap(find.text('My addresses'));
    await tester.pumpAndSettle();

    expect(find.text('Addresses destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile hierarchy holds in both light and dark themes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    _seedBuyer();

    for (final theme in [NexoraTheme.lightTheme, NexoraTheme.darkTheme]) {
      await tester.pumpWidget(_app(const ProfilePage(), theme: theme));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('profile-identity-card')),
        findsOneWidget,
      );
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Addresses'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('logout confirmation remains usable with large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    _seedBuyer();

    await tester.pumpWidget(
      _app(
        const ProfilePage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    await _scrollProfileUntilVisible(
      tester,
      find.byKey(const ValueKey('profile-logout-action')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-logout-action')));
    await tester.pump();

    expect(find.text('Log Out of Nexora?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _seedBuyer() {
  BuyerAccountService.instance.seedLoggedInBuyer(
    firstName: 'Phase',
    lastName: 'Eleven',
    email: 'phase11@nexora.test',
    mobileNumber: '09171234567',
    password: 'Password123!',
  );
}

Future<void> _scrollProfileUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  await tester.scrollUntilVisible(
    target,
    260,
    scrollable: find.descendant(
      of: find.byKey(const ValueKey('profile-dashboard-scroll')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pump();
}

Widget _app(
  Widget home, {
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? NexoraTheme.lightTheme,
    home: home,
    routes: {
      AppRoutes.login: (_) => const Scaffold(body: Text('Login destination')),
      AppRoutes.orders: (_) => const Scaffold(body: Text('Orders destination')),
      AppRoutes.wishlist: (_) =>
          const Scaffold(body: Text('Wishlist destination')),
      AppRoutes.followedStores: (_) =>
          const Scaffold(body: Text('Following destination')),
      AppRoutes.myAddresses: (_) =>
          const Scaffold(body: Text('Addresses destination')),
      AppRoutes.paymentMethods: (_) =>
          const Scaffold(body: Text('Payments destination')),
      AppRoutes.notificationPreferences: (_) =>
          const Scaffold(body: Text('Notifications destination')),
      AppRoutes.chat: (_) => const Scaffold(body: Text('Support destination')),
    },
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: child!,
    ),
  );
}
