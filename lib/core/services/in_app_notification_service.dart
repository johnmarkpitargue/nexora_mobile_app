import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'external_notification_service.dart';
import 'delivery_service.dart';
import '../../features/delivery/presentation/active_delivery_screen.dart';
import '../../features/delivery/presentation/rider_live_orders_screen.dart';
import '../../features/chat/presentation/rider_chat_screen.dart';

/// Data model representing a recorded Rider Notification.
class RiderNotificationItem {
  final String id;
  final String title;
  final String message;
  final String orderId;
  final DateTime timestamp;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onAction;
  bool isRead;

  RiderNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.orderId,
    required this.timestamp,
    this.icon = Icons.notifications_active_rounded,
    this.accentColor = const Color(0xFF0066FF),
    this.onAction,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Global high-visibility In-App Notification Overlay service for Rider App.
/// Drops down elegantly from the top of the screen (similar to iOS / Grab push banners),
/// ensures notifications never block bottom navigation, and NEVER gets stuck.
class InAppNotificationService {
  InAppNotificationService._();
  static final InAppNotificationService instance = InAppNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  OverlayEntry? _currentEntry;
  Timer? _dismissTimer;

  final List<RiderNotificationItem> _history = [];
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  List<RiderNotificationItem> get history => List.unmodifiable(_history);

  void markAllAsRead() {
    for (final item in _history) {
      item.isRead = true;
    }
    unreadCountNotifier.value = 0;
  }

  void clearHistory() {
    _history.clear();
    unreadCountNotifier.value = 0;
  }

  void showNotification({
    required String senderName,
    required String message,
    required String orderId,
    IconData icon = Icons.person_pin_circle_rounded,
    Color accentColor = const Color(0xFF0066FF),
    VoidCallback? onReply,
  }) {
    // 1. Determine title and trigger OS system-level phone notification + audio chime + vibration
    final isDispatch =
        senderName.contains('Dispatch') ||
        senderName.contains('Delivery') ||
        senderName.contains('Order') ||
        senderName.contains('Alert');

    final title = isDispatch ? '📦 $senderName' : '💬 Customer $senderName';

    ExternalNotificationService.show(
      title: title,
      body: message,
      orderId: orderId,
    );

    final effectiveReply =
        onReply ??
        () {
          final nav = navigatorKey.currentState;
          if (nav == null) return;

          final cleanId = orderId.replaceAll('#', '').trim();
          final active = DeliveryService.instance.activeOrder;
          if (active != null &&
              active.id.replaceAll('#', '').trim() == cleanId) {
            nav.push(
              MaterialPageRoute(
                builder: (_) => ActiveDeliveryScreen(order: active),
              ),
            );
            return;
          }

          final available = DeliveryService.instance.availableOrders;
          final match = available
              .where((o) => o.id.replaceAll('#', '').trim() == cleanId)
              .toList();
          if (match.isNotEmpty) {
            nav.push(
              MaterialPageRoute(
                builder: (_) => ActiveDeliveryScreen(order: match.first),
              ),
            );
            return;
          }

          if (isDispatch) {
            nav.push(
              MaterialPageRoute(builder: (_) => const RiderLiveOrdersScreen()),
            );
          } else {
            nav.push(
              MaterialPageRoute(
                builder: (_) =>
                    RiderChatScreen(orderId: orderId, customerName: senderName),
              ),
            );
          }
        };

    // 2. Add to notification history & increment unread counter
    final item = RiderNotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_$orderId',
      title: title,
      message: message,
      orderId: orderId,
      timestamp: DateTime.now(),
      icon: icon,
      accentColor: accentColor,
      onAction: effectiveReply,
      isRead: false,
    );

    _history.insert(0, item);
    if (_history.length > 50) {
      _history.removeLast();
    }
    unreadCountNotifier.value++;

    // 3. If an overlay is currently visible, dismiss it cleanly before displaying the new one
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
          item.isRead = true;
          effectiveReply();
        },
      ),
    );

    overlayState.insert(_currentEntry!);

    // Auto-dismiss after 4.5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 4500), () {
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

  /// Displays the full Nexora Notification History Bottom Sheet
  void showNotificationHistory(BuildContext context) {
    markAllAsRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NotificationHistorySheet(),
    );
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
                  children: [
                    // Nexora Blue Squircle Badge
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
                                  'NEXORA RIDER',
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
                                '#${widget.orderId.toUpperCase()}',
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
                          color: Color(0xFF94A3B8),
                          size: 17,
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

/// Nexora Notification History Bottom Sheet
class _NotificationHistorySheet extends StatefulWidget {
  const _NotificationHistorySheet();

  @override
  State<_NotificationHistorySheet> createState() =>
      _NotificationHistorySheetState();
}

class _NotificationHistorySheetState extends State<_NotificationHistorySheet> {
  bool _isPermissionGranted = ExternalNotificationService.isPermissionGranted;

  Future<void> _requestPhonePermission() async {
    final granted = await ExternalNotificationService.requestPermissionAsync();
    if (mounted) {
      setState(() {
        _isPermissionGranted = granted;
      });
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Phone System Notifications & Vibration Enabled!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _testPhoneAlert() {
    ExternalNotificationService.sendTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Sent test alert to phone lock screen & sound!'),
        backgroundColor: Color(0xFF0066FF),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = InAppNotificationService.instance.history;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF050B28),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF00D2FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispatch & Order Alerts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Real-time customer & courier notifications',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          InAppNotificationService.instance.clearHistory();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Phone Notification Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _isPermissionGranted
                          ? const Color(0xFF0F2342)
                          : const Color(0xFF281C10),
                      const Color(0xFF0A1535),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPermissionGranted
                        ? const Color(0xFF0066FF).withValues(alpha: 0.4)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isPermissionGranted
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPermissionGranted
                              ? 'Phone Push Alerts: Active'
                              : 'Phone Push Alerts: Tap to Enable',
                          style: TextStyle(
                            color: _isPermissionGranted
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Vibrate & Sound ON',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (!_isPermissionGranted) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _requestPhonePermission,
                              icon: const Icon(
                                Icons.notifications_active_rounded,
                                size: 15,
                              ),
                              label: const Text(
                                'Enable Phone Push',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testPhoneAlert,
                            icon: const Icon(
                              Icons.volume_up_rounded,
                              size: 15,
                              color: Color(0xFF00D2FF),
                            ),
                            label: const Text(
                              'Test Sound & Vibrate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF00D2FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0066FF)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Notifications List
            Flexible(
              child: history.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1A40),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0066FF)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF64748B),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No recent notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Incoming customer messages and new dispatch assignments will appear here and notify your phone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: history.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = history[index];
                        return Material(
                          color: const Color(0xFF0A1435),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              notif.isRead = true;
                              notif.onAction?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF1E293B),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: notif.accentColor.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      notif.icon,
                                      color: notif.accentColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              notif.timeAgo,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          notif.message,
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066FF)
                                          .withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF00D2FF)
                                            .withValues(alpha: 0.45),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'VIEW',
                                          style: TextStyle(
                                            color: Color(0xFF00D2FF),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Color(0xFF00D2FF),
                                          size: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
