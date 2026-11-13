import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/category_section.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/featured_products_section.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/floating_nav_dock.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/header_app_bar.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/promo_banners_section.dart';

void main() {
  testWidgets('primary home actions expose concise screen reader labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: Scaffold(
          appBar: const HeaderAppBar(),
          bottomNavigationBar: FloatingNavDock(
            currentIndex: 0,
            cartCount: 1,
            chatUnreadCount: 2,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Search products and brands'), findsOneWidget);
    expect(find.bySemanticsLabel('Wishlist'), findsOneWidget);
    expect(find.bySemanticsLabel('Cart, 1 item'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Messages, 2 unread messages'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('home discovery remains usable at 200 percent text scale', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: Scaffold(
                appBar: const HeaderAppBar(),
                body: const SingleChildScrollView(
                  child: Column(
                    children: [
                      PromoBannersSection(),
                      CategorySection(
                        selectedCategory: null,
                        onCategorySelected: _ignoreCategory,
                      ),
                      DailyDiscoverSection(selectedCategory: 'Gaming'),
                    ],
                  ),
                ),
                bottomNavigationBar: FloatingNavDock(
                  currentIndex: 0,
                  cartCount: 120,
                  chatUnreadCount: 8,
                  onTap: _ignoreIndex,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Shop now'), findsOneWidget);
    expect(find.text('Gaming'), findsWidgets);
    expect(find.text('Messages'), findsOneWidget);
  });

  testWidgets('home controls support right-to-left layout at compact width', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 720));

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: HeaderAppBar(),
            body: SingleChildScrollView(
              child: CategorySection(
                selectedCategory: 'Apparel & Fashion',
                onCategorySelected: _ignoreCategory,
              ),
            ),
            bottomNavigationBar: FloatingNavDock(
              currentIndex: 3,
              cartCount: 3,
              chatUnreadCount: 12,
              onTap: _ignoreIndex,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Fashion'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
  });
}

void _ignoreCategory(String? _) {}

void _ignoreIndex(int _) {}
