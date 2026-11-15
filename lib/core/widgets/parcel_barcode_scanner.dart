import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/rider_theme.dart';

enum ParcelScanMode {
  riderPickup,
  manifestLoading,
  parcelLookup,
}

class ParcelScanSubmissionResult {
  final bool success;
  final String message;
  final String? progressText;
  final bool keepScanning;

  const ParcelScanSubmissionResult({
    required this.success,
    required this.message,
    this.progressText,
    this.keepScanning = false,
  });
}

/// Reusable camera barcode scanner shared across Rider pickup,
/// Transfer Courier manifest loading, and Hub parcel lookup.
///
/// Never assumes a scan is valid locally: every decoded or manually entered
/// barcode must pass [onBarcodeSubmitted] backend validation before success
/// feedback is shown.
class ParcelBarcodeScanner extends StatefulWidget {
  final ParcelScanMode mode;
  final String title;
  final String subtitle;
  final String? expectedTrackingNumber;
  final String? initialProgressText;
  final bool continuousScan;
  final Future<ParcelScanSubmissionResult> Function(String trackingNumber)
      onBarcodeSubmitted;

  /// Optional test hook allowing widget tests to simulate decoded barcodes
  /// or camera errors without hardware camera plugins.
  final Widget Function(
    BuildContext context,
    void Function(String rawCode) emitBarcode,
  )? scannerPreviewOverride;

  const ParcelBarcodeScanner({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.onBarcodeSubmitted,
    this.expectedTrackingNumber,
    this.initialProgressText,
    this.continuousScan = false,
    this.scannerPreviewOverride,
  });

  static Future<bool?> open(
    BuildContext context, {
    required ParcelScanMode mode,
    required String title,
    required String subtitle,
    required Future<ParcelScanSubmissionResult> Function(String trackingNumber)
        onBarcodeSubmitted,
    String? expectedTrackingNumber,
    String? initialProgressText,
    bool continuousScan = false,
    Widget Function(
      BuildContext context,
      void Function(String rawCode) emitBarcode,
    )? scannerPreviewOverride,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ParcelBarcodeScanner(
          mode: mode,
          title: title,
          subtitle: subtitle,
          expectedTrackingNumber: expectedTrackingNumber,
          initialProgressText: initialProgressText,
          continuousScan: continuousScan,
          onBarcodeSubmitted: onBarcodeSubmitted,
          scannerPreviewOverride: scannerPreviewOverride,
        ),
      ),
    );
  }

  /// Normalize scanned/manual barcode identifiers consistently with Laravel.
  static String normalizeTrackingNumber(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
  }

  @override
  State<ParcelBarcodeScanner> createState() => _ParcelBarcodeScannerState();
}

