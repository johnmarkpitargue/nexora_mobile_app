import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/rider_account_service.dart';
import '../../../core/theme/rider_theme.dart';
import '../../auth/presentation/rider_login_page.dart';
import '../models/transfer_manifest_models.dart';
import '../services/transfer_courier_service.dart';

class ManifestDetailScreen extends StatefulWidget {
  final int manifestId;

  const ManifestDetailScreen({super.key, required this.manifestId});

  @override
  State<ManifestDetailScreen> createState() => _ManifestDetailScreenState();
}

class _ManifestDetailScreenState extends State<ManifestDetailScreen> {
  TransferManifestModel? _manifest;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await TransferCourierService.instance
          .fetchManifestDetail(widget.manifestId);
      if (mounted) {
        setState(() {
          _manifest = detail;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load manifest details.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openScanParcelSheet() async {
    final trackingController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Scan or Enter Parcel Tracking #',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verify each parcel against this manifest before confirming departure.',
                style: TextStyle(fontSize: 12, color: RiderTheme.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: trackingController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tracking Number',
                  hintText: 'e.g. TRK-2026-000123',
                  prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final code = trackingController.text.trim();
                  if (code.isEmpty) return;
                  Navigator.pop(ctx);
                  await _scanTrackingNumber(code);
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Verify & Mark Loaded'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleApiException(ApiException e) async {
    if (!mounted) return;
    if (e.statusCode == 401) {
      await ApiClient.instance.clearToken();
      RiderAccountService.instance.logout();
      TransferCourierService.instance.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please sign in again.'),
          backgroundColor: RiderTheme.errorRed,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RiderLoginPage()),
        (route) => false,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: RiderTheme.errorRed,
      ),
    );
  }

  Future<void> _scanTrackingNumber(String trackingNumber) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await TransferCourierService.instance
          .scanParcel(widget.manifestId, trackingNumber);
      await _loadManifest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Parcel scanned.'),
          backgroundColor: RiderTheme.onlineGreen,
        ),
      );
    } on ApiException catch (e) {
      await _handleApiException(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDeparture() async {
    final plateController =
        TextEditingController(text: _manifest?.vehiclePlateNumber ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Hub Departure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'All parcels are loaded. Confirm departure from origin hub?',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Vehicle Plate Number (Optional)',
                hintText: 'e.g. NXA 4512',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Departure'),
          ),
        ],
      ),
    );

    if (confirmed != true || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final updated = await TransferCourierService.instance.confirmDeparture(
        widget.manifestId,
        vehiclePlateNumber: plateController.text,
      );
      if (mounted) {
        setState(() => _manifest = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Departure confirmed (${updated.status.toUpperCase().replaceAll('_', ' ')}).',
            ),
            backgroundColor: RiderTheme.onlineGreen,
          ),
        );
      }
    } on ApiException catch (e) {
      await _handleApiException(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _markArrived() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final updated =
          await TransferCourierService.instance.markArrived(widget.manifestId);
      if (mounted) {
        setState(() => _manifest = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.status == 'exception'
                  ? 'Arrival reported with unresolved exceptions. Destination hub will verify parcels.'
                  : 'Arrival reported (${updated.status.toUpperCase().replaceAll('_', ' ')}). Destination hub staff will verify incoming parcels.',
            ),
            backgroundColor: updated.status == 'exception'
                ? RiderTheme.warningOrange
                : RiderTheme.onlineGreen,
          ),
        );
      }
    } on ApiException catch (e) {
      await _handleApiException(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openReportIssueDialog(String trackingNumber) async {
    String issueType = 'damaged';
    final notesController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Report Issue: $trackingNumber'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: issueType,
                items: const [
                  DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                  DropdownMenuItem(value: 'missing', child: Text('Missing')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => issueType = v);
                },
                decoration: const InputDecoration(labelText: 'Issue Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  hintText: 'Describe the parcel condition or discrepancy...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (notesController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderTheme.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await TransferCourierService.instance.reportIssue(
        widget.manifestId,
        trackingNumber: trackingNumber,
        issueType: issueType,
        notes: notesController.text,
      );
      await _loadManifest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported to logistics operators.'),
            backgroundColor: RiderTheme.warningOrange,
          ),
        );
      }
    } on ApiException catch (e) {
      await _handleApiException(e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderTheme.background,
      appBar: AppBar(
        title: Text(_manifest?.manifestNumber ?? 'Manifest Details'),
        actions: [
          IconButton(
            onPressed: _loadManifest,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: RiderTheme.errorRed)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadManifest,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final m = _manifest!;
    final progress =
        m.totalParcels > 0 ? m.loadedParcels / m.totalParcels : 0.0;

    return RefreshIndicator(
      onRefresh: _loadManifest,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RiderTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.manifestNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: RiderTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        m.status.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: RiderTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${m.originHub?.name ?? 'Origin Hub'}  →  ${m.destinationHub?.name ?? 'Destination Hub'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: RiderTheme.textDark,
                  ),
                ),
                if (m.vehiclePlateNumber != null &&
                    m.vehiclePlateNumber!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Vehicle Plate: ${m.vehiclePlateNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: RiderTheme.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  '${m.loadedParcels} of ${m.totalParcels} parcels loaded',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RiderTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: RiderTheme.cardBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      RiderTheme.onlineGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons
          if (m.canScanLoading)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _openScanParcelSheet,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan Parcel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RiderTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (_isSubmitting || !m.canConfirmDeparture) ? null : _confirmDeparture,
                    icon: const Icon(Icons.local_shipping_rounded),
                    label: const Text('Confirm Departure'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RiderTheme.onlineGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          if (m.canMarkArrived)
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _markArrived,
              icon: const Icon(Icons.pin_drop_rounded),
              label: const Text('Mark Arrived at Destination Hub'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

          const SizedBox(height: 18),
          Text(
            'Parcels (${m.items.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          ...m.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.isLoaded
                      ? RiderTheme.onlineGreen.withValues(alpha: 0.4)
                      : RiderTheme.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.isLoaded
                        ? Icons.check_circle_rounded
                        : Icons.inventory_2_outlined,
                    color: item.isLoaded
                        ? RiderTheme.onlineGreen
                        : RiderTheme.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.trackingNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Loading: ${item.loadingStatus.toUpperCase()}  •  Receiving: ${item.receivingStatus.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: RiderTheme.textMuted,
                          ),
                        ),
                        if (item.issueNotes != null &&
                            item.issueNotes!.isNotEmpty)
                          Text(
                            'Issue: ${item.issueNotes}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: RiderTheme.errorRed,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (m.canScanLoading && !item.isLoaded)
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _scanTrackingNumber(item.trackingNumber),
                      child: const Text('Scan'),
                    ),
                  if (m.status != 'completed' && m.status != 'cancelled')
                    IconButton(
                      tooltip: 'Report Issue',
                      onPressed: _isSubmitting
                          ? null
                          : () => _openReportIssueDialog(item.trackingNumber),
                      icon: const Icon(
                        Icons.report_problem_outlined,
                        color: RiderTheme.warningOrange,
                        size: 20,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
