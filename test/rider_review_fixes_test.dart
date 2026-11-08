import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_rider_app/core/network/api_client.dart';
import 'package:nexora_rider_app/core/services/delivery_service.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/core/services/rider_service.dart';
import 'package:nexora_rider_app/core/models/delivery_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'nexora_rider_auth_token': 'test_rider_token'});
    await ApiClient.instance.init();
  });

  group('Rider Review Fixes Tests', () {
    test('R1: Fetch hubs and select hub sends correct payload and refreshes orders', () async {
      int selectHubCalledWith = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/hubs') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'name': 'Laguna Central Santa Cruz', 'code': 'HUB-LAG-01', 'is_selected': true},
                {'id': 2, 'name': 'Calamba Distribution Center', 'code': 'HUB-LAG-02', 'is_selected': false},
              ],
              'message': 'Hubs retrieved',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/hub/select') && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          selectHubCalledWith = body['hub_id'] as int;
          return http.Response(
            jsonEncode({
              'data': {'sorting_center_id': selectHubCalledWith},
              'message': 'Hub selected successfully',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/offers') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 101,
                  'order_id': 55,
                  'order_number': 'NX-TEST-55',
                  'pickup_location': 'Santa Cruz Hub',
                  'dropoff_location': 'Barangay Pagsawitan',
                  'expected_pay': 50.0,
                  'cod_amount': 250.0,
                  'expires_in_seconds': 60,
                }
              ],
              'message': 'Offers retrieved',
            }),
            200,
          );
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      final hubs = await DeliveryService.instance.fetchHubsRemote();
      expect(hubs.length, 2);
      expect(hubs.first['name'], 'Laguna Central Santa Cruz');

      final selected = await DeliveryService.instance.selectHubRemote(2);
      expect(selected, isTrue);
      expect(selectHubCalledWith, 2);
      expect(DeliveryService.instance.availableOrders.length, 1);
      expect(DeliveryService.instance.availableOrders.first.id, 'NX-TEST-55');
    });

    test('R2: Accept offer racing with another rider returns 409 and removes offer without fake success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/offers/101/accept')) {
          return http.Response(
            jsonEncode({
              'message': 'This delivery was already accepted by another rider or has expired.',
              'errors': {'offer': ['Offer is no longer available.']},
            }),
            409,
          );
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      // Populate available orders
      DeliveryService.instance.refreshAvailableOrders();

      expect(
        () => DeliveryService.instance.acceptOrderRemote('NX-TEST-55', offerId: '101'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );

      // Verify no active order was created locally
      expect(DeliveryService.instance.activeOrder, isNull);
    });

    test('R3: Complete delivery requires valid OTP and photo, handles 422 wrong OTP', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/complete')) {
          return http.Response(
            jsonEncode({
              'message': 'Invalid Delivery OTP (1/3 failed attempts).',
              'errors': {'delivery_otp': ['Invalid Delivery OTP (1/3 failed attempts).']},
            }),
            422,
          );
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      // Manually set an active order for test
      DeliveryService.instance.acceptOrder(
        'NX-TEST-55',
        fallbackRow: const {'customer_id': 'Test Buyer', 'delivery_address': 'Santa Cruz Laguna'},
      );
      expect(DeliveryService.instance.activeOrder, isNotNull);

      // Attempt complete with wrong OTP should throw ApiException and not mark delivered
      expect(
        () => DeliveryService.instance.completeDeliveryRemote(
          orderId: 'NX-TEST-55',
          deliveryOtp: '000000',
          podFilePath: 'test/dummy_pod.jpg',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
      );

      // Active order still active
      expect(DeliveryService.instance.activeOrder, isNotNull);
      expect(DeliveryService.instance.activeOrder!.status, isNot(DeliveryStatus.delivered));
    });

    test('R3: Fail delivery posts to server and resets active order stage', () async {
      bool failEndpointCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/fail')) {
          failEndpointCalled = true;
          return http.Response(
            jsonEncode({
              'data': {'order_id': 55, 'status': 'failed_delivery'},
              'message': 'Delivery marked as failed attempt.',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/deliveries/active')) {
          return http.Response(jsonEncode({'data': [], 'message': 'No active'}), 200);
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      DeliveryService.instance.acceptOrder(
        'NX-TEST-55',
        fallbackRow: const {'customer_id': 'Test Buyer', 'delivery_address': 'Santa Cruz Laguna'},
      );
      expect(DeliveryService.instance.activeOrder, isNotNull);

      final failed = await DeliveryService.instance.failDeliveryRemote(
        orderId: 'NX-TEST-55',
        reason: 'buyer_not_home',
        notes: 'Door locked, recipient not answering phone calls.',
      );

      expect(failed, isTrue);
      expect(failEndpointCalled, isTrue);
      expect(DeliveryService.instance.activeOrder, isNull);
      expect(DeliveryService.instance.activeOrderStage, 0);
    });

    test('R4: Remittance submits to server and updates unremitted COD balance', () async {
      double remittedAmount = 0.0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/remittance') && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          remittedAmount = (body['amount'] as num).toDouble();
          return http.Response(
            jsonEncode({
              'data': {
                'id': 1,
                'remittance_number': 'REM-2026-001',
                'amount': remittedAmount,
                'status': 'submitted',
              },
              'message': 'Remittance submitted successfully',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/earnings') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': {
                'unremitted_cod_balance': 0.0,
                'earnings_balance': 350.0,
                'today_earnings': 100.0,
                'total_deliveries': 12,
              },
              'message': 'Earnings retrieved',
            }),
            200,
          );
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      EarningsService.instance.resetCodBalanceForTest(500.0);
      expect(EarningsService.instance.codHeldBalance, 500.0);

      final ok = await EarningsService.instance.submitRemittanceRemote(
        amount: 500.0,
        notes: 'GCash ref: 90218847192',
      );

      expect(ok, isTrue);
      expect(remittedAmount, 500.0);
      expect(EarningsService.instance.codHeldBalance, 0.0);
    });

    test('R5: Rider profile syncs real rating, reviews, deliveries, and company name from API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/profile') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': {
                'user': {
                  'id': 134,
                  'full_name': 'Juan Rider 01',
                  'email': 'juan.rider@laguna.ph',
                  'contact_number': '+63 917 111 2222',
                  'avatar_url': 'https://ui-avatars.com/api/?name=Juan+Rider+01',
                },
                'courier_profile': {
                  'id': 10,
                  'vehicle_type': 'Motorcycle',
                  'plate_number': 'MC-1001',
                  'company_name': 'Laguna Express Logistics',
                  'sorting_center': 'Santa Cruz Hub',
                  'license_number': 'N01-23-456789',
                  'license_expiry_date': '2030-03-22',
                },
                'is_online': true,
                'rating': 4.33,
                'reviews_count': 3,
                'total_deliveries': 4,
                'earnings_balance': 330.00,
                'unremitted_cod_balance': 0.00,
                'recent_reviews': [
                  {
                    'id': 1,
                    'rating': 5,
                    'comment': 'Ayos boi',
                    'buyer_name': 'Juan M. Dela Cruz',
                    'order_number': 'NX-5S9H3ZPWGB',
                    'created_at': '2026-10-17T13:55:00Z',
                  },
                  {
                    'id': 2,
                    'rating': 3,
                    'comment': 'borat',
                    'buyer_name': 'Bryan A. Garnace',
                    'order_number': 'NX-6BTSKBIGS3',
                    'created_at': '2026-10-19T08:10:00Z',
                  },
                ],
              },
              'message': 'Rider profile retrieved successfully.',
            }),
            200,
          );
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      final res = await RiderService.instance.fetchProfileRemote();
      expect(res.success, isTrue);

      final profile = RiderService.instance.profile;
      expect(profile.name, 'Juan Rider 01');
      expect(profile.company, 'Laguna Express Logistics');
      expect(profile.vehicleType, 'Motorcycle');
      expect(profile.plateNumber, 'MC-1001');
      expect(profile.rating, 4.33);
      expect(profile.totalDeliveries, 4);
      expect(profile.reviewsCount, 3);
      expect(profile.walletBalance, 330.00);

      // Verify real buyer feedback populated
      final reviews = RiderService.instance.reviews;
      expect(reviews.length, 2);
      expect(reviews.first.comment, 'Ayos boi');
      expect(reviews.first.orderId, 'NX-5S9H3ZPWGB');
      expect(reviews.last.comment, 'borat');
      expect(reviews.last.customerName, 'Bryan A. Garnace');
    });

    test('R6: EarningsService syncs ₱330.00 balance, past 7 days chart, and real transactions', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/earnings') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': {
                'earnings_balance': 330.00,
                'unremitted_cod_balance': 0.00,
                'today_summary': {
                  'pickups': 1,
                  'deliveries': 0,
                  'total_pay': 30.00,
                },
                'weekly_total_pay': 330.00,
                'past_7_days': [
                  {'date': '2026-11-02', 'day': 'Mon', 'amount': 0.0, 'trips': 0},
                  {'date': '2026-11-03', 'day': 'Tue', 'amount': 0.0, 'trips': 0},
                  {'date': '2026-11-04', 'day': 'Wed', 'amount': 0.0, 'trips': 0},
                  {'date': '2026-11-05', 'day': 'Thu', 'amount': 0.0, 'trips': 0},
                  {'date': '2026-11-06', 'day': 'Fri', 'amount': 0.0, 'trips': 0},
                  {'date': '2026-11-07', 'day': 'Sat', 'amount': 0.0, 'trips': 0},
                  {'date': '2026-11-08', 'day': 'Sun', 'amount': 330.0, 'trips': 9},
                ],
                'recent_earnings': [
                  {
                    'id': 9,
                    'type': 'pickup',
                    'amount': 30.00,
                    'description': 'Pickup Pay (NX-DR8SI0NSKQ)',
                    'order_number': 'NX-DR8SI0NSKQ',
                    'earned_at': '2026-10-28T03:54:51Z',
                  },
                  {
                    'id': 8,
                    'type': 'delivery',
                    'amount': 50.00,
                    'description': 'Delivery Pay (NX-6BTSKBIGS3)',
                    'order_number': 'NX-6BTSKBIGS3',
                    'earned_at': '2026-10-19T08:07:00Z',
                  },
                ],
              },
              'message': 'Earnings retrieved successfully.',
            }),
            200,
          );
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      final data = await EarningsService.instance.fetchEarningsRemote();
      expect(data, isNotNull);
      expect(RiderService.instance.profile.walletBalance, 330.00);

      // Verify weekly performance 7-day data
      final weekly = EarningsService.instance.weeklyData;
      expect(weekly.length, 7);
      expect(weekly.last.dayName, 'Sun');
      expect(weekly.last.amount, 330.00);
      expect(weekly.last.ordersCount, 9);

      // Verify transactions
      final txns = EarningsService.instance.transactions;
      expect(txns.length, 2);
      expect(txns.first.title, 'Pickup Pay (NX-DR8SI0NSKQ)');
      expect(txns.first.amount, 30.00);
      expect(txns.last.title, 'Delivery Pay (NX-6BTSKBIGS3)');
      expect(txns.last.amount, 50.00);
    });

    test('R7: Active delivery task fetching automatically loads Order 32', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/deliveries/active') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 32,
                  'order_number': 'NX-DR8SI0NSKQ',
                  'tracking_number': 'TRK-DR8SI0NSKQ',
                  'status': 'assigned_to_rider',
                  'role': 'delivery',
                  'total': 9279.05,
                  'payment_method': 'cod',
                  'recipient_name': 'Juan Buyer',
                  'recipient_phone': '+63 917 000 1234',
                  'pickup_address': 'Central Hub, Laguna',
                  'dropoff_address': 'Sta Cruz, Laguna',
                  'items_count': 1,
                  'items': [
                    {'id': 1, 'product_name': 'Gaming Keyboard', 'quantity': 1, 'price': 999.0}
                  ],
                }
              ],
              'message': 'Active deliveries retrieved.',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/offers') && request.method == 'GET') {
          return http.Response(jsonEncode({'data': [], 'message': 'No offers'}), 200);
        }
        return http.Response('{"message": "Not Found"}', 404);
      });

      ApiClient.instance.setMockClient(mockClient);

      await DeliveryService.instance.refreshAvailableOrders();

      expect(DeliveryService.instance.activeOrder, isNotNull);
      final active = DeliveryService.instance.activeOrder!;
      expect(active.id, 'NX-DR8SI0NSKQ');
      expect(active.customerName, 'Juan Buyer');
      expect(active.customerAddress, 'Sta Cruz, Laguna');
      expect(active.status, DeliveryStatus.pickedUp);
      expect(DeliveryService.instance.activeOrderStage, 2);
    });
  });
}
