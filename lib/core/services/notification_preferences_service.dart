import 'package:flutter/material.dart';
import 'external_notification_service.dart';

class NotificationPreferencesService extends ChangeNotifier {
  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();
  NotificationPreferencesService._();

  bool pushEnabled = true;
  bool browserOsEnabled = true;
  bool orderStatusAlerts = true;
  bool courierDispatchAlerts = true;
  bool chatMessagesAlerts = true;
  bool promoAlerts = false;
  bool soundEnabled = true;

  String get osPermissionStatus => ExternalNotificationService.permissionStatus;

  Future<String> requestOsPermission() async {
    final status = await ExternalNotificationService.requestPermissionAsync();
    notifyListeners();
    return status;
  }

  void updateSettings({
    bool? pushEnabled,
    bool? browserOsEnabled,
    bool? orderStatusAlerts,
    bool? courierDispatchAlerts,
    bool? chatMessagesAlerts,
    bool? promoAlerts,
    bool? soundEnabled,
  }) {
    if (pushEnabled != null) this.pushEnabled = pushEnabled;
    if (browserOsEnabled != null) this.browserOsEnabled = browserOsEnabled;
    if (orderStatusAlerts != null) this.orderStatusAlerts = orderStatusAlerts;
    if (courierDispatchAlerts != null) {
      this.courierDispatchAlerts = courierDispatchAlerts;
    }
    if (chatMessagesAlerts != null) {
      this.chatMessagesAlerts = chatMessagesAlerts;
    }
    if (promoAlerts != null) this.promoAlerts = promoAlerts;
    if (soundEnabled != null) this.soundEnabled = soundEnabled;
    notifyListeners();
  }
}
