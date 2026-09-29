import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';

class RiderRegistrationPage extends StatefulWidget {
  const RiderRegistrationPage({super.key});

  @override
  State<RiderRegistrationPage> createState() => _RiderRegistrationPageState();
}

class _RiderRegistrationPageState extends State<RiderRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  int _selectedVehicleIndex = 0; // 0: Motorcycle, 1: Bicycle/e-Bike, 2: Van/MPV
  String _selectedHub = 'Makati / BGC Central Hub #4';

  // Photo document upload state
  bool _licenseScanned = false;
  bool _nbiUploaded = false;
  bool _orCrUploaded = false;

  final List<String> _hubs = [
    'Makati / BGC Central Hub #4',
    'Quezon City North Hub #1',
    'Pasig / Ortigas East Hub #2',
    'Alabang / South Hub #3',
  ];

  void _handleScanLicense() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening AI camera scanner for Driver License...')),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _licenseScanned = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver License photo scanned & verified!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    });
  }

  void _handleUploadNbi() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _nbiUploaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NBI Clearance photo attached!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    });
  }

  void _handleUploadOrCr() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _orCrUploaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Motorcycle OR/CR photo attached!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rider credentials submitted! 24h fast-track review started.'),
          backgroundColor: Color(0xFF5038ED),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF5038ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Nexora',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF5038ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Pills
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFFAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.two_wheeler_rounded,
                              size: 13, color: Color(0xFF0891B2)),
                          SizedBox(width: 4),
                          Text(
                            'Courier Partner Onboarding',
                            style: TextStyle(
                              color: Color(0xFF0891B2),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5038ED),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Fast-Track AI Review',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5038ED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title & Subtitle
                const Text(
                  'Drive & Earn with Nexora',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Flexible shifts, instant daily cashouts to NexoraPay/GCash, and up to ₱1,800/day.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Rider Subsidy Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.card_giftcard_rounded,
                          size: 18, color: Color(0xFF5038ED)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '₱1,000 New Rider Gear Subsidy BONUS! Free Nexora helmet after 15 orders.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3730A3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stepper Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STEP 1 OF 3',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF5038ED),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rider & Vehicle Info',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEECFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '33% Done',
                              style: TextStyle(
                                color: Color(0xFF5038ED),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5038ED),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Container
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
                      // Section 1: Personal Identification
                      const Text(
                        'Personal Identification',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Full Legal Name',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'As on Driver\'s License',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: 'Mark Ronald Tan',
                        decoration: _buildInputDecoration(
                          hint: 'Mark Ronald Tan',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Text(
                            'For Dispatch OTP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5038ED),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: '+63 917 888 4321',
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          hint: '+63 917 888 4321',
                          prefixIcon: Icons.phone_android_outlined,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Vehicle Classification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vehicle Classification',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Select 1',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildVehicleCard(
                        index: 0,
                        title: 'Motorcycle',
                        subtitle: 'Scooter / Underbone (Up to 150cc)',
                        icon: Icons.two_wheeler_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildVehicleCard(
                        index: 1,
                        title: 'Bicycle / e-Bike',
                        subtitle: 'Short-distance express parcels',
                        icon: Icons.pedal_bike_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildVehicleCard(
                        index: 2,
                        title: 'Van / MPV',
                        subtitle: 'Bulk hub-to-store logistics',
                        icon: Icons.airport_shuttle_rounded,
                      ),
                      const SizedBox(height: 14),

                      // Model & Year + Plate No.
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Model & Year',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  initialValue: 'Honda Click 125i • 2022',
                                  decoration: _buildInputDecoration(
                                    hint: 'Honda Click 125i • 2022',
                                    prefixIcon: Icons.two_wheeler,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Plate / MV File No.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  initialValue: 'NXR-729',
                                  decoration: _buildInputDecoration(
                                    hint: 'NXR-729',
                                    prefixIcon: Icons.badge_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Preferred Delivery Hub Zone
                      const Text(
                        'Preferred Delivery Hub Zone',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedHub,
                        decoration: _buildInputDecoration(
                          hint: 'Select hub zone',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        items: _hubs.map((hub) {
                          return DropdownMenuItem(
                            value: hub,
                            child: Text(hub, style: const TextStyle(fontSize: 13.5)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedHub = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Section 3: Required Credentials (Photo Uploader)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Required Credentials',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCFFAFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'AI Auto-Check',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0891B2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload clear photos or high-res scans for automated 24-hour fast-track endorsement.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Credential 1: Driver's License
                      _buildCredentialRow(
                        icon: Icons.camera_alt_outlined,
                        title: 'Professional Driver\'s License',
                        subtitle: _licenseScanned
                            ? '✔ Photo License Verified'
                            : 'Ready to scan front & back',
                        btnLabel: _licenseScanned ? 'Uploaded' : 'Scan',
                        isUploaded: _licenseScanned,
                        onTap: _handleScanLicense,
                      ),
                      const SizedBox(height: 10),

                      // Credential 2: NBI Clearance
                      _buildCredentialRow(
                        icon: Icons.article_outlined,
                        title: 'NBI / Police Clearance',
                        subtitle: _nbiUploaded
                            ? '✔ NBI Photo Clearance Attached'
                            : 'Valid within 6 months',
                        btnLabel: _nbiUploaded ? 'Uploaded' : 'Upload',
                        isUploaded: _nbiUploaded,
                        onTap: _handleUploadNbi,
                      ),
                      const SizedBox(height: 10),

                      // Credential 3: Motorcycle OR/CR
                      _buildCredentialRow(
                        icon: Icons.receipt_long_outlined,
                        title: 'Motorcycle OR / CR (LTO)',
                        subtitle: _orCrUploaded
                            ? '✔ LTO Receipt Attached'
                            : 'Official receipt & cert of reg',
                        btnLabel: _orCrUploaded ? 'Uploaded' : 'Upload',
                        isUploaded: _orCrUploaded,
                        onTap: _handleUploadOrCr,
                      ),
                      const SizedBox(height: 20),

                      // Emergency Contact
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: 'Elena Tan (Spouse)',
                        decoration: _buildInputDecoration(
                          hint: 'Elena Tan (Spouse)',
                          prefixIcon: Icons.contact_phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: '+63 920 445 9901',
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          hint: '+63 920 445 9901',
                          prefixIcon: Icons.phone,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5038ED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit Documents for 24h Fast-Track',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
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
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF5038ED) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5038ED) : const Color(0xFFEEECFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF5038ED),
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
              color: isSelected ? const Color(0xFF5038ED) : Colors.grey.shade400,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FF),
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
              color: const Color(0xFFEEECFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF5038ED), size: 18),
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
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded ? const Color(0xFFDCFCE7) : const Color(0xFF5038ED),
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
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
