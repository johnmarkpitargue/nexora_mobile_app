import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/external_notification_service.dart';
import 'package:nexora_rider_app/core/services/in_app_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rider External & In-App Notification Tests', () {
    setUp(() {
      InAppNotificationService.instance.clearHistory();
    });

    test('ExternalNotificationService methods execute without errors', () async {
      expect(ExternalNotificationService.isPermissionGranted, isNotNull);
      ExternalNotificationService.playChime();
      ExternalNotificationService.vibrate();
      ExternalNotificationService.sendTestNotification();

      final res = await ExternalNotificationService.requestPermissionAsync();
      expect(res, isA<bool>());
    });

    test('InAppNotificationService records history and updates unread count', () {
      expect(InAppNotificationService.instance.history.isEmpty, isTrue);
      expect(InAppNotificationService.instance.unreadCountNotifier.value, 0);

      InAppNotificationService.instance.showNotification(
        senderName: 'Alex Rivera',
        message: 'Please leave the package at unit door',
        orderId: 'NX-9988',
      );

      expect(InAppNotificationService.instance.history.length, 1);
      expect(InAppNotificationService.instance.unreadCountNotifier.value, 1);

      final item = InAppNotificationService.instance.history.first;
      expect(item.orderId, 'NX-9988');
      expect(item.title, contains('Customer Alex Rivera'));
      expect(item.message, 'Please leave the package at unit door');
      expect(item.timeAgo, 'Just now');

      InAppNotificationService.instance.markAllAsRead();
      expect(item.isRead, isTrue);
      expect(InAppNotificationService.instance.unreadCountNotifier.value, 0);

      InAppNotificationService.instance.clearHistory();
      expect(InAppNotificationService.instance.history.isEmpty, isTrue);
    });

    testWidgets('Notification history sheet renders and displays controls', (tester) async {
      InAppNotificationService.instance.showNotification(
        senderName: 'New Delivery Dispatch',
        message: 'Order #NX-1002 is ready for pickup at Central Hub',
        orderId: 'NX-1002',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  InAppNotificationService.instance.showNotificationHistory(context);
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Dispatch & Order Alerts'), findsOneWidget);
      expect(find.textContaining('Phone Push Alerts'), findsOneWidget);
      expect(find.text('Test Sound & Vibrate'), findsOneWidget);
      expect(find.text('Order #NX-1002 is ready for pickup at Central Hub'), findsOneWidget);

      // Tap Test Sound & Vibrate
      await tester.tap(find.text('Test Sound & Vibrate'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sent test alert to phone lock screen'), findsOneWidget);
    });
  });
}
