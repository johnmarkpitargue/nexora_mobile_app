import 'package:flutter/material.dart';
import '../../../../core/theme/rider_theme.dart';
import '../../../../core/services/rider_service.dart';
import '../../../../core/services/earnings_service.dart';

class CashOutBottomSheet extends StatefulWidget {
  const CashOutBottomSheet({super.key});

  @override
  State<CashOutBottomSheet> createState() => _CashOutBottomSheetState();
}

class _CashOutBottomSheetState extends State<CashOutBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  String _selectedMethod = 'GCash';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _methods = [
    {
      'name': 'GCash',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF007DFE),
      'defaultAcc': '0918 555 0192',
    },
    {
      'name': 'Maya',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF22C55E),
      'defaultAcc': '0918 555 0192',
    },
    {
      'name': 'BDO Unibank',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF1E3A8A),
      'defaultAcc': '0049 8812 4432',
    },
    {
      'name': 'BPI Bank',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFFB91C1C),
      'defaultAcc': '1829 3341 09',
    },
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text =
        RiderService.instance.profile.walletBalance.toStringAsFixed(0);
    _accountController.text = _methods.first['defaultAcc'] as String;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _processCashOut() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final maxBalance = RiderService.instance.profile.walletBalance;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (amount > maxBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds your available wallet balance.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      final success = EarningsService.instance.requestCashOut(
        amount,
        _selectedMethod,
        _accountController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ₱${amount.toStringAsFixed(2)} transferred to $_selectedMethod successfully!',
            ),
            backgroundColor: RiderTheme.onlineGreen,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxBalance = RiderService.instance.profile.walletBalance;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const Text(
              'Instant Cash Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: RiderTheme.textDark,
              ),
            ),
            Text(
              'Available balance: ₱${maxBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                color: RiderTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),

            // Method Selector
            const Text(
              'Select Destination',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: RiderTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _methods.map((method) {
                final isSelected = _selectedMethod == method['name'];
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMethod = method['name'] as String;
                        _accountController.text =
                            method['defaultAcc'] as String;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? RiderTheme.primaryContainer
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? RiderTheme.primary
                              : RiderTheme.cardBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(method['icon'] as IconData,
                              size: 20,
                              color: isSelected
                                  ? RiderTheme.primary
                                  : Colors.grey.shade600),
                          const SizedBox(height: 4),
                          Text(
                            method['name'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? RiderTheme.primary
                                  : RiderTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Account number
            const Text(
              'Recipient Account Number / Mobile',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: RiderTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _accountController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RiderTheme.cardBorder),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Amount input
            const Text(
              'Amount to Cash Out (₱)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: RiderTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₱ ',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RiderTheme.cardBorder),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),

            // Preset Amount Pills
            Row(
              children: [
                _presetPill(500),
                _presetPill(1000),
                _presetPill(2000),
                _presetPill(maxBalance.toInt(), isMax: true),
              ],
            ),
            const SizedBox(height: 22),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processCashOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderTheme.onlineGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Transfer Immediately',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetPill(int amount, {bool isMax = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _amountController.text = amount.toString();
            });
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: RiderTheme.cardBorder),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            isMax ? 'ALL' : '₱$amount',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: RiderTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
