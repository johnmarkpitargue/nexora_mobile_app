import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/features/transfer_courier/models/transfer_manifest_models.dart';
import 'package:nexora_rider_app/features/transfer_courier/presentation/manifest_detail_screen.dart';

void main() {
  test('ParcelIncidentSummaryModel and TransferManifestModel parse lifecycle fields accurately', () {
    final manifestJson = {
      'id': 42,
      'manifest_number': 'MF-20261118-0042',
      'status': 'closed_with_exceptions',
      'transfer_type': 'internal',
      'total_parcels': 1,
      'loaded_parcels': 1,
      'loading_progress': '1/1',
      'all_loaded': true,
      'items': [
        {
          'id': 701,
          'manifest_id': 42,
          'order_id': 9001,
          'tracking_number': 'NX-TRK-INC-01',
          'loading_status': 'issue',
          'receiving_status': 'missing',
          'issue_notes': 'Damaged seam discovered en route.',
          'disposition': 'accepted_into_quarantine',
          'incident': {
            'id': 11,
            'incident_number': 'INC-20261118-0011',
            'incident_type': 'damage',
            'investigation_status': 'awaiting_disposition',
            'status_label': 'Awaiting Disposition',
            'disposition': 'accepted_into_quarantine',
            'disposition_label': 'Accepted Into Quarantine',
            'last_known_location': 'Calamba Dock B',
            'reported_at': 'Nov 18, 2026 09:00 AM',
            'events': [
              {
                'id': 501,
                'event_type': 'reported',
                'to_status': 'open',
                'location': 'Calamba Dock B',
                'notes': 'Seal torn near corner.',
                'occurred_at': 'Nov 18, 2026 09:00 AM',
              },
            ],
          },
        },
      ],
    };

    final manifest = TransferManifestModel.fromJson(manifestJson);

    expect(manifest.isTerminal, isTrue);
    expect(manifest.canReportIssue, isFalse);
    expect(manifest.items.length, 1);

    final item = manifest.items.first;
    expect(item.incident, isNotNull);
    expect(item.incident!.incidentNumber, 'INC-20261118-0011');
    expect(item.incident!.events.length, 1);
    expect(item.incident!.events.first.location, 'Calamba Dock B');
  });

  testWidgets('ManifestDetailScreen shows incident badge, opens read-only timeline, and omits self-resolve buttons', (tester) async {
    final activeManifest = TransferManifestModel(
      id: 88,
      manifestNumber: 'MF-20261118-0088',
      status: 'in_transit',
      transferType: 'internal',
      originHub: const HubSummary(id: 1, name: 'Calamba Hub', code: 'CAL'),
      destinationHub: const HubSummary(id: 2, name: 'Santa Cruz Hub', code: 'STC'),
      totalParcels: 1,
      loadedParcels: 1,
      loadingProgress: '1/1',
      allLoaded: true,
      vehiclePlateNumber: 'NXR-888',
      dispatchedAt: '2026-11-18T08:00:00Z',
      items: const [
        TransferManifestItemModel(
          id: 101,
          manifestId: 88,
          orderId: 500,
          trackingNumber: 'NX-RIDER-INC-1',
          loadingStatus: 'loaded',
          receivingStatus: 'pending',
          issueNotes: 'Minor carton crush near SLEX.',
          incident: ParcelIncidentSummaryModel(
            id: 21,
            incidentNumber: 'INC-20261118-0021',
            incidentType: 'damage',
            investigationStatus: 'under_investigation',
            statusLabel: 'Under Investigation',
            lastKnownLocation: 'SLEX Tollgate',
            reportedAt: 'Nov 18, 2026 08:30 AM',
            events: [
              ParcelIncidentEventModel(
                id: 901,
                eventType: 'reported',
                toStatus: 'open',
                location: 'SLEX Tollgate',
                notes: 'Carton crush documented by courier.',
                occurredAt: 'Nov 18, 2026 08:30 AM',
              ),
            ],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ManifestDetailScreen(
          manifestId: 88,
          initialManifestOverride: activeManifest,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NX-RIDER-INC-1'), findsOneWidget);
    expect(find.textContaining('INC-20261118-0021'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);

    // Couriers must never see self-resolution / loss declaration controls
    expect(find.text('Declare Lost'), findsNothing);
    expect(find.text('Resolve Incident'), findsNothing);

    // Tapping Timeline opens read-only investigation sheet
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();

    expect(find.text('Investigation Updates'), findsOneWidget);
    expect(find.textContaining('Carton crush documented by courier.'), findsOneWidget);
    expect(
      find.textContaining('Only authorized logistics operators or administrators can resolve incidents'),
      findsOneWidget,
    );

    // Dismiss sheet and verify Report Issue dialog includes location & photo evidence inputs
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Report Issue'));
    await tester.pumpAndSettle();

    expect(find.text('Issue Type'), findsOneWidget);
    expect(find.text('Last Known Location (Optional)'), findsOneWidget);
    expect(find.text('Attach Photo Evidence (Optional)'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);
  });
}