class _ParcelBarcodeScannerState extends State<ParcelBarcodeScanner>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocusNode = FocusNode();

  bool _isProcessing = false;
  bool _hasCompletedAnyScan = false;
  bool _isSuccessBanner = false;
  bool _isErrorBanner = false;
  bool _detectionPaused = false;
  String? _statusMessage;
  String? _progressText;
  String? _lastSubmittedCode;
  DateTime? _lastSubmittedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressText = widget.initialProgressText;

    if (widget.scannerPreviewOverride == null) {
      _controller = MobileScannerController(
        autoStart: true,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [
          BarcodeFormat.code128,
          BarcodeFormat.qrCode,
          BarcodeFormat.code39,
        ],
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_detectionPaused) {
          controller.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _manualController.dispose();
    _manualFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleDetectedRawCode(String raw) async {
    final normalized = ParcelBarcodeScanner.normalizeTrackingNumber(raw);
    if (normalized.isEmpty) return;

    if (_isProcessing || _detectionPaused) {
      return;
    }

    // Prevent rapid duplicate submissions of the same frame within 2.5s
    if (_lastSubmittedCode == normalized &&
        _lastSubmittedAt != null &&
        DateTime.now().difference(_lastSubmittedAt!).inMilliseconds < 2500) {
      return;
    }

    await _submitTrackingNumber(normalized, fromCamera: true);
  }

  Future<void> _submitTrackingNumber(
    String rawInput, {
    required bool fromCamera,
  }) async {
    final normalized = ParcelBarcodeScanner.normalizeTrackingNumber(rawInput);
    if (normalized.isEmpty) {
      setState(() {
        _isErrorBanner = true;
        _isSuccessBanner = false;
        _statusMessage = 'Please enter or scan a valid tracking number.';
      });
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _detectionPaused = true;
      _isSuccessBanner = false;
      _isErrorBanner = false;
      _statusMessage = 'Verifying $normalized with server...';
      _lastSubmittedCode = normalized;
      _lastSubmittedAt = DateTime.now();
    });

    try {
      await _controller?.stop();
    } catch (_) {}

    try {
      final result = await widget.onBarcodeSubmitted(normalized);
      if (!mounted) return;

      if (result.success) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isProcessing = false;
          _hasCompletedAnyScan = true;
          _isSuccessBanner = true;
          _isErrorBanner = false;
          _statusMessage = result.message;
          if (result.progressText != null) {
            _progressText = result.progressText;
          }
          _manualController.clear();
        });

        if (widget.continuousScan && result.keepScanning) {
          // Brief confirmation pause before resuming camera for next parcel
          await Future.delayed(const Duration(milliseconds: 900));
          if (mounted) {
            await _resumeScanning();
          }
        } else {
          await Future.delayed(const Duration(milliseconds: 650));
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _isProcessing = false;
          _detectionPaused = true;
          _isSuccessBanner = false;
          _isErrorBanner = true;
          _statusMessage = result.message;
          if (result.progressText != null) {
            _progressText = result.progressText;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isProcessing = false;
        _detectionPaused = true;
        _isSuccessBanner = false;
        _isErrorBanner = true;
        _statusMessage = e.toString();
      });
    }
  }

  Future<void> _resumeScanning() async {
    if (!mounted) return;
    setState(() {
      _detectionPaused = false;
      _isErrorBanner = false;
      if (!_isSuccessBanner) {
        _statusMessage = null;
      }
    });
    try {
      await _controller?.start();
    } catch (_) {}
  }

  String _modeBadgeLabel() {
    switch (widget.mode) {
      case ParcelScanMode.riderPickup:
        return 'RIDER PICKUP SCAN';
      case ParcelScanMode.manifestLoading:
        return 'MANIFEST LOADING SCAN';
      case ParcelScanMode.parcelLookup:
        return 'PARCEL VERIFICATION SCAN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final frameColor = _isSuccessBanner
        ? RiderTheme.onlineGreen
        : (_isErrorBanner ? RiderTheme.errorRed : RiderTheme.primary);

    return Scaffold(
      backgroundColor: const Color(0xFF050B28),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close scanner',
                    onPressed: () =>
                        Navigator.of(context).pop(_hasCompletedAnyScan),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: RiderTheme.primary.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _modeBadgeLabel(),
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_controller != null)
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller!,
                      builder: (context, state, _) {
                        final torchUnavailable =
                            state.torchState == TorchState.unavailable;
                        final torchOn = state.torchState == TorchState.on;
                        return IconButton(
                          tooltip: torchOn ? 'Turn off flashlight' : 'Flashlight',
                          onPressed: torchUnavailable
                              ? null
                              : () => _controller?.toggleTorch(),
                          icon: Icon(
                            torchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: torchUnavailable
                                ? Colors.white24
                                : (torchOn
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            if (_progressText != null && _progressText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LIVE PROGRESS',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _progressText!,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Camera Preview + Scanning Reticle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.scannerPreviewOverride != null)
                        widget.scannerPreviewOverride!(
                          context,
                          _handleDetectedRawCode,
                        )
                      else if (_controller != null)
                        MobileScanner(
                          controller: _controller!,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final raw = barcode.rawValue;
                              if (raw != null && raw.trim().isNotEmpty) {
                                _handleDetectedRawCode(raw);
                                break;
                              }
                            }
                          },
                          errorBuilder: (context, error) {
                            return _buildCameraUnavailableView(error);
                          },
                        ),

                      // Scanning Frame Overlay
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 270,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: frameColor,
                                width: 3,
                              ),
                              color: frameColor.withValues(alpha: 0.06),
                            ),
                            child: Center(
                              child: Container(
                                height: 2,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                color: frameColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (widget.expectedTrackingNumber != null &&
                          widget.expectedTrackingNumber!.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Expected Waybill: ${widget.expectedTrackingNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (_isProcessing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.65),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: RiderTheme.primary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Validating barcode with Nexora...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Feedback + Manual Entry Fallback
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccessBanner
                            ? const Color(0xFFDCFCE7)
                            : (_isErrorBanner
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFEFF6FF)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSuccessBanner
                              ? RiderTheme.onlineGreen
                              : (_isErrorBanner
                                  ? RiderTheme.errorRed
                                  : RiderTheme.primary),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccessBanner
                                ? Icons.check_circle_rounded
                                : (_isErrorBanner
                                    ? Icons.error_rounded
                                    : Icons.sync_rounded),
                            color: _isSuccessBanner
                                ? const Color(0xFF15803D)
                                : (_isErrorBanner
                                    ? const Color(0xFFB91C1C)
                                    : RiderTheme.primary),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _isSuccessBanner
                                    ? const Color(0xFF166534)
                                    : (_isErrorBanner
                                        ? const Color(0xFF991B1B)
                                        : const Color(0xFF1E3A8A)),
                              ),
                            ),
                          ),
                          if (_detectionPaused && !_isProcessing)
                            TextButton(
                              onPressed: _resumeScanning,
                              child: const Text(
                                'Retry Scan',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    const Text(
                      'Align the Code 128 waybill barcode inside the blue frame, or enter it manually below.',
                      style: TextStyle(
                        fontSize: 12,
                        color: RiderTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          focusNode: _manualFocusNode,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (val) =>
                              _submitTrackingNumber(val, fromCamera: false),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Manual fallback (e.g. NX-TRK-...)',
                            prefixIcon: const Icon(
                              Icons.keyboard_alt_outlined,
                              size: 20,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _submitTrackingNumber(
                                  _manualController.text,
                                  fromCamera: false,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RiderTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Verify',
                          style: TextStyle(fontWeight: FontWeight.w800),
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
    );
  }

  Widget _buildCameraUnavailableView(MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: const Color(0xFF0B132B),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              denied ? Icons.no_photography_rounded : Icons.videocam_off_rounded,
              color: const Color(0xFFF59E0B),
              size: 46,
            ),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'Camera Permission Required'
                  : 'Camera Unavailable on This Device',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              denied
                  ? 'Enable camera permission in device settings to scan waybills, or use manual tracking-number entry below.'
                  : 'Unable to start camera preview. Enter the tracking number manually below to verify with Nexora.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _manualFocusNode.requestFocus(),
              icon: const Icon(Icons.keyboard_rounded, size: 18),
              label: const Text('Enter Tracking Number Manually'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
