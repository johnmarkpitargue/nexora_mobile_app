import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/earnings_service.dart';
import '../../../core/services/rider_account_service.dart';
import '../../../core/services/rider_service.dart';
import '../../transfer_courier/services/transfer_courier_service.dart';

class CashOutScreen extends StatefulWidget {
  final bool isTransferCourier;

  const CashOutScreen({super.key, this.isTransferCourier = false});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _payoutMethod = 'gcash';
  bool _isProcessing = false;

  static const List<Map<String, dynamic>> _methods = [
    {
      'key': 'gcash',
      'label': 'GCash e-Wallet',
      'hint': '09XX XXX XXXX',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF007DFE),
    },
    {
      'key': 'maya',
      'label': 'Maya Wallet',
      'hint': '09XX XXX XXXX',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF00C48C),
    },
    {
      'key': 'bank_transfer',
      'label': 'Bank Transfer',
      'hint': 'Bank Name + Account Number',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF1E3A8A),
    },
    {
      'key': 'physical_cash',
      'label': 'Hub Cash Release',
      'hint': 'Dispatcher Counter Claim ID / Mobile',
      'icon': Icons.storefront_rounded,
      'color': Color(0xFFD97706),
    },
  ];

  double get _availableBalance => widget.isTransferCourier
      ? TransferCourierService.instance.availableForPayout
      : EarningsService.instance.availableForPayout;

  double get _pendingPayout => widget.isTransferCourier
      ? TransferCourierService.instance.pendingPayoutAmount
      : EarningsService.instance.pendingPayoutAmount;

  @override
  void initState() {
    super.initState();
    final session = RiderAccountService.instance.activeRiderSession;
    final defaultName = session?.fullName ?? RiderService.instance.profile.name;
    final defaultPhone =
        session?.mobileNumber ?? RiderService.instance.profile.phone;

    if (defaultName.isNotEmpty && defaultName != 'Nexora Rider') {
      _accountNameController.text = defaultName;
    }
    if (defaultPhone.isNotEmpty) {
      _accountNumberController.text = defaultPhone;
    }

    if (_availableBalance > 0) {
      _amountController.text = _availableBalance.toStringAsFixed(2);
    }
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _currentAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  void _setAmount(double value) {
    final capped = value > _availableBalance ? _availableBalance : value;
    _amountController.text = capped.toStringAsFixed(2);
  }

  Future<void> _onConfirmCashOut() async {
    final amount = _currentAmount;
    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    if (amount < 100.0) {
      _showError('Minimum payout request is ₱100.00.');
      return;
    }
    if (amount > _availableBalance + 0.001) {
      _showError(
        'Requested amount exceeds available withdrawable balance (₱${_availableBalance.toStringAsFixed(2)}).',
      );
      return;
    }
    if (accountName.isEmpty || accountNumber.isEmpty) {
      _showError(
        'Please enter your registered account holder name and account/mobile number.',
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = widget.isTransferCourier
          ? await TransferCourierService.instance.requestPayout(
              amount: amount,
              payoutMethod: _payoutMethod,
              accountName: accountName,
              accountNumber: accountNumber,
              courierNotes: _notesController.text.trim(),
            )
          : await EarningsService.instance.requestPayoutRemote(
              amount: amount,
              payoutMethod: _payoutMethod,
              accountName: accountName,
              accountNumber: accountNumber,
              courierNotes: _notesController.text.trim(),
            );

      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (result != null) {
        await _showSubmittedDialog(result);
      }
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) {
        _showError(
          'Unable to submit payout request right now. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  Future<void> _showSubmittedDialog(Map<String, dynamic> payout) async {
    final payoutNumber = payout['payout_number']?.toString() ?? 'PENDING';
    final amount = (payout['amount'] as num?)?.toDouble() ?? _currentAmount;
    final status = (payout['status'] ?? 'requested').toString().toUpperCase();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payout Request Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pending Logistics Finance verification. Your balance will be released once finance records the verified payout reference.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _summaryRow('Payout Number', payoutNumber),
                    const SizedBox(height: 6),
                    _summaryRow('Amount', '₱${amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    _summaryRow(
                      'Method',
                      _payoutMethod.replaceAll('_', ' ').toUpperCase(),
                    ),
                    const SizedBox(height: 6),
                    _summaryRow('Status', status),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'DONE',
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMethod = _methods.firstWhere((m) => m['key'] == _payoutMethod);
    final canSubmit =
        !_isProcessing &&
        _currentAmount >= 100.0 &&
        _currentAmount <= _availableBalance + 0.001 &&
        _accountNameController.text.trim().isNotEmpty &&
        _accountNumberController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Earnings Payout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available for payout',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF526077),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱${_availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                  ),
                  if (_pendingPayout > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '₱${_pendingPayout.toStringAsFixed(2)} reserved in pending payout requests',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: Color(0xFF1D4ED8),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Courier earnings payout is completely separate from Buyer COD cash. Logistics Finance verifies payout reference numbers before marking paid.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payout Channel',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _methods.map((m) {
                final selected = m['key'] == _payoutMethod;
                return ChoiceChip(
                  avatar: Icon(
                    m['icon'] as IconData,
                    size: 17,
                    color: selected
                        ? const Color(0xFF075FED)
                        : const Color(0xFF64748B),
                  ),
                  label: Text(m['label'] as String),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _payoutMethod = m['key'] as String),
                  selectedColor: const Color(0xFFE8F0FF),
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF075FED)
                        : const Color(0xFFE2E8F0),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF075FED)
                        : const Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recipient Details',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountNameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      filled: true,
                      fillColor: Color(0xFFF4F7FA),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountNumberController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Account / Mobile Number',
                      hintText: activeMethod['hint'] as String,
                      filled: true,
                      fillColor: const Color(0xFFF4F7FA),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes for Finance (Optional)',
                      filled: true,
                      fillColor: Color(0xFFF4F7FA),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payout Amount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Min. ₱100.00',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '₱ ',
                      filled: true,
                      fillColor: Color(0xFFF4F7FA),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final preset in [100.0, 500.0, 1000.0]) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _availableBalance >= preset
                                ? () => _setAmount(preset)
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              foregroundColor: const Color(0xFF334155),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('₱${preset.toInt()}'),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _availableBalance >= 100
                              ? () => _setAmount(_availableBalance)
                              : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFE8F0FF),
                            foregroundColor: const Color(0xFF075FED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Max'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canSubmit ? _onConfirmCashOut : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Submit payout  •  ₱${_currentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
