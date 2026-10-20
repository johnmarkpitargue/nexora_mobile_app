import 'package:flutter/material.dart';
import '../../features/auth/presentation/landing_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/rider_registration_page.dart';
import '../../features/home/presentation/homepage.dart';
import '../../features/orders/presentation/orders_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/checkout/presentation/checkout_page.dart';
import '../../features/product_details/presentation/product_details_page.dart';
import '../../features/cart/presentation/cart_page.dart';

import '../../core/services/order_service.dart';
import '../../core/models/shop_models.dart';
import '../../features/orders/presentation/order_details_page.dart';
import '../../features/orders/presentation/shipped_order_details_page.dart';
import '../../features/orders/presentation/rate_product_page.dart';
import '../../features/profile/presentation/my_addresses_page.dart';
import '../../features/profile/presentation/new_address_page.dart';
import '../../features/profile/presentation/wishlist_page.dart';
import '../../features/orders/presentation/customer_mock_order_screen.dart';
import '../../features/orders/presentation/order_tracking_screen.dart';
import '../../features/shop/presentation/shop_page.dart';

/// Centralized application routes configuration located in lib/app/routes
class AppRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String riderRegister = '/rider-register';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String checkout = '/checkout';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String shop = '/shop';
  static const String orderDetails = '/order-details';
  static const String shippedOrderDetails = '/shipped-order-details';
  static const String orderTracking = '/order-tracking';
  static const String rateProduct = '/rate-product';
  static const String myAddresses = '/my-addresses';
  static const String newAddress = '/new-address';
  static const String wishlist = '/wishlist';
  static const String customerMockOrder = '/mock-order';

  static Map<String, WidgetBuilder> get routes => {
        landing: (context) => const LandingPage(),
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        riderRegister: (context) => const RiderRegistrationPage(),
        home: (context) => const NexoraHomePage(),
        orders: (context) => const OrdersPage(),
        chat: (context) => const ChatPage(),
        profile: (context) => const ProfilePage(),
        checkout: (context) => const CheckoutPage(),
        productDetails: (context) => const ProductDetailsPage(),
        cart: (context) => const CartPage(),
        shop: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is ShopModel) {
            return ShopPage(initialShop: args);
          } else if (args is String) {
            return ShopPage(shopId: args);
          }
          return const ShopPage();
        },
        customerMockOrder: (context) => const CustomerMockOrderScreen(),
        orderDetails: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is OrderItemModel) {
            return OrderDetailsPage(order: args);
          }
          return const OrderDetailsPage();
        },
        shippedOrderDetails: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is OrderItemModel) {
            return ShippedOrderDetailsPage(order: args);
          }
          return const ShippedOrderDetailsPage();
        },
        orderTracking: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is OrderItemModel) {
            return OrderTrackingScreen(orderId: args.orderId, orderItem: args);
          } else if (args is String) {
            return OrderTrackingScreen(orderId: args);
          }
          return const OrderTrackingScreen();
        },
        rateProduct: (context) => const RateProductPage(),
        myAddresses: (context) => const MyAddressesPage(),
        newAddress: (context) => const NewAddressPage(),
        wishlist: (context) => const WishlistPage(),
      };
}

