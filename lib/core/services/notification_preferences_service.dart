import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'external_notification_service.dart';

class NotificationPreferencesService extends ChangeNotifier {
  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();
  NotificationPreferencesService._() {
    _load();
  }

  static const _prefsKey = 'nexora_buyer_notification_prefs';

  bool pushEnabled = true;
  bool browserOsEnabled = true;
  bool orderStatusAlerts = true;
  bool courierDispatchAlerts = true;
  bool chatMessagesAlerts = true;
  bool promoAlerts = false;
  bool soundEnabled = true;

  String get osPermissionStatus => ExternalNotificationService.permissionStatus;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      pushEnabled = prefs.getBool('${_prefsKey}_push') ?? true;
      browserOsEnabled = prefs.getBool('${_prefsKey}_browser') ?? true;
      orderStatusAlerts = prefs.getBool('${_prefsKey}_orders') ?? true;
      courierDispatchAlerts = prefs.getBool('${_prefsKey}_courier') ?? true;
      chatMessagesAlerts = prefs.getBool('${_prefsKey}_chat') ?? true;
      promoAlerts = prefs.getBool('${_prefsKey}_promo') ?? false;
      soundEnabled = prefs.getBool('${_prefsKey}_sound') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_prefsKey}_push', pushEnabled);
      await prefs.setBool('${_prefsKey}_browser', browserOsEnabled);
      await prefs.setBool('${_prefsKey}_orders', orderStatusAlerts);
      await prefs.setBool('${_prefsKey}_courier', courierDispatchAlerts);
      await prefs.setBool('${_prefsKey}_chat', chatMessagesAlerts);
      await prefs.setBool('${_prefsKey}_promo', promoAlerts);
      await prefs.setBool('${_prefsKey}_sound', soundEnabled);
    } catch (_) {}
  }

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
    _save();
    notifyListeners();
  }
}
