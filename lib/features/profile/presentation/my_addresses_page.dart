import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'new_address_page.dart';

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({super.key});

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  final _addressService = AddressService.instance;

  @override
  void initState() {
    super.initState();
    _addressService.loadAddressesFromApi();
  }

  void _openAddAddress() {
    if (!_addressService.canAddAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Maximum 10 addresses reached. Please edit or delete an existing address.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewAddressPage(),
      ),
    );
  }

  void _openEditAddress(AddressModel address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewAddressPage(editAddress: address),
      ),
    );
  }

  void _showInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0D1323) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF00B4D8)),
            const SizedBox(width: 8),
            Text('Address Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          ],
        ),
        content: Text(
          'Your default delivery address is automatically used during checkout. You can select any address to make it default, or edit and add new delivery addresses anytime.',
          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF060914) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0D1323) : Colors.white;
    final headerBg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF8FAFC);
    final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final tagBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final tagText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return AnimatedBuilder(
      animation: _addressService,
      builder: (context, _) {
        final addresses = _addressService.addresses;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: cardBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Addresses',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.info_outline, color: textSecondary, size: 22),
                onPressed: _showInfoDialog,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: dividerColor),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _addressService.loadAddressesFromApi(),
                  child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Section Header
                    Container(
                      width: double.infinity,
                      color: headerBg,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'ADDRESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    if (addresses.isEmpty) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: tagBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.location_off_outlined, color: textSecondary, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No addresses saved yet',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your delivery address for faster checkout',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Address List Items matching Image 1
                      ...List.generate(addresses.length, (index) {
                        final item = addresses[index];
                        final isLast = index == addresses.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                _addressService.setDefaultAddressRemote(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.fullName} set as default address'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: const Color(0xFF00B4D8),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Name | Phone, EDIT >
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.fullName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '|',
                                          style: TextStyle(
                                            color: dividerColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.phone,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _openEditAddress(item),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'EDIT',
                                                  style: TextStyle(
                                                    color: Color(0xFF0099CC),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                                SizedBox(width: 2),
                                                Icon(
                                                  Icons.chevron_right,
                                                  size: 15,
                                                  color: Color(0xFF0099CC),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Row 2: Address String
                                    Text(
                                      item.fullAddress,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 3: Badges
                                    Row(
                                      children: [
                                        if (item.isDefault) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0B2538) : const Color(0xFFE0F7FA),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFF00D2FF).withValues(alpha: 0.5),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                color: Color(0xFF00B4D8),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: tagBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              color: tagText,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (item.latitude != null && item.longitude != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0C2140) : const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.location_on_rounded, size: 11, color: Color(0xFF38BDF8)),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Pinpoint Set',
                                                  style: TextStyle(
                                                    color: Color(0xFF38BDF8),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(height: 1, color: dividerColor),
                          ],
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    // Quick checkout info note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: headerBg,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info,
                            color: Color(0xFF00BCD4),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Default address is automatically selected for quick checkout.',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                ),
              ),

              // Bottom Fixed Bar matching Image 1
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(
                    top: BorderSide(color: dividerColor, width: 0.8),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: OutlinedButton(
                    onPressed: _openAddAddress,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00D2FF), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Color(0xFF00B4D8),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Add a new address',
                          style: TextStyle(
                            color: Color(0xFF00B4D8),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
