import 'package:flutter/foundation.dart';

/// Web implementation: notifications are disabled on web per design requirements.
/// Real external notifications are handled exclusively on native mobile devices (phones).
void playNotificationChime() {
  // Web audio chime is disabled or silent on web
}

void vibratePhone([List<int>? pattern]) {
  // Vibrate is handled on native phone
}

bool isExternalNotificationGranted() {
  // Disabled on web
  return false;
}

void showExternalNotificationRequest() {
  // Web notifications are disabled; do not prompt user for browser notifications
  debugPrint('[ExternalNotification] Web notifications are intentionally disabled.');
}

Future<bool> requestExternalNotificationPermission() async {
  // Always return false on web as external notifications are phone-only
  debugPrint('[ExternalNotification] Web notifications are disabled. Phone notifications operate on mobile devices.');
  return false;
}

void showExternalNotification({
  required String title,
  required String body,
  String? icon,
  String? orderId,
}) {
  // Do not pop browser notifications on web
  debugPrint('[ExternalNotification] Ignored on web (phone-only): $title - $body');
}

