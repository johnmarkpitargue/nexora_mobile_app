import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/in_app_notification_service.dart';

/// Global service and animation manager for flying heart animations to the wishlist.
class WishlistAnimationService {
  /// Target GlobalKey assigned to the header wishlist button.
  static final GlobalKey targetWishlistKey = GlobalKey();

  /// ValueNotifier to trigger bounce scale on the destination wishlist icon.
  static final ValueNotifier<int> bounceNotifier = ValueNotifier<int>(0);

  /// Triggers a bounce micro-interaction on the target wishlist button.
  static void triggerBounce() {
    bounceNotifier.value++;
  }
}

/// Controller to launch a flying heart icon animation from any tapped position
/// into the header wishlist button destination.
class FlyToWishlistAnimation {
  static void fly({
    required BuildContext context,
    Offset? startPosition,
  }) {
    final overlay =
        Overlay.maybeOf(context) ??
        InAppNotificationService.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Calculate start position
    Offset start = startPosition ?? Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    // Calculate destination position (Header wishlist button)
    Offset end;
    final targetContext =
        WishlistAnimationService.targetWishlistKey.currentContext;
    if (targetContext != null) {
      final targetBox = targetContext.findRenderObject() as RenderBox?;
      if (targetBox != null && targetBox.hasSize) {
        end = targetBox.localToGlobal(
          Offset(targetBox.size.width / 2, targetBox.size.height / 2),
        );
      } else {
        end = Offset(
          MediaQuery.of(context).size.width - 70,
          MediaQuery.of(context).padding.top + 36,
        );
      }
    } else {
      end = Offset(
        MediaQuery.of(context).size.width - 70,
        MediaQuery.of(context).padding.top + 36,
      );
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _FlyingHeartWidget(
        start: start,
        end: end,
        onComplete: () {
          entry.remove();
          WishlistAnimationService.triggerBounce();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _FlyingHeartWidget extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onComplete;

  const _FlyingHeartWidget({
    required this.start,
    required this.end,
    required this.onComplete,
  });

  @override
  State<_FlyingHeartWidget> createState() => _FlyingHeartWidgetState();
}

class _FlyingHeartWidgetState extends State<_FlyingHeartWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuad,
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Evaluates quadratic bezier curve point for t in [0.0, 1.0]
  Offset _computeBezier(double t, Offset p0, Offset p1) {
    // Control point creates an upward, outward arc
    final double midX = (p0.dx + p1.dx) / 2;
    final double controlX = midX + (p0.dx > p1.dx ? 35 : -35);
    final double controlY = math.min(p0.dy, p1.dy) - 75;
    final Offset pCtrl = Offset(controlX, controlY);

    final double u = 1.0 - t;
    final double tt = t * t;
    final double uu = u * u;

    final double x = uu * p0.dx + 2 * u * t * pCtrl.dx + tt * p1.dx;
    final double y = uu * p0.dy + 2 * u * t * pCtrl.dy + tt * p1.dy;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double t = _animation.value;
        final Offset currentPos = _computeBezier(t, widget.start, widget.end);

        // Scale: pops up initially, stays legible in flight, shrinks as it enters the target icon
        double scale;
        if (t < 0.22) {
          scale = 0.5 + (t / 0.22) * 0.85; // 0.5 -> 1.35
        } else if (t < 0.82) {
          scale = 1.35 - ((t - 0.22) / 0.6) * 0.35; // 1.35 -> 1.0
        } else {
          scale = 1.0 - ((t - 0.82) / 0.18) * 0.65; // 1.0 -> 0.35
        }

        // Opacity: fades out right at the arrival moment
        final double opacity = t > 0.88 ? (1.0 - (t - 0.88) / 0.12).clamp(0.0, 1.0) : 1.0;

        // Subtle joyful rotation wobble during flight
        final double rotation = math.sin(t * math.pi * 2) * 0.18;

        return Positioned(
          left: currentPos.dx - 22,
          top: currentPos.dy - 22,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEF4444),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

