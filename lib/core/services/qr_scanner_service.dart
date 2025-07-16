import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:jhonny/core/services/qr_code_service.dart';

class QrScannerService {
  static const Duration _scanCooldown = Duration(seconds: 2);
  DateTime? _lastScanTime;

  /// Checks and requests camera permission
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    return false;
  }

  /// Shows a dialog to explain why camera permission is needed
  static Future<bool> showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
          'Camera access is needed to scan QR codes for adding children to your family. '
          'This allows kids to join without needing email accounts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Opens device settings for manual permission grant
  static Future<void> openAppSettings() async {
    await openAppSettings();
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

  /// Creates a QR scanner widget with proper error handling
  static Widget buildQrScanner({
    required Function(QrScanResult) onScan,
    Widget? overlay,
    bool allowDuplicates = false,
  }) {
    return QrScannerWidget(
      onScan: onScan,
      overlay: overlay,
      allowDuplicates: allowDuplicates,
    );
  }
}

/// Widget for QR code scanning with built-in error handling
class QrScannerWidget extends StatefulWidget {
  final Function(QrScanResult) onScan;
  final Widget? overlay;
  final bool allowDuplicates;

  const QrScannerWidget({
    super.key,
    required this.onScan,
    this.overlay,
    this.allowDuplicates = false,
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  QRViewController? _controller;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  final QrScannerService _scannerService = QrScannerService();
  bool _hasPermission = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await QrScannerService.checkCameraPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (_isProcessing || scanData.code == null) return;

      setState(() {
        _isProcessing = true;
      });

      final result = _scannerService.processScannedData(scanData.code!);
      widget.onScan(result);

      // Reset processing state after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _buildPermissionView();
    }

    return Stack(
      children: [
        QRView(
          key: _qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: _buildDefaultOverlay(),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera Permission Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please allow camera access to scan QR codes for adding children to your family.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final granted =
                      await QrScannerService.showPermissionDialog(context);
                  if (granted) {
                    _checkPermission();
                  }
                },
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  QrScannerOverlayShape _buildDefaultOverlay() {
    return QrScannerOverlayShape(
      borderColor: Colors.blue,
      borderRadius: 12,
      borderLength: 30,
      borderWidth: 5,
      cutOutSize: 250,
      overlayColor: Colors.black54,
    );
  }
}

/// Result of QR code scanning with different states
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

/// Custom overlay for QR scanner with instructions
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
        // Instruction text
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              instruction ?? 'Scan the QR code to add a child to your family',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Bottom tip
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white70,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Hold steady and keep QR code in frame',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
