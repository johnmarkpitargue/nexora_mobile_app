import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/rider_service.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../auth/presentation/rider_landing_page.dart';
import '../../courier/services/shift_duty_coordinator.dart';

class DocumentValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String fileTypeLabel;
  final double sizeMb;
  final String fileName;

  DocumentValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.fileTypeLabel,
    required this.sizeMb,
    required this.fileName,
  });
}

DocumentValidationResult validateUploadedDocument({
  required String fileName,
  required double sizeMb,
}) {
  final parts = fileName.toLowerCase().split('.');
  final ext = parts.length > 1 ? parts.last : '';

  String typeLabel;
  if (ext == 'pdf') {
    typeLabel = 'PDF Document';
  } else if (ext == 'jpg' || ext == 'jpeg') {
    typeLabel = 'JPEG Image';
  } else if (ext == 'png') {
    typeLabel = 'PNG Image';
  } else {
    typeLabel = ext.isNotEmpty ? ext.toUpperCase() : 'Unknown File';
  }

  final isAllowedExtension = ['jpg', 'jpeg', 'png', 'pdf'].contains(ext);
  final isDisguisedExeOrDocx =
      fileName.toLowerCase().contains('docx') || fileName.toLowerCase().contains('exe');

  if (!isAllowedExtension || isDisguisedExeOrDocx) {
    return DocumentValidationResult(
      isValid: false,
      errorMessage:
          'Invalid file format ($typeLabel). Only JPG, PNG, and PDF files are allowed.',
      fileTypeLabel: typeLabel,
      sizeMb: sizeMb,
      fileName: fileName,
    );
  }

  if (sizeMb > 5.0) {
    return DocumentValidationResult(
      isValid: false,
      errorMessage:
          'File size (${sizeMb.toStringAsFixed(2)} MB) exceeds the 5.0 MB limit. Please select a smaller file.',
      fileTypeLabel: typeLabel,
      sizeMb: sizeMb,
      fileName: fileName,
    );
  }

  return DocumentValidationResult(
    isValid: true,
    fileTypeLabel: typeLabel,
    sizeMb: sizeMb,
    fileName: fileName,
  );
}

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

  // --- File Upload & Validation Helpers (Max 5.0 MB, JPG/PNG/PDF) ---
  void _openDocumentPicker({
    required BuildContext context,
    required String title,
    required void Function(String fileName, double fileSizeMb) onFileSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded,
                        color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload $title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Max file size: 5.0 MB • JPG, PNG, or PDF',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF0284C7)),
                ),
                title: const Text('Take Photo (Camera)',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                subtitle: const Text('Capture document using device camera',
                    style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _pickImageFromSource(
                    context: context,
                    source: ImageSource.camera,
                    onFileSelected: onFileSelected,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF0284C7)),
                ),
                title: const Text('Choose from Gallery',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                subtitle: const Text('Select image from photo gallery',
                    style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _pickImageFromSource(
                    context: context,
                    source: ImageSource.gallery,
                    onFileSelected: onFileSelected,
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_outlined,
                      color: Color(0xFFD97706)),
                ),
                title: const Text('Browse Files (PDF or Images)',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                subtitle: const Text(
                    'Select official digital PDF scan or document file',
                    style: TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await _pickDocumentFile(
                    context: context,
                    title: title,
                    onFileSelected: onFileSelected,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource({
    required BuildContext context,
    required ImageSource source,
    required void Function(String fileName, double fileSizeMb) onFileSelected,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final sizeMb = bytes.length / (1024.0 * 1024.0);
      final fileName = file.name.isNotEmpty
          ? file.name
          : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (!context.mounted) return;

      _validateAndDispatchFile(
        context: context,
        fileName: fileName,
        sizeMb: sizeMb,
        onFileSelected: onFileSelected,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access image: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _pickDocumentFile({
    required BuildContext context,
    required String title,
    required void Function(String fileName, double fileSizeMb) onFileSelected,
  }) async {
    final nameController = TextEditingController(
      text: title.toLowerCase().contains('license')
          ? 'driver_license_scan.pdf'
          : 'or_cr_official_copy.pdf',
    );
    double selectedSizeMb = 1.2;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFEF4444), size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attach Digital PDF',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter or select document file name (JPG, PNG, or PDF):',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'File Name',
                      hintText: 'e.g. document.pdf',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Document Size:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${selectedSizeMb.toStringAsFixed(1)} MB',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selectedSizeMb > 5.0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: selectedSizeMb,
                    min: 0.5,
                    max: 6.0,
                    divisions: 11,
                    label: '${selectedSizeMb.toStringAsFixed(1)} MB',
                    activeColor: selectedSizeMb > 5.0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0284C7),
                    onChanged: (val) {
                      setDlgState(() => selectedSizeMb = val);
                    },
                  ),
                  const Text(
                    'Rule: Only JPG, PNG, and PDF up to 5.0 MB are accepted.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _validateAndDispatchFile(
                    context: context,
                    fileName: nameController.text.trim(),
                    sizeMb: selectedSizeMb,
                    onFileSelected: onFileSelected,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Attach & Validate'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _validateAndDispatchFile({
    required BuildContext context,
    required String fileName,
    required double sizeMb,
    required void Function(String fileName, double fileSizeMb) onFileSelected,
  }) {
    final validation = validateUploadedDocument(
      fileName: fileName,
      sizeMb: sizeMb,
    );

    if (!validation.isValid) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errorMessage ?? 'Invalid file.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    onFileSelected(validation.fileName, validation.sizeMb);
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
                      Icon(
                        orCrFile.toLowerCase().endsWith('.pdf')
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        color: orCrFile.toLowerCase().endsWith('.pdf')
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF0284C7),
                        size: 26,
                      ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'File Size: ${orCrSize < 1.0 ? '${(orCrSize * 1024).toStringAsFixed(0)} KB' : '${orCrSize.toStringAsFixed(2)} MB'} (Under 5.0 MB limit)',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _openDocumentPicker(
                            context: context,
                            title: 'OR/CR (LTO Registration)',
                            onFileSelected: (fileName, sizeMb) {
                              setSheetState(() {
                                orCrFile = fileName;
                                orCrSize = sizeMb;
                                localError = null;
                              });
                            },
                          );
                        },
                        icon: const Icon(Icons.upload_file_rounded, size: 16),
                        label: const Text('Upload File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
          final activeDocName =
              isLicense ? currentProfile.licenseDocName : currentProfile.orCrDocName;

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
                    'Company: ${currentProfile.company} • File: $activeDocName',
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

                  // 1. Actions for Driver's License: Expiry Date
                  if (isLicense) ...[
                    const Text(
                      'License Expiry Date',
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
                    const SizedBox(height: 16),
                  ],

                  // 2. Upload Document File Section (Driver's License & OR/CR)
                  Text(
                    isLicense
                        ? 'Driver\'s License Document'
                        : 'Vehicle OR/CR Document',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          activeDocName.toLowerCase().endsWith('.pdf')
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          color: activeDocName.toLowerCase().endsWith('.pdf')
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0284C7),
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeDocName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'JPG, PNG, or PDF • Max 5.0 MB',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _openDocumentPicker(
                              context: context,
                              title: isLicense
                                  ? "Driver's License"
                                  : "OR/CR (LTO Registration)",
                              onFileSelected: (fileName, sizeMb) {
                                final res = isLicense
                                    ? RiderService.instance.uploadDriverLicense(
                                        fileName: fileName,
                                        fileSizeMb: sizeMb,
                                      )
                                    : RiderService.instance.uploadOrCrDocument(
                                        fileName: fileName,
                                        fileSizeMb: sizeMb,
                                      );
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
                              },
                            );
                          },
                          icon: const Icon(Icons.file_upload_outlined,
                              size: 16),
                          label: const Text('Upload File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                    InAppNotificationService.instance.showNotificationHistory(context);
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
                                ShiftDutyCoordinator.handleRiderToggleDuty(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 1B. Customer Ratings & Order Acceptance Section
                _sectionHeader(
                  icon: Icons.star_rounded,
                  title: 'Customer Ratings & Acceptance',
                  actionText: '${RiderService.instance.reviews.length} Reviews',
                  actionColor: const Color(0xFFF59E0B),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        profile.rating.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Rider Rating',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${profile.completionRate.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Acceptance Rate',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${profile.totalDeliveries}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF075985),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Deliveries',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (RiderService.instance.reviews.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'RECENT BUYER FEEDBACK',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...RiderService.instance.reviews.take(3).map((review) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${review.customerName} • #${review.orderId}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (idx) => Icon(
                                          idx < review.driverRating
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 14,
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (review.comment.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '"${review.comment}"',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF334155),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                if (review.tags.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: review.tags
                                        .map(
                                          (tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2FE),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tag,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
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
