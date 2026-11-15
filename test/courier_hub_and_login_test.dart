import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_rider_app/core/network/api_client.dart';
import 'package:nexora_rider_app/core/services/rider_account_service.dart';
import 'package:nexora_rider_app/features/courier/models/courier_models.dart';
import 'package:nexora_rider_app/features/courier/services/courier_service.dart';
import 'package:nexora_rider_app/features/courier/presentation/courier_dashboard_page.dart';
import 'package:nexora_rider_app/features/auth/presentation/rider_login_page.dart';
import 'package:nexora_rider_app/features/transfer_courier/presentation/transfer_courier_shell.dart';

void main() {
  group('Courier Hub Domain & Service Tests', () {
    late CourierService service;

    setUp(() {
      service = CourierService.instance;
      service.resetToSeed();
    });

    test('CourierService initializes with default hub, riders, and parcels', () {
      expect(service.currentHub.id, 'NX-HUB-LAG-01');
      expect(service.riders.length, greaterThanOrEqualTo(4));
      expect(service.parcels.length, greaterThanOrEqualTo(9));

      expect(service.totalParcelsCount, equals(service.parcels.length));
      expect(service.deliveredTodayCount, greaterThan(0));
      expect(service.onTimeSuccessRate, greaterThan(0));
    });

    test('addInboundParcel adds a new parcel at sorting status', () {
      final initialCount = service.parcels.length;

      final newParcel = service.addInboundParcel(
        merchantName: 'Test Gadget Store',
        customerName: 'Juan dela Cruz',
        customerPhone: '09171234567',
        customerAddress: 'Santa Rosa Commercial Center, Laguna',
        city: 'Santa Rosa, Laguna',
        itemsDescription: 'Mechanical Keyboard x1',
        weightKg: 1.2,
        amountCod: 2500.0,
      );

      expect(service.parcels.length, equals(initialCount + 1));
      expect(newParcel.status, equals(CourierParcelStatus.sorting));
      expect(newParcel.id.startsWith('NX-PH-'), isTrue);
      expect(newParcel.merchantName, 'Test Gadget Store');
      expect(newParcel.amountCod, 2500.0);
    });

    test('assignParcelToRider assigns a parcel and rider correctly', () {
      final unassigned = service.parcels.firstWhere(
        (p) => p.assignedRiderId == null,
      );
      final rider = service.riders.first;

      final success = service.assignParcelToRider(
        parcelId: unassigned.id,
        riderId: rider.id,
      );
      expect(success, isTrue);

      final updated = service.parcels.firstWhere((p) => p.id == unassigned.id);
      expect(updated.assignedRiderId, equals(rider.id));
      expect(updated.assignedRiderName, equals(rider.name));
      expect(updated.status, equals(CourierParcelStatus.inTransit));
    });

    test('updateParcelStatus modifies status correctly', () {
      final parcel = service.parcels.first;

      final success = service.updateParcelStatus(
        parcelId: parcel.id,
        newStatus: CourierParcelStatus.delivered,
      );

      expect(success, isTrue);
      final updated = service.parcels.firstWhere((p) => p.id == parcel.id);
      expect(updated.status, equals(CourierParcelStatus.delivered));
      expect(updated.deliveredAt, isNotNull);
    });

    test('scanInboundWaybill receives or identifies scanned waybills', () {
      final firstId = service.parcels.first.id;

      // Scanning existing parcel returns it
      final scanned = service.scanInboundWaybill(firstId);
      expect(scanned, isNotNull);
      expect(scanned!.id, equals(firstId));

      // Scanning a brand new unknown tracking number creates an inbound parcel
      const newTracking = 'NX-PH-99998888';
      final autoCreated = service.scanInboundWaybill(newTracking);
      expect(autoCreated, isNotNull);
      expect(autoCreated!.status, equals(CourierParcelStatus.sorting));
    });

    test('batchDispatch assigns parcels to rider', () {
      final rider = service.riders.first;
      final unassignedParcels = service.parcels
          .where((p) => p.assignedRiderId == null)
          .take(2)
          .toList();

      final dispatchedCount = service.batchDispatch(
        riderId: rider.id,
        parcelIds: unassignedParcels.map((p) => p.id).toList(),
      );
      expect(dispatchedCount, equals(unassignedParcels.length));

      for (final p in unassignedParcels) {
        final updated = service.parcels.firstWhere((x) => x.id == p.id);
        expect(updated.assignedRiderId, equals(rider.id));
        expect(updated.status, equals(CourierParcelStatus.inTransit));
      }
    });
  });

  group('Courier Hub UI & Navigation Widget Tests', () {
    setUp(() {
      CourierService.instance.resetToSeed();
    });

    testWidgets('CourierDashboardPage renders hub header, metrics, and tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const MaterialApp(
          home: CourierDashboardPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Hub header
      expect(find.text('Nexora Courier Hub'), findsOneWidget);
      expect(find.text('Nexora Central Dispatch Hub'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);

      // Check Tabs
      expect(find.text('Parcels'), findsOneWidget);
      expect(find.text('Fleet'), findsOneWidget);
      expect(find.text('Scanner'), findsOneWidget);
      expect(find.text('Hub Stats'), findsOneWidget);

      // Check floating action button
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Switch to Fleet Tab
      await tester.tap(find.text('Fleet'));
      await tester.pumpAndSettle();
      expect(find.text('Pedro Jose Garcia'), findsOneWidget);

      // Switch to Waybill Scanner Tab
      await tester.tap(find.text('Scanner'));
      await tester.pumpAndSettle();
      expect(find.text('High-Speed Hub Waybill Terminal'), findsOneWidget);
      expect(find.text('Sample Waybills to Test:'), findsOneWidget);

      // Switch to Hub Stats Tab
      await tester.tap(find.text('Hub Stats'));
      await tester.pumpAndSettle();
      expect(find.text('Dispatch On-Time Performance'), findsOneWidget);
    });

    testWidgets('RiderLoginPage redirects courier role from Laravel API to TransferCourierShell', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ApiClient.instance.setMockClient(MockClient((req) async {
        if (req.url.path.endsWith('/auth/rider/login')) {
          return http.Response(jsonEncode({
            'data': {
              'token': 'test-courier-token',
              'role': 'courier',
              'user': {
                'id': 99,
                'first_name': 'Carlos',
                'last_name': 'Mendoza',
                'full_name': 'Carlos Mendoza',
                'email': 'courier@nexora.io',
                'contact_number': '09171234567',
                'role': 'courier',
                'account_status': 'active',
              },
              'courier_profile': {
                'company_name': 'Nexora Express Logistics',
              },
            },
            'message': 'Login successful.',
          }), 200);
        }
        return http.Response(jsonEncode({'data': {}, 'message': 'ok'}), 200);
      }));

      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderLoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextField, 'Enter your email or mobile number');
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, 'courier@nexora.io');
      await tester.pump();

      final passwordField = find.widgetWithText(TextField, 'Enter your password or 6-digit PIN');
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'Courier@2026');
      await tester.pumpAndSettle();

      final loginBtn = find.text('LOG IN');
      expect(loginBtn, findsOneWidget);
      await tester.ensureVisible(loginBtn);
      await tester.pumpAndSettle();
      await tester.tap(loginBtn);

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(TransferCourierShell), findsOneWidget);
      expect(RiderAccountService.instance.currentUserRole, equals('courier'));
    });
  });
}
