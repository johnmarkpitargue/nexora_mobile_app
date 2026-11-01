import 'package:flutter/material.dart';
import '../../app/routes/app_routes.dart';
import '../services/buyer_account_service.dart';

class GuestAuthGuard {
  GuestAuthGuard._();

  /// Checks if the buyer is logged in.
  /// If logged in, returns true immediately.
  /// If guest/unauthenticated, displays an elegant bottom sheet modal requiring login before proceeding.
  /// Returns true if the user successfully logged in, or false if dismissed/cancelled.
  static Future<bool> requireLogin(
    BuildContext context, {
    String title = 'Sign In to Proceed',
    String message = 'Please sign in or create an account to proceed with your order, secure delivery addresses, and track real-time courier updates.',
  }) async {
    if (BuyerAccountService.instance.isLoggedIn) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => _LoginPromptSheet(
        title: title,
        message: message,
      ),
    );

    return (result == true) || BuyerAccountService.instance.isLoggedIn;
  }
}

class _LoginPromptSheet extends StatelessWidget {
  final String title;
  final String message;

  const _LoginPromptSheet({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 22),

          // Glowing Brand Icon Badge
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF030D26),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shopping_bag_rounded,
                  size: 34,
                  color: Color(0xFF00A3FF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Trust Badges Pill Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 15, color: Color(0xFF059669)),
                SizedBox(width: 5),
                Text(
                  '100% Authentic',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                SizedBox(width: 10),
                Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                SizedBox(width: 10),
                Icon(Icons.local_shipping_outlined, size: 15, color: Color(0xFF0284C7)),
                SizedBox(width: 5),
                Text(
                  'Doorstep Delivery',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Primary Button: "Sign In to Account"
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF00A3FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, false);
                final res = await Navigator.pushNamed(context, AppRoutes.login);
                if (res == true && context.mounted) {
                  // Successfully signed in
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In to Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Button: "Create a New Account"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () async {
                Navigator.pop(context, false);
                await Navigator.pushNamed(context, AppRoutes.register);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Create a New Account',
                style: TextStyle(
                  color: Color(0xFF0066FF),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dismiss: "Continue Browsing as Guest"
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Continue Browsing as Guest',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
