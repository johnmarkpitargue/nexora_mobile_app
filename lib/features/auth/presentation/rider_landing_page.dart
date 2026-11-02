import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rider_login_page.dart';
import 'add_rider_page.dart';

class _RiderAdvantageSlide {
  final IconData icon;
  final String badgeText;
  final String title;
  final String description;
  final String bottomPrimary;
  final String bottomSecondary;

  const _RiderAdvantageSlide({
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.bottomPrimary,
    required this.bottomSecondary,
  });
}

class RiderLandingPage extends StatefulWidget {
  const RiderLandingPage({super.key});

  @override
  State<RiderLandingPage> createState() => _RiderLandingPageState();
}

class _RiderLandingPageState extends State<RiderLandingPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoRotateTimer;
  bool _isInteracting = false;

  late final AnimationController _bgAnimController;

  final List<_RiderAdvantageSlide> _slides = const [
    _RiderAdvantageSlide(
      icon: Icons.account_balance_wallet_outlined,
      badgeText: '⚡ ₱0 Transfer Fee',
      title: 'Instant GCash Cash Out',
      description: 'Daily settlement straight to GCash right after delivery completed with zero deductions.',
      bottomPrimary: 'Auto GCash Transfer',
      bottomSecondary: '0s Latency',
    ),
    _RiderAdvantageSlide(
      icon: Icons.access_time_rounded,
      badgeText: '⚡ Full Freedom',
      title: 'Flexible Shift Hours',
      description: 'Choose your preferred delivery zone and work whenever you want without shift quotas.',
      bottomPrimary: 'Pasig & Ortigas Hub',
      bottomSecondary: '100% Flexible',
    ),
    _RiderAdvantageSlide(
      icon: Icons.trending_up_rounded,
      badgeText: '⚡ Up to +₱45/drop',
      title: 'Peak Hour Surge Pay',
      description: 'Earn higher rates during peak lunch and dinner delivery rushes across commercial hubs.',
      bottomPrimary: 'Automatic Bonus',
      bottomSecondary: 'Live Boosts',
    ),
    _RiderAdvantageSlide(
      icon: Icons.local_gas_station_rounded,
      badgeText: '⚡ Weekly Aid',
      title: 'Fuel & Maintenance Subsidy',
      description: 'Exclusive fuel discounts and regular maintenance aid at all accredited partner stations.',
      bottomPrimary: 'Partner Stations',
      bottomSecondary: 'Save ₱800/mo',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Background ambient velocity & radar animation
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _startAutoRotation();
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _pageController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _startAutoRotation() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) {
      if (_isInteracting || !mounted) return;
      final next = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoRotation() {
    setState(() => _isInteracting = true);
  }

  void _resumeAutoRotation() {
    setState(() => _isInteracting = false);
  }

  void _goToSlide(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const RiderLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Stack(
        children: [
          // 1. Fluid Velocity Background: Ambient Aurora Mesh, Velocity Streaks, and Sparkle Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimController,
              builder: (context, _) {
                final reduceMotion =
                    MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                return CustomPaint(
                  painter: _FluidVelocityBgPainter(
                    progress: reduceMotion ? 0.35 : _bgAnimController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  // Top Bar: Header Capsule Pill & Live Radar Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Text(
                          'NEXORA RIDER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0066FF),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Headline: Ride, Deliver & Earn on Your Terms.
                  RichText(
                    text: const TextSpan(
                      text: 'Ride, Deliver & Earn on\n',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Your Terms.',
                          style: TextStyle(
                            color: Color(0xFF00BFFF),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtext
                  const Text(
                    'Use your own motorcycle, scooter, or bike. Get paid directly to GCash right after every trip with full control over your hours.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Title: KEY RIDER ADVANTAGES
                  const Text(
                    'KEY RIDER ADVANTAGES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF334155),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. The 4-Slide Interactive Carousel
                  MouseRegion(
                    onEnter: (_) => _pauseAutoRotation(),
                    onExit: (_) => _resumeAutoRotation(),
                    child: GestureDetector(
                      onPanDown: (_) => _pauseAutoRotation(),
                      onPanCancel: () => _resumeAutoRotation(),
                      onPanEnd: (_) => _resumeAutoRotation(),
                      child: SizedBox(
                        height: 195,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            final slide = _slides[index];
                            return _buildSlideCard(slide);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Clickable Pagination Dots Engine
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = _currentPage == index;
                      return GestureDetector(
                        onTap: () => _goToSlide(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 24 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF0066FF)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // 5. Social Proof Card (No green dot indicator on social proof per constraint)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Stacked Avatars: JD, MR, KL
                        SizedBox(
                          width: 66,
                          height: 30,
                          child: Stack(
                            children: [
                              _avatarCircle(0, 'JD', const Color(0xFF0F172A)),
                              _avatarCircle(18, 'MR', const Color(0xFF0066FF)),
                              _avatarCircle(36, 'KL', const Color(0xFF0066FF)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '12,400+ Active Riders',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Metro Manila Fleet',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: const Text(
                            'Free Accident Coverage',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0066FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 6. Primary Button: LOG IN AS A RIDER ->
                  _buildLoginButton(),
                  const SizedBox(height: 24),

                  // 7. Complete 3-Tier Dispatch Security Footer
                  _buildSecurityFooter(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideCard(_RiderAdvantageSlide slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  slide.icon,
                  color: const Color(0xFF0066FF),
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Text(
                  slide.badgeText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slide Title
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),

          // Slide Description
          Expanded(
            child: Text(
              slide.description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          // Bottom Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slide.bottomPrimary,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    slide.bottomSecondary,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarCircle(double left, String text, Color color) {
    return Positioned(
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0066FF), // Electric Cyan
            Color(0xFF0066FF), // Sky Blue
            Color(0xFF0369A1), // Deep Ocean
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _openLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LOG IN AS A RIDER',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Column(
      children: [
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              text: 'Need fleet help? Call Pasig Hub Dispatch at ',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: '(02) 8888–RIDE',
                  style: TextStyle(
                    color: Color(0xFF0066FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔒', style: TextStyle(fontSize: 12)),
                SizedBox(width: 6),
                Text(
                  'Nexora Fleet Access • 256–Bit SSL Encrypted',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              text: 'Nexora Logistics Philippines • ',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: 'Terms & Privacy',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Hidden mobile-only feature: Rider self-registration is disabled (web requires logistics admin invite)
        Opacity(
          opacity: 0.0,
          child: IgnorePointer(
            child: Center(
              child: TextButton.icon(
                key: const Key('logistics_add_rider_btn'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddRiderPage()),
                  );
                },
                icon: const Icon(
                  Icons.business_center_outlined,
                  size: 16,
                  color: Color(0xFF0066FF),
                ),
                label: const Text(
                  'Logistics Admin: Add Rider Form',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fluid Velocity Background Painter for Nexora Rider Onboarding:
/// 1. Ambient Aurora Mesh & Luminous Gradient Orbs (@keyframes float-drift)
/// 2. Diagonal Velocity Streaks / Streamlines (@keyframes velocity-stream at -35 deg)
/// 3. Subtle Light Sparkle Particles (@keyframes pulse-shimmer)
/// 4. 60fps GPU acceleration with near-zero overhead
class _FluidVelocityBgPainter extends CustomPainter {
  final double progress;

  _FluidVelocityBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 0. Base Ice-Blue Canvas Fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFF0F9FF),
    );

    // 1. Ambient Aurora Mesh & Luminous Gradient Orbs (@keyframes float-drift)
    _drawAuroraOrbs(canvas, size);

    // 2. Horizontal Logistics Routing Carrier Lines
    _drawCarrierRouteLines(canvas, size);

    // 3. Diagonal Velocity Streaks / Streamlines (@keyframes velocity-stream at -35 deg)
    _drawVelocityStreaks(canvas, size);

    // 4. Subtle Light Sparkle Particles (@keyframes pulse-shimmer)
    _drawSparkles(canvas, size);
  }

  void _drawAuroraOrbs(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Orb 1: Vibrant Cyan (#00C4FF) in slow, drifting orbital path (top-right)
    final double orb1X = w * 0.72 + math.cos(progress * 2 * math.pi) * 55;
    final double orb1Y = h * 0.18 + math.sin(progress * 2 * math.pi) * 45;
    final double orb1Radius =
        (w * 0.60) * (1.0 + 0.08 * math.sin(progress * 2 * math.pi));

    final orb1Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF0066FF).withValues(alpha: 0.32),
              const Color(0xFF0066FF).withValues(alpha: 0.16),
              const Color(0xFF00779E).withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 0.75, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(orb1X, orb1Y), radius: orb1Radius),
          );
    canvas.drawCircle(Offset(orb1X, orb1Y), orb1Radius, orb1Paint);

    // Orb 2: Deep Azure (#00779E) in opposing slow circular path (bottom-left)
    final double orb2X = w * 0.28 - math.sin(progress * 2 * math.pi) * 60;
    final double orb2Y = h * 0.76 - math.cos(progress * 2 * math.pi) * 50;
    final double orb2Radius =
        (w * 0.68) * (1.0 - 0.07 * math.sin(progress * 2 * math.pi));

    final orb2Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF00779E).withValues(alpha: 0.28),
              const Color(0xFF0066FF).withValues(alpha: 0.14),
              const Color(0xFF00779E).withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 0.75, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(orb2X, orb2Y), radius: orb2Radius),
          );
    canvas.drawCircle(Offset(orb2X, orb2Y), orb2Radius, orb2Paint);

    // Orb 3: Luminous mid-canvas atmospheric glow
    final double orb3X = w * 0.50 + math.sin(progress * 2 * math.pi + 1.5) * 40;
    final double orb3Y = h * 0.46 + math.cos(progress * 2 * math.pi + 1.5) * 35;
    final double orb3Radius = w * 0.50;

    final orb3Paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF0066FF).withValues(alpha: 0.15),
              const Color(0xFF00779E).withValues(alpha: 0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.50, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(orb3X, orb3Y), radius: orb3Radius),
          );
    canvas.drawCircle(Offset(orb3X, orb3Y), orb3Radius, orb3Paint);
  }

  void _drawCarrierRouteLines(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Carrier Route 1: Mid-lower logistics carrier line (below active riders card, y ~ 0.64)
    final double y1 = h * 0.64;
    final double pulse1 = (math.sin(progress * 2 * math.pi) * 0.5 + 0.5);
    final paint1 = Paint()
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0066FF).withValues(alpha: 0.0),
          const Color(0xFF0066FF).withValues(alpha: 0.20 + 0.16 * pulse1),
          const Color(0xFF00E5FF).withValues(alpha: 0.35 + 0.15 * pulse1),
          const Color(0xFF0066FF).withValues(alpha: 0.20 + 0.16 * pulse1),
          const Color(0xFF0066FF).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.20, 0.50, 0.80, 1.0],
      ).createShader(Rect.fromLTWH(0, y1 - 2, w, 4));
    canvas.drawLine(Offset(0, y1), Offset(w, y1), paint1);

    // Subtle soft glow halo along route 1
    final halo1 = Paint()
      ..strokeWidth = 6.0
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0066FF).withValues(alpha: 0.08 + 0.05 * pulse1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromLTWH(0, y1 - 5, w, 10));
    canvas.drawLine(Offset(0, y1), Offset(w, y1), halo1);

    // Carrier Route 2: Upper logistics carrier line (between header and advantages, y ~ 0.34)
    final double y2 = h * 0.34;
    final double pulse2 = (math.cos(progress * 2 * math.pi) * 0.5 + 0.5);
    final paint2 = Paint()
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0066FF).withValues(alpha: 0.0),
          const Color(0xFF0066FF).withValues(alpha: 0.12 + 0.08 * pulse2),
          const Color(0xFF0066FF).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromLTWH(0, y2 - 2, w, 4));
    canvas.drawLine(Offset(0, y2), Offset(w, y2), paint2);
  }

  void _drawVelocityStreaks(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Angle: -35 degrees (converted to radians)
    const double angleRad = -35 * (math.pi / 180);
    final double dirX = math.cos(angleRad);
    final double dirY = math.sin(angleRad);

    // 6 Staggered Velocity Streamlines across diagonal lanes
    final List<_StreakSpec> streaks = [
      const _StreakSpec(
        laneOffset: 0.12,
        speed: 1.0,
        phase: 0.05,
        length: 220,
        strokeWidth: 1.8,
        maxAlpha: 0.42,
      ),
      const _StreakSpec(
        laneOffset: 0.28,
        speed: 0.85,
        phase: 0.35,
        length: 280,
        strokeWidth: 2.2,
        maxAlpha: 0.38,
      ),
      const _StreakSpec(
        laneOffset: 0.48,
        speed: 1.15,
        phase: 0.65,
        length: 190,
        strokeWidth: 1.6,
        maxAlpha: 0.48,
      ),
      const _StreakSpec(
        laneOffset: 0.65,
        speed: 0.95,
        phase: 0.15,
        length: 260,
        strokeWidth: 2.0,
        maxAlpha: 0.40,
      ),
      const _StreakSpec(
        laneOffset: 0.82,
        speed: 1.10,
        phase: 0.80,
        length: 240,
        strokeWidth: 1.8,
        maxAlpha: 0.44,
      ),
      const _StreakSpec(
        laneOffset: 0.95,
        speed: 0.90,
        phase: 0.45,
        length: 210,
        strokeWidth: 1.5,
        maxAlpha: 0.36,
      ),
    ];

    for (final streak in streaks) {
      final double cycleProgress =
          (progress * streak.speed + streak.phase) % 1.0;

      // Calculate start and end position along diagonal trajectory
      final double totalTravel = math.sqrt(w * w + h * h) + streak.length;
      final double currentTravel =
          cycleProgress * totalTravel - (streak.length * 0.5);

      final double originX = w * 0.1 + (w * 0.9 * streak.laneOffset);
      final double originY = h * 0.1 + (h * 0.9 * streak.laneOffset);

      final double startX = originX + dirX * (currentTravel - streak.length);
      final double startY = originY + dirY * (currentTravel - streak.length);
      final double endX = originX + dirX * currentTravel;
      final double endY = originY + dirY * currentTravel;

      // Opacity curve: Smooth fade-in and fade-out
      final double alphaCurve = math.sin(cycleProgress * math.pi);
      final double currentAlpha = (streak.maxAlpha * alphaCurve).clamp(
        0.0,
        1.0,
      );

      if (currentAlpha <= 0.02) continue;

      final streakPaint = Paint()
        ..strokeWidth = streak.strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader =
            LinearGradient(
              colors: [
                const Color(0xFF0066FF).withValues(alpha: 0.0),
                const Color(0xFF0066FF).withValues(alpha: currentAlpha),
                const Color(0xFF00779E).withValues(alpha: currentAlpha * 0.4),
                const Color(0xFF0066FF).withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.50, 0.75, 1.0],
            ).createShader(
              Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)),
            );

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), streakPaint);
    }
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Micro-particles at staggered coordinates matching design
    final List<_SparkleSpec> sparkles = [
      _SparkleSpec(
        x: w * 0.25,
        y: h * 0.22,
        freq: 1.0,
        phase: 0.2,
        radius: 2.5,
      ),
      _SparkleSpec(
        x: w * 0.30,
        y: h * 0.65,
        freq: 0.8,
        phase: 1.5,
        radius: 3.2,
      ), // Prominent cyan node in design
      _SparkleSpec(
        x: w * 0.73,
        y: h * 0.78,
        freq: 1.2,
        phase: 3.2,
        radius: 3.0,
      ), // Lower right cyan node in design
      _SparkleSpec(
        x: w * 0.82,
        y: h * 0.15,
        freq: 0.9,
        phase: 2.1,
        radius: 2.2,
      ),
      _SparkleSpec(
        x: w * 0.14,
        y: h * 0.46,
        freq: 1.1,
        phase: 0.8,
        radius: 2.0,
      ),
      _SparkleSpec(
        x: w * 0.88,
        y: h * 0.52,
        freq: 0.7,
        phase: 2.9,
        radius: 2.4,
      ),
      _SparkleSpec(
        x: w * 0.50,
        y: h * 0.90,
        freq: 1.0,
        phase: 4.0,
        radius: 2.2,
      ),
    ];

    for (final s in sparkles) {
      // Pulse shimmer animation curve
      final double wave = math.sin((progress * 2 * math.pi * s.freq) + s.phase);
      final double pulse = 0.5 + 0.5 * wave; // 0.0 to 1.0
      final double alpha = (0.25 + 0.75 * pulse).clamp(0.0, 1.0);

      // 1. Radiant Outer Halo
      final haloPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0066FF).withValues(alpha: alpha * 0.26);
      canvas.drawCircle(Offset(s.x, s.y), s.radius * 3.5, haloPaint);

      // 2. Vibrant Inner Core
      final corePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0066FF).withValues(alpha: alpha);
      canvas.drawCircle(Offset(s.x, s.y), s.radius, corePaint);

      // 3. Peak Sparkle Glint Flare
      if (pulse > 0.84) {
        final double glintScale = (pulse - 0.84) / 0.16;
        final double glintLen = 4.5 * glintScale;
        final glintPaint = Paint()
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: glintScale * 0.9);

        canvas.drawLine(
          Offset(s.x - glintLen, s.y),
          Offset(s.x + glintLen, s.y),
          glintPaint,
        );
        canvas.drawLine(
          Offset(s.x, s.y - glintLen),
          Offset(s.x, s.y + glintLen),
          glintPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FluidVelocityBgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StreakSpec {
  final double laneOffset;
  final double speed;
  final double phase;
  final double length;
  final double strokeWidth;
  final double maxAlpha;

  const _StreakSpec({
    required this.laneOffset,
    required this.speed,
    required this.phase,
    required this.length,
    required this.strokeWidth,
    required this.maxAlpha,
  });
}

class _SparkleSpec {
  final double x;
  final double y;
  final double freq;
  final double phase;
  final double radius;

  const _SparkleSpec({
    required this.x,
    required this.y,
    required this.freq,
    required this.phase,
    required this.radius,
  });
}
