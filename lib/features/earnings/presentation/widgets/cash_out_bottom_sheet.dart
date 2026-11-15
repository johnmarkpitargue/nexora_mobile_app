import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/earnings_service.dart';
import '../../../../core/services/rider_account_service.dart';
import '../../../../core/services/rider_service.dart';
import '../../../../core/theme/rider_theme.dart';

class CashOutBottomSheet extends StatefulWidget {
  const CashOutBottomSheet({super.key});

  @override
  State<CashOutBottomSheet> createState() => _CashOutBottomSheetState();
}

class _CashOutBottomSheetState extends State<CashOutBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  String _selectedMethod = 'gcash';
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _methods = [
    {
      'key': 'gcash',
      'name': 'GCash',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF007DFE),
    },
    {
      'key': 'maya',
      'name': 'Maya',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF22C55E),
    },
    {
      'key': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF1E3A8A),
    },
    {
      'key': 'physical_cash',
      'name': 'Hub Counter',
      'icon': Icons.storefront_rounded,
      'color': Color(0xFFD97706),
    },
  ];

  @override
  void initState() {
    super.initState();
    final session = RiderAccountService.instance.activeRiderSession;
    _amountController.text =
        EarningsService.instance.availableForPayout.toStringAsFixed(2);
    _accountNameController.text =
        session?.fullName ?? RiderService.instance.profile.name;
    _accountController.text =
        session?.mobileNumber ?? RiderService.instance.profile.phone;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _processCashOut() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final maxBalance = EarningsService.instance.availableForPayout;
    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountController.text.trim();

    if (amount < 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum payout request is ₱100.00.')),
      );
      return;
    }

    if (amount > maxBalance + 0.001) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount exceeds available withdrawable balance.'),
        ),
      );
      return;
    }

    if (accountName.isEmpty || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account holder name and account number are required.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final created = await EarningsService.instance.requestPayoutRemote(
        amount: amount,
        payoutMethod: _selectedMethod,
        accountName: accountName,
        accountNumber: accountNumber,
      );

      if (!mounted) return;
      Navigator.pop(context);
      final payoutNumber = created?['payout_number'] ?? 'PENDING';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payout request $payoutNumber for ₱${amount.toStringAsFixed(2)} submitted — Pending Logistics Verification.',
          ),
          backgroundColor: RiderTheme.onlineGreen,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = EarningsService.instance.availableForPayout;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Earnings Payout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Available: ₱${available.toStringAsFixed(2)} • Verified by Logistics Finance',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _methods.map((m) {
                  return ChoiceChip(
                    label: Text(m['name'] as String),
                    selected: _selectedMethod == m['key'],
                    onSelected: (_) =>
                        setState(() => _selectedMethod = m['key'] as String),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Account / Mobile Number',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (Min. ₱100.00)',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processCashOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SUBMIT PAYOUT REQUEST',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
