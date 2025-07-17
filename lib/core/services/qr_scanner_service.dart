import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/services/qr_code_service.dart';
import 'package:jhonny/core/theme/app_theme.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';

class QrScannerService {
  static const Duration _scanCooldown = Duration(seconds: 2);
  DateTime? _lastScanTime;

  /// Simple permission check
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      print('Current camera permission status: $status');

      if (status.isGranted) {
        print('Camera permission already granted');
        return true;
      }

      if (status.isDenied) {
        print('Camera permission denied, requesting...');
        final result = await Permission.camera.request();
        print('Permission request result: $result');
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        print('Camera permission permanently denied');
        return false;
      }

      // For any other status, try requesting
      print('Unknown permission status, trying to request...');
      final result = await Permission.camera.request();
      print('Permission request result: $result');
      return result.isGranted;
    } catch (e) {
      print('Error checking camera permission: $e');
      return false;
    }
  }

  /// Validates scanned QR code and returns child invitation data
  QrScanResult processScannedData(String scannedData) {
    // Implement scan cooldown to prevent multiple rapid scans
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < _scanCooldown) {
      return QrScanResult.cooldown();
    }

    _lastScanTime = now;

    // Try to parse as child invitation QR code
    final childInviteData = QrCodeService.parseChildInviteQrData(scannedData);

    if (childInviteData != null) {
      // Check if QR code is expired
      if (childInviteData.isExpired()) {
        return QrScanResult.expired(childInviteData);
      }

      return QrScanResult.success(childInviteData);
    }

    // Not a valid child invitation QR code
    return QrScanResult.invalid(scannedData);
  }

  /// Creates a simple QR scanner widget
  static Widget buildQrScanner({
    required Function(QrScanResult) onScan,
    Widget? overlay,
  }) {
    return SimpleQrScannerWidget(
      onScan: onScan,
      overlay: overlay,
    );
  }
}

/// Simplified QR scanner widget
class SimpleQrScannerWidget extends StatefulWidget {
  final Function(QrScanResult) onScan;
  final Widget? overlay;

  const SimpleQrScannerWidget({
    super.key,
    required this.onScan,
    this.overlay,
  });

  @override
  State<SimpleQrScannerWidget> createState() => _SimpleQrScannerWidgetState();
}

class _SimpleQrScannerWidgetState extends State<SimpleQrScannerWidget> {
  final QrScannerService _scannerService = QrScannerService();
  MobileScannerController? _controller;
  bool _hasPermission = false;
  bool _isProcessing = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      print('Starting scanner initialization...');

      // Always try to initialize camera directly since permission might work even if check fails
      _controller = MobileScannerController(
        formats: [BarcodeFormat.qrCode],
        facing: CameraFacing.back,
      );

      // Assume permission granted if controller creation succeeds
      setState(() {
        _hasPermission = true;
        _isInitializing = false;
      });

      print('Scanner initialization complete. Camera ready.');
    } catch (e) {
      print('Error initializing scanner: $e');
      setState(() {
        _hasPermission = false;
        _isInitializing = false;
      });
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;

    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    final result = _scannerService.processScannedData(code);
    widget.onScan(result);

    // Reset processing state after a delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionDeniedView();
    }

    if (_controller == null) {
      return const Center(
        child: Text('Camera initialization failed'),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MobileScanner(
            controller: _controller!,
            onDetect: _onBarcodeDetected,
          ),
        ),
        // Scanning overlay
        widget.overlay ?? _buildDefaultOverlay(),
        // Processing overlay
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Camera Permission Required',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To scan QR codes for child signup, please enable camera access in your device settings.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    EnhancedButton(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      type: EnhancedButtonType.primary,
                      isExpanded: true,
                      child: const Text('Open Settings'),
                    ),
                    const SizedBox(height: 12),
                    EnhancedButton(
                      onPressed: _initializeScanner,
                      type: EnhancedButtonType.ghost,
                      isExpanded: true,
                      child: const Text('Try Again'),
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

  Widget _buildDefaultOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Semi-transparent overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.accent,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point your camera at the QR code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppTheme.accent,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Processing QR Code...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScanResult {
  final QrScanStatus status;
  final ChildInviteQrData? childInviteData;
  final String? rawData;
  final String? errorMessage;

  const QrScanResult({
    required this.status,
    this.childInviteData,
    this.rawData,
    this.errorMessage,
  });

  factory QrScanResult.success(ChildInviteQrData data) {
    return QrScanResult(
      status: QrScanStatus.success,
      childInviteData: data,
    );
  }

  factory QrScanResult.invalid(String rawData) {
    return QrScanResult(
      status: QrScanStatus.invalid,
      rawData: rawData,
      errorMessage: 'This QR code is not a valid family invitation',
    );
  }

  factory QrScanResult.expired(ChildInviteQrData data) {
    return QrScanResult(
      status: QrScanStatus.expired,
      childInviteData: data,
      errorMessage: 'This invitation has expired',
    );
  }

  factory QrScanResult.cooldown() {
    return const QrScanResult(
      status: QrScanStatus.cooldown,
      errorMessage: 'Please wait before scanning again',
    );
  }

  factory QrScanResult.error(String message) {
    return QrScanResult(
      status: QrScanStatus.error,
      errorMessage: message,
    );
  }

  bool get isSuccess => status == QrScanStatus.success;
  bool get hasError =>
      status != QrScanStatus.success && status != QrScanStatus.cooldown;
}

/// Status of QR code scan result
enum QrScanStatus {
  success,
  invalid,
  expired,
  cooldown,
  error,
}

/// Simple overlay for QR scanner
class ChildInviteQrOverlay extends StatelessWidget {
  final String? instruction;
  final Color? borderColor;

  const ChildInviteQrOverlay({
    super.key,
    this.instruction,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay
        Container(
          color: Colors.black.withOpacity(0.5),
        ),

        // Scanning frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor ?? AppTheme.accent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Instruction text
        if (instruction != null)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                instruction!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
