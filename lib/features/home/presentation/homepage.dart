import 'package:flutter/material.dart';
import '../../chat/presentation/chat_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../profile/presentation/profile_page.dart';
import 'widgets/header_app_bar.dart';
import 'widgets/search_and_trend_section.dart';
import 'widgets/category_section.dart';
import 'widgets/active_order_tracker_card.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/weekly_perks_banner.dart';
import 'widgets/floating_nav_dock.dart';

class NexoraHomePage extends StatefulWidget {
  const NexoraHomePage({super.key});

  @override
  State<NexoraHomePage> createState() => _NexoraHomePageState();
}

class _NexoraHomePageState extends State<NexoraHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) {
      return const OrdersPage();
    }

    if (_currentIndex == 2) {
      return const ChatPage();
    }

    if (_currentIndex == 3) {
      return const ProfilePage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: const HeaderAppBar(),
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Search Bar & Trend Chips Carousel
                const SearchAndTrendSection(),

                // Category Section
                const CategorySection(),

                // Active Live Tracker Card
                const ActiveOrderTrackerCard(),

                // Featured Products Grid
                const FeaturedProductsSection(),

                // Weekly Perks Banner
                const WeeklyPerksBanner(),

                // Clearance spacing for floating bottom dock
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Floating Bottom Navigation Dock
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavDock(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}