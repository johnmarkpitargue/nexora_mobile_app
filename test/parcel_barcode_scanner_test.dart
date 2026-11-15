import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/widgets/parcel_barcode_scanner.dart';
import 'package:nexora_rider_app/features/courier/presentation/tabs/scanner_tab_view.dart';
import 'package:nexora_rider_app/features/courier/services/courier_service.dart';
import 'package:nexora_rider_app/features/transfer_courier/models/transfer_manifest_models.dart';
import 'package:nexora_rider_app/features/transfer_courier/presentation/manifest_detail_screen.dart';

void main() {
  group('ParcelBarcodeScanner & Transfer Courier Scanning Tests', () {
    testWidgets(
      'Successful scan invokes validator, suppresses rapid duplicate frames, and pops true',
      (tester) async {
        final submitted = <String>[];
        bool? scannerResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    scannerResult = await ParcelBarcodeScanner.open(
                      context,
                      mode: ParcelScanMode.riderPickup,
                      title: 'Scan Order Waybill',
                      subtitle: 'Point camera at parcel barcode',
                      scannerPreviewOverride: (ctx, emitBarcode) => Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => emitBarcode('  nx-trk-abc123  '),
                            child: const Text('EMIT FRAME'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              emitBarcode('nx-trk-dup');
                              emitBarcode('nx-trk-dup');
                            },
                            child: const Text('EMIT DOUBLE FRAME'),
                          ),
                        ],
                      ),
                      onBarcodeSubmitted: (code) async {
                        submitted.add(code);
                        return ParcelScanSubmissionResult(
                          success: true,
                          message: 'Verified $code',
                        );
                      },
                    );
                  },
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('OPEN'));
        await tester.pumpAndSettle();

        expect(find.text('RIDER PICKUP SCAN'), findsOneWidget);

        await tester.tap(find.text('EMIT FRAME'));
        await tester.pump();
        expect(submitted, equals(['NX-TRK-ABC123']));
        expect(find.text('Verified NX-TRK-ABC123'), findsOneWidget);

        // Wait for delayed pop(true)
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(scannerResult, isTrue);
      },
    );

    testWidgets(
      'Failed backend scan shows error banner, pauses detection until Retry Scan, and preserves state',
      (tester) async {
        int calls = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: ParcelBarcodeScanner(
              mode: ParcelScanMode.manifestLoading,
              title: 'Manifest MNF-100',
              subtitle: 'Calamba Hub -> Sta Cruz Hub',
              initialProgressText: '0 / 2 parcels loaded',
              scannerPreviewOverride: (ctx, emitBarcode) => ElevatedButton(
                onPressed: () => emitBarcode('NX-WRONG-999'),
                child: const Text('EMIT WRONG'),
              ),
              onBarcodeSubmitted: (code) async {
                calls++;
                return const ParcelScanSubmissionResult(
                  success: false,
                  message: 'Parcel does not belong to this manifest.',
                );
              },
            ),
          ),
        );

        // Emit invalid barcode; tapping twice rapidly must not double-submit while paused
        await tester.tap(find.text('EMIT WRONG'));
        await tester.pump();
        await tester.tap(find.text('EMIT WRONG'));
        await tester.pump();

        expect(calls, equals(1));
        expect(find.text('Parcel does not belong to this manifest.'), findsOneWidget);
        expect(find.text('0 / 2 parcels loaded'), findsOneWidget);
        expect(find.text('Retry Scan'), findsOneWidget);

        // Empty manual entry validation
        await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
        await tester.pump();
        expect(find.text('Please enter or scan a valid tracking number.'), findsOneWidget);
      },
    );

    testWidgets(
      'ManifestDetailScreen continuous camera scanning updates live progress and finishes',
      (tester) async {
        final manifest = TransferManifestModel(
          id: 77,
          manifestNumber: 'MNF-2026-0077',
          status: 'loading',
          transferType: 'inter_hub',
          originHub: const HubSummary(id: 1, name: 'Calamba Hub', code: 'CAL-01'),
          destinationHub: const HubSummary(id: 2, name: 'Sta Cruz Hub', code: 'STC-01'),
          totalParcels: 2,
          loadedParcels: 0,
          loadingProgress: '0%',
          allLoaded: false,
          items: const [
            TransferManifestItemModel(
              id: 1,
              manifestId: 77,
              orderId: 101,
              trackingNumber: 'NX-TRK-0001',
              loadingStatus: 'pending',
              receivingStatus: 'pending',
            ),
            TransferManifestItemModel(
              id: 2,
              manifestId: 77,
              orderId: 102,
              trackingNumber: 'NX-TRK-0002',
              loadingStatus: 'pending',
              receivingStatus: 'pending',
            ),
          ],
        );

        int loaded = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: ManifestDetailScreen(
              manifestId: 77,
              initialManifestOverride: manifest,
              scannerPreviewOverride: (ctx, emitBarcode) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => emitBarcode('NX-TRK-0001'),
                    child: const Text('SCAN PARCEL 1'),
                  ),
                  ElevatedButton(
                    onPressed: () => emitBarcode('NX-TRK-0002'),
                    child: const Text('SCAN PARCEL 2'),
                  ),
                ],
              ),
              onScanBarcodeOverride: (tracking) async {
                loaded++;
                return ParcelScanSubmissionResult(
                  success: true,
                  message: 'Loaded $tracking',
                  progressText: '$loaded / 2 parcels loaded',
                  keepScanning: loaded < 2,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Start Scanning Parcels'), findsOneWidget);
        await tester.tap(find.text('Start Scanning Parcels'));
        await tester.pumpAndSettle();

        expect(find.text('MANIFEST LOADING SCAN'), findsOneWidget);
        expect(find.text('0 / 2 parcels loaded'), findsOneWidget);

        // Scan parcel 1: stays open in continuous mode after pause window
        await tester.tap(find.text('SCAN PARCEL 1'));
        await tester.pump();
        expect(find.text('1 / 2 parcels loaded'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 950));
        await tester.pumpAndSettle();

        // Still inside scanner for parcel 2
        expect(find.text('SCAN PARCEL 2'), findsOneWidget);
        await tester.tap(find.text('SCAN PARCEL 2'));
        await tester.pump();
        expect(find.text('2 / 2 parcels loaded'), findsOneWidget);

        // Auto-closes after final parcel completes
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(find.text('Start Scanning Parcels'), findsOneWidget);
      },
    );

    testWidgets(
      'ScannerTabView rejects unknown tracking numbers instead of silently selecting a parcel',
      (tester) async {
        CourierService.instance.resetToSeed();

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ScannerTabView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CAMERA READY'), findsOneWidget);
        expect(find.text('Tap to Open Camera Scanner'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'UNKNOWN-CODE-999');
        await tester.tap(find.text('Process'));
        await tester.pumpAndSettle();

        expect(find.text('Parcel "UNKNOWN-CODE-999" was not found.'), findsWidgets);
        ScaffoldMessenger.of(tester.element(find.byType(ScannerTabView))).clearSnackBars();

        // Valid seed parcel still resolves accurately
        final validParcel = CourierService.instance.parcels.first;
        await tester.enterText(find.byType(TextField), validParcel.id);
        await tester.tap(find.text('Process'));
        await tester.pumpAndSettle();

        expect(
          find.text('Customer: ${validParcel.customerName} (${validParcel.customerPhone})'),
          findsOneWidget,
        );
      },
    );
  });
}
