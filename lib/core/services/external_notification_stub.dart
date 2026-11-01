import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
bool _isInitialized = false;
int _notificationCounter = 1000;

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
        debugPrint('[ExternalNotification] User tapped phone notification: ${response.payload}');
      },
    );

    // Create high-priority notification channel for Android 8.0+
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'nexora_rider_orders',
          'Nexora Rider Deliveries',
          description: 'High priority alerts for incoming orders, pickup updates, and customer messages',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    _isInitialized = true;
    debugPrint('[ExternalNotification] Phone local notifications initialized successfully');
  } catch (e) {
    debugPrint('[ExternalNotification] Init error: $e');
  }
}

void showExternalNotificationRequest() {
  requestExternalNotificationPermission();
}

Future<bool> requestExternalNotificationPermission() async {
  if (kIsWeb) return false;
  await _ensureInitialized();
  try {
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? true;
    } else if (Platform.isIOS) {
      final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? true;
    }
    return true;
  } catch (e) {
    debugPrint('[ExternalNotification] Permission error: $e');
    return false;
  }
}

bool isExternalNotificationGranted() => true;

void playNotificationChime() {
  try {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
  } catch (_) {}
}

void vibratePhone([List<int>? pattern]) {
  try {
    HapticFeedback.vibrate();
  } catch (_) {}
}

void showExternalNotification({
  required String title,
  required String body,
  String? icon,
  String? orderId,
}) {
  debugPrint('[ExternalNotification] Firing phone notification: $title - $body (order: $orderId)');
  playNotificationChime();
  vibratePhone();

  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

  _ensureInitialized().then((_) async {
    try {
      final id = ++_notificationCounter;
      const androidDetails = AndroidNotificationDetails(
        'nexora_rider_orders',
        'Nexora Rider Deliveries',
        channelDescription: 'High priority alerts for incoming orders, pickup updates, and customer messages',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Nexora Rider Alert',
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF0066FF),
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.status,
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
        payload: orderId,
      );
    } catch (e) {
      debugPrint('[ExternalNotification] Show error on phone: $e');
    }
  });
}

