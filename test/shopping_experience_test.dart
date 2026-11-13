import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import 'package:nexora_flutter_app/features/home/presentation/search_browse_page.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/shopping_components.dart';
import 'package:nexora_flutter_app/features/product_details/presentation/product_details_page.dart';
import 'package:nexora_flutter_app/features/profile/presentation/wishlist_page.dart';
import 'package:nexora_flutter_app/features/shop/presentation/shop_page.dart';

void main() {
  setUp(() {
    BuyerAccountService.instance.resetState();
    WishlistService.instance.clearWishlist();
  });

  testWidgets('search uses an adaptive product grid and clear controls', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final layout in <(double, int)>[(390, 2), (760, 4)]) {
      await tester.binding.setSurfaceSize(Size(layout.$1, 900));
      await tester.pumpWidget(_app(const SearchBrowsePage()));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('shopping-search-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('shopping-filter-action')),
        findsOneWidget,
      );
      expect(find.byType(ProductCard), findsWidgets);

      final grid = tester.widget<GridView>(
        find.descendant(
          of: find.byType(ShoppingProductGrid),
          matching: find.byType(GridView),
        ),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, layout.$2);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('filter sheet explains an invalid price range', (tester) async {
    await tester.pumpWidget(_app(const SearchBrowsePage()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('shopping-filter-action')));
    await tester.pumpAndSettle();
    expect(find.text('Filter products'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Minimum'), '5000');
    await tester.enterText(find.widgetWithText(TextField, 'Maximum'), '100');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Show results'));
    await tester.pump();

    expect(
      find.text('Minimum price cannot exceed maximum price.'),
      findsOneWidget,
    );
  });

  testWidgets('wishlist teaches the empty state and renders saved products', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const WishlistPage()));
    await tester.pump();

    expect(find.text('Save products for later'), findsOneWidget);
    expect(find.text('Discover products'), findsOneWidget);

    final product = ShopService.allAppProducts.first;
    WishlistService.instance.addToWishlist(product);
    await tester.pump();

    expect(find.text(product.title), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
    expect(
      find.byTooltip('Remove ${product.title} from wishlist'),
      findsOneWidget,
    );
  });

  testWidgets('product decisions fit compact width and large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    final product = ShopService.allAppProducts.first;

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: RouteSettings(arguments: product),
          builder: (_) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: const ProductDetailsPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);
    expect(find.text('Buy Now'), findsOneWidget);
    expect(find.byTooltip('Chat with shop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store surface respects compact width and reduced motion', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 820));
    final shop = ShopService.instance.getShopById('nexora_official');

    await tester.pumpWidget(
      _app(ShopPage(initialShop: shop), disableAnimations: true),
    );
    await tester.pump();

    expect(find.text(shop.name), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: NexoraTheme.lightTheme,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: home,
      ),
    ),
  );
}
