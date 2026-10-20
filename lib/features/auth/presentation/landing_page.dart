import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late final AnimationController _col1Controller;
  late final AnimationController _col2Controller;
  late final AnimationController _col3Controller;
  late final AnimationController _pulseController;

  // Curated showcase products matching the Nexora catalog
  final List<_ShowcaseProduct> _col1Products = const [
    _ShowcaseProduct(
      title: 'Nexora ANC Pro',
      category: 'Audio',
      price: '₱2,450',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=400&q=80',
      badge: 'OFFICIAL',
    ),
    _ShowcaseProduct(
      title: 'Minimalist Hoodie',
      category: 'Fashion',
      price: '₱1,250',
      imageUrl:
          'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=400&q=80',
      badge: 'HOT',
    ),
    _ShowcaseProduct(
      title: 'Cyber Pulse Watch',
      category: 'Wearables',
      price: '₱1,890',
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=400&q=80',
      badge: '-25%',
    ),
    _ShowcaseProduct(
      title: 'Aura Retro Shades',
      category: 'Accessories',
      price: '₱890',
      imageUrl:
          'https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  final List<_ShowcaseProduct> _col2Products = const [
    _ShowcaseProduct(
      title: 'Aura Heavy Fleece',
      category: 'Streetwear',
      price: '₱1,600',
      imageUrl:
          'https://images.unsplash.com/photo-1578587018452-892bacefd3f2?auto=format&fit=crop&w=400&q=80',
      badge: 'TOP PICK',
    ),
    _ShowcaseProduct(
      title: 'Apex 75% Mechanical',
      category: 'Gaming',
      price: '₱3,890',
      imageUrl:
          'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=400&q=80',
      badge: '-30%',
    ),
    _ShowcaseProduct(
      title: 'Urban Explorer Bag',
      category: 'Travel',
      price: '₱2,190',
      imageUrl:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=400&q=80',
    ),
    _ShowcaseProduct(
      title: 'Lumix Prime 4K',
      category: 'Cameras',
      price: '₱14,500',
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=400&q=80',
      badge: 'PRO',
    ),
  ];

  final List<_ShowcaseProduct> _col3Products = const [
    _ShowcaseProduct(
      title: 'Pulse Studio Buds',
      category: 'Audio',
      price: '₱1,490',
      imageUrl:
          'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=400&q=80',
      badge: 'NEW',
    ),
    _ShowcaseProduct(
      title: 'Street Runner V2',
      category: 'Footwear',
      price: '₱3,200',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=400&q=80',
      badge: '-15%',
    ),
    _ShowcaseProduct(
      title: 'Titan Carbon Mug',
      category: 'Lifestyle',
      price: '₱650',
      imageUrl:
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80',
    ),
    _ShowcaseProduct(
      title: 'Nova Smart Speaker',
      category: 'Smart Home',
      price: '₱2,780',
      imageUrl:
          'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=400&q=80',
      badge: 'HOT',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Staggered infinite vertical marquee speeds
    _col1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();

    _col2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 38),
    )..repeat();

    _col3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Subtle ambient glow breathing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _col1Controller.dispose();
    _col2Controller.dispose();
    _col3Controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.pushNamed(context, AppRoutes.register);
  }

  void _onSignIn() {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Glowing Orbs
          Positioned(
            top: -60,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 0.95 + (_pulseController.value * 0.15);
                final opacity = 0.14 + (_pulseController.value * 0.10);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00A3FF).withValues(alpha: opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 220,
            left: -80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final opacity = 0.10 + (_pulseController.value * 0.08);
                return Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0066FF).withValues(alpha: opacity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Animated Vertical Product Columns (Marquee)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 60 || constraints.maxHeight < 60) {
                  return const SizedBox.shrink();
                }
                return ClipRect(
                  child: Opacity(
                    opacity: 0.65,
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.08, 0.92, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Column 1 (Scrolls upward)
                          Expanded(
                            child: _VerticalMarqueeColumn(
                              controller: _col1Controller,
                              reverse: false,
                              initialPhase: 0.0,
                              products: _col1Products,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Column 2 (Scrolls downward / staggered)
                          Expanded(
                            child: _VerticalMarqueeColumn(
                              controller: _col2Controller,
                              reverse: true,
                              initialPhase: 0.38,
                              products: _col2Products,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Column 3 (Scrolls upward / alternate phase)
                          Expanded(
                            child: _VerticalMarqueeColumn(
                              controller: _col3Controller,
                              reverse: false,
                              initialPhase: 0.68,
                              products: _col3Products,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Frosted Glass & Gradient Mask Layer
          // Fades smoothly so products are visible at top/edges while keeping text 100% crisp
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.22, 0.48, 0.75, 1.0],
                    colors: [
                      const Color(0xFFF6F8FC).withValues(alpha: 0.58),
                      const Color(0xFFF6F8FC).withValues(alpha: 0.78),
                      const Color(0xFFF6F8FC).withValues(alpha: 0.93),
                      const Color(0xFFF6F8FC).withValues(alpha: 0.98),
                      const Color(0xFFF6F8FC),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Foreground UI Layer (Pinned Header & Single Get Started Action)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxHeight < 60 || constraints.maxWidth < 60) {
                  return const SizedBox.shrink();
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                  children: [
                    // Top Brand Bar (Pinned to the top side)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22.0,
                        vertical: 12.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A)
                                        .withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Center(
                                    child: Text(
                                      'N',
                                      style: TextStyle(
                                        color: Color(0xFF00A3FF),
                                        fontSize: 22,
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
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Centered Content Body
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // "WELCOME TO NEXORA" Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F7FD),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFBCEAF9),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'WELCOME TO NEXORA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Headline
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Everything You Need,\n',
                                      style: TextStyle(
                                        fontSize: 28,
                                        height: 1.22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Delivered Instantly',
                                      style: TextStyle(
                                        fontSize: 28,
                                        height: 1.22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF00A3FF),
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Subtitle
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Shop authentic brands with fast, reliable\nnationwide delivery.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.45,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // 3 Benefit Feature Cards in a row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFeatureCard(
                                      icon: Icons.local_shipping_outlined,
                                      title: 'Free Shipping',
                                      subtitle: '₱0 Min Spend',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildFeatureCard(
                                      icon: Icons.verified_outlined,
                                      title: '100% Authentic',
                                      subtitle: 'Official Brands',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildFeatureCard(
                                      icon: Icons.payments_outlined,
                                      title: 'COD Available',
                                      subtitle: 'Doorstep Pay',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // The Only Button: "Get Started ->"
                              Container(
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00A3FF),
                                      Color(0xFF0080F6),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(27),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0084FF)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
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
                                        'Get Started',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Inline "Already have an account? Sign In" link
                              Padding(
                                padding: const EdgeInsets.only(top: 14.0),
                                child: InkWell(
                                  onTap: _onSignIn,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: RichText(
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Already have an account? ',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Sign In',
                                            style: TextStyle(
                                              color: Color(0xFF0084FF),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Trust Badges: Nexora Guarantee • SSL Protected
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 15,
                                    color: Color(0xFF0084FF),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Nexora Guarantee',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 7),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 15,
                                    color: Color(0xFF0084FF),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'SSL Protected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Legal Disclaimer
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'By continuing, you agree to Nexora’s ',
                                      ),
                                      TextSpan(
                                        text: 'Terms',
                                        style: TextStyle(
                                          color: Color(0xFF0084FF),
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Privacy Policy.',
                                        style: TextStyle(
                                          color: Color(0xFF0084FF),
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
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
      ),
    ],
  ),
);
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Vertical Infinite Marquee Animated Column
// -------------------------------------------------------------
class _VerticalMarqueeColumn extends StatelessWidget {
  final AnimationController controller;
  final bool reverse;
  final double initialPhase;
  final List<_ShowcaseProduct> products;

  const _VerticalMarqueeColumn({
    required this.controller,
    required this.reverse,
    this.initialPhase = 0.0,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    // Card height + vertical gap
    const double itemHeight = 154.0;
    final double totalHeight = products.length * itemHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final progress = (controller.value + initialPhase) % 1.0;
            final double offset = reverse
                ? -progress * totalHeight
                : -(1.0 - progress) * totalHeight;

            return Transform.translate(
              offset: Offset(0, offset % totalHeight - totalHeight),
              child: SizedBox(
                width: constraints.maxWidth,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Render 3 sets to guarantee endless seamless loop without empty gaps
                      ...products.map((p) => _ProductCardItem(product: p)),
                      ...products.map((p) => _ProductCardItem(product: p)),
                      ...products.map((p) => _ProductCardItem(product: p)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductCardItem extends StatelessWidget {
  final _ShowcaseProduct product;

  const _ProductCardItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (product.badge != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.category,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                product.price,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00A3FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowcaseProduct {
  final String title;
  final String category;
  final String price;
  final String imageUrl;
  final String? badge;

  const _ShowcaseProduct({
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.badge,
  });
}

