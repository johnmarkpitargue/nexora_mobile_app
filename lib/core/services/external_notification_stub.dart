import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
bool _isInitialized = false;
int _notificationCounter = 2000;
String _currentStatus = 'granted';

Future<void> _ensureInitialized() async {
  if (_isInitialized || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
  try {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[ExternalNotification] User tapped buyer notification: ${response.payload}');
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'nexora_buyer_alerts',
          'Nexora Order & Delivery Alerts',
          description: 'Live order tracking, delivery updates, and store promotions',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    _isInitialized = true;
    debugPrint('[ExternalNotification] Buyer phone notifications initialized');
  } catch (e) {
    debugPrint('[ExternalNotification] Buyer init error: $e');
  }
}

void showExternalNotificationRequest() {
  requestExternalNotificationPermission();
}

Future<String> requestExternalNotificationPermission() async {
  if (kIsWeb) return 'unsupported';
  await _ensureInitialized();
  try {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      _currentStatus = (granted ?? true) ? 'granted' : 'denied';
      return _currentStatus;
    } else if (Platform.isIOS) {
      final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _currentStatus = (granted ?? true) ? 'granted' : 'denied';
      return _currentStatus;
    }
    _currentStatus = 'granted';
    return _currentStatus;
  } catch (e) {
    debugPrint('[ExternalNotification] Permission error: $e');
    return 'denied';
  }
}

String getExternalNotificationPermissionStatus() => _currentStatus;

void showExternalNotification({
  required String title,
  required String body,
  String? icon,
}) {
  debugPrint('[ExternalNotification] Firing buyer phone notification: $title - $body');
  try {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.lightImpact();
  } catch (_) {}

  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

  _ensureInitialized().then((_) async {
    try {
      final id = ++_notificationCounter;
      const androidDetails = AndroidNotificationDetails(
        'nexora_buyer_alerts',
        'Nexora Order & Delivery Alerts',
        channelDescription: 'Live order tracking, delivery updates, and store promotions',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF0066FF),
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          '',
          htmlFormatContent: true,
          htmlFormatTitle: true,
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('[ExternalNotification] Show error on phone: $e');
    }
  });
}

