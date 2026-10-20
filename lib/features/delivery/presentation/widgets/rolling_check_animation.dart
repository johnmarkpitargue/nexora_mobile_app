import 'package:flutter/material.dart';

/// A simple, clean rolling checkmark animation that plays once when loaded.
class RollingCheckAnimation extends StatefulWidget {
  final double size;

  const RollingCheckAnimation({
    super.key,
    this.size = 72,
  });

  @override
  State<RollingCheckAnimation> createState() => _RollingCheckAnimationState();
}

class _RollingCheckAnimationState extends State<RollingCheckAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Single smooth roll: 1 full rotation decelerating to a stop
    _rotation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Clean scale entrance
    _scale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Plays exactly once
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return ScaleTransition(
      scale: _scale,
      child: RotationTransition(
        turns: _rotation,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981), // Green check circle
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: size * 0.62,
          ),
        ),
      ),
    );
  }
}
