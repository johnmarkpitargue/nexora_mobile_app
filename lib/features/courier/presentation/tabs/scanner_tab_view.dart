import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/courier_models.dart';
import '../../services/courier_service.dart';

class ScannerTabView extends StatefulWidget {
  const ScannerTabView({super.key});

  @override
  State<ScannerTabView> createState() => _ScannerTabViewState();
}

class _ScannerTabViewState extends State<ScannerTabView> {
  final CourierService _service = CourierService.instance;
  final TextEditingController _scanInputController = TextEditingController();
  CourierParcel? _scannedParcel;
  String? _scanErrorMessage;

  @override
  void dispose() {
    _scanInputController.dispose();
    super.dispose();
  }

  void _processScannedBarcode(String code) {
    HapticFeedback.mediumImpact();
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    final found = _service.parcels.firstWhere(
      (p) => p.id.toUpperCase() == cleanCode.toUpperCase(),
      orElse: () => _service.parcels.first,
    );

    setState(() {
      _scannedParcel = found;
      _scanErrorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Barcode Recognized: ${found.id} ($cleanCode)')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF050B28),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00D2FF), size: 24),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'High-Speed Hub Waybill Terminal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AUTO-DETECT 60FPS',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Mock Scan Viewport with Reticle
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0066FF), width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF00D2FF), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.barcode_reader, color: Colors.white70, size: 48),
                              SizedBox(height: 4),
                              Text(
                                'Align Waybill Barcode',
                                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Hold package steady within frame',
                            style: TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Manual Waybill Code Entry
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scanInputController,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'Or enter tracking # manually...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_scanInputController.text.isNotEmpty) {
                          _processScannedBarcode(_scanInputController.text);
                        }
                      },
                      child: const Text('Process', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Result Card if parcel was scanned
          if (_scannedParcel != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _scannedParcel!.id,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _scannedParcel!.status.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _scannedParcel!.status.label,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _scannedParcel!.status.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Customer: ${_scannedParcel!.customerName} (${_scannedParcel!.customerPhone})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Address: ${_scannedParcel!.customerAddress}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  Text('Items: ${_scannedParcel!.itemsDescription}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _scannedParcel!.isCod ? 'COD ₱${_scannedParcel!.amountCod.toStringAsFixed(2)}' : 'PREPAID',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0066FF), fontSize: 13),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.local_shipping, size: 16),
                        label: const Text('Update Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          _service.updateParcelStatus(
                            parcelId: _scannedParcel!.id,
                            newStatus: CourierParcelStatus.inTransit,
                          );
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Waybill status updated to Out for Delivery!')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (_scanErrorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _scanErrorMessage!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

          const SizedBox(height: 16),
          // Quick Tap Waybill Simulations
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sample Waybills to Test:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _service.parcels.take(4).map((p) {
              return ActionChip(
                avatar: const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFF0066FF)),
                label: Text(p.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                onPressed: () {
                  _scanInputController.text = p.id;
                  _processScannedBarcode(p.id);
                },
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
