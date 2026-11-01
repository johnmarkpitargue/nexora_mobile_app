import 'package:flutter/material.dart';
import '../../../../core/theme/rider_theme.dart';
import '../../../../core/models/delivery_order.dart';

class ProofOfDeliverySheet extends StatefulWidget {
  final DeliveryOrder order;
  final Function(String photoPath, String notes) onConfirm;

  const ProofOfDeliverySheet({
    super.key,
    required this.order,
    required this.onConfirm,
  });

  @override
  State<ProofOfDeliverySheet> createState() => _ProofOfDeliverySheetState();
}

class _ProofOfDeliverySheetState extends State<ProofOfDeliverySheet> {
  final TextEditingController _notesController = TextEditingController();
  bool _photoAttached = false;
  bool _codConfirmed = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = 'Handed to ${widget.order.customerName} in person.';
    if (!widget.order.paymentType.contains('COD')) {
      _codConfirmed = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _simulateCapturePhoto() {
    setState(() {
      _photoAttached = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery proof photo captured & timestamped!'),
        backgroundColor: RiderTheme.onlineGreen,
      ),
    );
  }

  void _submit() {
    if (widget.order.paymentType.contains('COD') && !_codConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm you collected the COD cash payment.'),
          backgroundColor: RiderTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      widget.onConfirm(
        _photoAttached ? 'captured_pod_photo.jpg' : 'direct_handover.jpg',
        _notesController.text.trim(),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCOD = widget.order.paymentType.contains('COD');

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
            const Row(
              children: [
                Icon(Icons.verified_user_rounded,
                    color: RiderTheme.onlineGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  'Proof of Delivery (POD)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: RiderTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Order ${widget.order.id} • ${widget.order.customerName}',
              style: const TextStyle(
                fontSize: 13,
                color: RiderTheme.textMuted,
              ),
            ),
            const SizedBox(height: 18),

            // COD Checkbox if needed
            if (isCOD) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RiderTheme.warningOrangeLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: RiderTheme.warningOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _codConfirmed,
                      activeColor: RiderTheme.warningOrange,
                      onChanged: (val) {
                        setState(() => _codConfirmed = val ?? false);
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cash on Delivery Collected',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: RiderTheme.textDark,
                            ),
                          ),
                          Text(
                            'Collected ₱${widget.order.orderTotal.toStringAsFixed(2)} from recipient',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Photo Capture Card
            InkWell(
              onTap: _simulateCapturePhoto,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: _photoAttached
                      ? RiderTheme.onlineGreenLight
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _photoAttached
                        ? RiderTheme.onlineGreen
                        : RiderTheme.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _photoAttached
                          ? Icons.check_circle_rounded
                          : Icons.camera_alt_rounded,
                      size: 38,
                      color: _photoAttached
                          ? RiderTheme.onlineGreen
                          : RiderTheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _photoAttached
                          ? 'Photo Proof Attached & Verified'
                          : 'Snap Photo Proof of Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _photoAttached
                            ? const Color(0xFF10B981)
                            : RiderTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _photoAttached
                          ? 'Tap to retake photo'
                          : 'Capture package at doorstep or with recipient',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recipient Notes
            const Text(
              'Handover Note / Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: RiderTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g. Received by Alex Rivera at Tower 2 lobby',
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
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiderTheme.onlineGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Complete Delivery (Collect ₱${widget.order.riderEarnings.toStringAsFixed(2)})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
