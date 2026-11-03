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
          content: Text('Address limit reached. You can only save up to 10 addresses.'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF00B4D8)),
            SizedBox(width: 8),
            Text('Address Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your default delivery address is automatically used during checkout. You can select any address to make it default, or edit and add new delivery addresses anytime.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
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
    return AnimatedBuilder(
      animation: _addressService,
      builder: (context, _) {
        final addresses = _addressService.addresses;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'My Addresses',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, color: Color(0xFF475569), size: 22),
                onPressed: _showInfoDialog,
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
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
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: const Text(
                        'ADDRESS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
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
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_off_outlined, color: Color(0xFF94A3B8), size: 32),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No addresses saved yet',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add your delivery address for faster checkout',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          '|',
                                          style: TextStyle(
                                            color: Color(0xFFCBD5E1),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.phone,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _openEditAddress(item),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
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
                                              color: const Color(0xFFE0F7FA),
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
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.label,
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
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
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFFBFDBFE),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.location_on_rounded, size: 11, color: Color(0xFF0066FF)),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Pinpoint Set',
                                                  style: TextStyle(
                                                    color: Color(0xFF0066FF),
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
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ],
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    // Quick checkout info note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info,
                            color: Color(0xFF00BCD4),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Default address is automatically selected for quick checkout.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
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
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 0.8),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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
