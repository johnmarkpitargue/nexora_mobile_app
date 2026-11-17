import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/buyer_account_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  PageController? _pageController;
  bool _lastIsWide = false;
  Timer? _autoSlideTimer;
  int _activeIndex = 0;
  bool? _animationsDisabled;

  static const _products = [
    _HeroProduct(
      title: 'Studio Pro headphones',
      detail: 'Immersive sound with all-day comfort.',
      price: '\u20B12,450',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=1000&q=88',
      fallbackIcon: Icons.headphones_rounded,
    ),
    _HeroProduct(
      title: 'CyberPulse watch',
      detail: 'A clear view of every move.',
      price: '\u20B11,890',
      imageUrl:
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=1000&q=88',
      fallbackIcon: Icons.watch_rounded,
    ),
    _HeroProduct(
      title: 'Street Runner V2',
      detail: 'Lightweight cushioning for everyday miles.',
      price: '\u20B13,200',
      imageUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1000&q=88',
      fallbackIcon: Icons.directions_run_rounded,
    ),
  ];

  PageController _getController(bool isWide) {
    if (_pageController == null || _lastIsWide != isWide) {
      _lastIsWide = isWide;
      _pageController?.dispose();
      _pageController = PageController(
        initialPage: _activeIndex,
        viewportFraction: isWide ? 1.0 : 0.92,
      );
    }
    return _pageController!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == disabled) return;

    _animationsDisabled = disabled;
    _autoSlideTimer?.cancel();
    if (!disabled) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || _pageController == null || !_pageController!.hasClients) {
          return;
        }
        final next = (_activeIndex + 1) % _products.length;
        _pageController!.animateToPage(
          next,
          duration: NexoraMotion.emphasized,
          curve: NexoraMotion.emphasizedCurve,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _exploreAsGuest() {
    BuyerAccountService.instance.enterGuestMode();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _openSignIn() {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  void _openRegistration() {
    Navigator.pushNamed(context, AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NexoraTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: NexoraTheme.surface,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final accessibilityGrowth =
                      ((textScale - 1).clamp(0.0, 1.0) * 150);

                  final verticalPad = isWide ? NexoraSpacing.xl : NexoraSpacing.md;
                  final horizontalPad = isWide ? NexoraSpacing.xxl : NexoraSpacing.lg;

                  return SingleChildScrollView(
                    key: const ValueKey('landing-scroll'),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      verticalPad,
                      horizontalPad,
                      isWide ? NexoraSpacing.xl : NexoraSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 1040 : 520,
                          minHeight: (constraints.maxHeight - verticalPad * 2)
                              .clamp(0, double.infinity),
                        ),
                        child: isWide
                            ? _buildWideHeroLayout(
                                context,
                                theme,
                                constraints,
                                accessibilityGrowth,
                              )
                            : _buildCompactHeroLayout(
                                context,
                                theme,
                                constraints,
                                accessibilityGrowth,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet / iPad / Desktop Adaptive Two-Column Hero
  // ---------------------------------------------------------------------------
  Widget _buildWideHeroLayout(
    BuildContext context,
    ThemeData theme,
    BoxConstraints constraints,
    double accessibilityGrowth,
  ) {
    final controller = _getController(true);
    final storyHeight = ((constraints.maxHeight * 0.52).clamp(420.0, 520.0) +
            accessibilityGrowth)
        .clamp(420.0, 600.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Brand Navigation, Headline, Copy, Action Buttons, Trust Row
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: NexoraSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LandingHeader(onSignIn: _openSignIn),
                const SizedBox(height: NexoraSpacing.xxl),
                Text(
                  'Good finds, without the noise.',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 38,
                    height: 1.08,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: NexoraSpacing.md),
                Text(
                  'Curated everyday essentials, clear prices, and a checkout that stays out of your way.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF475569),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: NexoraSpacing.xl),
                FilledButton.icon(
                  key: const ValueKey('landing-explore-action'),
                  onPressed: _exploreAsGuest,
                  style: FilledButton.styleFrom(
                    backgroundColor: NexoraTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 2,
                    shadowColor: NexoraTheme.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NexoraRadius.control),
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text(
                    'Explore the shop',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                const SizedBox(height: NexoraSpacing.sm),
                OutlinedButton.icon(
                  key: const ValueKey('landing-register-action'),
                  onPressed: _openRegistration,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NexoraRadius.control),
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_outward_rounded, size: 19),
                  label: const Text(
                    'Create an account',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                const SizedBox(height: NexoraSpacing.xl),
                const _TrustRow(),
              ],
            ),
          ),
        ),

        // Right Column: Showcase Card Carousel & Dots (Cleanly Contained)
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: storyHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(NexoraRadius.large),
                      child: PageView.builder(
                        key: const ValueKey('landing-product-stories'),
                        controller: controller,
                        clipBehavior: Clip.antiAlias,
                        itemCount: _products.length,
                        onPageChanged: (index) =>
                            setState(() => _activeIndex = index),
                        itemBuilder: (context, index) {
                          return _ProductStoryCard(
                            product: _products[index],
                            position: index + 1,
                            count: _products.length,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: NexoraSpacing.md),
                  _StoryIndicator(
                    activeIndex: _activeIndex,
                    count: _products.length,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Phone / Compact Vertical Flow
  // ---------------------------------------------------------------------------
  Widget _buildCompactHeroLayout(
    BuildContext context,
    ThemeData theme,
    BoxConstraints constraints,
    double accessibilityGrowth,
  ) {
    final controller = _getController(false);
    final storyHeight = ((constraints.maxHeight * 0.40).clamp(330.0, 390.0) +
            accessibilityGrowth)
        .clamp(330.0, 540.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LandingHeader(onSignIn: _openSignIn),
        const SizedBox(height: NexoraSpacing.xxl),
        Text(
          'Good finds, without the noise.',
          style: theme.textTheme.displaySmall?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: NexoraSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Text(
            'Curated everyday essentials, clear prices, and a checkout that stays out of your way.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: NexoraSpacing.xl),
        SizedBox(
          height: storyHeight,
          child: PageView.builder(
            key: const ValueKey('landing-product-stories'),
            controller: controller,
            padEnds: true,
            clipBehavior: Clip.antiAlias,
            itemCount: _products.length,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _ProductStoryCard(
                  product: _products[index],
                  position: index + 1,
                  count: _products.length,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: NexoraSpacing.sm),
        _StoryIndicator(
          activeIndex: _activeIndex,
          count: _products.length,
        ),
        const SizedBox(height: NexoraSpacing.xl),
        FilledButton.icon(
          key: const ValueKey('landing-explore-action'),
          onPressed: _exploreAsGuest,
          style: FilledButton.styleFrom(
            backgroundColor: NexoraTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            elevation: 2,
            shadowColor: NexoraTheme.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                NexoraRadius.control,
              ),
            ),
          ),
          iconAlignment: IconAlignment.end,
          icon: const Icon(
            Icons.arrow_forward_rounded,
            size: 19,
          ),
          label: const Text(
            'Explore the shop',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: NexoraSpacing.xs),
        OutlinedButton.icon(
          key: const ValueKey('landing-register-action'),
          onPressed: _openRegistration,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F172A),
            side: const BorderSide(
              color: Color(0xFFCBD5E1),
              width: 1.2,
            ),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                NexoraRadius.control,
              ),
            ),
          ),
          iconAlignment: IconAlignment.end,
          icon: const Icon(
            Icons.arrow_outward_rounded,
            size: 18,
          ),
          label: const Text(
            'Create an account',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: NexoraSpacing.lg),
        const _TrustRow(),
      ],
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: NexoraTheme.darkNavy,
            borderRadius: BorderRadius.circular(NexoraRadius.control),
          ),
          child: Image.asset(
            'assets/images/logo.png',
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: NexoraSpacing.sm),
        const Expanded(
          child: Text(
            'NEXORA',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('landing-sign-in-action'),
          onPressed: onSignIn,
          style: TextButton.styleFrom(
            foregroundColor: NexoraTheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

class _ProductStoryCard extends StatelessWidget {
  const _ProductStoryCard({
    required this.product,
    required this.position,
    required this.count,
  });

  final _HeroProduct product;
  final int position;
  final int count;

  @override
  Widget build(BuildContext context) {
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Semantics(
      container: true,
      label:
          'Featured product $position of $count. ${product.title}. ${product.detail} ${product.price}.',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(NexoraRadius.large),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: usesLargeText ? 5 : 7,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: const Color(0xFFF1F5F9),
                  child: Icon(
                    product.fallbackIcon,
                    size: 64,
                    color: NexoraTheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: usesLargeText ? 6 : 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NexoraSpacing.md,
                  vertical: NexoraSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: NexoraSpacing.xs),
                    Expanded(
                      child: Text(
                        product.detail,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: NexoraSpacing.xs),
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: NexoraTheme.primary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
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
}

class _StoryIndicator extends StatelessWidget {
  const _StoryIndicator({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Featured product ${activeIndex + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            return AnimatedContainer(
              duration: NexoraMotion.resolve(context),
              curve: NexoraMotion.standardCurve,
              width: index == activeIndex ? 24 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == activeIndex
                    ? NexoraTheme.primary
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(NexoraRadius.full),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: NexoraSpacing.lg,
      runSpacing: NexoraSpacing.sm,
      children: [
        _TrustItem(icon: Icons.lock_outline_rounded, label: 'Secure checkout'),
        _TrustItem(
          icon: Icons.local_shipping_outlined,
          label: 'Tracked delivery',
        ),
        _TrustItem(icon: Icons.replay_rounded, label: 'Easy returns'),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroProduct {
  const _HeroProduct({
    required this.title,
    required this.detail,
    required this.price,
    required this.imageUrl,
    required this.fallbackIcon,
  });

  final String title;
  final String detail;
  final String price;
  final String imageUrl;
  final IconData fallbackIcon;
}
