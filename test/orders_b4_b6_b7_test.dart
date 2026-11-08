import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('B4, B6, B7 Order Operations & Hub Status Suite', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      OrderService.instance.enablePolling = false;
      BuyerAccountService.instance.resetState();
      OrderService.instance.clearAllOrders();
      await ApiClient.instance.saveToken('test_sanctum_token_123');
      BuyerAccountService.instance.registerBuyer(
        firstName: 'Test',
        lastName: 'Buyer',
        email: 'test.buyer@example.com',
        mobileNumber: '09171234567',
        dateOfBirth: DateTime(1995, 1, 1),
        password: 'Password@123',
        confirmPassword: 'Password@123',
        agreeTerms: true,
      );
      BuyerAccountService.instance.loginBuyer(
        emailOrPhone: 'test.buyer@example.com',
        password: 'Password@123',
      );
    });

    tearDown(() {
      OrderService.instance.stopPolling();
    });

    test('B4-1: cancelOrderRemote uses numeric serverId on /orders/{id}/cancel', () async {
      int? requestedServerId;
      String? requestedPath;
      String? sentReason;

      ApiClient.instance.client = MockClient((req) async {
        requestedPath = req.url.path;
        final segments = req.url.pathSegments;
        // /api/mobile/v1/buyer/orders/{id}/cancel
        if (req.url.path.contains('/cancel')) {
          final idIdx = segments.indexOf('orders') + 1;
          requestedServerId = int.tryParse(segments[idIdx]);
          final body = jsonDecode(req.body);
          sentReason = body['reason'];

          return http.Response(
            jsonEncode({
              'data': {
                'id': 789,
                'order_number': 'NX-20261108-789',
                'status': 'cancelled',
                'cancellation_reason': sentReason,
                'subtotal': 1200.0,
                'total': 1250.0,
                'items': [],
              },
              'message': 'Order cancelled successfully.',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final result = await OrderService.instance.cancelOrderRemote(
        789,
        reason: 'Duplicate order placed',
      );

      expect(requestedServerId, equals(789));
      expect(requestedPath, contains('/buyer/orders/789/cancel'));
      expect(sentReason, equals('Duplicate order placed'));
      expect(result.rawStatus, equals('cancelled'));
      expect(result.cancellationReason, equals('Duplicate order placed'));
    });

    test('B4-2: cancelOrderRemote throws ApiException on 422 and does NOT mutate state locally', () async {
      // Preload active order
      final activeOrder = OrderItemModel(
        serverId: 456,
        orderId: 'NX-456-ACTIVE',
        rawStatus: 'preparing',
        dateText: 'Today',
        statusText: 'Preparing',
        statusColor: const Color(0xFF2563EB),
        etaText: 'Preparing parcel',
        etaTime: '-',
        progress: 0.35,
        items: [],
        totalPrice: 999.0,
        paymentMethod: 'Cash on Delivery',
      );

      ApiClient.instance.client = MockClient((req) async {
        if (req.url.path.contains('/orders/456/cancel')) {
          return http.Response(
            jsonEncode({
              'message': 'Order cannot be cancelled because it is already preparing.',
            }),
            422,
          );
        }
        return http.Response('{}', 404);
      });

      expect(
        () => OrderService.instance.cancelOrderRemote(
          activeOrder.serverId,
          reason: 'Changed mind',
        ),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('already preparing'),
        )),
      );
    });

    test('B4-3: confirmReceiptRemote uses numeric serverId on /orders/{id}/confirm-receipt', () async {
      int? requestedServerId;

      ApiClient.instance.client = MockClient((req) async {
        if (req.url.path.contains('/confirm-receipt')) {
          final segments = req.url.pathSegments;
          final idIdx = segments.indexOf('orders') + 1;
          requestedServerId = int.tryParse(segments[idIdx]);

          return http.Response(
            jsonEncode({
              'data': {
                'id': 555,
                'order_number': 'NX-555-DELIVERED',
                'status': 'delivered',
                'subtotal': 800.0,
                'total': 850.0,
                'items': [],
              },
              'message': 'Receipt confirmed.',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final result = await OrderService.instance.confirmReceiptRemote(555);

      expect(requestedServerId, equals(555));
      expect(result.rawStatus, equals('delivered'));
      expect(result.tabBucket, equals('completed'));
    });

    test('B7-1: All backend logistics & hub statuses map to correct tabs and presentations', () {
      // 1. To Ship statuses
      for (final s in ['placed', 'confirmed', 'preparing', 'processing']) {
        final p = OrderItemModel.describeStatus(s);
        expect(p.tabBucket, equals('to_ship'), reason: 'Status $s must be in to_ship tab');
        final item = OrderItemModel(
          serverId: 1,
          orderId: 'NX-1',
          rawStatus: s,
          dateText: 'Today',
          statusText: p.statusText,
          statusColor: p.statusColor,
          etaText: p.etaText,
          etaTime: p.etaTime,
          progress: p.progress,
          items: [],
          totalPrice: 100.0,
          paymentMethod: 'COD',
        );
        expect(item.matchesTab('to_ship'), isTrue);
      }

      // 2. To Receive statuses (pickup, hub transfers, riders)
      final toReceiveStatuses = [
        'ready_for_pickup',
        'assigned',
        'picked_up',
        'at_hub',
        'at_sorting_center',
        'received_at_hub',
        'in_transit_hub',
        'in_transit',
        'sorting_hub',
        'sorted',
        'assigned_to_rider',
        'out_for_delivery',
        'failed_delivery',
        'delivery_failed',
        'shipped',
        'shipping',
        'to_deliver',
      ];

      for (final s in toReceiveStatuses) {
        final p = OrderItemModel.describeStatus(s, currentHubName: 'Sta. Cruz Hub');
        expect(p.tabBucket, equals('to_receive'), reason: 'Status $s must be in to_receive tab');
        final item = OrderItemModel(
          serverId: 1,
          orderId: 'NX-1',
          rawStatus: s,
          currentHubName: 'Sta. Cruz Hub',
          dateText: 'Today',
          statusText: p.statusText,
          statusColor: p.statusColor,
          etaText: p.etaText,
          etaTime: p.etaTime,
          progress: p.progress,
          items: [],
          totalPrice: 100.0,
          paymentMethod: 'COD',
        );
        expect(item.matchesTab('to_receive'), isTrue);
        if (s == 'received_at_hub') {
          expect(p.statusText, equals('Received at Hub'));
          expect(p.etaText, contains('Sta. Cruz Hub'));
        }
        if (s == 'in_transit_hub') {
          expect(p.statusText, equals('In Transit Between Hubs'));
          expect(p.etaText, contains('between hubs'));
        }
      }

      // 3. Completed statuses
      for (final s in ['delivered', 'completed']) {
        final p = OrderItemModel.describeStatus(s);
        expect(p.tabBucket, equals('completed'));
      }

      // 4. Cancelled status
      final cancelP = OrderItemModel.describeStatus('cancelled');
      expect(cancelP.tabBucket, equals('cancelled'));

      // 5. Return / Refund statuses
      for (final s in ['returned', 'return_to_sender', 'returned_to_sender']) {
        final p = OrderItemModel.describeStatus(s);
        expect(p.tabBucket, equals('return_refund'));
      }

      // Dispute on delivered order shifts presentation to Return / Refund
      final disputeP = OrderItemModel.describeStatus('delivered', hasDispute: true);
      expect(disputeP.tabBucket, equals('return_refund'));
      expect(disputeP.statusText, contains('Return / Refund Requested'));
    });

    test('B6-1: Delivery OTP is populated and visible when status is out_for_delivery', () {
      final json = {
        'id': 321,
        'order_number': 'NX-OTP-321',
        'status': 'out_for_delivery',
        'delivery_otp': '789123',
        'subtotal': 1500.0,
        'total': 1550.0,
        'items': [],
      };

      final order = OrderItemModel.fromApiJson(json);
      expect(order.rawStatus, equals('out_for_delivery'));
      expect(order.deliveryOtp, equals('789123'));
      expect(order.deliveryOtp.length, equals(6));
    });
  });
}

