import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../cart/presentation/cart_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/chat_service.dart';
import 'widgets/floating_nav_dock.dart';
import 'widgets/header_app_bar.dart';
import 'widgets/promo_banners_section.dart';
import 'widgets/category_section.dart';
import 'widgets/featured_products_section.dart';

class NexoraHomePage extends StatefulWidget {
  const NexoraHomePage({super.key});

  @override
  State<NexoraHomePage> createState() => _NexoraHomePageState();
}

class _NexoraHomePageState extends State<NexoraHomePage> {
  int _currentIndex = 0;

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Banners & Promo Action Pills Section
          const PromoBannersSection(),

          // Categories Section
          CategorySection(
            selectedCategory: null,
            onCategorySelected: (category) {
              if (category == null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.categoryProducts,
                  arguments: {'category': 'All', 'title': 'All Categories'},
                );
              } else {
                Navigator.pushNamed(
                  context,
                  AppRoutes.categoryProducts,
                  arguments: {'category': category, 'title': category},
                );
              }
            },
          ),

          // Keep discovery broad; category cards open complete result pages.
          const DailyDiscoverSection(selectedCategory: null),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _currentIndex == 0 ? const HeaderAppBar() : null,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            const CartPage(),
            const OrdersPage(),
            const ChatPage(),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: Listenable.merge([
            CartService.instance,
            ChatService.instance,
          ]),
          builder: (context, _) {
            final cartCount = CartService.instance.itemCount;
            final chatUnread = ChatService.instance.totalUnreadCount;

            return FloatingNavDock(
              currentIndex: _currentIndex,
              cartCount: cartCount,
              chatUnreadCount: chatUnread,
              onTap: (index) {
                if (index == _currentIndex) return;
                setState(() => _currentIndex = index);
              },
            );
          },
        ),
      ),
    );
  }
}
