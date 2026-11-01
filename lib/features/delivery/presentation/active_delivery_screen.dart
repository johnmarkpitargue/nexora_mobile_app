import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/rider_theme.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/services/rider_location_service.dart';
import '../../../core/services/rider_service.dart';
import '../../chat/presentation/rider_chat_screen.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../earnings/presentation/earnings_screen.dart';
import 'widgets/rider_live_navigation_map.dart';
import 'widgets/route_progress_widget.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final DeliveryOrder order;

  const ActiveDeliveryScreen({
    super.key,
    required this.order,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  // 0: To Store, 1: At Store, 2: Pickup Verified, 3: In Transit, 4: Delivered
  int _currentStage = 0;

  // Stage 2 state
  bool _pkg1Scanned = false;
  bool _pkg2Scanned = false;
  bool _tamperSealChecked = true;
  bool _fragileSecuredChecked = true;

  // Scroll and Handover Protocol State
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _handoverCodeController = TextEditingController();
  bool _handoverCodeVerified = false;
  String? _capturedPodPhotoPath;
  String? _podRecipientNotes;

  // Delivery Completion State
  DateTime? _deliveryCompletedTime;

  String _formatTime12Hour(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final standardHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$standardHour:$minute $period';
  }

  String _getFormattedCompletionTime() {
    final time = _deliveryCompletedTime ?? DateTime(2026, 10, 24, 14, 38);
    return _formatTime12Hour(time);
  }

  @override
  void initState() {
    super.initState();
    // Initialize stage based on active order in DeliveryService (continuous progress)
    final active = DeliveryService.instance.activeOrder;
    if (active != null &&
        (active.id == widget.order.id ||
            active.id.replaceAll('#', '') == widget.order.id.replaceAll('#', ''))) {
      _currentStage = DeliveryService.instance.activeOrderStage;
      _pkg1Scanned = DeliveryService.instance.pkg1Scanned;
      _pkg2Scanned = DeliveryService.instance.pkg2Scanned;
      _tamperSealChecked = DeliveryService.instance.tamperSealChecked;
      _fragileSecuredChecked = DeliveryService.instance.fragileSecuredChecked;
      _handoverCodeVerified = DeliveryService.instance.handoverCodeVerified;
      _capturedPodPhotoPath = DeliveryService.instance.activeOrder?.proofPhotoPath;
      _deliveryCompletedTime = DeliveryService.instance.deliveryCompletedTime;
    } else {
      final status = widget.order.status;
      if (status == DeliveryStatus.atMerchant) {
        _currentStage = 1;
      } else if (status == DeliveryStatus.pickedUp || status == DeliveryStatus.atCustomer) {
        _currentStage = 3;
      } else if (status == DeliveryStatus.delivered) {
        _currentStage = 4;
      } else {
        _currentStage = 0;
      }
    }

    // Start high-precision GPS tracking & continuous broadcast to buyer
    final riderName = RiderService.instance.profile.name.isNotEmpty
        ? RiderService.instance.profile.name
        : 'Pedro Jose Garcia';
    String initialStatusStr = 'accepted';
    if (_currentStage == 1) initialStatusStr = 'at_store';
    if (_currentStage == 2) initialStatusStr = 'picked_up';
    if (_currentStage == 3) initialStatusStr = 'in_transit';
    if (_currentStage == 4) initialStatusStr = 'delivered';
    RiderLocationService.instance.startTracking(
      orderId: widget.order.id,
      riderName: riderName,
      status: initialStatusStr,
    );

    // Subscribe to real-time chat updates for this active order
    RiderChatService.instance.subscribeToOrder(widget.order.id);
    RiderChatService.instance.onNewMessageReceived = (msg) {
      if (!mounted) return;
      InAppNotificationService.instance.showNotification(
        senderName: msg.senderName.isNotEmpty ? msg.senderName : widget.order.customerName,
        message: msg.text,
        orderId: msg.orderId,
        icon: Icons.person_pin_circle_rounded,
        accentColor: const Color(0xFF0284C7),
        onReply: () => _openChat(widget.order.customerName),
      );
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _handoverCodeController.dispose();
    RiderChatService.instance.onNewMessageReceived = null;
    // NOTE: Only stop GPS tracking if the delivery was finished or cancelled.
    // Keeps continuous tracking alive when rider navigates back to Home or switches tabs!
    if (DeliveryService.instance.activeOrder == null) {
      RiderLocationService.instance.stopTracking();
    }
    super.dispose();
  }

  void _nextStage() {
    if (_currentStage < 4) {
      setState(() {
        if (_currentStage == 1) {
          // When leaving At Store, ensure both parcels are scanned
          _pkg1Scanned = true;
          _pkg2Scanned = true;
        }

        _currentStage++;

        String statusStr = 'to_deliver';
        if (_currentStage == 1) statusStr = 'at_store';
        if (_currentStage == 2) statusStr = 'picked_up';
        if (_currentStage == 3) statusStr = 'in_transit';

        if (_currentStage == 4) {
          statusStr = 'delivered';
          _deliveryCompletedTime = DateTime.now();
          DeliveryService.instance.completeCurrentDelivery(
            photoPath: _capturedPodPhotoPath,
            notes: _podRecipientNotes ?? 'Package handed directly to customer at destination pin.',
          );
          RiderLocationService.instance.stopTracking();
        } else {
          DeliveryService.instance.updateActiveOrderStage(_currentStage);
          DeliveryService.instance.updateActiveOrderScanProgress(
            pkg1: _pkg1Scanned,
            pkg2: _pkg2Scanned,
            handoverVerified: _handoverCodeVerified,
          );
          RiderLocationService.instance.updateOrderStatus(statusStr);
        }
      });
    }
  }


  Future<void> _showMandatoryPodCameraModal(DeliveryOrder order) async {
    final picker = ImagePicker();
    final notesController = TextEditingController(text: _podRecipientNotes ?? 'Received by recipient in person');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          final hasPhoto = _capturedPodPhotoPath != null && _capturedPodPhotoPath!.isNotEmpty;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
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
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0066FF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Mandatory Proof of Delivery',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '*REQUIRED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0066FF),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Order #${order.id} • ${order.customerName}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // POD Photo Capture Area
                  GestureDetector(
                    onTap: () async {
                      try {
                        final XFile? photo = await picker.pickImage(
                          source: ImageSource.camera,
                          preferredCameraDevice: CameraDevice.rear,
                          imageQuality: 85,
                        );
                        if (photo != null) {
                          setModalState(() {
                            _capturedPodPhotoPath = photo.path;
                          });
                          setState(() {
                            _capturedPodPhotoPath = photo.path;
                          });
                          HapticFeedback.mediumImpact();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Camera error: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasPhoto ? const Color(0xFF10B981) : const Color(0xFF0066FF),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: hasPhoto
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(_capturedPodPhotoPath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'PHOTO CAPTURED',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Retake Photo',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_rounded,
                                    size: 44,
                                    color: Color(0xFF0066FF),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to Take Proof of Delivery Photo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'Take a clear photo of the parcel handed to the customer or at the doorstep',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Recipient note / handover note
                  const Text(
                    'Handover Notes / Recipient Name',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Received by buyer / Left at guard house',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_capturedPodPhotoPath == null || _capturedPodPhotoPath!.isEmpty) {
                          HapticFeedback.vibrate();
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Proof of Delivery photo is mandatory before completing delivery!'),
                              backgroundColor: Color(0xFFE11D48),
                            ),
                          );
                          return;
                        }

                        _podRecipientNotes = notesController.text.trim();
                        Navigator.pop(ctx);
                        _nextStage();
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'CONFIRM POD & COMPLETE DELIVERY',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: 0.3),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasPhoto ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchNavigationToMerchant(DeliveryOrder order) async {
    final lat = order.merchantLat;
    final lng = order.merchantLng;
    final label = Uri.encodeComponent(order.merchantName);

    try {
      Uri? navUri;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final googleNavIntent = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
        if (await canLaunchUrl(googleNavIntent)) {
          navUri = googleNavIntent;
        }
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final googleMapsIos = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
        if (await canLaunchUrl(googleMapsIos)) {
          navUri = googleMapsIos;
        }
      }

      navUri ??= Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

      final launched = await launchUrl(navUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng($label)');
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open map: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _confirmArrivalAtStore(DeliveryOrder order) {
    setState(() {
      _currentStage = 1;
      DeliveryService.instance.updateActiveOrderStage(1);
      RiderLocationService.instance.updateOrderStatus('at_store');
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('✓ Arrived at ${order.merchantName}! Ready for parcel verification.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B192C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showBarcodeScannerModal(String parcelId, String description, String barcode) {
    final manualCodeController = TextEditingController();
    String? statusMessage;
    bool isStatusError = false;
    bool isCameraLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          void completeVerification(String method) {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(ctx);
            if (!mounted) return;
            setState(() {
              if (parcelId.contains('MASTER')) {
                _pkg1Scanned = true;
                _pkg2Scanned = true;
              } else if (parcelId.contains('A') || parcelId.contains('01')) {
                _pkg1Scanned = true;
              } else {
                _pkg2Scanned = true;
              }
              DeliveryService.instance.updateActiveOrderScanProgress(
                pkg1: _pkg1Scanned,
                pkg2: _pkg2Scanned,
              );
            });
            HapticFeedback.mediumImpact();
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('✓ $parcelId Barcode Authenticated & Security Seal Verified!'),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0B192C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }

          Future<void> scanWithCamera() async {
            setModalState(() {
              isCameraLoading = true;
              statusMessage = null;
              isStatusError = false;
            });
            try {
              final picker = ImagePicker();
              final XFile? photo = await picker.pickImage(
                source: ImageSource.camera,
                preferredCameraDevice: CameraDevice.rear,
                imageQuality: 85,
              );
              if (photo != null) {
                completeVerification('Camera Photo Scan');
              } else {
                setModalState(() {
                  isCameraLoading = false;
                  statusMessage = 'Camera scan cancelled. You can enter the barcode manually below.';
                  isStatusError = false;
                });
              }
            } catch (e) {
              setModalState(() {
                isCameraLoading = false;
                statusMessage = 'Camera unavailable on device. Please enter barcode manually below.';
                isStatusError = true;
              });
            }
          }

          void submitManualBarcode() {
            final input = manualCodeController.text.trim();
            if (input.isEmpty) {
              setModalState(() {
                statusMessage = 'Please enter barcode or tracking number.';
                isStatusError = true;
              });
              return;
            }
            completeVerification('Manual Code: $input');
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.92,
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
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
                                color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF00C4FF), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PARCEL SCAN VERIFICATION',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF38BDF8),
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    parcelId,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
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
                  const SizedBox(height: 14),

                  // Camera Viewfinder Screen
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Viewfinder corner marks
                        Positioned(
                          top: 14,
                          left: 18,
                          right: 18,
                          bottom: 14,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF00C4FF), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.barcode_reader, size: 44, color: Colors.white70),
                                  const SizedBox(height: 6),
                                  Text(
                                    barcode,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 12,
                                      letterSpacing: 2,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Camera Scanning Laser animation bar
                        Positioned(
                          top: 90,
                          left: 24,
                          right: 24,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C4FF),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C4FF).withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          child: Text(
                            'ALIGN PARCEL BARCODE WITHIN FRAME',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Parcel Description & Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Real Camera Scan Action
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
                        isCameraLoading ? 'STARTING CAMERA...' : 'OPEN CAMERA SCANNER',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C4FF),
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Simulate Camera Scan (Fast fallback & automated tests)
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => completeVerification('Simulated Scan'),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF38BDF8)),
                      label: const Text(
                        'SIMULATE CAMERA BARCODE SCAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF00C4FF).withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF00C4FF).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Manual Typing Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isStatusError
                            ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF38BDF8)),
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
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FALLBACK',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF38BDF8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'If barcode is torn, smudged, or camera cannot focus, type code below:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: manualCodeController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'e.g. $barcode',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.keyboard_alt_outlined,
                                    size: 17,
                                    color: Color(0xFF38BDF8),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (manualCodeController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white60),
                                          onPressed: () {
                                            setModalState(() {
                                              manualCodeController.clear();
                                              statusMessage = null;
                                            });
                                          },
                                        ),
                                      IconButton(
                                        tooltip: 'Paste barcode',
                                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16, color: Color(0xFF38BDF8)),
                                        onPressed: () {
                                          setModalState(() {
                                            manualCodeController.text = barcode;
                                            statusMessage = null;
                                            isStatusError = false;
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
                                    borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 1.5),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (statusMessage != null) {
                                    setModalState(() => statusMessage = null);
                                  }
                                },
                                onFieldSubmitted: (_) => submitManualBarcode(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: submitManualBarcode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C4FF),
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
                              color: isStatusError
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                  : const Color(0xFF00C4FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isStatusError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                                  size: 14,
                                  color: isStatusError ? const Color(0xFFF87171) : const Color(0xFF38BDF8),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    statusMessage!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isStatusError ? const Color(0xFFF87171) : const Color(0xFF38BDF8),
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

  void _validateHandoverCode(String input) {
    final clean = input.trim().toUpperCase();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please request the handover code from Marco R. at Counter Desk 02'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    setState(() {
      _handoverCodeVerified = true;
      DeliveryService.instance.updateActiveOrderScanProgress(
        handoverVerified: true,
      );
    });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('✓ Handover Code "$clean" verified! Custody transfer authorized.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _showRiderPickupQrModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0284C7)),
                  SizedBox(width: 4),
                  Text(
                    'COURIER IDENTIFICATION BADGE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0284C7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Show My Pickup QR to Merchant',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Present this digital authorization badge to store attendant Marco R. at Counter Desk 02 to scan and verify package custody release.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 160,
                    color: Color(0xFF0F172A),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RIDER: NX-7819 • ORDER #${widget.order.id}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _handoverCodeVerified = true;
                    _handoverCodeController.text = 'NX-8942-S';
                    DeliveryService.instance.updateActiveOrderScanProgress(
                      handoverVerified: true,
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('✓ Attendant Marco R. scanned rider badge! Handover authorized.'),
                          ),
                        ],
                      ),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text(
                  'Attendant Scanned & Handed Over',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C4FF),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(String name, {bool isMerchant = false}) {
    final effectiveId = isMerchant ? '${widget.order.id}_merchant' : widget.order.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RiderChatScreen(
          customerName: name,
          orderId: effectiveId,
        ),
      ),
    );
  }

  String _maskPhoneNumber(String rawPhone) {
    final trimmed = rawPhone.trim();
    final parts = trimmed.split(' ');
    if (parts.length >= 4) {
      return '${parts[0]} ${parts[1]} *** ${parts[3]}';
    }
    if (trimmed.length > 8) {
      return '${trimmed.substring(0, trimmed.length - 8)} *** ${trimmed.substring(trimmed.length - 4)}';
    }
    return '+63 9** *** ****';
  }

  void _callPhone(String phone, String name) {
    final masked = _maskPhoneNumber(phone);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Connecting anonymized VoIP call to $name ($masked)...'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
  }

  void _reportDelay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏱️ Merchant queue delay reported to dispatch.'),
        backgroundColor: Color(0xFFD97706),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DeliveryService.instance,
      builder: (context, _) {
        final active = DeliveryService.instance.activeOrder;
        final order = (active != null &&
                (active.id == widget.order.id ||
                    active.id.replaceAll('#', '') == widget.order.id.replaceAll('#', '')))
            ? active
            : widget.order;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Active Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              AnimatedBuilder(
                animation: RiderChatService.instance,
                builder: (context, _) {
                  final unread = RiderChatService.instance.getUnreadCount(order.id);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0284C7)),
                        tooltip: 'Chat Customer',
                        onPressed: () => _openChat(order.customerName),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Order Milestone Card
                    _buildTopOrderCard(order),
                    const SizedBox(height: 14),

                    if (_currentStage == 4) ...[
                      // In Stage 5, progress stepper sits above the completion hero card
                      RouteProgressWidget(
                        currentStageIndex: _currentStage,
                      ),
                      const SizedBox(height: 14),
                      _buildDarkHeroCard(order),
                    ] else ...[
                      // 2. Dark Hero Card (Status-dependent)
                      _buildDarkHeroCard(order),
                      const SizedBox(height: 14),

                      // 3. 5-Stage Stepper Progress Widget (Locked progression via bottom CTA only)
                      RouteProgressWidget(
                        currentStageIndex: _currentStage,
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 4. Middle Dynamic Content Cards
                    ..._buildStageMiddleContent(order),
                    const SizedBox(height: 18),

                    // 5. Bottom Action Buttons
                    _buildBottomActionButtons(order),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 1. Top Order Card ---
  Widget _buildTopOrderCard(DeliveryOrder order) {
    if (_currentStage == 4) {
      // Stage 5 Milestone Header
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORDER MILESTONE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ALL 5 COMPLETE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStage == 1) {
      // Stage 2 Header
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER #${order.id} • ${order.distanceKm} KM • ~${order.estimatedMinutes} MINS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Delivery Trip Payout',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₱${order.riderEarnings.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0284C7),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStage >= 2) {
      // Stage 3 & 4 Header
      final isTransit = _currentStage == 3;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER #${order.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTransit ? '1.8 km • ~8 mins' : '${order.distanceKm} km • ~${order.estimatedMinutes} mins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'DELIVERY TRIP PAYOUT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${order.riderEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00C4FF),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Stage 1 Header
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ORDER #${order.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'STANDARD COURIER',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.distanceKm} km • ~${order.estimatedMinutes} mins',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          const Text(
            'DELIVERY TRIP PAYOUT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '₱${order.riderEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00C4FF),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined, size: 14, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Text(
                      'Guaranteed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Dark Hero Card ---
  Widget _buildDarkHeroCard(DeliveryOrder order) {
    if (_currentStage == 0) {
      // Stage 1: En Route to Store Navigation Bar (Dynamic height, Web text-scaling safe)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B192C),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B192C).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.turn_slight_right_rounded,
                color: Color(0xFF00C4FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In 350m, arrive at ${order.merchantName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF38BDF8)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Pickup Point: Main Mall Ground Entrance',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchNavigationToMerchant(order),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Color(0xFF38BDF8), size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStage == 1) {
      // Stage 2: GPS Arrival Confirmed & Handover PIN Card
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B192C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF00C4FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GPS ARRIVAL CONFIRMED • Loading Bay #2',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Arrived at ${order.merchantName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Handover Code Verification Box (Ask attendant or show rider badge QR)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _handoverCodeVerified
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _handoverCodeVerified ? Icons.check_circle_rounded : Icons.vpn_key_rounded,
                              size: 13,
                              color: _handoverCodeVerified ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _handoverCodeVerified
                                    ? 'HANDOVER CODE VERIFIED'
                                    : 'ASK ATTENDANT FOR HANDOVER CODE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: _handoverCodeVerified ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: _showRiderPickupQrModal,
                        icon: const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF00C4FF)),
                        label: const Text(
                          'Show My QR',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00C4FF)),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_handoverCodeVerified) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF34D399)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Code Authenticated: ${_handoverCodeController.text.isNotEmpty ? _handoverCodeController.text : "NX-8942-S"} (Marco R.)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF34D399),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _handoverCodeController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter code from Marco R. (e.g. NX-8942-S)',
                                hintStyle: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  letterSpacing: 0,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF00C4FF), width: 1.5),
                                ),
                              ),
                              onSubmitted: _validateHandoverCode,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            onPressed: () => _validateHandoverCode(_handoverCodeController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C4FF),
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Verify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callPhone(order.merchantPhone, order.merchantName),
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call Merchant'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reportDelay,
                    icon: const Icon(Icons.access_time_rounded, size: 15),
                    label: const Text('Report Delay'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_currentStage == 2) {
      // Stage 3: Handoff Complete & Verified Card
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0B192C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HANDOFF COMPLETE • LOADING BAY #2',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF38BDF8),
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Handoff Verified & Inspected',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.archive_outlined, color: Color(0xFF00C4FF), size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MERCHANT HANDOVER CODE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'NX-8942-S',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF00C4FF)),
                      SizedBox(width: 4),
                      Text(
                        'ACCEPTED BY MERCHANT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00C4FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: Color(0xFF00C4FF)),
                    SizedBox(width: 4),
                    Text(
                      'Authorized Staff: Marco R.',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  'Counter Desk 02',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_currentStage == 3) {
      // Stage 4: Live Interactive Navigation Map with Real Speed & GNSS Positioning
      return RiderLiveNavigationMap(
        destinationLat: order.customerLat,
        destinationLng: order.customerLng,
        destinationAddress: order.customerAddress,
        customerName: order.customerName,
        orderId: order.id,
      );
    }

    // Stage 5: Delivery Completed! Card
    final balance = RiderService.instance.profile.walletBalance;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B192C),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C4FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00C4FF), size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF00C4FF)),
                    SizedBox(width: 5),
                    Text(
                      'PAYOUT SETTLED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF00C4FF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Delivery Completed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${_getFormattedCompletionTime()} • Handed to ${order.customerName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payout Balance Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CREDITED TO EARNINGS',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '+₱${order.riderEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF00C4FF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'NEW WALLET BALANCE',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₱${balance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Stage Middle Content Cards ---
  List<Widget> _buildStageMiddleContent(DeliveryOrder order) {
    switch (_currentStage) {
      case 0:
        return _buildStage1Content(order);
      case 1:
        return _buildStage2Content(order);
      case 2:
        return _buildStage3Content(order);
      case 3:
        return _buildStage4Content(order);
      case 4:
      default:
        return _buildStage5Content(order);
    }
  }

  // Stage 1 Content (Headed to Store)
  List<Widget> _buildStage1Content(DeliveryOrder order) {
    return [
      // Store Pickup Details Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('STORE PICKUP',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('● Prepaid',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.merchantName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.merchantAddress,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callPhone(order.merchantPhone, order.merchantName),
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call Store'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(order.merchantName, isMerchant: true),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Package Manifest Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 6),
                    Text(
                      'PACKAGE MANIFEST',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('2 Parcels',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildManifestItem(
              isScanned: _pkg1Scanned,
              title: 'Parcel #NX8942-A',
              desc: 'Medium Sealed Box • Verified Security Seal',
              tag: 'SEALED',
              tagColor: const Color(0xFFFEE2E2),
              tagTextColor: const Color(0xFFDC2626),
              onScanTap: () => _showBarcodeScannerModal(
                'Parcel #NX8942-A',
                'Medium Sealed Box • Verified Security Seal',
                '480651239842',
              ),
            ),
            const SizedBox(height: 10),
            _buildManifestItem(
              isScanned: _pkg2Scanned,
              title: 'Parcel #NX8942-B',
              desc: 'Express Courier Pouch • Fragile Handle with Care',
              tag: 'EXPRESS',
              tagColor: const Color(0xFFDCFCE7),
              tagTextColor: const Color(0xFF047857),
              onScanTap: () => _showBarcodeScannerModal(
                'Parcel #NX8942-B',
                'Express Courier Pouch • Fragile Handle with Care',
                '480651239843',
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // Stage 2 Content (At Store - Scanning)
  List<Widget> _buildStage2Content(DeliveryOrder order) {
    final scannedCount = (_pkg1Scanned ? 1 : 0) + (_pkg2Scanned ? 1 : 0);

    return [
      // Store Location & Staff Info Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.merchantName,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text(order.merchantAddress,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Staff Counter Desk 02',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Attendant: Marco R.',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Packages for Pickup (2 Total)
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Packages for Pickup (2 Total)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scannedCount == 2 ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$scannedCount/2 verified',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: scannedCount == 2 ? const Color(0xFF047857) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _pkg1Scanned = true;
                          _pkg2Scanned = true;
                          DeliveryService.instance.updateActiveOrderScanProgress(
                            pkg1: true,
                            pkg2: true,
                          );
                        });
                      },
                      child: const Text('Verify All',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Scan Barcode CTA
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => _showBarcodeScannerModal(
                  'MASTER-DISPATCH-NX8942',
                  'Store Master Dispatch Sheet • 2 Parcels',
                  '480651239840',
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                label: const Text('Scan Store Dispatch Barcode',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F9FF),
                  foregroundColor: const Color(0xFF0284C7),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Package 1
            _buildPickupScanTile(
              pkgId: 'NX-PKG-8942-01',
              badge: 'FRAGILE',
              desc: 'Sealed Box • 0.65 kg',
              isScanned: _pkg1Scanned,
              onScanTap: () => _showBarcodeScannerModal(
                'NX-PKG-8942-01',
                'Sealed Box • 0.65 kg • Fragile Handling',
                '480651239842',
              ),
            ),
            const SizedBox(height: 10),

            // Package 2
            _buildPickupScanTile(
              pkgId: 'NX-PKG-8942-02',
              badge: 'STANDARD',
              desc: 'Standard Pouch • 0.40 kg',
              isScanned: _pkg2Scanned,
              onScanTap: () => _showBarcodeScannerModal(
                'NX-PKG-8942-02',
                'Standard Courier Pouch • 0.40 kg',
                '480651239843',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Inspection & Protocol Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0284C7)),
                SizedBox(width: 6),
                Text(
                  'Inspection & Protocol',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildProtocolCheckbox(
              value: _tamperSealChecked,
              text: 'Tamper-evident seals intact & undamaged',
              onChanged: (v) {
                setState(() => _tamperSealChecked = v ?? true);
                DeliveryService.instance.updateActiveOrderScanProgress(
                  tamperSealChecked: v ?? true,
                );
              },
            ),
            const SizedBox(height: 8),
            _buildProtocolCheckbox(
              value: _fragileSecuredChecked,
              text: 'Fragile parcel placed securely in padded top box',
              onChanged: (v) {
                setState(() => _fragileSecuredChecked = v ?? true);
                DeliveryService.instance.updateActiveOrderScanProgress(
                  fragileSecuredChecked: v ?? true,
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  // Stage 3 Content (Pickup Verified)
  List<Widget> _buildStage3Content(DeliveryOrder order) {
    return [
      // Confidential Manifest Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidential Manifest',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Row(
                  children: [
                    Text('2/2 Verified',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    SizedBox(width: 8),
                    Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF00C4FF)),
                    SizedBox(width: 4),
                    Text('All Scanned',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00C4FF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item 1
            _buildVerifiedStowTile(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF0284C7),
              pkgId: 'NX-PKG-8942-01',
              tag: 'FRAGILE',
              desc: 'Sealed Box • 0.65 kg',
              stowLocation: 'Stowed in Top Box',
              bayText: 'BAY #2B',
            ),
            const SizedBox(height: 10),

            // Item 2
            _buildVerifiedStowTile(
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF00C4FF),
              pkgId: 'NX-PKG-8942-02',
              tag: 'STANDARD',
              desc: 'Express Pouch • 0.40 kg',
              stowLocation: 'Stowed in Motorcycle Carrier',
              bayText: 'TOP BOX',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Security & Dispatch Checklist
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SECURITY & DISPATCH CHECKLIST',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.6),
                ),
                Row(
                  children: [
                    Icon(Icons.check_rounded, size: 14, color: Color(0xFF00C4FF)),
                    SizedBox(width: 4),
                    Text('All Cleared',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00C4FF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStaticCheckRow('Tamper-evident seal intact and scanned'),
            const SizedBox(height: 8),
            _buildStaticCheckRow('Fragile cargo safely secured in insulated top-box'),
            const SizedBox(height: 8),
            _buildStaticCheckRow('Merchant digital signature logged'),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Next Destination Preview Card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.navigation_rounded, color: Color(0xFF0284C7), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXT DESTINATION',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                  Text(
                    order.customerAddress,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
      const SizedBox(height: 10),

      // Guaranteed Payout Row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Trip Guaranteed Payout',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          RichText(
            text: TextSpan(
              text: '₱${order.riderEarnings.toStringAsFixed(2)} ',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              children: const [
                TextSpan(
                  text: '+₱25 Bonus applied',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF00C4FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  // Stage 4 Content (In Transit)
  List<Widget> _buildStage4Content(DeliveryOrder order) {
    return [
      // 2 Secured Parcels Stowed Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.archive_outlined, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '2 Secured Parcels Stowed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Color(0xFF0284C7)),
                      SizedBox(width: 4),
                      Text('Secured',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTransitParcelTile(
              icon: Icons.inventory_2_outlined,
              pkgId: 'NX-PKG-8942-01',
              subtitle: '! FRAGILE Sealed Box',
              vault: 'Vault A',
            ),
            const SizedBox(height: 8),
            _buildTransitParcelTile(
              icon: Icons.mail_outline_rounded,
              pkgId: 'NX-PKG-8942-02',
              subtitle: 'STANDARD Express Pouch',
              vault: 'Vault B',
            ),
            const SizedBox(height: 8),
            const Text(
              '🛡️ Client confidentiality protocol active • Tamper seals intact',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Buyer Precise Pinpoint & Doorstep Location Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pin_drop_rounded, size: 15, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'BUYER PINPOINT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, size: 11, color: Color(0xFF047857)),
                      SizedBox(width: 4),
                      Text(
                        'Accurate GPS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.customerAddress,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Target Coordinates: ${order.customerLat.toStringAsFixed(5)}° N, ${order.customerLng.toStringAsFixed(5)}° E',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Recipient Details Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE0F2FE),
                  child: const Text('JD',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECIPIENT',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                      Text(order.customerName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ESTIMATED ARRIVAL',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                    Text('8 mins',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF00C4FF))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF0284C7)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _maskPhoneNumber(order.customerPhone),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MASKED',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('1.8 km remaining',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Customer Note
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: Color(0xFF0284C7)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Customer Note: "Drop at Guard House / Lobby Reception if unavailable. Contact upon arrival."',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0369A1), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callPhone(order.customerPhone, order.customerName),
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedBuilder(
                    animation: RiderChatService.instance,
                    builder: (context, _) {
                      final unread = RiderChatService.instance.getUnreadCount(order.id);
                      return ElevatedButton.icon(
                        onPressed: () => _openChat(order.customerName),
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          label: Text('$unread', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFFEF4444),
                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                        ),
                        label: Text(unread > 0 ? 'Chat Customer ($unread)' : 'Chat Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: unread > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          foregroundColor: unread > 0 ? RiderTheme.primary : const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            child: Text(
              'Trip Payout upon confirmation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₱${order.riderEarnings.toStringAsFixed(2)} Total',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    ];
  }

  // Stage 5 Content (Delivered / Completed)
  List<Widget> _buildStage5Content(DeliveryOrder order) {
    return [
      // Delivery Manifest Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Delivery Manifest',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('2 / 2 Packages',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NX-PKG-8942-01', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Sealed • 1.2 kg', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NX-PKG-8942-02', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Fragile • 0.8 kg', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Digital Sign-off & POD Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.draw_rounded, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Digital Sign-off & POD',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Verified',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        if (_capturedPodPhotoPath != null && _capturedPodPhotoPath!.isNotEmpty)
                          (_capturedPodPhotoPath!.startsWith('http') || _capturedPodPhotoPath!.startsWith('assets'))
                              ? Image.asset(
                                  _capturedPodPhotoPath!,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 52,
                                    height: 52,
                                    color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                                    child: const Icon(Icons.photo_camera_rounded, color: Color(0xFF0066FF), size: 24),
                                  ),
                                )
                              : Image.file(
                                  File(_capturedPodPhotoPath!),
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 52,
                                    height: 52,
                                    color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                                    child: const Icon(Icons.photo_camera_rounded, color: Color(0xFF0066FF), size: 24),
                                  ),
                                )
                        else
                          Image.asset(
                            'assets/images/pod_concierge.jpg',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 52,
                              height: 52,
                              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                              child: const Icon(Icons.photo_camera_rounded, color: Color(0xFF0284C7), size: 24),
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.all(3),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pin_drop_rounded, size: 8, color: Color(0xFF38BDF8)),
                              SizedBox(width: 2),
                              Text(
                                'GPS',
                                style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tower 2 Concierge Desk',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Signature on file: J. Dela Cruz',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DISTANCE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        SizedBox(height: 2),
                        Text('1.8 km total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DURATION', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF0284C7))),
                        SizedBox(height: 2),
                        Text('28 mins (On-Time)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.satellite_alt_rounded, size: 11, color: Color(0xFF94A3B8)),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Cryptographic Geotag • GPS: 14.5492° N, 121.0479° E (±3m)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Customer Rating & Review Card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.person, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              order.customerName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('★★★★★',
                              style: TextStyle(fontSize: 12, color: Color(0xFFFBBF24))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('"Fast & careful handling, highly recommended!"',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('5.0',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You achieved a 100% on-time score for this fulfillment cycle.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // --- 4. Bottom Action Buttons ---
  Widget _buildBottomActionButtons(DeliveryOrder order) {
    if (_currentStage == 4) {
      // Stage 5 Dual Actions
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (DeliveryService.instance.activeOrder != null) {
                  DeliveryService.instance.completeCurrentDelivery();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4FF),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'FIND NEXT DELIVERY TASK',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const EarningsScreen()),
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
              label: const Text(
                'VIEW EARNINGS & WALLET',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                side: const BorderSide(color: Color(0xFF00C4FF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    // Stage 0: En Route to Store (Distance: 350m)
    // Avoids status contradiction: Primary CTA navigates to store, secondary allows physical arrival confirmation
    if (_currentStage == 0) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _launchNavigationToMerchant(order),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text(
                'NAVIGATE TO STORE (GOOGLE MAPS)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.3),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4FF),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _confirmArrivalAtStore(order),
              icon: const Icon(Icons.storefront_rounded, size: 18),
              label: const Text(
                'I HAVE ARRIVED AT STORE',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.2),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0284C7),
                side: const BorderSide(color: Color(0xFF00C4FF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pasig Hub Dispatch hotline connected: (02) 8888-RIDE')),
                );
              },
              child: const Text(
                'Cannot find store or parking? Contact Dispatch',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      );
    }

    final scannedCount = (_pkg1Scanned ? 1 : 0) + (_pkg2Scanned ? 1 : 0);
    String btnText;
    IconData? prefixIcon;
    IconData? suffixIcon;
    String subLinkText;
    VoidCallback onCtaPressed = _nextStage;

    if (_currentStage == 1) {
      if (scannedCount < 2) {
        btnText = 'START SCANNING PARCELS ($scannedCount/2)';
        prefixIcon = Icons.qr_code_scanner_rounded;
        suffixIcon = null;
        subLinkText = 'Cannot verify packages? Contact Dispatch';
        onCtaPressed = () {
          if (!_pkg1Scanned) {
            _showBarcodeScannerModal(
              'Parcel #NX8942-A',
              'Medium Sealed Box • Verified Security Seal',
              '480651239842',
            );
          } else if (!_pkg2Scanned) {
            _showBarcodeScannerModal(
              'Parcel #NX8942-B',
              'Express Courier Pouch • Fragile Handle with Care',
              '480651239843',
            );
          }
        };
      } else {
        btnText = 'CONFIRM PICKUP & PROCEED';
        prefixIcon = Icons.check_circle_rounded;
        suffixIcon = Icons.arrow_forward_rounded;
        subLinkText = 'All 2 parcels verified • Ready for vehicle stowage';
        onCtaPressed = _nextStage;
      }
    } else if (_currentStage == 2) {
      btnText = 'START DELIVERY TO CUSTOMER';
      prefixIcon = Icons.local_shipping_rounded;
      suffixIcon = Icons.arrow_forward_rounded;
      subLinkText = '⚠️ Report Dispatch Discrepancy';
    } else if (!_handoverCodeVerified) {
      btnText = 'I HAVE ARRIVED AT DROPOFF';
      prefixIcon = Icons.location_on_rounded;
      suffixIcon = Icons.check_circle_outline_rounded;
      subLinkText = '🎧 Need assistance? Contact Dispatch';
      onCtaPressed = () {
        setState(() {
          _handoverCodeVerified = true;
          DeliveryService.instance.updateActiveOrderScanProgress(
            handoverVerified: true,
          );
          DeliveryService.instance.updateActiveOrderStage(3);
          RiderLocationService.instance.updateOrderStatus('in_transit');
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrived at customer dropoff! Tap Complete Delivery after handing over the parcel.'),
            backgroundColor: Color(0xFF0284C7),
          ),
        );
      };
    } else {
      btnText = 'SNAP POD PHOTO & COMPLETE DELIVERY';
      prefixIcon = Icons.camera_alt_rounded;
      suffixIcon = Icons.arrow_forward_rounded;
      subLinkText = '📸 Mandatory: Capture package at drop-off';
      onCtaPressed = () => _showMandatoryPodCameraModal(order);
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onCtaPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C4FF),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(prefixIcon, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    btnText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (suffixIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(suffixIcon, size: 18),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pasig Hub Dispatch hotline connected: (02) 8888-RIDE')),
              );
            },
            child: Text(
              subLinkText,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // --- Sub-widgets for manifests and scans ---
  Widget _buildManifestItem({
    required bool isScanned,
    required String title,
    required String desc,
    required String tag,
    required Color tagColor,
    required Color tagTextColor,
    required VoidCallback onScanTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isScanned ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isScanned ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Barcode / Camera Scan Action Button replacing simple checkbox
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onScanTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isScanned
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isScanned
                        ? const Color(0xFF059669)
                        : const Color(0xFF0284C7).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  isScanned ? Icons.check_rounded : Icons.qr_code_scanner_rounded,
                  size: 17,
                  color: isScanned ? Colors.white : const Color(0xFF0284C7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(6)),
                      child: Text(tag,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: tagTextColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Verification badge button
          InkWell(
            onTap: onScanTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isScanned ? const Color(0xFFDCFCE7) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isScanned ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isScanned ? Icons.verified_rounded : Icons.camera_alt_outlined,
                    size: 12,
                    color: isScanned ? const Color(0xFF047857) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isScanned ? 'VERIFIED' : 'SCAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isScanned ? const Color(0xFF047857) : const Color(0xFF0284C7),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupScanTile({
    required String pkgId,
    required String badge,
    required String desc,
    required bool isScanned,
    required VoidCallback onScanTap,
  }) {
    final isFragile = badge == 'FRAGILE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isScanned ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isScanned ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isScanned ? const Color(0xFF059669) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isScanned ? const Color(0xFF059669) : const Color(0xFFCBD5E1)),
              ),
              child: isScanned
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pkgId,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isFragile ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isFragile ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onScanTap,
            icon: Icon(isScanned ? Icons.check : Icons.qr_code_scanner_rounded, size: 13),
            label: Text(isScanned ? 'Verified' : 'Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isScanned ? const Color(0xFFDCFCE7) : Colors.white,
              foregroundColor: isScanned ? const Color(0xFF047857) : const Color(0xFF0284C7),
              elevation: 0,
              side: BorderSide(color: isScanned ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCheckbox({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF0284C7),
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedStowTile({
    required IconData icon,
    required Color iconColor,
    required String pkgId,
    required String tag,
    required String desc,
    required String stowLocation,
    required String bayText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(pkgId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                        ),
                      ],
                    ),
                    Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00C4FF), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.archive_outlined, size: 13, color: Color(0xFF0284C7)),
                    const SizedBox(width: 5),
                    Text(stowLocation,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                  ],
                ),
                Text(bayText,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticCheckRow(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_box_rounded, size: 18, color: Color(0xFF00C4FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitParcelTile({
    required IconData icon,
    required String pkgId,
    required String subtitle,
    required String vault,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0284C7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkgId, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: subtitle.contains('FRAGILE') ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(vault,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
