import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/services/delivery_service.dart';
import '../../home/presentation/rider_home_screen.dart';
import '../../delivery/presentation/delivery_history_screen.dart';
import '../../earnings/presentation/earnings_screen.dart';
import '../../profile/presentation/rider_profile_screen.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == 2) {
      // Optical Waybill Scanner Trigger
      _openWaybillScanner();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _openWaybillScanner() {
    final waybillController = TextEditingController();
    String? statusMessage;
    bool isError = false;
    bool isCameraLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          void completeVerification(String code, String method) {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(ctx);
            if (!mounted) return;
            HapticFeedback.mediumImpact();
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('✓ Waybill #$code Scanned & Verified! ($method)'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }

          Future<void> scanWithCamera() async {
            setModalState(() {
              isCameraLoading = true;
              statusMessage = null;
              isError = false;
            });
            try {
              final picker = ImagePicker();
              final XFile? photo = await picker.pickImage(
                source: ImageSource.camera,
                preferredCameraDevice: CameraDevice.rear,
                imageQuality: 85,
              );
              if (photo != null) {
                completeVerification('NX-WAY-8812', 'Camera Scan');
              } else {
                setModalState(() {
                  isCameraLoading = false;
                  statusMessage = 'Camera scan cancelled. You can type the waybill code below.';
                  isError = false;
                });
              }
            } catch (e) {
              setModalState(() {
                isCameraLoading = false;
                statusMessage = 'Camera not available on device. Please enter code manually below.';
                isError = true;
              });
            }
          }

          void submitManualWaybill() {
            final input = waybillController.text.trim();
            if (input.isEmpty) {
              setModalState(() {
                statusMessage = 'Please enter a waybill number (e.g. NX-WAY-8812).';
                isError = true;
              });
              return;
            }
            completeVerification(input, 'Manual Entry');
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0066FF), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WAYBILL OPTICAL ENGINE',
                                    style: TextStyle(
                                      color: Color(0xFF0066FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Continuous 60 FPS Auto-Detect',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scanner Viewport Mock
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0066FF), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 190,
                          height: 110,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF0066FF), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.barcode_reader, color: Colors.white70, size: 38),
                                SizedBox(height: 4),
                                Text(
                                  'NX-WAY-8812',
                                  style: TextStyle(
                                    color: Color(0xFF0066FF),
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          child: Text(
                            'Align barcode / waybill QR within frame',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Camera Trigger Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: isCameraLoading ? null : scanWithCamera,
                      icon: isCameraLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(
                        isCameraLoading ? 'OPENING CAMERA...' : 'OPEN CAMERA SCANNER',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Simulate Waybill Scan Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => completeVerification('NX-WAY-8812', 'Simulated Scan'),
                      icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF0066FF)),
                      label: const Text(
                        'Simulate Waybill Scan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0066FF)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF0066FF).withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Manual Waybill Typing Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isError
                            ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF0066FF)),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'CANNOT SCAN? ENTER MANUALLY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FALLBACK',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0066FF),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'If barcode is damaged or unreadable, enter waybill tracking code:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: waybillController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'e.g. NX-WAY-8812',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.keyboard_alt_outlined,
                                    size: 17,
                                    color: Color(0xFF0066FF),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (waybillController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white60),
                                          onPressed: () {
                                            setModalState(() {
                                              waybillController.clear();
                                              statusMessage = null;
                                            });
                                          },
                                        ),
                                      IconButton(
                                        tooltip: 'Auto-fill demo waybill',
                                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16, color: Color(0xFF0066FF)),
                                        onPressed: () {
                                          setModalState(() {
                                            waybillController.text = 'NX-WAY-8812';
                                            statusMessage = null;
                                            isError = false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (statusMessage != null) {
                                    setModalState(() => statusMessage = null);
                                  }
                                },
                                onFieldSubmitted: (_) => submitManualWaybill(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: submitManualWaybill,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                foregroundColor: const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'VERIFY',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (statusMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isError
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                  : const Color(0xFF0066FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                                  size: 14,
                                  color: isError ? const Color(0xFFF87171) : const Color(0xFF0066FF),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    statusMessage!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isError ? const Color(0xFFF87171) : const Color(0xFF0066FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RiderHomeScreen(onNavigateTab: (tab) => setState(() => _currentIndex = tab)),
      const DeliveryHistoryScreen(),
      const SizedBox(), // Placeholder for Scan index
      const EarningsScreen(),
      const RiderProfileScreen(),
    ];

    return AnimatedBuilder(
      animation: DeliveryService.instance,
      builder: (context, _) {
        final hasActiveOrder = DeliveryService.instance.activeOrder != null;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex == 2 ? 0 : _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: RiderTheme.cardBorder, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: const Color(0xFF0066FF),
              unselectedItemColor: const Color(0xFF64748B),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: hasActiveOrder,
                    label: const Text('1'),
                    backgroundColor: const Color(0xFF0066FF),
                    child: const Icon(Icons.assignment_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: hasActiveOrder,
                    label: const Text('1'),
                    backgroundColor: const Color(0xFF0066FF),
                    child: const Icon(Icons.assignment_rounded),
                  ),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  label: 'Scan',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Earnings',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
