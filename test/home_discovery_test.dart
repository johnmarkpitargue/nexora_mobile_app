import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/category_section.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/featured_products_section.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';

void main() {
  testWidgets('category rail maps concise labels to real product categories', (
    tester,
  ) async {
    String? selectedCategory;

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return CategorySection(
                  selectedCategory: selectedCategory,
                  onCategorySelected: (category) {
                    setState(() => selectedCategory = category);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Find your next favorite.'), findsOneWidget);
    expect(find.byKey(const ValueKey('browse-all-categories')), findsOneWidget);
    expect(find.text('Beauty'), findsNothing);
    expect(find.text('Sports'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('category-apparel-fashion')),
      260,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('editorial-category-rail')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('category-apparel-fashion')));
    await tester.pumpAndSettle();
    expect(selectedCategory, 'Apparel & Fashion');

    await tester.tap(find.byKey(const ValueKey('category-apparel-fashion')));
    await tester.pumpAndSettle();
    expect(selectedCategory, isNull);
  });

  testWidgets('editorial category story fits compact screens and large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 900),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: CategorySection(
                selectedCategory: null,
                onCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Find your next favorite.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('editorial-category-rail')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery grid filters products without unrelated fallback', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 900));

    final expectedCount = DailyDiscoverSection.allProducts
        .where((product) => product.category == 'Apparel & Fashion')
        .length;

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: DailyDiscoverSection(selectedCategory: 'Apparel & Fashion'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Apparel & Fashion'), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(expectedCount));
    expect(find.text('Loading more recommendations...'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product card fits the compact two-column width', (tester) async {
    const product = ProductModel(
      id: 'compact-card',
      title: 'Ultra High Performance Mechanical Wireless Keyboard with RGB Backlight',
      imageUrl: '',
      category: 'Gaming',
      discountTag: '-45%',
      price: '₱3,890.00',
      originalPrice: '₱5,200',
      rating: 4.9,
      soldCount: '1.2k',
      shippingTag: 'Next Day Delivery | Metro Manila',
      hasVoucher: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 138,
              height: 292,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('₱3,890.00'), findsOneWidget);
    expect(find.text('[Mall] '), findsNothing);
  });

  testWidgets('discovery grid adapts from two to four columns', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final layout in <(double, int)>[(390, 2), (560, 3), (760, 4)]) {
      await tester.binding.setSurfaceSize(Size(layout.$1, 900));
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(child: DailyDiscoverSection()),
          ),
        ),
      );
      await tester.pump();

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, layout.$2);
      expect(tester.takeException(), isNull);
    }
  });
}
