import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/seller_registration_page.dart';
import '../../features/auth/presentation/rider_registration_page.dart';
import '../../features/home/presentation/homepage.dart';
import '../../features/orders/presentation/orders_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/checkout/presentation/checkout_page.dart';
import '../../features/product_details/presentation/product_details_page.dart';
import '../../features/cart/presentation/cart_page.dart';

/// Centralized application routes configuration located in lib/app/routes
class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String sellerRegister = '/seller-register';
  static const String riderRegister = '/rider-register';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String checkout = '/checkout';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        sellerRegister: (context) => const SellerRegistrationPage(),
        riderRegister: (context) => const RiderRegistrationPage(),
        home: (context) => const NexoraHomePage(),
        orders: (context) => const OrdersPage(),
        chat: (context) => const ChatPage(),
        profile: (context) => const ProfilePage(),
        checkout: (context) => const CheckoutPage(),
        productDetails: (context) => const ProductDetailsPage(),
        cart: (context) => const CartPage(),
      };
}

