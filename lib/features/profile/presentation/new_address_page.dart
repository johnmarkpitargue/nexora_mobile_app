import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';

class NewAddressPage extends StatefulWidget {
  final AddressModel? editAddress;

  const NewAddressPage({
    super.key,
    this.editAddress,
  });

  @override
  State<NewAddressPage> createState() => _NewAddressPageState();
}

class _NewAddressPageState extends State<NewAddressPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _regionController;
  late final TextEditingController _postalController;
  late final TextEditingController _streetController;

  bool _isDefault = false;
  String _selectedLabel = 'Home'; // 'Work' or 'Home'

  final List<String> _commonRegions = [
    'Liliw, Laguna, South Luzon',
    'Quezon City, Metro Manila',
    'Makati City, Metro Manila',
    'Taguig City (BGC), Metro Manila',
    'Pasig City, Metro Manila',
    'Mandaluyong City, Metro Manila',
    'City of Manila, Metro Manila',
    'Cebu City, Central Visayas',
    'Davao City, Davao Region',
    'Bacolod City, Western Visayas',
    'Iloilo City, Western Visayas',
    'Cagayan de Oro, Northern Mindanao',
    'Antipolo, Rizal, Calabarzon',
    'Imus, Cavite, Calabarzon',
    'Santa Rosa, Laguna, Calabarzon',
    'San Fernando, Pampanga, Central Luzon',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.editAddress;
    _nameController = TextEditingController(text: item?.fullName ?? '');
    _phoneController = TextEditingController(text: item?.phone ?? '');
    _regionController = TextEditingController(text: item?.regionCity ?? '');
    _postalController = TextEditingController(text: item?.postalCode ?? '');
    _streetController = TextEditingController(text: item?.streetBuilding ?? '');

    _isDefault = item?.isDefault ?? false;
    _selectedLabel = item?.label ?? 'Home';
  }

  @override
  void dispose() {
    _nameController.dispose;
    _phoneController.dispose;
    _regionController.dispose;
    _postalController.dispose;
    _streetController.dispose;
    super.dispose();
  }

  void _openRegionSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Region & City',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: ListView.separated(
                itemCount: _commonRegions.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final region = _commonRegions[index];
                  final isSelected = _regionController.text == region;
                  return ListTile(
                    title: Text(
                      region,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFF00B4D8) : const Color(0xFF0F172A),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF00B4D8), size: 18)
                        : null,
                    onTap: () {
                      setState(() {
                        _regionController.text = region;
                        if (_postalController.text.isEmpty) {
                          if (region.contains('4004') || region.contains('Liliw')) {
                            _postalController.text = '4004';
                          } else if (region.contains('Quezon City')) {
                            _postalController.text = '1127';
                          } else if (region.contains('Makati')) {
                            _postalController.text = '1200';
                          } else if (region.contains('Taguig')) {
                            _postalController.text = '1634';
                          } else if (region.contains('Manila')) {
                            _postalController.text = '1000';
                          } else if (region.contains('Cebu')) {
                            _postalController.text = '6000';
                          } else if (region.contains('Davao')) {
                            _postalController.text = '8000';
                          }
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final region = _regionController.text.trim();
    final postal = _postalController.text.trim();
    final street = _streetController.text.trim();

    if (name.isEmpty) {
      _showToast('Please enter your full name');
      return;
    }
    if (phone.isEmpty) {
      _showToast('Please enter your phone number');
      return;
    }
    if (street.isEmpty) {
      _showToast('Please enter street and building information');
      return;
    }

    final effectiveRegion = region.isNotEmpty ? region : 'Metro Manila';
    final effectivePostal = postal.isNotEmpty ? postal : '1000';

    if (widget.editAddress != null) {
      final updated = widget.editAddress!.copyWith(
        fullName: name,
        phone: phone,
        regionCity: effectiveRegion,
        postalCode: effectivePostal,
        streetBuilding: street,
        label: _selectedLabel,
        isDefault: _isDefault,
      );
      AddressService.instance.updateAddress(updated);
      _showToast('Address updated successfully');
    } else {
      final newAddr = AddressModel(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        fullName: name,
        phone: phone,
        regionCity: effectiveRegion,
        postalCode: effectivePostal,
        streetBuilding: street,
        label: _selectedLabel,
        isDefault: _isDefault,
      );
      AddressService.instance.addAddress(newAddr);
      _showToast('New address saved successfully');
    }

    Navigator.pop(context);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF00B4D8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editAddress != null;
    final canSubmit = _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background per Image 2
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Address' : 'New Address',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card 1: Address Details (Matching Image 2)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Full Name
                  TextField(
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Phone Number
                  TextField(
                    controller: _phoneController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Phone Number',
                      hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Region, Province, City, Barangay
                  InkWell(
                    onTap: _openRegionSelector,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _regionController.text.isNotEmpty
                                  ? _regionController.text
                                  : 'Region, Province, City, Barangay',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _regionController.text.isNotEmpty
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF94A3B8),
                                fontWeight: _regionController.text.isNotEmpty
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Postal Code
                  TextField(
                    controller: _postalController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Postal Code',
                      hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Street Name, Building, House No.
                  TextField(
                    controller: _streetController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Street Name, Building, House No.',
                      hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Card 2: Settings (Matching Image 2)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Set as Default Address Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Set as Default Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      CupertinoSwitch(
                        value: _isDefault,
                        activeTrackColor: const Color(0xFF00D2FF),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        onChanged: (val) {
                          setState(() {
                            _isDefault = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Label As: Work / Home Row
                  Row(
                    children: [
                      const Text(
                        'Label As:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      // Work Chip
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLabel = 'Work';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedLabel == 'Work'
                                ? const Color(0xFFE0F7FA)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: _selectedLabel == 'Work'
                                ? Border.all(color: const Color(0xFF00D2FF), width: 1.2)
                                : null,
                          ),
                          child: Text(
                            'Work',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _selectedLabel == 'Work'
                                  ? const Color(0xFF00B4D8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Home Chip
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLabel = 'Home';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedLabel == 'Home'
                                ? const Color(0xFFE0F7FA)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: _selectedLabel == 'Home'
                                ? Border.all(color: const Color(0xFF00D2FF), width: 1.2)
                                : null,
                          ),
                          child: Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _selectedLabel == 'Home'
                                  ? const Color(0xFF00B4D8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Submit Bar (Matching Image 2)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? const Color(0xFF00C1D4) : const Color(0xFFDDE4F0),
                foregroundColor: canSubmit ? Colors.white : const Color(0xFF94A3B8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: canSubmit ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
