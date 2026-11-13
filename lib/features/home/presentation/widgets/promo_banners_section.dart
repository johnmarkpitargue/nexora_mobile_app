import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/nexora_theme.dart';
import '../../../../core/services/shop_service.dart';
import 'product_card.dart';

class PromoBannersSection extends StatefulWidget {
  const PromoBannersSection({super.key});

  @override
  State<PromoBannersSection> createState() => _PromoBannersSectionState();
}

class _PromoBannersSectionState extends State<PromoBannersSection> {
  static const List<_HeroSlideData> _fallbackCampaigns = [
    _HeroSlideData(
      title: 'SoundMax Pro 18',
      releaseNote: 'New this week',
      description: 'Spatial audio, ANC, and zero-latency listening.',
      searchQuery: 'SoundMax Pro 18',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=1200&q=88',
      fallbackIcon: Icons.headphones_rounded,
      gradient: [NexoraTheme.darkNavy, Color(0xFF0C4A6E)],
    ),
    _HeroSlideData(
      title: 'AuraFit Ultra 2',
      releaseNote: 'Limited stock',
      description: 'A vivid AMOLED display with a 14-day battery.',
      searchQuery: 'AuraFit Ultra 2',
      imageUrl:
          'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?auto=format&fit=crop&w=1200&q=88',
      fallbackIcon: Icons.watch_rounded,
      gradient: [Color(0xFF071631), Color(0xFF0B4D99)],
    ),
    _HeroSlideData(
      title: 'Apex Pro Keyboards',
      releaseNote: 'Special edition',
      description: 'Responsive switches and focused desk-ready lighting.',
      searchQuery: 'Apex Pro Keyboards',
      imageUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=1200&q=88',
      fallbackIcon: Icons.keyboard_rounded,
      gradient: [Color(0xFF0A1028), Color(0xFF123B68)],
    ),
  ];

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _autoSlideTimer?.cancel();
    } else {
      _startAutoSlideTimer();
    }
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final slideCount = _getSlides().length;
      if (slideCount <= 1) return;
      final nextPage = (_currentPage + 1) % slideCount;
      _pageController.animateToPage(
        nextPage,
        duration: NexoraMotion.emphasized,
        curve: NexoraMotion.emphasizedCurve,
      );
    });
  }

  List<_HeroSlideData> _getSlides() {
    final liveProducts = ShopService.instance.products;
    if (liveProducts.isNotEmpty) {
      final topFour = liveProducts.take(4).toList();
      const gradients = [
        [Color(0xFF050B28), Color(0xFF0C2454), Color(0xFF0284C7)],
        [Color(0xFF071631), Color(0xFF0B4D99), Color(0xFF0066FF)],
        [Color(0xFF0A1028), Color(0xFF1E293B), Color(0xFF0EA5E9)],
        [Color(0xFF06152B), Color(0xFF0C4A6E), Color(0xFF38BDF8)],
      ];

      return List.generate(topFour.length, (i) {
        final prod = topFour[i];
        final badge = prod.isMall
            ? 'Nexora Mall'
            : (prod.shopName.isNotEmpty ? prod.shopName : 'Featured');
        final discountDesc = prod.discountTag != null
            ? '${prod.discountTag} OFF • Only ${prod.price}'
            : 'Available now for ${prod.price}';

        return _HeroSlideData(
          title: prod.title,
          releaseNote: badge,
          description: discountDesc,
          imageUrl: prod.imageUrl,
          fallbackIcon: Icons.shopping_bag_outlined,
          gradient: gradients[i % gradients.length],
          product: prod,
        );
      });
    }
    return _fallbackCampaigns;
  }

  void _openSlide(_HeroSlideData slide) {
    if (slide.product != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.productDetails,
        arguments: slide.product,
      );
    } else if (slide.searchQuery != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.search,
        arguments: slide.searchQuery,
      );
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motionDuration = NexoraMotion.resolve(context);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: ShopService.instance,
      builder: (context, _) {
        final slides = _getSlides();
        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final accessibilityGrowth =
                    ((textScale - 1).clamp(0.0, 1.0) * 138);
                final bannerHeight =
                    ((constraints.maxWidth * 0.68).clamp(232.0, 310.0) +
                            accessibilityGrowth)
                        .clamp(232.0, 448.0);

                return SizedBox(
                  height: bannerHeight,
                  child: PageView.builder(
                    key: const ValueKey('campaign-hero-rail'),
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return _HeroSlideCard(
                        key: ValueKey('hero-slide-$index'),
                        slide: slide,
                        pageIndex: index,
                        pageCount: slides.length,
                        onPressed: () => _openSlide(slide),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: NexoraSpacing.sm),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (index) {
                  final isSelected = _currentPage == index;
                  return AnimatedContainer(
                    duration: motionDuration,
                    curve: NexoraMotion.standardCurve,
                    width: isSelected ? 24 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(NexoraRadius.full),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroSlideData {
  const _HeroSlideData({
    required this.title,
    required this.releaseNote,
    required this.description,
    this.searchQuery,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.gradient,
    this.product,
  });

  final String title;
  final String releaseNote;
  final String description;
  final String? searchQuery;
  final String imageUrl;
  final IconData fallbackIcon;
  final List<Color> gradient;
  final ProductModel? product;
}

class _HeroSlideCard extends StatelessWidget {
  const _HeroSlideCard({
    super.key,
    required this.slide,
    required this.pageIndex,
    required this.pageCount,
    required this.onPressed,
  });

  final _HeroSlideData slide;
  final int pageIndex;
  final int pageCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final contentWidth = textScale > 1.3 ? 0.92 : 0.76;

    return Semantics(
      label: 'Featured product ${pageIndex + 1} of $pageCount',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (slide.imageUrl.isNotEmpty)
              Image.network(
                slide.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Icon(
                        slide.fallbackIcon,
                        size: 96,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  );
                },
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    slide.gradient.first.withValues(alpha: 0.95),
                    slide.gradient.first.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.58, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NexoraSpacing.md,
                vertical: NexoraSpacing.lg,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          slide.releaseNote.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: NexoraTheme.fontFamily,
                            color: Colors.white,
                            fontSize: 9.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slide.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: NexoraTheme.fontFamily,
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slide.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: NexoraTheme.fontFamily,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: NexoraTheme.darkNavy,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Shop now',
                              style: TextStyle(
                                fontFamily: NexoraTheme.fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
