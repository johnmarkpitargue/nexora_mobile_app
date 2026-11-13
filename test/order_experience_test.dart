import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/features/orders/presentation/order_details_page.dart';
import 'package:nexora_flutter_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:nexora_flutter_app/features/orders/presentation/orders_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BuyerAccountService.instance.resetState();
    OrderService.instance.clearAllOrders();
  });

  testWidgets('order hub stays scannable at compact width and large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    final order = _seedActiveOrder();

    await tester.pumpWidget(
      _app(
        const OrdersPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.byKey(const ValueKey('orders-filter-0')), findsOneWidget);
    expect(find.byKey(ValueKey('order-card-${order.orderId}')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('orders-search-action')));
    await tester.pump();
    expect(find.byKey(const ValueKey('orders-search-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('orders-search-field')),
      'headphones',
    );
    await tester.pump();
    expect(find.byKey(ValueKey('order-card-${order.orderId}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('newcomer order state remains usable at 200 percent text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    _seedBuyer();

    await tester.pumpWidget(
      _app(
        const OrdersPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome to Nexora, Phase!'), findsOneWidget);
    expect(find.byKey(const ValueKey('orders-newcomer-hub')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Claim Voucher'),
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('orders-newcomer-hub')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('₱150 Welcome Voucher'), findsOneWidget);
    expect(find.text('Claim Voucher'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('order details prioritize status, delivery, and payment', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    final order = _seedActiveOrder();

    await tester.pumpWidget(
      _app(
        OrderDetailsPage(order: order),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('To Ship'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('order-details-scroll-view')),
      findsOneWidget,
    );
    expect(find.text('Get help'), findsOneWidget);
  });

  testWidgets('tracking header adapts and honors reduced motion', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 760));
    final order = _seedActiveOrder();
    OrderService.instance.markAsToReceive(order.orderId);
    final inTransit = OrderService.instance.activeOrders.first;

    await tester.pumpWidget(
      _app(
        OrderTrackingScreen(orderId: inTransit.orderId, orderItem: inTransit),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Track order'), findsOneWidget);
    expect(find.byTooltip('Live tracking active'), findsOneWidget);
  });
}

void _seedBuyer() {
  BuyerAccountService.instance.seedLoggedInBuyer(
    firstName: 'Phase',
    lastName: 'Nine',
    email: 'phase9@nexora.test',
    mobileNumber: '09171234567',
    password: 'Password123!',
  );
  OrderService.instance.clearActiveUserOrders();
}

OrderItemModel _seedActiveOrder() {
  _seedBuyer();
  OrderService.instance.placeOrder(
    items: [
      CartItemModel(
        id: 'phase9-item',
        storeName: 'Nexora Official Store',
        storeBadge: 'OFFICIAL STORE',
        title: 'Nexora Studio Wireless Headphones',
        variant: 'Midnight Navy',
        imageUrl: 'invalid://order-image',
        price: 2499,
        originalPrice: 2999,
      ),
    ],
    totalPrice: 2499,
    paymentMethod: 'Cash on Delivery',
    recipientName: 'Phase Nine',
    recipientPhone: '09171234567',
    shippingAddress: '192 Poblacion St, Liliw, Laguna 4004',
    estimatedArrival: '8 - 9 Nov',
    deliveryLat: 14.1332,
    deliveryLng: 121.4367,
  );
  return OrderService.instance.activeOrders.first;
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
      '/chat': (_) => const Scaffold(body: Text('Chat')),
      '/order-tracking': (_) => const Scaffold(body: Text('Tracking')),
      '/rate-product': (_) => const Scaffold(body: Text('Rate')),
      '/product-details': (_) => const Scaffold(body: Text('Product')),
      '/order-details': (_) => const Scaffold(body: Text('Details')),
      '/shipped-order-details': (_) => const Scaffold(body: Text('Shipped')),
    },
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: child!,
    ),
  );
}
