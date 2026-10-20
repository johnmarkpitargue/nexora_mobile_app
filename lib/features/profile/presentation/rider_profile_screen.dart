import 'package:flutter/material.dart';
import '../../../core/services/rider_service.dart';
import '../../auth/presentation/rider_landing_page.dart';

class RiderProfileScreen extends StatefulWidget {
  final String? initialRiderId;
  const RiderProfileScreen({super.key, this.initialRiderId});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  String? _unauthorizedViewId;

  @override
  void initState() {
    super.initState();
    if (widget.initialRiderId != null &&
        widget.initialRiderId != RiderService.instance.profile.id) {
      _unauthorizedViewId = widget.initialRiderId;
    }
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 8),
            Text(
              'Rider Emergency SOS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Broadcast your live GPS coordinates directly to the Pasig Central Hub Emergency Dispatch desk?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('🚨 SOS Alert Dispatched! Roadside team alerted.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Dispatch SOS Alert'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            const Icon(Icons.power_settings_new_rounded,
                color: Color(0xFFEF4444), size: 42),
            const SizedBox(height: 12),
            const Text(
              'End Shift & Log Out?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your active shift will be clocked out. You will not receive new incoming dispatch requests until you go on duty again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const RiderLandingPage(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'End & Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- RID-PROF-002 & RID-PROF-003: Edit Vehicle Details Modal ---
  void _showEditVehicleDialog(BuildContext context) {
    final profile = RiderService.instance.profile;
    final plateController = TextEditingController(text: profile.plateNumber);
    String orCrFile = profile.orCrDocName;
    double orCrSize = 0.9;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        color: Color(0xFF0284C7), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Update Vehicle Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Changes to plate number or vehicle registration (OR/CR) require re-verification by Logistics Hub.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // Error Banner if validation fails
                if (localError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localError!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Plate Input
                const Text(
                  'Vehicle Plate Number *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. 789GHI or 123ABC',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    prefixIcon: const Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 8),

                // Quick QA Test Chips
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Plate 789GHI (Valid)',
                          style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFF0FDF4),
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      onPressed: () {
                        setSheetState(() {
                          plateController.text = '789GHI';
                          orCrFile = 'or_cr.pdf';
                          orCrSize = 0.9;
                          localError = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('ABC1234 (Duplicate)',
                          style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      onPressed: () {
                        setSheetState(() {
                          plateController.text = 'ABC1234';
                          localError = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('abc1234 (Duplicate lowercase)',
                          style: TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      onPressed: () {
                        setSheetState(() {
                          plateController.text = 'abc1234';
                          localError = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Attached OR/CR document preview
                const Text(
                  'Upload New OR/CR (LTO Registration) *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          color: Color(0xFFEF4444), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orCrFile,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'File Size: ${(orCrSize * 1024).toStringAsFixed(0)} KB (Under 5.0 MB limit)',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            orCrFile = 'or_cr.pdf';
                            orCrSize = 0.9;
                          });
                        },
                        child: const Text('Re-upload',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final result =
                          RiderService.instance.updateVehicleDetails(
                        newPlate: plateController.text,
                        newOrCrName: orCrFile,
                        orCrSizeMb: orCrSize,
                      );

                      if (!result.success) {
                        setSheetState(() {
                          localError = result.message;
                        });
                      } else {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(result.message)),
                              ],
                            ),
                            backgroundColor: const Color(0xFF0284C7),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save & Submit for Re-verification',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  // --- RID-PROF-001, RID-PROF-004 & RID-PROF-005: Interactive Document Viewer ---
  void _showDocumentViewer({
    required BuildContext context,
    required String title,
    required String docName,
    required bool isLicense,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentProfile = RiderService.instance.profile;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Text(
                          '✓ Active & Verified',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Company: ${currentProfile.company} • File: $docName',
                    style:
                        const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  // Simulated Document Card Preview
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.security_rounded,
                                    color: Color(0xFF00D2FF), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isLicense
                                      ? 'REPUBLIC OF THE PHILIPPINES'
                                      : 'LAND TRANSPORTATION OFFICE (LTO)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OFFICIAL RECORD',
                                style: TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLicense
                                  ? 'License No: ${currentProfile.licenseNumber}'
                                  : 'Vehicle Plate: ${currentProfile.plateNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLicense
                                  ? 'Bearer: ${currentProfile.name} • Expiry: ${currentProfile.licenseExpiry}'
                                  : 'Owner: ${currentProfile.name} • Type: ${currentProfile.vehicleType}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Verified by Nexora Hub ID: ${currentProfile.id}',
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 10),
                            ),
                            const Icon(Icons.qr_code_2_rounded,
                                color: Colors.white70, size: 22),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Actions for Driver's License (RID-PROF-004 & RID-PROF-005)
                  if (isLicense) ...[
                    const Text(
                      'License Expiry Date (RID-PROF-004)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Current Expiry: ${currentProfile.licenseExpiry}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate:
                                  now.subtract(const Duration(days: 365)),
                              lastDate: now.add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              final res = RiderService.instance
                                  .updateLicenseExpiry(picked);
                              setModalState(() {});
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.message),
                                  backgroundColor: res.success
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.calendar_today_rounded,
                              size: 15),
                          label: const Text('Pick Date'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Quick Boundary Buttons: Yesterday vs Today
                    Wrap(
                      spacing: 6,
                      children: [
                        ActionChip(
                          label: const Text('Set to Yesterday (Reject)',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          onPressed: () {
                            final yesterday = DateTime.now()
                                .subtract(const Duration(days: 1));
                            final res = RiderService.instance
                                .updateLicenseExpiry(yesterday);
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          label: const Text('Set to Today (Accept)',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                          onPressed: () {
                            final today = DateTime.now();
                            final res = RiderService.instance
                                .updateLicenseExpiry(today);
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // RID-PROF-005: File Upload Boundary Rules
                    const Text(
                      'Document Upload Rules (RID-PROF-005)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Rule: Only JPG/PNG/PDF <= 5.0 MB accepted. Rejected uploads preserve existing document.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('size_5.0MB.jpg (accept)',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                          onPressed: () {
                            final res =
                                RiderService.instance.uploadDriverLicense(
                              fileName: 'size_5.0MB.jpg',
                              fileSizeMb: 5.0,
                            );
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          label: const Text('size_5.1MB.jpg (reject)',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          onPressed: () {
                            final res =
                                RiderService.instance.uploadDriverLicense(
                              fileName: 'size_5.1MB.jpg',
                              fileSizeMb: 5.1,
                            );
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          label: const Text('price_list.docx (reject)',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          onPressed: () {
                            final res =
                                RiderService.instance.uploadDriverLicense(
                              fileName: 'price_list.docx',
                              fileSizeMb: 1.2,
                            );
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          label: const Text('renamed_exe.jpg (reject)',
                              style: TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          onPressed: () {
                            final res =
                                RiderService.instance.uploadDriverLicense(
                              fileName: 'renamed_exe.jpg',
                              fileSizeMb: 1.0,
                            );
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Close Document Preview'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: RiderService.instance,
      builder: (context, _) {
        final profile = RiderService.instance.profile;
        final isOnline = profile.isOnline;

        // RID-PROF-007: Authorization Guard Check
        if (_unauthorizedViewId != null &&
            _unauthorizedViewId != profile.id) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Security Check',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () => setState(() => _unauthorizedViewId = null),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gpp_bad_rounded,
                          color: Color(0xFFEF4444),
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Access Denied (RID-PROF-007)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Denied. Rider ${profile.name} (${profile.id}) is not permitted to view Rider 2 ($_unauthorizedViewId)\'s private record or documents.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _unauthorizedViewId = null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Return to My Verified Profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            title: const Text(
              'Courier Profile',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Color(0xFF0F172A), size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No new dispatch notifications')),
                    );
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QA Test Bench Switcher Bar (Instant testing of test cases)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.science_outlined,
                              color: Color(0xFF38BDF8), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'QA Test Scenarios Switcher:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _qaChip(
                              'Rider 1 (Active: Pedro)',
                              isSelected: profile.id == 'NX-RD-001' &&
                                  _unauthorizedViewId == null,
                              onTap: () {
                                setState(() => _unauthorizedViewId = null);
                                RiderService.instance.switchRider('NX-RD-001');
                              },
                            ),
                            const SizedBox(width: 6),
                            _qaChip(
                              'Rider 3 (Suspended: RID-006)',
                              isSelected: profile.id == 'NX-RD-003' &&
                                  _unauthorizedViewId == null,
                              onTap: () {
                                setState(() => _unauthorizedViewId = null);
                                RiderService.instance.switchRider('NX-RD-003');
                              },
                            ),
                            const SizedBox(width: 6),
                            _qaChip(
                              'View Rider 2 (RID-007 Auth Denied)',
                              isSelected: _unauthorizedViewId != null,
                              onTap: () {
                                setState(() => _unauthorizedViewId = 'NX-RD-002');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Rider Header Card (RID-PROF-001)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rider Avatar with status indicator
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  profile.avatarUrl,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, error, stackTrace) =>
                                      Container(
                                    width: 58,
                                    height: 58,
                                    color: const Color(0xFF0284C7),
                                    child: const Icon(Icons.person,
                                        color: Colors.white, size: 32),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: profile.accountStatus == 'Suspended'
                                        ? const Color(0xFFEF4444)
                                        : (isOnline
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF94A3B8)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      profile.accountStatus == 'Suspended'
                                          ? Icons.block_rounded
                                          : Icons.verified_rounded,
                                      color: profile.accountStatus == 'Suspended'
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF0284C7),
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${profile.id} • ${profile.company}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status Badge (Active / Suspended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: profile.accountStatus == 'Suspended'
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: profile.accountStatus == 'Suspended'
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Text(
                              profile.accountStatus.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: profile.accountStatus == 'Suspended'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Hub line
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              profile.assignedHub,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // License summary line
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 14, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'License: ${profile.licenseNumber} (Exp: ${profile.licenseExpiry})',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0369A1),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // On Duty Toggle Container (RID-PROF-006: Block if Suspended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: profile.accountStatus == 'Suspended'
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: profile.accountStatus == 'Suspended'
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFBAE6FD),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: profile.accountStatus == 'Suspended'
                                    ? const Color(0xFFEF4444)
                                    : (isOnline
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF94A3B8)),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.accountStatus == 'Suspended'
                                        ? 'Account Suspended'
                                        : (isOnline ? 'On Duty' : 'Off Duty'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: profile.accountStatus ==
                                              'Suspended'
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    profile.accountStatus == 'Suspended'
                                        ? 'Suspended riders cannot work or go online'
                                        : (isOnline
                                            ? 'Accepting dispatches & drop-offs'
                                            : 'Currently offline'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: profile.accountStatus ==
                                              'Suspended'
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isOnline,
                              activeThumbColor: const Color(0xFF0284C7),
                              activeTrackColor: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.35),
                              onChanged: (_) {
                                final res =
                                    RiderService.instance.toggleOnlineStatus();
                                if (!res.success) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.block_rounded,
                                              color: Color(0xFFEF4444),
                                              size: 24),
                                          SizedBox(width: 8),
                                          Text(
                                            'Suspension Notice',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                      content: Text(res.message),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFEF4444),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Acknowledge'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Vehicle & Gear Section (RID-PROF-002 & RID-PROF-003)
                _sectionHeader(
                  icon: Icons.two_wheeler_rounded,
                  title: 'Vehicle & Gear',
                  actionText: 'Edit Vehicle Details',
                  actionColor: const Color(0xFF0284C7),
                  onAction: () => _showEditVehicleDialog(context),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Vehicle Model & Plate Number
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.sports_motorsports_rounded,
                                color: Color(0xFF0284C7),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.vehicleModel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    profile.vehicleSub,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Plate Badge (Updates to 789GHI on valid save)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                profile.plateNumber,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Re-verification Status Card & Inspection
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: profile.vehicleReverificationStatus ==
                                        'Pending Re-verification'
                                    ? const Color(0xFFFFFBEB)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      profile.vehicleReverificationStatus ==
                                              'Pending Re-verification'
                                          ? const Color(0xFFFCD34D)
                                          : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LTO Verification',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.vehicleReverificationStatus,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          profile.vehicleReverificationStatus ==
                                                  'Pending Re-verification'
                                              ? const Color(0xFFB45309)
                                              : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    profile.vehicleReverificationStatus ==
                                            'Pending Re-verification'
                                        ? 'Flagged for Logistics 1'
                                        : profile.inspectionExpiry,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          profile.vehicleReverificationStatus ==
                                                  'Pending Re-verification'
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thermal Delivery Bag',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile.thermalBag,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    profile.thermalBagSub,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Maintenance Schedule row
                      Row(
                        children: [
                          const Icon(Icons.build_outlined,
                              size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          const Text(
                            'Fleet Maintenance Schedule',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            profile.maintenanceSchedule,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Compliance & Badges Section (RID-PROF-001, RID-PROF-004 & RID-PROF-005)
                _sectionHeader(
                  icon: Icons.verified_user_outlined,
                  title: 'Compliance & Badges (Tap to Open)',
                  actionText: '100% Compliant',
                  actionColor: const Color(0xFF059669),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Driver's License item
                      InkWell(
                        onTap: () => _showDocumentViewer(
                          context: context,
                          title: "Professional Driver's License",
                          docName: profile.licenseDocName,
                          isLicense: true,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _complianceItem(
                            icon: Icons.badge_outlined,
                            title: "Professional Driver's License",
                            subtitle:
                                'No: ${profile.licenseNumber} • Expiry: ${profile.licenseExpiry}',
                            badgeText: '✓ Open Doc',
                          ),
                        ),
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),

                      // OR/CR item
                      InkWell(
                        onTap: () => _showDocumentViewer(
                          context: context,
                          title: 'Vehicle Registration (OR/CR)',
                          docName: profile.orCrDocName,
                          isLicense: false,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _complianceItem(
                            icon: Icons.description_outlined,
                            title: 'Vehicle Registration (OR/CR)',
                            subtitle:
                                'File: ${profile.orCrDocName} • Plate: ${profile.plateNumber}',
                            badgeText: '✓ Open Doc',
                          ),
                        ),
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),

                      // NBI Clearance item
                      _complianceItem(
                        icon: Icons.shield_outlined,
                        title: 'NBI & National Police Clearance',
                        subtitle: 'Active Biometrics Clean Record',
                        badgeText: '✓ Active',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Tools & Hardware Section
                _sectionHeader(
                  icon: Icons.devices_other_rounded,
                  title: 'Rider Tools & Hardware',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Navigation Engine
                      Row(
                        children: [
                          _toolIcon(Icons.explore_outlined),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Navigation App Engine',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Google Maps (Auto Reroute)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFBAE6FD),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  size: 13,
                                  color: Color(0xFF0284C7),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Google Maps',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22, color: Color(0xFFF1F5F9)),

                      // Dispatch Audio Prompts
                      Row(
                        children: [
                          _toolIcon(Icons.volume_up_outlined),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dispatch Audio Prompts',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'High-Gain Alert + Turn-by-Turn Voice',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: profile.audioPromptsEnabled,
                            activeColor: const Color(0xFF0284C7),
                            onChanged: (val) {
                              RiderService.instance
                                  .toggleAudioPrompts(val ?? true);
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 22, color: Color(0xFFF1F5F9)),

                      // Waybill Optical Engine
                      Row(
                        children: [
                          _toolIcon(Icons.qr_code_scanner_rounded),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Waybill Optical Engine',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'AI Auto-Detect Active (Continuous 60 FPS)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Hub Escalations & Safety Section
                _sectionHeader(
                  icon: Icons.support_agent_rounded,
                  title: 'Hub Escalations & Safety',
                ),
                const SizedBox(height: 8),

                // Hub Supervisor Dispatch Line
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _toolIcon(Icons.headset_mic_outlined),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hub Supervisor Dispatch Line',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Direct to Pasig Central Cluster Desk',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Dialing Pasig Hub Supervisor Cluster Desk (+63 2 8999 4400)...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.call_outlined,
                            color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Rider Emergency SOS Alert
                InkWell(
                  onTap: () => _showSosDialog(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rider Emergency SOS Alert',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              Text(
                                'Broadcast live coordinates & alert hub response',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFEF4444), size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 6. End Shift & Log Out Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _confirmLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEF2FF),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.power_settings_new_rounded,
                            color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'End Shift & Log Out',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 7. Footer Engine Info
                const Center(
                  child: Text(
                    'Nexora Rider Engine v4.18.2 (Pasig Build 902)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qaChip(String text,
      {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? actionText,
    Color? actionColor,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0284C7)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        if (actionText != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (actionColor ?? const Color(0xFF0284C7))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: actionColor ?? const Color(0xFF0284C7),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _toolIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF0284C7)),
    );
  }


  Widget _complianceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
  }) {
    return Row(
      children: [
        _toolIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0284C7),
            ),
          ),
        ),
      ],
    );
  }
}
