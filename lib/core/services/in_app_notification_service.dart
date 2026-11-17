import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'external_notification_service.dart';

/// Global high-visibility In-App Notification Overlay service.
/// Drops down elegantly from the top of the screen (similar to iOS / Grab push banners),
/// ensures notifications never block bottom navigation, and NEVER gets stuck.
class InAppNotificationService {
  InAppNotificationService._();
  static final InAppNotificationService instance = InAppNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  OverlayEntry? _currentEntry;
  Timer? _dismissTimer;

  void showNotification({
    required String senderName,
    required String message,
    required String orderId,
    IconData icon = Icons.two_wheeler_rounded,
    Color accentColor = const Color(0xFF0284C7),
    VoidCallback? onReply,
  }) {
    // 1. Trigger OS system-level notification (for when user is outside the app/minimized)
    ExternalNotificationService.show(title: '💬 $senderName', body: message);

    // 2. If an overlay is currently visible, dismiss it cleanly before displaying the new one
    dismiss();

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    _currentEntry = OverlayEntry(
      builder: (context) => _TopNotificationBanner(
        senderName: senderName,
        message: message,
        orderId: orderId,
        icon: icon,
        accentColor: accentColor,
        onDismiss: dismiss,
        onReply: () {
          dismiss();
          onReply?.call();
        },
      ),
    );

    overlayState.insert(_currentEntry!);

    // Guaranteed 4-second auto-dismissal
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      dismiss();
    });
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }
}

class _TopNotificationBanner extends StatefulWidget {
  final String senderName;
  final String message;
  final String orderId;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onDismiss;
  final VoidCallback onReply;

  const _TopNotificationBanner({
    required this.senderName,
    required this.message,
    required this.orderId,
    required this.icon,
    required this.accentColor,
    required this.onDismiss,
    required this.onReply,
  });

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnim = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _animController.forward();
  }

  void _handleDismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top > 0
        ? mediaQuery.padding.top + 8
        : 16.0;

    return Positioned(
      top: topPadding,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _offsetAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4) {
                _handleDismiss();
              }
            },
            onTap: widget.onReply,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF1F5F9),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nexora Blue Squircle Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0066FF), Color(0xFF00D2FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066FF)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(widget.icon, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Sender & Message text
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NEXORA ORDER',
                                  style: TextStyle(
                                    color: Color(0xFF0066FF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.senderName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '#${widget.orderId.replaceAll('#', '').toUpperCase()}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nexora Blue Pill Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066FF)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: widget.onReply,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6.5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VIEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 9,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Dismiss 'X' Button
                    InkWell(
                      onTap: _handleDismiss,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
