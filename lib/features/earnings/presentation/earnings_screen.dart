import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/earning_record.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/earnings_service.dart';
import '../../../core/services/in_app_notification_service.dart';
import 'cash_out_screen.dart';
import 'widgets/weekly_chart_widget.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedTxnFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      EarningsService.instance.fetchEarningsRemote(),
      EarningsService.instance.fetchCodCollectionsRemote(),
      EarningsService.instance.fetchPayoutsRemote(),
    ]);
  }

  Future<void> _openCashOut(BuildContext context) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (ctx) => const CashOutScreen()),
    );
    if (submitted == true) {
      await _refreshAll();
    }
  }

  void _openCodRemitModal(BuildContext context) {
    final service = EarningsService.instance;
    final openCollections = service.openCodCollections;
    final selectedOrderIds = <int>{};
    for (final c in openCollections) {
      final status = (c['status'] ?? '').toString();
      final avail = (c['available_to_submit_amount'] as num?)?.toDouble() ??
          (c['remaining_balance'] as num?)?.toDouble() ??
          (c['outstanding_amount'] as num?)?.toDouble() ??
          0.0;
      if ((status == 'collected' ||
              status == 'partial' ||
              status == 'shortage_flagged' ||
              status == 'collected_by_rider' ||
              status == 'partially_remitted') &&
          avail > 0) {
        final oid = (c['order_id'] as num?)?.toInt();
        if (oid != null) selectedOrderIds.add(oid);
      }
    }

    String paymentMethod = 'physical_cash';
    final amountController = TextEditingController(
      text: service.codAvailableForRemittance > 0
          ? service.codAvailableForRemittance.toStringAsFixed(2)
          : service.codHeldBalance.toStringAsFixed(2),
    );
    final refController = TextEditingController();
    final notesController = TextEditingController();
    String? pickedProofPath;
    bool isSubmitting = false;

    double computeSelectedTotal() {
      if (selectedOrderIds.isEmpty) return 0.0;
      double total = 0.0;
      for (final c in openCollections) {
        final oid = (c['order_id'] as num?)?.toInt();
        if (oid != null && selectedOrderIds.contains(oid)) {
          total += (c['available_to_submit_amount'] as num?)?.toDouble() ??
              (c['remaining_balance'] as num?)?.toDouble() ??
              (c['outstanding_amount'] as num?)?.toDouble() ??
              (c['actual_collected_amount'] as num?)?.toDouble() ??
              (c['collected_amount'] as num?)?.toDouble() ??
              0.0;
        }
      }
      return total;
    }

    if (openCollections.isNotEmpty && selectedOrderIds.isNotEmpty) {
      amountController.text = computeSelectedTotal().toStringAsFixed(2);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isNonCash = paymentMethod != 'physical_cash';
          final held = service.codHeldBalance;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalCtx).size.height * 0.9,
              ),
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Submit COD Cash Remittance',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    Text(
                      'On hand: ₱${held.toStringAsFixed(2)} • Pending verification: ₱${service.codPendingVerificationAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Color(0xFFB45309)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Remittances stay Pending Verification until a Logistics Officer verifies the actual cash or external payment proof.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (openCollections.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Select Open COD Orders',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...openCollections.map((c) {
                        final oid = (c['order_id'] as num?)?.toInt() ?? 0;
                        final orderNumber =
                            c['order_number']?.toString() ?? 'Order #$oid';
                        final remaining = (c['available_to_submit_amount']
                                    as num?)
                                ?.toDouble() ??
                            (c['remaining_balance'] as num?)?.toDouble() ??
                            (c['outstanding_amount'] as num?)?.toDouble() ??
                            (c['actual_collected_amount'] as num?)
                                ?.toDouble() ??
                            (c['collected_amount'] as num?)?.toDouble() ??
                            0.0;
                        final reserved =
                            (c['pending_reserved_amount'] as num?)?.toDouble() ??
                                0.0;
                        final status = (c['status'] ?? '').toString();
                        final locked = status == 'remittance_pending' ||
                            (remaining <= 0 && reserved > 0);
                        final checked = selectedOrderIds.contains(oid);

                        return Material(
                          type: MaterialType.transparency,
                          child: CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: checked,
                            onChanged: locked
                                ? null
                                : (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        selectedOrderIds.add(oid);
                                      } else {
                                        selectedOrderIds.remove(oid);
                                      }
                                      if (selectedOrderIds.isNotEmpty) {
                                        amountController.text =
                                            computeSelectedTotal()
                                                .toStringAsFixed(2);
                                      }
                                    });
                                  },
                            title: Text(
                              '$orderNumber — ₱${remaining.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              locked
                                  ? 'Locked in pending remittance'
                                  : 'Status: ${status.replaceAll('_', ' ')}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Remittance Channel',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final m in const [
                          ['physical_cash', 'Physical Cash'],
                          ['gcash', 'GCash'],
                          ['maya', 'Maya'],
                          ['bank_transfer', 'Bank Transfer'],
                        ])
                          ChoiceChip(
                            label: Text(m[1]),
                            selected: paymentMethod == m[0],
                            onSelected: (_) =>
                                setModalState(() => paymentMethod = m[0]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount Remitted',
                        prefixText: '₱ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (isNonCash) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: refController,
                        decoration: InputDecoration(
                          labelText:
                              '${paymentMethod.toUpperCase()} Reference Number *',
                          hintText: 'e.g. GCASH-883920194',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setModalState(() => pickedProofPath = picked.path);
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unable to open image picker on this device.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(
                          pickedProofPath == null
                              ? 'Upload Receipt / Proof Image *'
                              : 'Proof Attached: ${pickedProofPath!.split(Platform.pathSeparator).last}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Hub Counter Info (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amount = double.tryParse(
                                        amountController.text.trim()) ??
                                    0.0;
                                setModalState(() => isSubmitting = true);
                                try {
                                  final created = await EarningsService.instance
                                      .submitRemittanceRemote(
                                    amount: amount,
                                    paymentMethod: paymentMethod,
                                    externalReference: refController.text,
                                    transferDate: DateTime.now(),
                                    orderIds: selectedOrderIds.isNotEmpty
                                        ? selectedOrderIds.toList()
                                        : null,
                                    proofFilePath: pickedProofPath,
                                    notes: notesController.text,
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(sheetCtx);
                                  final remitNo =
                                      created?['remittance_number']?.toString() ??
                                          'SUBMITTED';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Remittance $remitNo (₱${amount.toStringAsFixed(2)}) submitted — Pending Verification.',
                                      ),
                                      backgroundColor: const Color(0xFF0066FF),
                                    ),
                                  );
                                } on ApiException catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.message),
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  setModalState(() => isSubmitting = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to submit COD remittance.',
                                        ),
                                        backgroundColor: Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SUBMIT FOR LOGISTICS VERIFICATION',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<EarningTransaction> _getFilteredTransactions(
    List<EarningTransaction> all,
  ) {
    if (_selectedTxnFilter == 'All') return all;
    if (_selectedTxnFilter == 'Deliveries & Pickups') {
      return all
          .where((t) =>
              t.type == TransactionType.deliveryFee ||
              t.type == TransactionType.tip)
          .toList();
    }
    if (_selectedTxnFilter == 'Incentives & Quests') {
      return all.where((t) => t.type == TransactionType.bonus).toList();
    }
    return all;
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'SUBMITTED';
      case 'pending':
      case 'under_review':
      case 'requested':
        return 'PENDING VERIFICATION';
      case 'partially_verified':
      case 'partial':
        return 'PARTIALLY VERIFIED';
      case 'verified':
      case 'approved':
      case 'paid':
        return 'VERIFIED';
      case 'disputed':
      case 'discrepancy_flagged':
      case 'shortage_flagged':
        return 'DISPUTED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'paid':
        return const Color(0xFFDCFCE7);
      case 'rejected':
      case 'shortage_flagged':
      case 'discrepancy_flagged':
      case 'disputed':
      case 'partial':
      case 'partially_verified':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'paid':
        return const Color(0xFF15803D);
      case 'rejected':
      case 'shortage_flagged':
      case 'discrepancy_flagged':
      case 'disputed':
      case 'partial':
      case 'partially_verified':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EarningsService.instance,
      builder: (context, _) {
        final service = EarningsService.instance;
        final filteredTxns = _getFilteredTransactions(service.transactions);
        final policy = service.activePolicy;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Earnings & COD Wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Color(0xFF0F172A)),
                onPressed: () {
                  InAppNotificationService.instance
                      .showNotificationHistory(context);
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (service.lastError != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            service.lastError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F1D1D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _refreshAll,
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // 1. Courier Earnings & Payout Wallet Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A192F), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AVAILABLE EARNINGS FOR PAYOUT',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₱${service.availableForPayout.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Pending Payout: ₱${service.pendingPayoutAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Paid Out: ₱${service.totalPaidOut.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF34D399),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (policy != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Active Rate: Pickup ₱${(policy['pickup_rate'] as num?)?.toStringAsFixed(2) ?? '30.00'} • Delivery ₱${(policy['delivery_rate'] as num?)?.toStringAsFixed(2) ?? '50.00'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => _openCashOut(context),
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: const Text(
                            'Request Payout',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Strictly Separate Buyer COD Accountability Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: service.codHeldBalance > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'COD CASH ACCOUNTABILITY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB45309),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: service.codHeldBalance > 0
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              service.codHeldBalance > 0
                                  ? '₱${service.codHeldBalance.toStringAsFixed(2)} Held'
                                  : '₱0.00 Held',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: service.codHeldBalance > 0
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Buyer COD cash collected on delivery (never combined with your earnings).',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _metricBox(
                              'Available to Remit',
                              '₱${service.codAvailableForRemittance.toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _metricBox(
                              'Pending Verification',
                              '₱${service.codPendingVerificationAmount.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                      if (service.codTotalShortageFlagged > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Flagged Shortage Balance: ₱${service.codTotalShortageFlagged.toStringAsFixed(2)} — Coordinate with Logistics Finance.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: service.codHeldBalance > 0 ||
                                  service.openCodCollections.isNotEmpty
                              ? () => _openCodRemitModal(context)
                              : null,
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: const Text(
                            'Submit COD Remittance',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (service.recentRemittances.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Recent COD Remittances',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...service.recentRemittances.take(5).map((r) {
                    final status = (r['status'] ?? 'submitted').toString();
                    final claimed =
                        (r['claimed_amount'] ?? r['amount'] ?? 0) as num;
                    final method = (r['payment_method'] ?? 'physical_cash')
                        .toString()
                        .replaceAll('_', ' ');
                    final shortage = (r['shortage_amount'] as num?)?.toDouble() ?? 0.0;
                    final reason = r['discrepancy_reason']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['remittance_number']?.toString() ?? 'REMIT',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '₱${claimed.toStringAsFixed(2)} • ${method.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                if (shortage > 0 || reason.isNotEmpty)
                                  Text(
                                    shortage > 0
                                        ? 'Shortage: ₱${shortage.toStringAsFixed(2)} $reason'
                                        : reason,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _statusFg(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                if (service.recentPayouts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Payout Requests History',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...service.recentPayouts.take(5).map((p) {
                    final status = (p['status'] ?? 'requested').toString();
                    final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                    final ref = p['payout_reference']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p['payout_number'] ?? 'PAYOUT'} — ₱${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${(p['payout_method'] ?? '').toString().replaceAll('_', ' ').toUpperCase()}${ref.isNotEmpty ? ' • Ref: $ref' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _statusFg(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),
                WeeklyChartWidget(data: service.weeklyData),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Earned Compensation Ledger',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedTxnFilter,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(
                          value: 'Deliveries & Pickups',
                          child: Text('Trips'),
                        ),
                        DropdownMenuItem(
                          value: 'Incentives & Quests',
                          child: Text('Incentives'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedTxnFilter = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filteredTxns.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No recorded earnings transactions yet.',
                        style:
                            TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                else
                  ...filteredTxns.map((txn) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  txn.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+₱${txn.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
