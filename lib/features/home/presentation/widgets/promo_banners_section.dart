import 'dart:async';
import 'package:flutter/material.dart';

class PromoBannersSection extends StatefulWidget {
  const PromoBannersSection({super.key});

  @override
  State<PromoBannersSection> createState() => _PromoBannersSectionState();
}

class _PromoBannersSectionState extends State<PromoBannersSection> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _heroBanners = [
    {
      'tag': 'NEXORA FLAGSHIP',
      'releaseDate': 'Oct 16 Release',
      'titleLine1': 'SoundMax ',
      'titleLine2': 'Pro 18',
      'subtitle': 'Spatial Audio ANC • Zero Latency...',
      'badgeColor': const Color(0xFF00E5FF),
      'gradient': const [
        Color(0xFF030A1C),
        Color(0xFF071E42),
        Color(0xFF0C3866),
      ],
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuALgo4xVz9Wo_SuIU15ulvo-3G_HtejrhhLzW9Fgxp3t8CaI9fDN_t1BdIIRcHxxXEMC-7rLUJYBpIuY-c5YZ6dEo1scBwFSm14g-9T0PjdIixf5vHFuKFaU5-JDEnk_S8XO6M25JsCrNtVix9tigvacz5nurRgwZsHt4omGOaVSmm9mBM54NxSPO4-UO5xlTtt4Xb4p2y-MJVDYmv1KBa-MXWZ1XH_wb0wGPMd0IUiLGZ54l_WY1s',
      'fallbackIcon': Icons.headphones,
    },
    {
      'tag': 'EXCLUSIVE PRE-ORDER',
      'releaseDate': 'Limited Stock',
      'titleLine1': 'AuraFit ',
      'titleLine2': 'Ultra 2',
      'subtitle': 'AMOLED Display • 14-Day Battery...',
      'badgeColor': const Color(0xFFFFD700),
      'gradient': const [
        Color(0xFF0F172A),
        Color(0xFF1E293B),
        Color(0xFF0284C7),
      ],
      'imageUrl':
          'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?auto=format&fit=crop&w=400&q=80',
      'fallbackIcon': Icons.watch_outlined,
    },
    {
      'tag': 'MEGA DROP',
      'releaseDate': 'Special Edition',
      'titleLine1': 'Apex Pro ',
      'titleLine2': 'Keyboards',
      'subtitle': 'Gateron Switches • RGB Lighting...',
      'badgeColor': const Color(0xFFE11D48),
      'gradient': const [
        Color(0xFF1F0929),
        Color(0xFF4C1D95),
        Color(0xFF06B6D4),
      ],
      'imageUrl':
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=400&q=80',
      'fallbackIcon': Icons.keyboard,
    },
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
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _heroBanners.length;
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          // 1. Sliding Top Hero Campaign & Pre-order Banner
          SizedBox(
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
                  itemCount: _heroBanners.length,
                  itemBuilder: (context, index) {
                    final banner = _heroBanners[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: banner['gradient'] as List<Color>,
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
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: banner['badgeColor'] as Color,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        banner['tag'] as String,
                                        style: const TextStyle(
                                          color: Color(0xFF030A1C),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        banner['releaseDate'] as String,
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
                                RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: banner['titleLine1'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextSpan(
                                        text: banner['titleLine2'] as String,
                                        style: TextStyle(
                                          color: banner['badgeColor'] as Color,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  banner['subtitle'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: _currentPage == index ? 1.0 : 0.95,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00A3FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'PRE-ORDER NOW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                        SizedBox(width: 2),
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
                              child: Image.network(
                                banner['imageUrl'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: const Color(0xFF0F172A),
                                  child: Icon(
                                    banner['fallbackIcon'] as IconData,
                                    color: banner['badgeColor'] as Color,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Carousel Indicator Dots
                Positioned(
                  bottom: 8,
                  left: 14,
                  child: Row(
                    children: List.generate(_heroBanners.length, (index) {
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
        ],
      ),
    );
  }
}
