import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/in_app_notification_service.dart';

/// Floating center HUD toast matching modern e-commerce standards (Shopee / Lazada).
/// Displays a dark rounded modal in the center of the screen with a white circular
/// checkmark and "Added to cart" label upon adding an item.
class AddedToCartHUD {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static bool get _isTesting {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static bool get isTesting => _isTesting;

  /// Displays the "Added to cart" center HUD toast over the current screen.
  static void show(BuildContext context) {
    dismiss();

    final overlay =
        Overlay.maybeOf(context) ??
        InAppNotificationService.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final entry = OverlayEntry(builder: (ctx) => const _AddedToCartHUDWidget());

    _currentEntry = entry;
    overlay.insert(entry);

    if (!_isTesting) {
      _timer = Timer(const Duration(milliseconds: 1700), () {
        dismiss();
      });
    }
  }

  /// Cleanly dismisses any currently active HUD instance.
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }
}

class _AddedToCartHUDWidget extends StatefulWidget {
  const _AddedToCartHUDWidget();

  @override
  State<_AddedToCartHUDWidget> createState() => _AddedToCartHUDWidgetState();
}

class _AddedToCartHUDWidgetState extends State<_AddedToCartHUDWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Trigger fade-out shortly before removal
    if (!AddedToCartHUD.isTesting) {
      _fadeTimer = Timer(const Duration(milliseconds: 1350), () {
        if (mounted) {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 155,
              height: 125,
              decoration: BoxDecoration(
                color: const Color(
                  0xEB262626,
                ), // Dark charcoal with smooth opacity
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // White circular checkmark icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Color(0xFF262626),
                        size: 30,
                        weight: 900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // "Added to cart" label
                  const Text(
                    'Added to cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
