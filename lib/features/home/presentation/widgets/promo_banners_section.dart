import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/services/shop_service.dart';
import 'product_card.dart';

class PromoBannersSection extends StatefulWidget {
  const PromoBannersSection({super.key});

  @override
  State<PromoBannersSection> createState() => _PromoBannersSectionState();
}

class _PromoBannersSectionState extends State<PromoBannersSection> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  static const List<List<Color>> _bannerGradients = [
    [Color(0xFF030A1C), Color(0xFF071E42), Color(0xFF0C3866)],
    [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0284C7)],
    [Color(0xFF1F0929), Color(0xFF4C1D95), Color(0xFF06B6D4)],
    [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF059669)],
  ];

  static const List<Color> _badgeColors = [
    Color(0xFF00E5FF),
    Color(0xFFFFD700),
    Color(0xFFE11D48),
    Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final products = ShopService.instance.products;
      final count = products.isEmpty ? 1 : products.take(4).length;
      if (_pageController.hasClients && count > 1) {
        final nextPage = (_currentPage + 1) % count;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _openProduct(ProductModel product) {
    Navigator.pushNamed(context, AppRoutes.productDetails, arguments: product);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ShopService.instance,
      builder: (context, _) {
        final realProducts = ShopService.instance.products.take(4).toList();

        if (realProducts.isEmpty) {
          // Clean default banner when catalog is still loading
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Container(
              height: 128,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF030A1C),
                    Color(0xFF071E42),
                    Color(0xFF0C3866),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NEXORA MARKETPLACE',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Discover Authentic Local Merchants',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Direct from verified stores • Safe COD Guarantee',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: SizedBox(
            height: 128,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: realProducts.length,
                  itemBuilder: (context, index) {
                    final product = realProducts[index];
                    final gradient =
                        _bannerGradients[index % _bannerGradients.length];
                    final badgeColor =
                        _badgeColors[index % _badgeColors.length];
                    final tag = product.isFlashSale
                        ? 'FLASH SALE'
                        : (product.isMall
                              ? 'NEXORA MALL'
                              : (product.category.isNotEmpty
                                    ? product.category.toUpperCase()
                                    : 'FEATURED'));

                    return GestureDetector(
                      onTap: () => _openProduct(product),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 14,
                              top: 12,
                              bottom: 12,
                              right: 125,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            color: Color(0xFF030A1C),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (product.shopName.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            product.shopName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.price,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 200),
                                    scale: _currentPage == index ? 1.0 : 0.95,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00A3FF),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'VIEW PRODUCT',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          Icon(
                                            Icons.arrow_circle_right,
                                            size: 11,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right Product Preview Image
                            Positioned(
                              right: 8,
                              top: 8,
                              bottom: 8,
                              width: 110,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: const Color(0xFF0F172A),
                                  child: product.imageUrl.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Center(
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                      color: badgeColor,
                                                      size: 36,
                                                    ),
                                                  ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            color: badgeColor,
                                            size: 36,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Carousel Indicator Dots
                if (realProducts.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 14,
                    child: Row(
                      children: List.generate(realProducts.length, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 4),
                          height: 5,
                          width: isSelected ? 16 : 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
