import 'package:flutter/material.dart';
import '../../../core/services/rider_account_service.dart';
import 'rider_set_password_page.dart';

class AddRiderPage extends StatefulWidget {
  const AddRiderPage({super.key});

  @override
  State<AddRiderPage> createState() => AddRiderPageState();
}

class AddRiderPageState extends State<AddRiderPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseNoController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  // Vehicle Selection (0: Motorcycle, 1: Car, 2: Van per Test Data)
  int _selectedVehicleIndex = 0;
  final List<String> _vehicleTypes = ['Motorcycle', 'Car', 'Van'];

  // Document Upload State
  String? _licenseDocName;
  double _licenseDocSizeMb = 0.0;
  String? _orCrDocName;
  double _orCrDocSizeMb = 0.0;

  // Form submission & network state
  bool _isSubmitting = false;
  bool _isOffline = false;
  String? _generalError;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNoController.dispose();
    _expiryController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _firstNameController.text.isNotEmpty ||
        _lastNameController.text.isNotEmpty ||
        _dobController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _licenseNoController.text.isNotEmpty ||
        _expiryController.text.isNotEmpty ||
        _plateController.text.isNotEmpty ||
        _licenseDocName != null ||
        _orCrDocName != null;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 8),
            Text(
              'Discard Rider Details?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'You have entered rider details that have not been saved yet. Leaving now will discard all input data.',
          style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Keep editing
            child: const Text(
              'Keep Editing',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // Discard
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  void setOfflineForTesting(bool value) {
    setState(() {
      _isOffline = value;
    });
  }

  void showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
          'Nexora needs $permissionName access to attach registration documents. Please enable access in system Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required bool isDob,
  }) async {
    final now = DateTime.now();
    final initialDate = isDob
        ? DateTime(now.year - 20, now.month, now.day)
        : DateTime(now.year + 2, now.month, now.day);
    final firstDate = isDob ? DateTime(1940) : DateTime(now.year, now.month, now.day - 7);
    final lastDate = isDob ? now : DateTime(now.year + 20);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0284C7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        controller.text = formatted;
        _fieldErrors.remove(isDob ? 'dateOfBirth' : 'licenseExpiryDate');
      });
    }
  }

  void _showDocumentPicker({
    required String docTitle,
    required bool isLicense,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attach $docTitle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Accepted formats: JPG, PNG, PDF • Max size: 5.0 MB',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Source 1: Camera
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0284C7)),
                ),
                title: const Text('Take Photo (Camera)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                subtitle: const Text('Capture using device camera (auto-compressed to <= 5MB)',
                    style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDocumentSelected(
                    fileName: isLicense ? 'drivers_license.jpg' : 'or_cr.jpg',
                    fileSizeMb: 1.5,
                    isLicense: isLicense,
                  );
                },
              ),

              // Source 2: Gallery
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF0284C7)),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                subtitle: const Text('Pick photo from local image gallery',
                    style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDocumentSelected(
                    fileName: isLicense ? 'drivers_license.png' : 'or_cr.png',
                    fileSizeMb: 2.0,
                    isLicense: isLicense,
                  );
                },
              ),

              // Source 3: Files (PDF / Documents)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_outlined, color: Color(0xFFD97706)),
                ),
                title: const Text('Browse Files (PDF or Images)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                subtitle: const Text('Select official digital PDF scan or certified document',
                    style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDocumentSelected(
                    fileName: isLicense ? 'drivers_license.pdf' : 'or_cr.pdf',
                    fileSizeMb: 0.9,
                    isLicense: isLicense,
                  );
                },
              ),

              const Divider(),
              // Testing presets row for specific TC verification
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('Valid 5.0 MB (TC-018)', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleDocumentSelected(
                          fileName: isLicense ? 'size_5.0MB.jpg' : 'or_cr_5.0MB.pdf',
                          fileSizeMb: 5.0,
                          isLicense: isLicense,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('Reject 5.1 MB (TC-018)', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleDocumentSelected(
                          fileName: isLicense ? 'size_5.1MB.jpg' : 'or_cr_5.1MB.pdf',
                          fileSizeMb: 5.1,
                          isLicense: isLicense,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('Reject .docx (TC-017)', style: TextStyle(fontSize: 10)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleDocumentSelected(
                          fileName: 'price_list.docx',
                          fileSizeMb: 0.32,
                          isLicense: isLicense,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDocumentSelected({
    required String fileName,
    required double fileSizeMb,
    required bool isLicense,
  }) {
    final ext = fileName.split('.').last.toLowerCase();
    if (!RiderValidationRules.allowedFileExtensions.contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid file type ".$ext". Accepted types: JPG, PNG, PDF.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      setState(() {
        _fieldErrors[isLicense ? 'licenseDoc' : 'orCrDoc'] =
            'Invalid file type. Only JPG, PNG, and PDF files are accepted.';
      });
      return;
    }

    if (fileSizeMb > RiderValidationRules.maxFileSizeMb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File size ${fileSizeMb.toStringAsFixed(1)} MB exceeds the 5.0 MB limit.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      setState(() {
        _fieldErrors[isLicense ? 'licenseDoc' : 'orCrDoc'] =
            'File size exceeds maximum limit of 5.0 MB.';
      });
      return;
    }

    setState(() {
      if (isLicense) {
        _licenseDocName = fileName;
        _licenseDocSizeMb = fileSizeMb;
        _fieldErrors.remove('licenseDoc');
      } else {
        _orCrDocName = fileName;
        _orCrDocSizeMb = fileSizeMb;
        _fieldErrors.remove('orCrDoc');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fileName (${fileSizeMb.toStringAsFixed(1)} MB) attached successfully!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _generalError = null;
      _fieldErrors.clear();
    });

    if (_isOffline || !RiderAccountService.instance.isNetworkConnected) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _generalError = 'No internet connection. Please check your network connection and tap Retry.';
      });
      return;
    }

    final errors = RiderAccountService.instance.validateForm(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      dateOfBirth: _dobController.text,
      email: _emailController.text,
      mobileNumber: _phoneController.text,
      licenseNumber: _licenseNoController.text,
      licenseExpiryDate: _expiryController.text,
      vehicleType: _vehicleTypes[_selectedVehicleIndex],
      plateNumber: _plateController.text,
      licenseDocName: _licenseDocName ?? '',
      licenseDocSizeMb: _licenseDocSizeMb,
      orCrDocName: _orCrDocName ?? '',
      orCrDocSizeMb: _orCrDocSizeMb,
    );

    if (errors.isNotEmpty) {
      setState(() {
        _isSubmitting = false;
        _fieldErrors = errors;
        _generalError = 'Please fix the highlighted required fields to continue.';
      });
      return;
    }

    final result = await RiderAccountService.instance.createRider(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      dateOfBirth: _dobController.text,
      email: _emailController.text,
      mobileNumber: _phoneController.text,
      licenseNumber: _licenseNoController.text,
      licenseExpiryDate: _expiryController.text,
      vehicleType: _vehicleTypes[_selectedVehicleIndex],
      plateNumber: _plateController.text,
      licenseDocName: _licenseDocName ?? '',
      licenseDocSizeMb: _licenseDocSizeMb,
      orCrDocName: _orCrDocName ?? '',
      orCrDocSizeMb: _orCrDocSizeMb,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      _showSuccessDialog(result);
    } else {
      setState(() {
        _generalError = result.message;
        if (result.fieldErrors != null) {
          _fieldErrors = result.fieldErrors!;
        }
      });
    }
  }

  void _showSuccessDialog(RiderOpResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rider Successfully Created!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Company Fleet:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(result.rider?.companyName ?? 'Bilis Hatid Express Inc.',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Account Status:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Pending Activation',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Activation Link:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const Text('Valid for 24 Hours',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (result.activationToken != null) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Open Activation Link (Set Password)', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderSetPasswordPage(
                        activationToken: result.activationToken!,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done & Return to Fleet', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _fillAccount1Data() {
    setState(() {
      _firstNameController.text = 'Pedro Jose';
      _lastNameController.text = 'Garcia';
      _dobController.text = '03/22/1995';
      _emailController.text = 'pedrojose.garcia@example.com';
      _phoneController.text = '09451239876';
      _licenseNoController.text = 'N01-23-456789';
      _expiryController.text = '03/22/2030';
      _selectedVehicleIndex = 0; // Motorcycle
      _plateController.text = '123ABC';
      _licenseDocName = 'drivers_license.jpg';
      _licenseDocSizeMb = 1.5;
      _orCrDocName = 'or_cr.pdf';
      _orCrDocSizeMb = 0.9;
      _fieldErrors.clear();
      _generalError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F9FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            key: const Key('rider_back_button'),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            'Add Rider',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF0284C7)),
              tooltip: 'Fill Valid Account 1 Data (TC-001)',
              onPressed: _fillAccount1Data,
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isOffline)
                      Container(
                        key: const Key('offline_banner'),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'No Internet Connection',
                                style: TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOffline = false;
                                });
                              },
                              child: const Text(
                                'Retry Connection',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_generalError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_generalError!.contains('internet') || _generalError!.contains('connection'))
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isOffline = false;
                                    _generalError = null;
                                  });
                                  _handleSave();
                                },
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Fleet Header Pill
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.two_wheeler_rounded, size: 13, color: Color(0xFF0284C7)),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Logistics Fleet Dispatch',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Bilis Hatid Express Inc.',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Register New Fleet Rider',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a rider record under Bilis Hatid Express Inc. An activation link valid for 24h will be emailed to the rider to set their password.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
                    ),
                    const SizedBox(height: 16),

                    // Main Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION 1
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('First Name', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('rider_first_name_field'),
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              hint: 'Pedro Jose',
                              prefixIcon: Icons.person_outline,
                              errorText: _fieldErrors['firstName'],
                            ),
                            onChanged: (_) {
                              if (_fieldErrors.containsKey('firstName')) {
                                setState(() => _fieldErrors.remove('firstName'));
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Last Name', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('rider_last_name_field'),
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: _buildInputDecoration(
                              hint: 'Garcia',
                              prefixIcon: Icons.badge_outlined,
                              errorText: _fieldErrors['lastName'],
                            ),
                            onChanged: (_) {
                              if (_fieldErrors.containsKey('lastName')) {
                                setState(() => _fieldErrors.remove('lastName'));
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Date of Birth (At least 18 years old)', isRequired: true),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickDate(controller: _dobController, isDob: true),
                            child: IgnorePointer(
                              child: TextFormField(
                                key: const Key('rider_dob_field'),
                                controller: _dobController,
                                decoration: _buildInputDecoration(
                                  hint: 'MM/DD/YYYY (e.g. 03/22/1995)',
                                  prefixIcon: Icons.cake_outlined,
                                  suffixIcon: Icons.calendar_month_outlined,
                                  errorText: _fieldErrors['dateOfBirth'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Email Address (Unique across all roles)', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('rider_email_field'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            decoration: _buildInputDecoration(
                              hint: 'pedrojose.garcia@example.com',
                              prefixIcon: Icons.email_outlined,
                              errorText: _fieldErrors['email'],
                            ),
                            onChanged: (_) {
                              if (_fieldErrors.containsKey('email')) {
                                setState(() => _fieldErrors.remove('email'));
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Mobile Number (09XXXXXXXXX or +639XXXXXXXXX)', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('rider_mobile_field'),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _buildInputDecoration(
                              hint: '09451239876',
                              prefixIcon: Icons.phone_android_outlined,
                              errorText: _fieldErrors['mobileNumber'],
                            ),
                            onChanged: (_) {
                              if (_fieldErrors.containsKey('mobileNumber')) {
                                setState(() => _fieldErrors.remove('mobileNumber'));
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // SECTION 2
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Driver\'s License & Vehicle Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('Driver\'s License No. (LTO: A00-00-000000)', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('rider_license_field'),
                            controller: _licenseNoController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _buildInputDecoration(
                              hint: 'N01-23-456789',
                              prefixIcon: Icons.credit_card_outlined,
                              errorText: _fieldErrors['licenseNumber'],
                            ),
                            onChanged: (_) {
                              if (_fieldErrors.containsKey('licenseNumber')) {
                                setState(() => _fieldErrors.remove('licenseNumber'));
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _buildFieldLabel('License Expiry Date (Today or later)', isRequired: true),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickDate(controller: _expiryController, isDob: false),
                            child: IgnorePointer(
                              child: TextFormField(
                                key: const Key('rider_expiry_field'),
                                controller: _expiryController,
                                decoration: _buildInputDecoration(
                                  hint: 'MM/DD/YYYY (e.g. 03/22/2030)',
                                  prefixIcon: Icons.event_available_outlined,
                                  suffixIcon: Icons.calendar_month_outlined,
                                  errorText: _fieldErrors['licenseExpiryDate'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildFieldLabel('Vehicle Type', isRequired: true),
                          const SizedBox(height: 8),
                          _buildVehicleCard(
                            index: 0,
                            title: 'Motorcycle',
                            subtitle: 'Scooter / Underbone parcel deliveries',
                            icon: Icons.two_wheeler_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildVehicleCard(
                            index: 1,
                            title: 'Car',
                            subtitle: 'Sedan / Hatchback courier delivery',
                            icon: Icons.directions_car_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildVehicleCard(
                            index: 2,
                            title: 'Van',
                            subtitle: 'MPV / Light commercial cargo transport',
                            icon: Icons.airport_shuttle_rounded,
                          ),
                          if (_fieldErrors.containsKey('vehicleType')) ...[
                            const SizedBox(height: 4),
                            Text(
                              _fieldErrors['vehicleType']!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                            ),
                          ],
                          const SizedBox(height: 14),

                          _buildFieldLabel('Vehicle Plate Number', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('rider_plate_field'),
                            controller: _plateController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _buildInputDecoration(
                              hint: '123ABC',
                              prefixIcon: Icons.confirmation_number_outlined,
                              errorText: _fieldErrors['plateNumber'],
                            ),
                            onChanged: (_) {
                              if (_fieldErrors.containsKey('plateNumber')) {
                                setState(() => _fieldErrors.remove('plateNumber'));
                              }
                            },
                          ),
                          const SizedBox(height: 18),

                          // SECTION 3: Documents
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Required Credentials Upload',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'JPG, PNG, PDF <= 5MB',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload valid verification documents. Camera photos > 5MB are automatically compressed.',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),

                          _buildCredentialRow(
                            buttonKey: const Key('rider_license_upload_btn'),
                            icon: Icons.badge_outlined,
                            title: 'Professional Driver\'s License *',
                            subtitle: _licenseDocName != null
                                ? '✔ $_licenseDocName (${_licenseDocSizeMb.toStringAsFixed(1)} MB)'
                                : 'Tap to upload (JPG, PNG or PDF)',
                            btnLabel: _licenseDocName != null ? 'Replace' : 'Upload',
                            isUploaded: _licenseDocName != null,
                            onTap: () => _showDocumentPicker(
                              docTitle: "Driver's License",
                              isLicense: true,
                            ),
                          ),
                          if (_fieldErrors.containsKey('licenseDoc')) ...[
                            const SizedBox(height: 4),
                            Text(
                              _fieldErrors['licenseDoc']!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                            ),
                          ],
                          const SizedBox(height: 10),

                          _buildCredentialRow(
                            buttonKey: const Key('rider_or_cr_upload_btn'),
                            icon: Icons.receipt_long_outlined,
                            title: 'Vehicle OR / CR (LTO Registration) *',
                            subtitle: _orCrDocName != null
                                ? '✔ $_orCrDocName (${_orCrDocSizeMb.toStringAsFixed(1)} MB)'
                                : 'Tap to upload (JPG, PNG or PDF)',
                            btnLabel: _orCrDocName != null ? 'Replace' : 'Upload',
                            isUploaded: _orCrDocName != null,
                            onTap: () => _showDocumentPicker(
                              docTitle: 'Vehicle OR/CR',
                              isLicense: false,
                            ),
                          ),
                          if (_fieldErrors.containsKey('orCrDoc')) ...[
                            const SizedBox(height: 4),
                            Text(
                              _fieldErrors['orCrDoc']!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                            ),
                          ],
                          const SizedBox(height: 24),

                          ElevatedButton(
                            key: const Key('rider_save_button'),
                            onPressed: _isSubmitting ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFBAE6FD),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isSubmitting
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Saving Rider Details...',
                                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Save Rider Details',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEF4444),
            ),
          ),
      ],
    );
  }

  Widget _buildVehicleCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedVehicleIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleIndex = index;
          _fieldErrors.remove('vehicleType');
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF0284C7),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? const Color(0xFF0284C7) : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String btnLabel,
    required bool isUploaded,
    required VoidCallback onTap,
    Key? buttonKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded ? const Color(0xFF22C55E) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isUploaded ? const Color(0xFF15803D) : const Color(0xFF0284C7),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUploaded ? const Color(0xFF15803D) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            key: buttonKey,
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded ? const Color(0xFFDCFCE7) : const Color(0xFF0284C7),
              foregroundColor: isUploaded ? const Color(0xFF15803D) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              btnLabel,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    IconData? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: const Color(0xFF64748B), size: 18)
          : null,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      errorText: errorText,
      errorMaxLines: 2,
      errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: errorText != null
            ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
