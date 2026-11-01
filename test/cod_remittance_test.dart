import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/earnings_service.dart';
import 'package:nexora_rider_app/features/earnings/presentation/earnings_screen.dart';

void main() {
  setUp(() {
    EarningsService.instance.resetCodBalanceForTest(640.00);
  });

  group('COD Cash Remittance Flows Test', () {
    testWidgets('1. E-wallet Remittance Flow (GCash/Maya) clears held cash balance', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: EarningsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial COD card shows 640 Held
      expect(find.text('COD Remit'), findsOneWidget);
      expect(find.text('₱640 Held'), findsOneWidget);

      // Tap COD Remit Card to open bottom sheet
      await tester.tap(find.text('COD Remit'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with options
      expect(find.text('COD Cash Remittance'), findsOneWidget);
      expect(find.text('₱640.00 Held'), findsOneWidget);
      expect(find.text('Remit via GCash / Maya Direct'), findsOneWidget);
      expect(find.text('Hub Counter Deposit (Pasig Central)'), findsOneWidget);

      // Tap Remit via GCash / Maya Direct
      await tester.tap(find.text('Remit via GCash / Maya Direct'));
      await tester.pumpAndSettle();

      // E-wallet sheet is opened
      expect(find.text('Remit via e-Wallet'), findsOneWidget);
      expect(find.text('GCash Direct'), findsOneWidget);
      expect(find.text('Maya Direct'), findsOneWidget);
      expect(find.text('CONFIRM & REMIT ₱640.00'), findsOneWidget);

      // Switch to Maya
      await tester.tap(find.text('Maya Direct'));
      await tester.pumpAndSettle();
      expect(find.text('Maya Account'), findsOneWidget);

      // Toggle to QR Ph Scan mode
      await tester.tap(find.text('QR Ph Scan'));
      await tester.pumpAndSettle();
      expect(find.text('National Retail Payment System'), findsOneWidget);

      // Toggle back to 1-Click Remit
      await tester.tap(find.text('1-Click Remit'));
      await tester.pumpAndSettle();

      // Tap Confirm & Remit button
      final confirmBtn = find.text('CONFIRM & REMIT ₱640.00');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);

      // Pump through progress duration
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Check success dialog
      expect(find.text('Remittance Complete!'), findsOneWidget);
      expect(find.text('₱640.00 hand cash has been cleared.'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);

      // Tap DONE to close dialog
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // Balance is now 0.00, COD card displays 'All Cleared'
      expect(EarningsService.instance.codHeldBalance, 0.0);
      expect(find.text('All Cleared'), findsOneWidget);
    });

    testWidgets('2. Hub Counter Deposit Flow displays barcode voucher and clears cash', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: EarningsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open COD Remit Sheet
      await tester.tap(find.text('COD Remit'));
      await tester.pumpAndSettle();

      // Tap Hub Counter Deposit
      await tester.tap(find.text('Hub Counter Deposit (Pasig Central)'));
      await tester.pumpAndSettle();

      // Verify Hub Counter Deposit Pass is shown
      expect(find.text('Hub Counter Deposit Pass'), findsOneWidget);
      expect(find.text('Pasig Central Sorting Hub • Cluster 4B'), findsOneWidget);
      expect(find.text('VCH-PASIG-COD-88412'), findsOneWidget);
      expect(find.text('Cashier on Duty: Elena V. (ID: #PV-409)'), findsOneWidget);

      // Tap CASHIER SCANNED & RECEIVED CASH
      final cashierBtn = find.text('CASHIER SCANNED & RECEIVED CASH');
      expect(cashierBtn, findsOneWidget);
      await tester.tap(cashierBtn);

      // Pump through progress duration
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Success dialog shown
      expect(find.text('Remittance Complete!'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // Verify balance cleared
      expect(EarningsService.instance.codHeldBalance, 0.0);
    });

    testWidgets('3. Partial Remittance with amount chip selection', (tester) async {
      tester.view.physicalSize = const Size(450, 950);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: EarningsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open COD Remit Sheet
      await tester.tap(find.text('COD Remit'));
      await tester.pumpAndSettle();

      // Open E-wallet sheet
      await tester.tap(find.text('Remit via GCash / Maya Direct'));
      await tester.pumpAndSettle();

      // Select ₱200 chip
      await tester.tap(find.text('₱200'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM & REMIT ₱200.00'), findsOneWidget);
      await tester.tap(find.text('CONFIRM & REMIT ₱200.00'));

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('₱200.00 hand cash has been cleared.'), findsOneWidget);
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // Remaining is 640 - 200 = 440
      expect(EarningsService.instance.codHeldBalance, 440.00);
      expect(find.text('₱440 Held'), findsOneWidget);
    });
  });
}
