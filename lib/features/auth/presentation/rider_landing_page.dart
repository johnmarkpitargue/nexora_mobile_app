import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/rider_account_service.dart';
import '../../shell/presentation/rider_shell.dart';
import '../../transfer_courier/presentation/transfer_courier_shell.dart';
import 'rider_login_page.dart';

class RiderLandingPage extends StatefulWidget {
  const RiderLandingPage({super.key});

  @override
  State<RiderLandingPage> createState() => _RiderLandingPageState();
}

class _RiderLandingPageState extends State<RiderLandingPage>
    with SingleTickerProviderStateMixin {
  static const _minimumDisplayTime = Duration(milliseconds: 1400);

  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );
    _introController.forward();
    _continueToApp();
  }

  Future<void> _continueToApp() async {
    final minimumDelay = Future<void>.delayed(_minimumDisplayTime);
    Widget destination = const RiderLoginPage();

    if (ApiClient.instance.isAuthenticated) {
      final role = await RiderAccountService.instance
          .restoreSessionRemote()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (role != null) {
        destination = role == 'courier'
            ? const TransferCourierShell()
            : const RiderShell();
      }
    }

    await minimumDelay;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: _SplashPainter())),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: disableAnimations
                    ? kAlwaysCompleteAnimation
                    : _fadeAnimation,
                child: ScaleTransition(
                  scale: disableAnimations
                      ? kAlwaysCompleteAnimation
                      : _scaleAnimation,
                  child: const _SplashBrand(),
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: _SplashProgress(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Nexora Rider',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF075FED).withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'NEXORA RIDER',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Laguna Express Logistics',
            style: TextStyle(
              color: Color(0xFF52657E),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Preparing your rider workspace',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 112,
            child: LinearProgressIndicator(
              minHeight: 3,
              borderRadius: BorderRadius.all(Radius.circular(3)),
              backgroundColor: Color(0xFFCDE7FA),
              color: Color(0xFF075FED),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Preparing your workspace',
            style: TextStyle(
              color: const Color(0xFF52657E).withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  const _SplashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF7FBFF), Color(0xFFE6F5FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    final routePaint = Paint()
      ..color = const Color(0xFF2584FF).withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-size.width * 0.12, size.height * 0.64),
      Offset(size.width * 0.78, size.height * 0.34),
      routePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.98),
      Offset(size.width * 1.10, size.height * 0.72),
      routePaint,
    );

    final nodePaint = Paint()
      ..color = const Color(0xFF2584FF).withValues(alpha: 0.24);
    for (final point in [
      Offset(size.width * 0.82, size.height * 0.17),
      Offset(size.width * 0.18, size.height * 0.73),
      Offset(size.width * 0.78, size.height * 0.76),
    ]) {
      canvas.drawCircle(point, 7, nodePaint);
      canvas.drawCircle(point, 2.2, Paint()..color = const Color(0xFF2584FF));
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => false;
}
