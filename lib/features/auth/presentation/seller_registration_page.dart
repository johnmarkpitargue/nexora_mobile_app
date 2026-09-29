import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';

class SellerRegistrationPage extends StatefulWidget {
  const SellerRegistrationPage({super.key});

  @override
  State<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends State<SellerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  int _businessStructureIndex = 0; // 0: Individual/Sole, 1: Registered Corp
  String _selectedCategory = 'Fashion & Apparel';
  bool _enableFulfillment = true;
  bool _agreeTerms = true;

  // Photo / Document Upload State
  String? _uploadedDocName;
  bool _isUploadingDoc = false;

  final List<String> _categories = [
    'Fashion & Apparel',
    'Tech & Electronics',
    'Home & Living',
    'Beauty & Personal Care',
    'Sports & Outdoors',
    'Food & Groceries',
  ];

  void _handleUploadDocument() {
    setState(() {
      _isUploadingDoc = true;
    });

    // Simulate photo/document picker upload
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isUploadingDoc = false;
        _uploadedDocName = 'Business_Permit_2026_AuraStudios.jpg';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo document uploaded successfully!'),
          backgroundColor: Color(0xFF5038ED),
        ),
      );
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the Merchant Agreement.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller application submitted! Verification in progress.'),
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
                // Top Partner Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.storefront_rounded,
                              size: 13, color: Color(0xFF5038ED)),
                          SizedBox(width: 4),
                          Text(
                            'NEXORA MERCHANT PARTNER',
                            style: TextStyle(
                              color: Color(0xFF5038ED),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.3,
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
                            color: Color(0xFF0D9488),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Portal ID: NX-9024',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title & Subtitle
                const Text(
                  'Become a Nexora Seller',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reach millions of shoppers, access instant payouts, and scale your brand seamlessly.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),

                // Commission perk banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF5038ED)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '0% commission for the first 30 days • Free hub pick-up',
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
                const SizedBox(height: 16),

                // Role Selector Tabs (Merchant / Shopper / Courier)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _buildRoleTab('Merchant', Icons.storefront_rounded, true, () {}),
                      _buildRoleTab('Shopper', Icons.shopping_bag_outlined, false, () {
                        Navigator.pushReplacementNamed(context, AppRoutes.register);
                      }),
                      _buildRoleTab('Courier', Icons.two_wheeler_rounded, false, () {
                        Navigator.pushReplacementNamed(context, AppRoutes.riderRegister);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stepper Header Box
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
                                'Store & Identity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEECFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Color(0xFF5038ED),
                              size: 20,
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
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1. Store Details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5038ED),
                            ),
                          ),
                          Text(
                            '2. Verification',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '3. Bank Setup',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Container Card
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
                      // Business Structure
                      const Text(
                        'Business Structure',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _businessStructureIndex = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _businessStructureIndex == 0
                                      ? const Color(0xFFF5F3FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _businessStructureIndex == 0
                                        ? const Color(0xFF5038ED)
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_outline,
                                        size: 16, color: Color(0xFF5038ED)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Individual / Sole',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _businessStructureIndex = 1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _businessStructureIndex == 1
                                      ? const Color(0xFFF5F3FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _businessStructureIndex == 1
                                        ? const Color(0xFF5038ED)
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.business_outlined,
                                        size: 16, color: Color(0xFF64748B)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Registered Corp',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Store or Brand Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Store or Brand Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Public facing',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: 'Aura Studios Manila',
                        decoration: _buildInputDecoration(
                          hint: 'e.g. Aura Studios Manila',
                          prefixIcon: Icons.storefront_outlined,
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Please enter store name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Core Product Category
                      const Text(
                        'Core Product Category',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: _buildInputDecoration(
                          hint: 'Select category',
                          prefixIcon: Icons.category_outlined,
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Business Email
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Business Email',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Color(0xFF0D9488)),
                              SizedBox(width: 4),
                              Text(
                                'Real-time check',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: 'alex@aurastudios.com',
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          hint: 'alex@aurastudios.com',
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo / Document Upload Box
                      const Text(
                        'KYB / Business Identity Document',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _isUploadingDoc ? null : _handleUploadDocument,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _uploadedDocName != null
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFC7D2FE),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEECFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isUploadingDoc
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF5038ED),
                                        ),
                                      )
                                    : Icon(
                                        _uploadedDocName != null
                                            ? Icons.check_circle_rounded
                                            : Icons.cloud_upload_outlined,
                                        color: _uploadedDocName != null
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFF5038ED),
                                        size: 24,
                                      ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _uploadedDocName ??
                                    'Upload Business Permit or Valid Gov ID',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _uploadedDocName != null
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _uploadedDocName != null
                                    ? 'Photo document attached cleanly'
                                    : 'Drag document here or tap to browse camera roll',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Text(
                                  '🛡️ JPG, PNG or PDF up to 10MB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fulfillment & Terms Checkboxes
                      InkWell(
                        onTap: () {
                          setState(() {
                            _enableFulfillment = !_enableFulfillment;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _enableFulfillment,
                                  onChanged: (val) {
                                    setState(() {
                                      _enableFulfillment = val ?? true;
                                    });
                                  },
                                  activeColor: const Color(0xFF5038ED),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text(
                                          'Enable Instant Fulfillment Network ',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'EXPRESS',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0891B2),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Auto-dispatch parcels via Nexora Express Couriers with real-time tracking for customers.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _agreeTerms = !_agreeTerms;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeTerms,
                                  onChanged: (val) {
                                    setState(() {
                                      _agreeTerms = val ?? true;
                                    });
                                  },
                                  activeColor: const Color(0xFF5038ED),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I confirm the details provided are accurate and agree to the Nexora Merchant Agreement and Seller Code of Conduct.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                              'Continue to Business Verification',
                              style: TextStyle(
                                fontSize: 15,
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

  Widget _buildRoleTab(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5038ED) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
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
