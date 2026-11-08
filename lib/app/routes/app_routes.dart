import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/auth/presentation/landing_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/email_verification_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
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
import '../../features/home/presentation/search_browse_page.dart';
import '../../features/profile/presentation/payment_methods_page.dart';
import '../../features/profile/presentation/notification_preferences_page.dart';
import '../../features/profile/presentation/followed_stores_page.dart';

/// Centralized application routes configuration located in lib/app/routes
class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
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
  static const String search = '/search';
  static const String paymentMethods = '/payment-methods';
  static const String notificationPreferences = '/notification-preferences';
  static const String followedStores = '/followed-stores';

  static Map<String, WidgetBuilder> get routes => {
        search: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return SearchBrowsePage(initialQuery: args);
          } else if (args is Map<String, dynamic>) {
            return SearchBrowsePage(
              initialQuery: args['query'] as String? ?? '',
              initialCategory: args['category'] as String?,
            );
          }
          return const SearchBrowsePage();
        },
        splash: (context) => const SplashPage(),
        '/splash': (context) => const SplashPage(),
        landing: (context) => const LandingPage(),
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        emailVerification: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return EmailVerificationPage(email: args);
          } else if (args is Map<String, dynamic>) {
            return EmailVerificationPage(
              email: args['email'] as String?,
              isLoginMode: args['isLoginMode'] as bool? ?? false,
            );
          }
          return const EmailVerificationPage();
        },
        forgotPassword: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final email = args is String ? args : null;
          return ForgotPasswordPage(initialEmail: email);
        },
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
        if (!kReleaseMode) customerMockOrder: (context) => const CustomerMockOrderScreen(),
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
        rateProduct: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is OrderItemModel) {
            return RateProductPage(orderItem: args);
          }
          return const RateProductPage();
        },
        myAddresses: (context) => const MyAddressesPage(),
        newAddress: (context) => const NewAddressPage(),
        wishlist: (context) => const WishlistPage(),
        paymentMethods: (context) => const PaymentMethodsPage(),
        notificationPreferences: (context) => const NotificationPreferencesPage(),
        followedStores: (context) => const FollowedStoresPage(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name != null) {
      // Handle deep links like /products/:id or https://nexora.app/products/:id
      final uri = Uri.tryParse(name);
      if (uri != null) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2 && pathSegments[0] == 'products') {
          final productId = pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => const ProductDetailsPage(),
            settings: RouteSettings(
              name: AppRoutes.productDetails,
              arguments: productId,
            ),
          );
        }
      }
    }
    return null;
  }
}


