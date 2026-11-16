import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/external_notification_service.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../../core/services/notification_preferences_service.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  final NotificationPreferencesService _service = NotificationPreferencesService.instance;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _triggerExternalTest() async {
    final status = _service.osPermissionStatus;
    if (status != 'granted') {
      final newStatus = await _service.requestOsPermission();
      if (newStatus == 'denied') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone notifications are disabled. Please enable push notifications in your phone settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Start 3 second countdown so user can lock/minimize phone
    setState(() {
      _countdownSeconds = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
        } else {
          timer.cancel();
          _countdownSeconds = 0;
          // Send external phone push notification
          ExternalNotificationService.show(
            title: 'Nexora Delivery Alert',
            body: 'Sample delivery update preview from Nexora Express Logistics.',
          );
          InAppNotificationService.instance.showNotification(
            senderName: 'Nexora Courier Alert',
            message: 'Phone push notification sent to your device notification bar!',
            orderId: 'NX-COURIER-TEST',
            icon: Icons.notifications_active_rounded,
          );
        }
      });
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF060914) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0D1323) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final iconBoxBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Preferences',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: dividerColor),
        ),
      ),
      body: AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          final permStatus = _service.osPermissionStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: System / OS Notification Permission Status Card
                _buildSystemStatusCard(permStatus, isDark),

                const SizedBox(height: 22),

                // SECTION 2: Notification Channels
                Text(
                  'Notification Channels',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                _buildChannelCard(isDark, cardBg, cardBorder, dividerColor, iconBoxBg, textPrimary, textSecondary),

                const SizedBox(height: 22),

                // SECTION 3: Live Interactive Test Controls
                Text(
                  'Test Notification Triggers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTestingCard(isDark, cardBg, cardBorder, textPrimary, textSecondary),

                const SizedBox(height: 22),

                // SECTION 4: Background & Exit Explanation
                _buildEducationalInfoCard(isDark, cardBorder, textPrimary, textSecondary),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemStatusCard(String permStatus, bool isDark) {
    bool isGranted = permStatus == 'granted';
    bool isDenied = permStatus == 'denied';

    Color cardBg = isGranted
        ? (isDark ? const Color(0xFF062817) : const Color(0xFFF0FDF4))
        : isDenied
            ? (isDark ? const Color(0xFF2D1214) : const Color(0xFFFEF2F2))
            : (isDark ? const Color(0xFF2A1D07) : const Color(0xFFFFFBEB));
    Color borderColor = isGranted
        ? (isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0))
        : isDenied
            ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA))
            : (isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A));
    Color badgeColor = isGranted
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
        : isDenied
            ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
            : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706));
    Color descColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    String statusTitle = isGranted
        ? 'Phone Push Notifications Active'
        : isDenied
            ? 'Phone Notifications Disabled'
            : 'Phone Notification Permission Needed';
    String statusDesc = isGranted
        ? 'Your phone push notification channel is enabled. You will receive real-time alerts on your phone lock screen and notification bar when your order is packed, dispatched, or when your courier messages you.'
        : isDenied
            ? 'Push notifications are currently disabled in your phone settings. Open your device Settings > Apps > Nexora > Notifications and toggle Allow Notifications.'
            : 'Tap below to enable phone push notifications so you receive real-time delivery and chat alerts on your mobile device.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGranted
                      ? Icons.notifications_active_rounded
                      : isDenied
                          ? Icons.notifications_off_rounded
                          : Icons.notifications_paused_rounded,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: ${permStatus.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusDesc,
            style: TextStyle(
              fontSize: 12.5,
              color: descColor,
              height: 1.4,
            ),
          ),
          if (!isGranted && !isDenied) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _service.requestOsPermission(),
                icon: const Icon(Icons.phone_android_rounded, size: 18),
                label: const Text('Enable Phone Push Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelCard(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color dividerColor,
    Color iconBoxBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Order Status & Tracking',
            subtitle: 'Immediate alerts when order is packed, shipped, or delivered',
            icon: Icons.local_shipping_outlined,
            value: _service.orderStatusAlerts,
            onChanged: (v) => _service.updateSettings(orderStatusAlerts: v),
            iconBoxBg: iconBoxBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(height: 1, indent: 56, color: dividerColor),
          _buildSwitchTile(
            title: 'Courier Dispatch & Live Location',
            subtitle: 'Driver pickup, proximity arrival notices, and doorstep delivery',
            icon: Icons.moped_rounded,
            value: _service.courierDispatchAlerts,
            onChanged: (v) => _service.updateSettings(courierDispatchAlerts: v),
            iconBoxBg: iconBoxBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(height: 1, indent: 56, color: dividerColor),
          _buildSwitchTile(
            title: 'Chat & Seller Messages',
            subtitle: 'Direct messages from shops, store reps, and courier inquiries',
            icon: Icons.chat_bubble_outline_rounded,
            value: _service.chatMessagesAlerts,
            onChanged: (v) => _service.updateSettings(chatMessagesAlerts: v),
            iconBoxBg: iconBoxBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(height: 1, indent: 56, color: dividerColor),
          _buildSwitchTile(
            title: 'Promotions, Vouchers & Flash Sales',
            subtitle: 'Discount vouchers, daily deals, and product restock alerts',
            icon: Icons.local_offer_outlined,
            value: _service.promoAlerts,
            onChanged: (v) => _service.updateSettings(promoAlerts: v),
            iconBoxBg: iconBoxBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Divider(height: 1, indent: 56, color: dividerColor),
          _buildSwitchTile(
            title: 'Sound & Audio Alert',
            subtitle: 'Chime on new in-app banner updates',
            icon: Icons.volume_up_outlined,
            value: _service.soundEnabled,
            onChanged: (v) => _service.updateSettings(soundEnabled: v),
            iconBoxBg: iconBoxBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color iconBoxBg,
    required Color textPrimary,
    required Color textSecondary,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBoxBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0066FF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF0066FF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTestingCard(
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Notification Simulator',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Test the notifications directly on your mobile device to see how in-app and phone push notifications behave.',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 14),

          // Test Button 1: In-App Banner
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                InAppNotificationService.instance.showNotification(
                  senderName: 'Order Dispatched',
                  message: 'Your Nexora order #NEX-88219 has departed the Laguna distribution hub!',
                  orderId: 'NEX-88219',
                  icon: Icons.local_shipping_outlined,
                  accentColor: const Color(0xFF0284C7),
                );
              },
              icon: const Icon(Icons.touch_app_outlined, size: 18, color: Color(0xFF0066FF)),
              label: const Text(
                'Test In-App Notification Banner',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0066FF)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Test Button 2: Phone Push Notification (Countdown)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _countdownSeconds > 0 ? null : _triggerExternalTest,
              icon: Icon(
                _countdownSeconds > 0 ? Icons.timer_outlined : Icons.phone_iphone_rounded,
                size: 18,
              ),
              label: Text(
                _countdownSeconds > 0
                    ? 'Lock / Minimize Phone! Sending in ${_countdownSeconds}s...'
                    : 'Test Phone Push Notification (3s Timer)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _countdownSeconds > 0
                    ? const Color(0xFFEA580C)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_countdownSeconds > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1508) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF9A3412) : const Color(0xFFFFEDD5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Color(0xFFEA580C)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Minimize the app or lock your phone screen now to see the push alert on your phone notification bar!',
                      style: TextStyle(fontSize: 11, color: Color(0xFFEA580C), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationalInfoCard(
    bool isDark,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1323) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 18, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                'How Phone Push Notifications Work',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Lock Screen & Status Bar: When the Nexora app is minimized or your phone is locked, real-time order updates and courier chat alerts are delivered directly to your Android / iOS notification drawer.\n\n'
            '• Sound & Vibration: Phone alerts use your mobile device\'s high-priority notification channel with vibration and sound chimes.',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
