import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/in_app_notification_service.dart';

/// Floating center HUD toast with smooth heart bounce animation.
/// Triggered whenever an item is added to the user's wishlist.
class AddedToWishlistHUD {
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

  /// Displays the "Saved to Wishlist" HUD overlay with the updated wishlist count.
  static void show(
    BuildContext context, {
    String message = 'Saved to Wishlist',
    int? count,
  }) {
    dismiss();

    final overlay =
        Overlay.maybeOf(context) ??
        InAppNotificationService.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (ctx) => _AddedToWishlistHUDWidget(
        message: message,
        count: count,
      ),
    );

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

class _AddedToWishlistHUDWidget extends StatefulWidget {
  final String message;
  final int? count;
  const _AddedToWishlistHUDWidget({
    this.message = 'Saved to Wishlist',
    this.count,
  });

  @override
  State<_AddedToWishlistHUDWidget> createState() =>
      _AddedToWishlistHUDWidgetState();
}

class _AddedToWishlistHUDWidgetState extends State<_AddedToWishlistHUDWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _heartPulseAnimation;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _heartPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();

    if (!AddedToWishlistHUD.isTesting) {
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Container(
                    width: 155,
                    height: widget.count != null ? 135 : 120,
                    decoration: BoxDecoration(
                      color: const Color(0xEE0F172A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _heartPulseAnimation,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.15),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFEF4444),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (widget.count != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${widget.count} ${widget.count == 1 ? 'item' : 'items'} in wishlist',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Color(0xFFCBD5E1),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ],
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
}
