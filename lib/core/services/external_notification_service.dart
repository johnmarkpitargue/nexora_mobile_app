import 'external_notification_stub.dart'
    if (dart.library.html) 'external_notification_web.dart';

class ExternalNotificationData {
  final String title;
  final String body;
  final String? icon;
  final String? payload;
  final DateTime timestamp;

  ExternalNotificationData({
    required this.title,
    required this.body,
    this.icon,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service providing OS system-level notifications when rider is outside the app
/// (e.g. In background, device locked, minimized, or viewing another browser tab/window).
/// Handles both mobile phone Service Worker notifications (Android/iOS) and desktop browsers.
class ExternalNotificationService {
  static final ExternalNotificationService instance = ExternalNotificationService._();
  ExternalNotificationService._();
  ExternalNotificationService();

  static final List<ExternalNotificationData> simulatedNotifications = [];

  static void requestPermission() {
    showExternalNotificationRequest();
  }

  static Future<bool> requestPermissionAsync() async {
    return requestExternalNotificationPermission();
  }

  static bool get isPermissionGranted => isExternalNotificationGranted();

  static void playChime() {
    playNotificationChime();
  }

  static void vibrate([List<int>? pattern]) {
    vibratePhone(pattern);
  }

  static void show({
    required String title,
    required String body,
    String? icon,
    String? orderId,
    String? payload,
    int? id,
  }) {
    final finalPayload = payload ?? orderId;
    simulatedNotifications.add(
      ExternalNotificationData(
        title: title,
        body: body,
        icon: icon,
        payload: finalPayload,
      ),
    );
    showExternalNotification(
      title: title,
      body: body,
      icon: icon,
      orderId: finalPayload,
    );
  }

  void showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String? icon,
  }) {
    show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      icon: icon,
    );
  }

  static void sendTestNotification() {
    show(
      title: '🔔 Nexora Rider Test Alert',
      body: 'External phone notifications, sound, and vibration are fully operational!',
      orderId: 'TEST-ALERT',
    );
  }
}
