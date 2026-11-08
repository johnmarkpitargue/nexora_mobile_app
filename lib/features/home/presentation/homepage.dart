import 'package:flutter/material.dart';

import '../../cart/presentation/cart_page.dart';
import '../../chat/presentation/chat_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/shop_service.dart';
import 'widgets/product_card.dart';
import 'widgets/header_app_bar.dart';
import 'widgets/promo_banners_section.dart';
import 'widgets/category_section.dart';
import 'widgets/featured_products_section.dart';

class NexoraHomePage extends StatefulWidget {
  const NexoraHomePage({super.key});

  @override
  State<NexoraHomePage> createState() => _NexoraHomePageState();
}

class _NexoraHomePageState extends State<NexoraHomePage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};
  String? _selectedCategory;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateOrdersPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OrderService.instance.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    _updateOrdersPolling();
  }

  void _updateOrdersPolling() {
    final isOrdersTab = _currentIndex == 2;
    final isForeground = _appLifecycleState == AppLifecycleState.resumed;
    if (isOrdersTab && isForeground && ApiClient.instance.hasToken) {
      OrderService.instance.startPolling();
    } else {
      OrderService.instance.stopPolling();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await ShopService.instance.loadCatalogRemote(
          category: _selectedCategory,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banners & Promo Action Pills Section
            const PromoBannersSection(),

            // Dynamic Categories Section
            CategorySection(
              selectedCategory: _selectedCategory,
              onCategorySelected: (categorySlug) {
                setState(() {
                  _selectedCategory = categorySlug;
                });
                ShopService.instance
                    .loadCatalogRemote(category: categorySlug)
                    .catchError((_) => <ProductModel>[]);
              },
            ),

            // DAILY DISCOVER Product Grid dynamically filtered by Category
            DailyDiscoverSection(
              selectedCategory: _selectedCategory,
              onLoadMore: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All recommendations loaded'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: _currentIndex == 0 ? const HeaderAppBar() : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _loadedTabs.contains(1) ? const CartPage() : const SizedBox.shrink(),
          _loadedTabs.contains(2)
              ? OrdersPage(isActiveTab: _currentIndex == 2)
              : const SizedBox.shrink(),
          _loadedTabs.contains(3) ? const ChatPage() : const SizedBox.shrink(),
          _loadedTabs.contains(4)
              ? const ProfilePage()
              : const SizedBox.shrink(),
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

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _loadedTabs.add(index);
              });
              _updateOrdersPolling();
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0066FF),
            unselectedItemColor: const Color(0xFF64748B),
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 8,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.storefront),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (cartCount > 0)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D2FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    if (chatUnread > 0)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE11D48),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Chat',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
