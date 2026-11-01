import 'external_notification_stub.dart'
    if (dart.library.html) 'external_notification_web.dart';

/// Service providing OS system-level notifications when user is outside the app
/// (e.g. In background, minimized, or viewing another browser tab/window).
class ExternalNotificationService {
  static void requestPermission() {
    showExternalNotificationRequest();
  }

  static Future<String> requestPermissionAsync() async {
    return requestExternalNotificationPermission();
  }

  static String get permissionStatus {
    return getExternalNotificationPermissionStatus();
  }

  static void show({
    required String title,
    required String body,
    String? icon,
  }) {
    showExternalNotification(title: title, body: body, icon: icon);
  }
}
