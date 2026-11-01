import 'package:flutter/material.dart';
import '../services/courier_profile_service.dart';

class CourierProfileScreen extends StatefulWidget {
  final String? initialCourierId;

  const CourierProfileScreen({
    super.key,
    this.initialCourierId,
  });

  @override
  State<CourierProfileScreen> createState() => _CourierProfileScreenState();
}

class _CourierProfileScreenState extends State<CourierProfileScreen> {
  final CourierProfileService _service = CourierProfileService.instance;
  bool _accessDenied = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _checkAccessControl();
  }

  void _checkAccessControl() {
    if (widget.initialCourierId != null &&
        !_service.canViewCourierProfile(widget.initialCourierId!)) {
      setState(() => _accessDenied = true);
    } else {
      setState(() => _accessDenied = false);
    }
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _handleDutyToggle() {
    final result = _service.toggleDutyStatus();
    if (!result.success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Suspension Notice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: Text(
            result.message,
            style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: _service.profile.isOnDuty
              ? const Color(0xFF10B981)
              : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openDocumentPreview({
    required String title,
    required String subHeader,
    required String fileName,
    required String docTag,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined, color: Color(0xFF0066FF), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                          Text(subHeader, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 18),
                    SizedBox(width: 8),
                    Text(
                      '✓ Active & Verified',
                      style: TextStyle(color: Color(0xFF14532D), fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.file_present_rounded, size: 48, color: Color(0xFF0066FF)),
                      const SizedBox(height: 8),
                      Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Document Tag: $docTag',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close Document Preview', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditVehicleModal() {
    final profile = _service.profile;
    final capacityCtrl = TextEditingController(text: '${profile.loadCapacityKg}');
    final plateCtrl = TextEditingController(text: profile.plateNumber);
    final orCrCtrl = TextEditingController(text: 'truck_or_cr.pdf');
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_shipping_rounded, color: Color(0xFF0066FF)),
                        SizedBox(width: 8),
                        Text(
                          'Edit Vehicle & Capacity',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (localError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          localError!,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    const Text('LOAD CAPACITY (KG)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('courier_capacity_input'),
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixText: 'kg',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('PLATE NUMBER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('courier_plate_input'),
                      controller: plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        hintText: 'e.g. NAB4521',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('UPDATED VEHICLE OR/CR FILE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('courier_or_cr_input'),
                      controller: orCrCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.attach_file_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final parsedCap = int.tryParse(capacityCtrl.text.trim()) ?? profile.loadCapacityKg;
                          final enteredPlate = plateCtrl.text.trim();
                          final enteredOrCr = orCrCtrl.text.trim();

                          // If plate changed, validate duplicate plate (COU-PROF-003)
                          if (enteredPlate.toUpperCase() != profile.plateNumber.toUpperCase()) {
                            final plateRes = _service.updatePlateNumber(enteredPlate);
                            if (!plateRes.success) {
                              setModalState(() => localError = plateRes.message);
                              return;
                            }
                          }

                          // Save Capacity and OR/CR (COU-PROF-002)
                          final capRes = _service.updateLoadCapacityAndOrCr(
                            newCapacityKg: parsedCap,
                            newOrCrName: enteredOrCr.isNotEmpty ? enteredOrCr : profile.orCrDocName,
                          );

                          if (!capRes.success) {
                            setModalState(() => localError = capRes.message);
                            return;
                          }

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(capRes.message),
                              backgroundColor: const Color(0xFF0066FF),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save & Submit for Re-verification', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLicenseExpiryPicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      final res = _service.updateLicenseExpiry(picked);
      if (!res.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _showDocumentUploadModal({
    required String docTypeTitle,
    required Function(String fileName, double sizeMb, String source) onUpload,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload $docTypeTitle',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select document source. Accepted formats: JPG, PNG, PDF up to 5.0 MB.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF16A34A)),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Capture using device camera', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onUpload('license_camera_capture.jpg', 2.8, 'Camera');
                  },
                ),
              ),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.folder_open_rounded, color: Color(0xFF0066FF)),
                  ),
                  title: const Text('Choose from Files', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: const Text('Browse device files or cloud storage', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onUpload('truck_or_cr.pdf', 1.8, 'Files');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Security Verification', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, size: 54, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access Denied (COU-PROF-007)',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Denied. No Courier 2 data is shown.\nYou are not authorized to view another courier personnel profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _accessDenied = false);
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Return to My Verified Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final courier = _service.profile;
    final isSuspended = courier.accountStatus.toLowerCase() == 'suspended';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // On Duty / Off Duty Status Chip & Switch
          Row(
            children: [
              Text(
                courier.isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: courier.isOnDuty ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: courier.isOnDuty,
                onChanged: (val) => _handleDutyToggle(),
                activeThumbColor: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Courier Identity Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      courier.name.isNotEmpty ? courier.name[0] : 'C',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF0066FF)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                courier.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSuspended ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isSuspended ? 'SUSPENDED' : 'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isSuspended ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${courier.company} • Home Hub: ${courier.homeHub}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                            Text(
                              '${courier.rating} • ${courier.totalDeliveries} completed dispatches',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Vehicle & Capacity Section Card (COU-PROF-001, COU-PROF-002, COU-PROF-003)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_shipping_rounded, color: Color(0xFF0066FF), size: 20),
                          SizedBox(width: 8),
                          Text('Vehicle & Capacity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _showEditVehicleModal,
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Edit Vehicle Details', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0066FF),
                          side: const BorderSide(color: Color(0xFF0066FF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildKeyValueRow('Vehicle Type', courier.vehicleType),
                  const SizedBox(height: 8),
                  _buildKeyValueRow('Plate Number', courier.plateNumber),
                  const SizedBox(height: 8),
                  _buildKeyValueRow(
                    'Load Capacity',
                    '${_formatNumber(courier.loadCapacityKg)} kg',
                    isHighlight: true,
                  ),
                  const SizedBox(height: 8),
                  _buildKeyValueRow('Home Hub', courier.homeHub),
                  if (courier.vehicleReverificationStatus == 'Pending Re-verification') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pending Re-verification', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E))),
                                Text('Flagged for Logistics 1 review.', style: TextStyle(fontSize: 10.5, color: Color(0xFF78350F))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Driver's License Information (COU-PROF-001, COU-PROF-004)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_rounded, color: Color(0xFF0066FF), size: 20),
                          SizedBox(width: 8),
                          Text('Driver\'s License', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _showLicenseExpiryPicker,
                        icon: const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF0066FF)),
                        label: const Text('Update Expiry', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildKeyValueRow('License Number', courier.licenseNumber),
                  const SizedBox(height: 8),
                  _buildKeyValueRow('License Classification', courier.licenseType),
                  const SizedBox(height: 8),
                  _buildKeyValueRow('License Expiry', courier.licenseExpiry, isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Uploaded Fleet Documents Section (COU-PROF-001, COU-PROF-005, COU-PROF-008)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.folder_shared_rounded, color: Color(0xFF0066FF), size: 20),
                      SizedBox(width: 8),
                      Text('Uploaded Fleet Documents', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Document 1: Professional Driver's License
                  _buildDocumentItem(
                    title: "Professional Driver's License",
                    subHeader: 'LTO Official Professional License',
                    fileName: courier.licenseDocName,
                    docTag: 'LTO-DL-VERIFIED',
                    onPreview: () => _openDocumentPreview(
                      title: "Professional Driver's License",
                      subHeader: 'LTO Official Professional License',
                      fileName: courier.licenseDocName,
                      docTag: 'LTO-DL-VERIFIED',
                    ),
                    onReplace: () => _showDocumentUploadModal(
                      docTypeTitle: "Professional Driver's License",
                      onUpload: (fileName, sizeMb, source) {
                        final res = _service.uploadDriverLicense(fileName: fileName, fileSizeMb: sizeMb, source: source);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message), backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 20),

                  // Document 2: Vehicle Registration (OR/CR)
                  _buildDocumentItem(
                    title: 'Vehicle Registration (OR/CR)',
                    subHeader: 'LAND TRANSPORTATION OFFICE (LTO)',
                    fileName: courier.orCrDocName,
                    docTag: 'LTO-OR-CR-OFFICIAL',
                    onPreview: () => _openDocumentPreview(
                      title: 'Vehicle Registration (OR/CR)',
                      subHeader: 'LAND TRANSPORTATION OFFICE (LTO)',
                      fileName: courier.orCrDocName,
                      docTag: 'LTO-OR-CR-OFFICIAL',
                    ),
                    onReplace: () => _showDocumentUploadModal(
                      docTypeTitle: 'Vehicle Registration (OR/CR)',
                      onUpload: (fileName, sizeMb, source) {
                        final res = _service.uploadOrCrDocument(fileName: fileName, fileSizeMb: sizeMb, source: source);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message), backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 20),

                  // Document 3: NBI Clearance
                  _buildDocumentItem(
                    title: 'NBI Clearance',
                    subHeader: 'NATIONAL BUREAU OF INVESTIGATION (NBI)',
                    fileName: courier.nbiClearanceDocName,
                    docTag: 'NBI-CLEARED-PHILIPPINES',
                    onPreview: () => _openDocumentPreview(
                      title: 'NBI Clearance',
                      subHeader: 'NATIONAL BUREAU OF INVESTIGATION (NBI)',
                      fileName: courier.nbiClearanceDocName,
                      docTag: 'NBI-CLEARED-PHILIPPINES',
                    ),
                    onReplace: () => _showDocumentUploadModal(
                      docTypeTitle: 'NBI Clearance',
                      onUpload: (fileName, sizeMb, source) {
                        final res = _service.uploadNbiClearance(fileName: fileName, fileSizeMb: sizeMb);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message), backgroundColor: res.success ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: isHighlight ? const Color(0xFF0066FF) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String subHeader,
    required String fileName,
    required String docTag,
    required VoidCallback onPreview,
    required VoidCallback onReplace,
  }) {
    return InkWell(
      onTap: onPreview,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.file_copy_outlined, size: 20, color: Color(0xFF0066FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(fileName, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined, size: 18, color: Color(0xFF0066FF)),
              tooltip: 'Upload / Replace Document',
              onPressed: onReplace,
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
