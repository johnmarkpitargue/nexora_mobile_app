import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/header_app_bar.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/promo_banners_section.dart';

void main() {
  testWidgets('home header prioritizes search and removes duplicate actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        routes: {
          AppRoutes.search: (_) => const Scaffold(body: Text('Search screen')),
          AppRoutes.wishlist: (_) =>
              const Scaffold(body: Text('Wishlist screen')),
          AppRoutes.notificationPreferences: (_) =>
              const Scaffold(body: Text('Notifications screen')),
        },
        home: const Scaffold(appBar: HeaderAppBar()),
      ),
    );

    expect(find.text('Search products and brands'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-wishlist-action')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-notifications-action')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-search-action')));
    await tester.pumpAndSettle();

    expect(find.text('Search screen'), findsOneWidget);
  });

  testWidgets('wishlist shortcut opens the existing wishlist route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        routes: {
          AppRoutes.wishlist: (_) =>
              const Scaffold(body: Text('Wishlist screen')),
        },
        home: const Scaffold(appBar: HeaderAppBar()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('home-wishlist-action')));
    await tester.pumpAndSettle();

    expect(find.text('Wishlist screen'), findsOneWidget);
  });

  testWidgets('notification shortcut opens preferences without a menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.darkTheme,
        routes: {
          AppRoutes.notificationPreferences: (_) =>
              const Scaffold(body: Text('Notifications screen')),
        },
        home: const Scaffold(appBar: HeaderAppBar()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('home-notifications-action')));
    await tester.pumpAndSettle();

    expect(find.text('Notifications screen'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
  });

  testWidgets('campaign hero has a clear hierarchy and working action', (
    tester,
  ) async {
    Object? routeArguments;

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.search) {
            routeArguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Campaign search')),
            );
          }
          return null;
        },
        home: const Scaffold(body: PromoBannersSection()),
      ),
    );

    expect(find.text('SoundMax Pro 18'), findsOneWidget);
    expect(find.text('Shop now'), findsOneWidget);
    expect(find.text('NEXORA FLAGSHIP'), findsNothing);
    expect(find.text('PRE-ORDER NOW'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('promo-cta-0')));
    await tester.pumpAndSettle();

    expect(find.text('Campaign search'), findsOneWidget);
    expect(routeArguments, 'SoundMax Pro 18');
  });

  testWidgets('header and hero fit compact and large phone widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final width in [320.0, 430.0]) {
      await tester.binding.setSurfaceSize(Size(width, 720));
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: const Scaffold(
            appBar: HeaderAppBar(),
            body: SingleChildScrollView(child: PromoBannersSection()),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Header or hero overflowed at ${width.toInt()}px',
      );
    }
  });

  testWidgets('campaign hero remains usable at 200 percent text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 720));

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: const Scaffold(
            body: SingleChildScrollView(child: PromoBannersSection()),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('campaign-hero-rail')), findsOneWidget);
    expect(find.text('Shop now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
