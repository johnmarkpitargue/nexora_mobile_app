import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/profile_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Clean 2-second presentation before transitioning into the app
    _timer = Timer(const Duration(milliseconds: 2000), () {
      _proceedToApp();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  void _proceedToApp() {
    if (!mounted || _navigated) return;
    _navigated = true;
    _timer?.cancel();

    // Check both local buyer session and active Supabase session
    final supabaseUser = SupabaseAuthService.instance.currentUser;
    if (supabaseUser != null && !BuyerAccountService.instance.isLoggedIn) {
      final email = supabaseUser.email ?? '';
      final metadata = supabaseUser.userMetadata ?? {};
      final name = (metadata['full_name'] ?? metadata['name'] ?? email.split('@').first).toString();
      BuyerAccountService.instance.establishGoogleSession(name: name, email: email);
      ProfileService.instance.updateProfile(name: name, email: email, phone: '');
    }

    final isLoggedIn = BuyerAccountService.instance.isLoggedIn ||
        SupabaseAuthService.instance.isAuthenticated;
    final targetRoute = isLoggedIn ? AppRoutes.home : AppRoutes.landing;

    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011030),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceedToApp, // Tap anywhere to skip instantly
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.90 + (0.10 * value),
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/images/logo.png',
              width: 240,
              height: 240,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.shopping_bag_rounded,
                size: 80,
                color: Color(0xFF0066FF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
