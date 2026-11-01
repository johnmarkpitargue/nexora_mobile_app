import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/buyer_account_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final PageController _heroPageController;
  int _activeHeroIndex = 0;
  Timer? _autoSlideTimer;

  // Curated showcase products representing Nexora's flagship collections
  final List<_HeroProduct> _heroProducts = const [
    _HeroProduct(
      title: 'Nexora ANC Studio Pro',
      subtitle: 'Spatial Audio • Active Noise Cancelling',
      category: 'AUDIO & TECH',
      price: '₱2,450',
      originalPrice: '₱3,499',
      rating: '4.9',
      reviews: '6.4k',
      badge: 'FEATURED',
      badgeColor: Color(0xFF0066FF),
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80',
    ),
    _HeroProduct(
      title: 'CyberPulse Ultra Watch',
      subtitle: 'AMOLED Display • Titanium Finish',
      category: 'WEARABLES',
      price: '₱1,890',
      originalPrice: '₱2,700',
      rating: '4.8',
      reviews: '3.9k',
      badge: 'TOP PICK',
      badgeColor: Color(0xFF7C3AED),
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=600&q=80',
    ),
    _HeroProduct(
      title: 'Street Runner V2 Prime',
      subtitle: 'Ultralight Cushion • Breathable Knit',
      category: 'FOOTWEAR',
      price: '₱3,200',
      originalPrice: '₱4,500',
      rating: '5.0',
      reviews: '1.2k',
      badge: 'LIMITED DROP',
      badgeColor: Color(0xFFEA580C),
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=600&q=80',
    ),
    _HeroProduct(
      title: 'Apex 75% Mechanical RGB',
      subtitle: 'Hot-Swap Switches • Wireless 2.4G',
      category: 'GAMING GEAR',
      price: '₱3,890',
      originalPrice: '₱5,200',
      rating: '4.9',
      reviews: '4.1k',
      badge: 'HOT DEAL',
      badgeColor: Color(0xFF0284C7),
      imageUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController(viewportFraction: 0.92);

    // Auto-advance showcase carousel every 3.5 seconds
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted) return;
      if (_heroPageController.hasClients) {
        final nextIndex = (_activeHeroIndex + 1) % _heroProducts.length;
        _heroPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    // Enable Guest Mode: directly explore shop without forcing login
    BuyerAccountService.instance.enterGuestMode();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _onSignIn() {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  void _onRegister() {
    Navigator.pushNamed(context, AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Top Brand Navigation Bar
                            _buildHeader(),

                            const SizedBox(height: 16),

                            // 2. Interactive Flagship Hero Carousel
                            _buildHeroCarousel(),

                            const SizedBox(height: 12),

                            // 3. Carousel Pagination Indicators
                            _buildCarouselIndicators(),

                            const SizedBox(height: 18),

                            // 4. Headline & Brand Value Proposition
                            _buildHeadlineSection(),

                            const SizedBox(height: 18),

                            // 5. Creative Bento Feature Highlights
                            _buildBentoFeatures(),

                            const Spacer(),

                            const SizedBox(height: 24),

                            // 6. Primary Action Buttons & Footer Anchoring
                            _buildActionArea(),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Bar
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand Identity Emblem
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF030D26),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: Color(0xFF00A3FF),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Nexora',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        // Quick Sign In Button
        InkWell(
          onTap: _onSignIn,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: Color(0xFF0066FF),
                ),
                SizedBox(width: 5),
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Interactive Flagship Hero Carousel
  // ---------------------------------------------------------------------------
  Widget _buildHeroCarousel() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _heroPageController,
        itemCount: _heroProducts.length,
        onPageChanged: (index) {
          setState(() {
            _activeHeroIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final product = _heroProducts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _buildHeroCard(product),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(_HeroProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: product.badgeColor.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Product Cover Imagery
            Positioned(
              right: -10,
              top: -10,
              bottom: -10,
              width: 170,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // Left Gradient Mask for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.52, 0.72, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Card Content & Details
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge & Category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: product.badgeColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: product.badgeColor.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            product.badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFF64748B).withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),

                    // Title & Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 190,
                          child: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          width: 175,
                          child: Text(
                            product.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Price & Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.price,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            product.originalPrice,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                              const SizedBox(width: 3),
                              Text(
                                product.rating,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Carousel Pagination Dots
  // ---------------------------------------------------------------------------
  Widget _buildCarouselIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_heroProducts.length, (index) {
        final isActive = index == _activeHeroIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0066FF) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Headline & Brand Value Proposition
  // ---------------------------------------------------------------------------
  Widget _buildHeadlineSection() {
    return Column(
      children: [
        // Welcome Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF0284C7)),
              SizedBox(width: 5),
              Text(
                'THE PREMIER SHOPPING EXPERIENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Hero Typography
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Everything You Need,\n',
                style: TextStyle(
                  fontSize: 27,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              TextSpan(
                text: 'Delivered Instantly',
                style: TextStyle(
                  fontSize: 27,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0066FF),
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'Shop 100% verified authentic brands, exclusive drops, and enjoy lightning-fast doorstep delivery nationwide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Creative Bento Feature Highlights
  // ---------------------------------------------------------------------------
  Widget _buildBentoFeatures() {
    return Row(
      children: [
        Expanded(
          child: _buildBentoCard(
            icon: Icons.local_shipping_outlined,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFE0F2FE),
            title: 'Free Shipping',
            subtitle: '₱0 Min Spend',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBentoCard(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF059669),
            bgColor: const Color(0xFFD1FAE5),
            title: '100% Authentic',
            subtitle: 'Direct from Brands',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBentoCard(
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFEDE9FE),
            title: 'COD Ready',
            subtitle: 'Doorstep Pay',
          ),
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Area: Get Started & Sign In
  // ---------------------------------------------------------------------------
  Widget _buildActionArea() {
    return Column(
      children: [
        // Primary Call to Action Button
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0066FF),
                Color(0xFF00A3FF),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066FF).withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start Shopping as Guest',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Inline Sign In & Create Account options
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Already a member? ',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              onTap: _onSignIn,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: Color(0xFF0066FF),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
            const SizedBox(width: 4),
            InkWell(
              onTap: _onRegister,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Trust & Guarantee Badges
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: Color(0xFF059669)),
            SizedBox(width: 4),
            Text(
              '100% Buyer Protection',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            SizedBox(width: 8),
            Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
            SizedBox(width: 8),
            Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF0284C7)),
            SizedBox(width: 4),
            Text(
              '256-Bit SSL Secured',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Legal Terms
        Text(
          'By continuing, you agree to Nexora’s Terms of Service & Privacy Policy',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Data Model for Hero Showcase Products
// -----------------------------------------------------------------------------
class _HeroProduct {
  final String title;
  final String subtitle;
  final String category;
  final String price;
  final String originalPrice;
  final String rating;
  final String reviews;
  final String badge;
  final Color badgeColor;
  final String imageUrl;

  const _HeroProduct({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviews,
    required this.badge,
    required this.badgeColor,
    required this.imageUrl,
  });
}
