import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/features/cart/presentation/cart_page.dart';
import 'package:nexora_flutter_app/features/checkout/presentation/checkout_page.dart';
import 'package:nexora_flutter_app/features/checkout/presentation/widgets/shipping_option_modal.dart';

void main() {
  setUp(() async {
    await BuyerAccountService.instance.resetState();
    CartService.instance.clearCart();
  });

  testWidgets('empty cart teaches the next action at compact width', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 760));

    await tester.pumpWidget(
      _app(
        const CartPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Your Shopping Cart is Empty'), findsOneWidget);
    expect(find.text('Start Shopping'), findsOneWidget);
  });

  testWidgets('cart review and editing remain usable with large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    CartService.instance.addToCart(
      title: 'Nexora Studio Wireless Headphones',
      variant: 'Midnight Navy',
      price: 2499,
      originalPrice: 2999,
      imageUrl: 'invalid://cart-image',
      storeName: 'Nexora Official Store',
      storeBadge: 'OFFICIAL STORE',
      discountTag: 'SAVE 17%',
    );

    await tester.pumpWidget(
      _app(
        const CartPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('cart-edit-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('cart-checkout-action')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('cart-scroll-view')),
      const Offset(0, -240),
    );
    await tester.pump();
    expect(find.text('Nexora Official Store'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cart-edit-action')));
    await tester.pump();
    expect(find.text('Move to My Likes'), findsOneWidget);
    expect(find.text('Delete (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout decisions fit compact screens and 200 percent text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    _seedSignedInBuyer();
    AddressService.instance.resetState();
    CartService.instance.buyNow(
      title: 'Nexora Studio Wireless Headphones',
      variant: 'Midnight Navy',
      price: 2499,
      originalPrice: 2999,
      imageUrl: 'invalid://checkout-image',
      storeName: 'Nexora Official Store',
      storeBadge: 'OFFICIAL STORE',
    );

    await tester.pumpWidget(
      _app(
        const CheckoutPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CheckoutPage), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('checkout-address-section')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('OFFICIAL STORE'),
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('checkout-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('OFFICIAL STORE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Shop Voucher'),
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('checkout-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Shop Voucher'), findsOneWidget);
    expect(find.text('Message for Seller'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('checkout-place-order-action')),
      findsOneWidget,
    );
  });

  testWidgets(
    'shipping options expose delivery and pickup choices accessibly',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(320, 760));

      await tester.pumpWidget(
        _app(
          const ShippingOptionModal(
            initialSelection: ShippingOptionResult(
              methodType: 'door_to_door',
              optionName: 'Standard Local',
              estimatedDate: '8 - 9 Oct',
              shippingFee: 0,
            ),
          ),
          textScaler: const TextScaler.linear(2),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Door-to-door'), findsOneWidget);
      expect(find.text('Self pick-up'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Standard Local'),
        120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('shipping-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Standard Local'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Priority Next-Day'),
        120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('shipping-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Priority Next-Day'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('confirm-shipping-option')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Self pick-up'),
        -120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('shipping-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Self pick-up'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Liliw Central Pick-Up Hub'),
        120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('shipping-options-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Liliw Central Pick-Up Hub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

void _seedSignedInBuyer() {
  BuyerAccountService.instance.seedLoggedInBuyer(
    firstName: 'Phase',
    lastName: 'Eight',
    email: 'phase8@nexora.test',
    mobileNumber: '09171234567',
    password: 'Password123!',
  );
}

Widget _app(
  Widget home, {
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: NexoraTheme.lightTheme,
    home: home,
    routes: {
      '/home': (_) => const Scaffold(body: Text('Home')),
      '/checkout': (_) => const CheckoutPage(),
      '/my-addresses': (_) => const Scaffold(body: Text('Addresses')),
    },
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: child!,
    ),
  );
}
