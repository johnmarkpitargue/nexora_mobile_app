import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/rider_service.dart';
import '../models/courier_models.dart';
import '../services/courier_service.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final CourierService _service = CourierService.instance;

  String? _selectedDeclineReason;
  final TextEditingController _customReasonCtrl = TextEditingController();

  static const List<String> _commonDeclineReasons = [
    'Vehicle problem',
    'Heavy traffic / Unsafe weather',
    'Cargo capacity full',
    'Personal emergency',
  ];

  @override
  void dispose() {
    _customReasonCtrl.dispose();
    super.dispose();
  }

  void _handleAccept(CourierTrip trip) {
    final profile = RiderService.instance.profile;
    final res = _service.acceptTrip(
      tripId: trip.id,
      courierId: profile.id,
      companyId: trip.companyId,
      expectedVersion: trip.version,
    );

    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(res.message)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showDeclineDialog(CourierTrip trip) {
    _selectedDeclineReason = null;
    _customReasonCtrl.clear();
    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.report_problem_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Decline Trip Assignment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please specify a valid reason for declining this dispatch transfer. Dispatch will be notified and this trip will return to unassigned status.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (dialogError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dialogError!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ..._commonDeclineReasons.map((reason) {
                    final isSelected = _selectedDeclineReason == reason;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          _selectedDeclineReason = reason;
                          dialogError = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0066FF)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected
                                  ? const Color(0xFF0066FF)
                                  : const Color(0xFF94A3B8),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reason,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF0066FF)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // COU-TRIP-003 Step 1: Confirmation without a reason is blocked
                  final finalReason =
                      (_selectedDeclineReason ?? _customReasonCtrl.text).trim();
                  if (finalReason.isEmpty) {
                    setDialogState(() {
                      dialogError =
                          'Step 1 Blocked: A decline reason is required.';
                    });
                    return;
                  }

                  Navigator.pop(dialogCtx);

                  // Step 2: Confirm with reason
                  final profile = RiderService.instance.profile;
                  final res = _service.declineTrip(
                    tripId: trip.id,
                    courierId: profile.id,
                    reason: finalReason,
                  );

                  if (res.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${trip.id} declined ("$finalReason"). Trip returned to Unassigned in Logistics 1. Payout: ₱0.00.',
                        ),
                        backgroundColor: const Color(0xFF475569),
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Confirm Decline'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleStartLoading(CourierTrip trip) {
    final profile = RiderService.instance.profile;
    final res = _service.startLoadingTrip(
      tripId: trip.id,
      courierId: profile.id,
    );
    if (res.success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showScanModal(CourierTrip trip) {
    final waybillCtrl = TextEditingController();
    bool isFlashlightOn = false;
    bool isAirplaneMode = false;
    String? scanFeedback;
    bool isFeedbackError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;

          void processScan(String code) {
            final res = _service.scanParcelForTrip(
              tripId: trip.id,
              trackingOrWaybill: code,
              isOffline: isAirplaneMode,
            );
            setModalState(() {
              scanFeedback = res.message;
              isFeedbackError = !res.success;
            });
            setState(() {});
          }

          return Container(
            margin: EdgeInsets.only(bottom: bottomInset),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFF0066FF),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scan Waybill (${trip.loadedCount}/${trip.parcelsCount})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Flashlight toggle (COU-LOAD-008)
                          IconButton(
                            icon: Icon(
                              isFlashlightOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: isFlashlightOn
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF94A3B8),
                            ),
                            tooltip: 'Toggle Flashlight',
                            onPressed: () {
                              setModalState(() {
                                isFlashlightOn = !isFlashlightOn;
                              });
                            },
                          ),
                          // Airplane mode toggle (COU-LOAD-009)
                          IconButton(
                            icon: Icon(
                              Icons.airplanemode_active_rounded,
                              color: isAirplaneMode
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF94A3B8),
                            ),
                            tooltip: 'Simulate Airplane Mode',
                            onPressed: () {
                              setModalState(() {
                                isAirplaneMode = !isAirplaneMode;
                                if (!isAirplaneMode) {
                                  _service.syncOfflinePendingScans(trip.id);
                                  scanFeedback = 'Airplane mode OFF: Synced pending scans!';
                                  isFeedbackError = false;
                                } else {
                                  scanFeedback = 'Airplane mode ON: Scans will be queued offline.';
                                  isFeedbackError = false;
                                }
                              });
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isAirplaneMode)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.airplanemode_active_rounded,
                            color: Color(0xFFDC2626),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Airplane Mode Active: Scans saved offline',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Camera scanner simulation button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Scan the next unloaded parcel
                        final nextUnloaded = trip.parcelIds.firstWhere(
                          (id) => !trip.loadedParcelIds.contains(id),
                          orElse: () => trip.parcelIds.isNotEmpty
                              ? trip.parcelIds.first
                              : 'NX-TRP1-P01',
                        );
                        final parcel = _service.parcels
                            .cast<CourierParcel?>()
                            .firstWhere(
                              (p) => p?.id == nextUnloaded,
                              orElse: () => null,
                            );
                        processScan(parcel?.waybillNumber ?? nextUnloaded);
                      },
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(
                        isFlashlightOn
                            ? 'Scan with Camera (Flashlight ON)'
                            : 'Scan with Camera',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Manual input (COU-LOAD-008 crumpled waybill)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: waybillCtrl,
                          decoration: InputDecoration(
                            hintText: 'Type waybill or tracking #',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          processScan(waybillCtrl.text);
                          waybillCtrl.clear();
                        },
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Quick scan chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...trip.parcelIds.map((pid) {
                        final isLoaded = trip.loadedParcelIds.contains(pid);
                        final p = _service.parcels
                            .cast<CourierParcel?>()
                            .firstWhere(
                              (x) => x?.id == pid,
                              orElse: () => null,
                            );
                        final label = p?.waybillNumber ?? pid;
                        return ActionChip(
                          avatar: Icon(
                            isLoaded ? Icons.check_circle : Icons.qr_code,
                            size: 14,
                            color: isLoaded
                                ? Colors.white
                                : const Color(0xFF0066FF),
                          ),
                          backgroundColor: isLoaded
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEFF6FF),
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isLoaded
                                  ? Colors.white
                                  : const Color(0xFF0066FF),
                            ),
                          ),
                          onPressed: () => processScan(label),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(
                          Icons.block,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        backgroundColor: const Color(0xFFFEE2E2),
                        label: const Text(
                          'ADDR-1 (wrong trip)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        onPressed: () => processScan('ADDR-1'),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.search_off,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        backgroundColor: const Color(0xFFFEE2E2),
                        label: const Text(
                          'TRK-000000 (not found)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        onPressed: () => processScan('TRK-000000'),
                      ),
                    ],
                  ),
                  if (scanFeedback != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isFeedbackError
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        scanFeedback!,
                        style: TextStyle(
                          color: isFeedbackError
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF166534),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDepartModal(CourierTrip trip) {
    final sealCtrl = TextEditingController(text: 'EH-0804521');
    String? departError;
    bool simulateFar = false;

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  color: Color(0xFF0066FF),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Depart Hub Transfer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip: ${trip.id} (${trip.originHubId} → ${trip.destinationHubId})\nParcels: ${trip.loadedCount}/${trip.parcelsCount} loaded.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cargo Container Seal Number:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: sealCtrl,
                    decoration: InputDecoration(
                      hintText: 'EH-0000000 (EH- followed by 7 digits)',
                      hintStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text(
                          'Empty',
                          style: TextStyle(fontSize: 9),
                        ),
                        onPressed: () => setDState(() => sealCtrl.text = ''),
                      ),
                      ActionChip(
                        label: const Text(
                          'EH-080452 (6 dig)',
                          style: TextStyle(fontSize: 9),
                        ),
                        onPressed: () =>
                            setDState(() => sealCtrl.text = 'EH-080452'),
                      ),
                      ActionChip(
                        label: const Text(
                          'EH-08045210 (8 dig)',
                          style: TextStyle(fontSize: 9),
                        ),
                        onPressed: () =>
                            setDState(() => sealCtrl.text = 'EH-08045210'),
                      ),
                      ActionChip(
                        label: const Text(
                          'EH-ABC4521',
                          style: TextStyle(fontSize: 9),
                        ),
                        onPressed: () =>
                            setDState(() => sealCtrl.text = 'EH-ABC4521'),
                      ),
                      ActionChip(
                        label: const Text(
                          'EH-0804521 (valid)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: const Color(0xFFDCFCE7),
                        onPressed: () =>
                            setDState(() => sealCtrl.text = 'EH-0804521'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: simulateFar,
                        onChanged: (v) =>
                            setDState(() => simulateFar = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Simulate courier >500m from origin hub',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (departError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        departError!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final profile = RiderService.instance.profile;
                  final lat = simulateFar ? 14.6650 : trip.originLatitude;
                  final lng = simulateFar ? 121.0500 : trip.originLongitude;

                  final res = _service.departTrip(
                    tripId: trip.id,
                    courierId: profile.id,
                    sealNumber: sealCtrl.text,
                    currentLatitude: lat,
                    currentLongitude: lng,
                  );

                  if (!res.success) {
                    setDState(() {
                      departError = res.message;
                    });
                  } else {
                    Navigator.pop(dCtx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.message),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                child: const Text('Depart'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleNavigate(CourierTrip trip) async {
    // COU-TRIP-008: [Mobile] Navigate to destination hub
    final lat = trip.destinationLatitude;
    final lng = trip.destinationLongitude;
    final hubName = Uri.encodeComponent(trip.destinationHubName);

    // Show choice sheet: Google Maps or Waze
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Navigation App',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Destination: ${trip.destinationHubName} (${trip.destinationAddress})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                title: const Text(
                  'Google Maps',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Turn-by-turn navigation',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$hubName',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    final fallback = Uri.parse(
                      'geo:$lat,$lng?q=$lat,$lng($hubName)',
                    );
                    await launchUrl(
                      fallback,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF0066FF),
                  ),
                ),
                title: const Text(
                  'Waze Navigation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Live community traffic alerts',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(
                    'https://waze.com/ul?ll=$lat,$lng&navigate=yes',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    final fallback = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                    );
                    await launchUrl(
                      fallback,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _service.getTripById(widget.tripId);
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Not Found')),
        body: const Center(child: Text('This trip assignment does not exist.')),
      );
    }

    final isAssigned = trip.status == CourierTripStatus.assigned;
    final isAccepted = trip.status == CourierTripStatus.accepted;
    final isLoading = trip.status == CourierTripStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          trip.id,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: trip.status.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trip.status.label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: trip.status.color,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Route Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF00D2FF)),
                        ),
                        child: Text(
                          'Scheduled: ${trip.scheduledDeparture.hour.toString().padLeft(2, '0')}:${trip.scheduledDeparture.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '₱${trip.payAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Origin Hub
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        children: [
                          Icon(
                            Icons.trip_origin_rounded,
                            color: Color(0xFF38BDF8),
                            size: 18,
                          ),
                          SizedBox(
                            height: 28,
                            child: VerticalDivider(
                              color: Colors.white24,
                              thickness: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORIGIN: ${trip.originHubId}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              trip.originHubName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              trip.originAddress,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Destination Hub
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DESTINATION: ${trip.destinationHubId}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              trip.destinationHubName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              trip.destinationAddress,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cargo & Specs Metrics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSpecItem(
                      label: 'Total Parcels',
                      value: '${trip.parcelsCount} parcels',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF0066FF),
                    ),
                  ),
                  const SizedBox(
                    height: 36,
                    child: VerticalDivider(color: Color(0xFFE2E8F0)),
                  ),
                  Expanded(
                    child: _buildSpecItem(
                      label: 'Gross Weight',
                      value: '${trip.weightKg} kg',
                      icon: Icons.scale_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(
                    height: 36,
                    child: VerticalDivider(color: Color(0xFFE2E8F0)),
                  ),
                  Expanded(
                    child: _buildSpecItem(
                      label: 'Trip Payout',
                      value: '₱${trip.payAmount.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status notice if accepted or declined
            if (trip.acceptedAt != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF16A34A),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Trip accepted at ${trip.acceptedAt!.hour.toString().padLeft(2, '0')}:${trip.acceptedAt!.minute.toString().padLeft(2, '0')}. Start loading parcels at origin hub.',
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (trip.declinedReason != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Declined: "${trip.declinedReason}". Returned to Unassigned. Payout: ₱0.00.',
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            if (isAssigned) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showDeclineDialog(trip),
                      child: const Text(
                        'Decline Trip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _handleAccept(trip),
                      child: const Text(
                        'Accept Trip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isAccepted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _handleStartLoading(trip),
                  icon: const Icon(Icons.forklift, size: 20),
                  label: const Text(
                    'Start Loading',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _handleNavigate(trip),
                  icon: const Icon(Icons.navigation_rounded, size: 20),
                  label: const Text(
                    'Navigate to Destination Hub',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else if (isLoading) ...[
              // Interactive Loading & Departure Console (COU-LOAD-001 to 009)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Loading Counter',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: trip.isFullyLoaded
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${trip.loadedCount}/${trip.parcelsCount}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: trip.isFullyLoaded
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: trip.parcelsCount > 0
                            ? (trip.loadedCount / trip.parcelsCount)
                            : 0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: trip.isFullyLoaded
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0066FF),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Parcels in this Trip:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...trip.parcelIds.map((pid) {
                      final isLoaded = trip.loadedParcelIds.contains(pid);
                      final p = _service.parcels
                          .cast<CourierParcel?>()
                          .firstWhere((x) => x?.id == pid, orElse: () => null);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isLoaded
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isLoaded
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLoaded
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: isLoaded
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p?.waybillNumber ?? pid} • ${p?.itemsDescription ?? "Parcel"}',
                                    style: TextStyle(
                                      fontWeight: isLoaded
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 12,
                                      color: isLoaded
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${p?.weightKg ?? 0.0} kg • ${p?.customerAddress ?? ""}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isLoaded
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isLoaded ? 'Ticked' : 'Pending',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isLoaded
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0066FF),
                        side: const BorderSide(color: Color(0xFF0066FF)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showScanModal(trip),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text(
                        'Scan Waybills',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showDepartModal(trip),
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      label: const Text(
                        'Depart',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (trip.status == CourierTripStatus.inTransit) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7DD3FC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.departure_board_rounded,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trip In Transit • Seal: ${trip.sealNumber ?? "N/A"}',
                          style: const TextStyle(
                            color: Color(0xFF0369A1),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Departed at ${trip.departedAt?.hour.toString().padLeft(2, '0')}:${trip.departedAt?.minute.toString().padLeft(2, '0')}. Route: ${trip.originHubId} → ${trip.destinationHubId}.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF0C4A6E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _handleNavigate(trip),
                  icon: const Icon(Icons.navigation_rounded, size: 20),
                  label: const Text(
                    'Navigate to Destination Hub',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
