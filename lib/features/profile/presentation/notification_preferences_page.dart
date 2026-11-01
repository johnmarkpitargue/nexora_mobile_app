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
            title: '📦 Nexora Courier Alert',
            body: 'Your package is out for delivery with Rider Pedro Jose Garcia! Tap to view live tracking.',
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Preferences',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
                _buildSystemStatusCard(permStatus),

                const SizedBox(height: 22),

                // SECTION 2: Notification Channels
                const Text(
                  'Notification Channels',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                _buildChannelCard(),

                const SizedBox(height: 22),

                // SECTION 3: Live Interactive Test Controls
                const Text(
                  'Test Notification Triggers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTestingCard(),

                const SizedBox(height: 22),

                // SECTION 4: Background & Exit Explanation
                _buildEducationalInfoCard(),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemStatusCard(String permStatus) {
    bool isGranted = permStatus == 'granted';
    bool isDenied = permStatus == 'denied';

    Color cardBg = isGranted
        ? const Color(0xFFF0FDF4)
        : isDenied
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFFFBEB);
    Color borderColor = isGranted
        ? const Color(0xFFBBF7D0)
        : isDenied
            ? const Color(0xFFFECACA)
            : const Color(0xFFFDE68A);
    Color badgeColor = isGranted
        ? const Color(0xFF16A34A)
        : isDenied
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);
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
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
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

  Widget _buildChannelCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Order Status & Tracking',
            subtitle: 'Immediate alerts when order is packed, shipped, or delivered',
            icon: Icons.local_shipping_outlined,
            value: _service.orderStatusAlerts,
            onChanged: (v) => _service.updateSettings(orderStatusAlerts: v),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildSwitchTile(
            title: 'Courier Dispatch & Live Location',
            subtitle: 'Driver pickup, proximity arrival notices, and doorstep delivery',
            icon: Icons.moped_rounded,
            value: _service.courierDispatchAlerts,
            onChanged: (v) => _service.updateSettings(courierDispatchAlerts: v),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildSwitchTile(
            title: 'Chat & Seller Messages',
            subtitle: 'Direct messages from shops, store reps, and courier inquiries',
            icon: Icons.chat_bubble_outline_rounded,
            value: _service.chatMessagesAlerts,
            onChanged: (v) => _service.updateSettings(chatMessagesAlerts: v),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildSwitchTile(
            title: 'Promotions, Vouchers & Flash Sales',
            subtitle: 'Discount vouchers, daily deals, and product restock alerts',
            icon: Icons.local_offer_outlined,
            value: _service.promoAlerts,
            onChanged: (v) => _service.updateSettings(promoAlerts: v),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildSwitchTile(
            title: 'Sound & Audio Alert',
            subtitle: 'Chime on new in-app banner updates',
            icon: Icons.volume_up_outlined,
            value: _service.soundEnabled,
            onChanged: (v) => _service.updateSettings(soundEnabled: v),
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
              color: const Color(0xFFF1F5F9),
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
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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

  Widget _buildTestingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Notification Simulator',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Test the notifications directly on your mobile device to see how in-app and phone push notifications behave.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                side: const BorderSide(color: Color(0xFFBFDBFE)),
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
                backgroundColor: _countdownSeconds > 0 ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
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
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFEDD5)),
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

  Widget _buildEducationalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF475569)),
              SizedBox(width: 8),
              Text(
                'How Phone Push Notifications Work',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Lock Screen & Status Bar: When the Nexora app is minimized or your phone is locked, real-time order updates and courier chat alerts are delivered directly to your Android / iOS notification drawer.\n\n'
            '• Sound & Vibration: Phone alerts use your mobile device\'s high-priority notification channel with vibration and sound chimes.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
