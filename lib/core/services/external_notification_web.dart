import 'package:flutter/foundation.dart';

/// Phone notification channel state for mobile/web preview.
String _phoneNotificationStatus = 'granted';

void playNotificationChime() {
  // Handled by phone notification sound channel
}

void vibratePhone([List<int>? pattern]) {
  // Handled by native phone haptics
}

void showExternalNotificationRequest() {
  _phoneNotificationStatus = 'granted';
  debugPrint('[ExternalNotification] Phone notification channel active.');
}

Future<String> requestExternalNotificationPermission() async {
  _phoneNotificationStatus = 'granted';
  debugPrint('[ExternalNotification] Phone push notification permission granted.');
  return _phoneNotificationStatus;
}

String getExternalNotificationPermissionStatus() {
  return _phoneNotificationStatus;
}

void showExternalNotification({
  required String title,
  required String body,
  String? icon,
}) {
  debugPrint('[PhoneNotification] 📱 $title — $body');
}

