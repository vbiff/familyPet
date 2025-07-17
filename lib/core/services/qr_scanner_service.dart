import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/services/qr_code_service.dart';
import 'package:jhonny/core/theme/app_theme.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';

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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.mediumShadow,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(delay: 200.ms, duration: 300.ms)
                      .shimmer(delay: 500.ms, duration: 1500.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Camera Permission 📷',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 10),
                  Text(
                    'We need your camera to scan QR codes! This lets kids join families easily without needing email accounts. 🌟',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: EnhancedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          type: EnhancedButtonType.ghost,
                          foregroundColor: Colors.white,
                          size: EnhancedButtonSize.small,
                          child: const Text('Cancel'),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 300.ms)
                            .slideX(begin: -0.3, end: 0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: EnhancedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          size: EnhancedButtonSize.small,
                          child: const Text('Allow'),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 300.ms)
                            .slideX(begin: 0.3, end: 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return result ?? false;
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

class _QrScannerWidgetState extends State<QrScannerWidget>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  QRViewController? _controller;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  final QrScannerService _scannerService = QrScannerService();
  bool _hasPermission = false;
  bool _isProcessing = false;
  bool _isCheckingPermission = false;

  late AnimationController _pulseController;
  late AnimationController _scanlineController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scanlineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _pulseController.dispose();
    _scanlineController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isCheckingPermission) {
      print('App resumed, re-checking permission...');
      _checkPermission(); // Re-check permission when returning from settings
    }
  }

  Future<void> _checkPermission() async {
    if (_isCheckingPermission) {
      print('Permission check already in progress, skipping...');
      return;
    }

    _isCheckingPermission = true;
    print('Starting permission check...');

    try {
      var status = await Permission.camera.status;
      print('Camera permission status: $status');
      if (status.isGranted) {
        print('Permission already granted');
        setState(() => _hasPermission = true);
      } else if (status.isPermanentlyDenied) {
        print('Permission permanently denied');
        await _showOpenSettingsDialog();
      } else {
        print('Requesting permission...');
        final result = await Permission.camera.request();
        print('Permission request result: $result');
        if (result.isGranted) {
          setState(() => _hasPermission = true);
        } else if (result.isPermanentlyDenied) {
          print('Permission permanently denied after request');
          await _showOpenSettingsDialog();
        }
      }
    } finally {
      _isCheckingPermission = false;
    }
  }

  Future<void> _showOpenSettingsDialog() async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.orange, AppTheme.yellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.mediumShadow,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(delay: 200.ms, duration: 300.ms)
                      .shake(delay: 500.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Settings Help ⚙️',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Camera access was denied. Please enable it in your device settings to scan QR codes! 🔧',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: EnhancedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          type: EnhancedButtonType.ghost,
                          foregroundColor: Colors.white,
                          size: EnhancedButtonSize.small,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: EnhancedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.orange,
                          size: EnhancedButtonSize.small,
                          child: const Text('Settings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (openSettings == true) {
      print('Opening app settings...');
      await openAppSettings();
    }
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
          overlay: widget.overlay != null
              ? QrScannerOverlayShape(
                  borderColor: AppTheme.accent,
                  borderRadius: 12,
                  borderLength: 30,
                  borderWidth: 5,
                  cutOutSize: 250,
                  overlayColor: Colors.black54,
                )
              : _buildDefaultOverlay(),
        ),
        // Add colorful scanning animations
        _buildScanningAnimations(),
        // Add custom overlay on top if provided
        if (widget.overlay != null) widget.overlay!,
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildPermissionView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 150,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated camera icon - more compact
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .scale(
                        delay: 200.ms,
                        duration: 600.ms,
                        curve: AppTheme.bounceIn)
                    .shimmer(delay: 800.ms, duration: 2000.ms),

                const SizedBox(height: 16),

                Text(
                  'Camera Permission Required',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Please allow camera access to scan QR codes for adding children to your family. 📱✨',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 20),

                EnhancedButton(
                  onPressed: _checkPermission,
                  type: EnhancedButtonType.primary,
                  isExpanded: true,
                  size: EnhancedButtonSize.medium,
                  child: const Text('Grant Permission'),
                ).animate().fadeIn(delay: 800.ms, duration: 500.ms).scale(
                    begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),

                const SizedBox(height: 16),

                // Simplified decorative elements
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFloatingIcon(
                        Icons.security_rounded, AppTheme.green, 0),
                    const SizedBox(width: 12),
                    _buildFloatingIcon(
                        Icons.family_restroom, AppTheme.accent, 500),
                    const SizedBox(width: 12),
                    _buildFloatingIcon(
                        Icons.qr_code_scanner, AppTheme.secondary, 1000),
                  ],
                ).animate().fadeIn(delay: 1000.ms, duration: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color, int delay) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .moveY(
          begin: 0,
          end: -6,
          duration: (2000 + delay).ms,
          curve: Curves.easeInOut,
        )
        .then()
        .moveY(
          begin: -6,
          end: 0,
          duration: (2000 + delay).ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildScanningAnimations() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.accent.withOpacity(
                    0.3 + (_pulseController.value * 0.4),
                  ),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.mediumShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              )
                  .animate()
                  .scale(duration: 300.ms)
                  .then()
                  .shimmer(duration: 1000.ms),
              const SizedBox(height: 16),
              Text(
                'Scanning QR Code... ✨',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  QrScannerOverlayShape _buildDefaultOverlay() {
    return QrScannerOverlayShape(
      borderColor: AppTheme.accent,
      borderRadius: 20,
      borderLength: 40,
      borderWidth: 6,
      cutOutSize: 280,
      overlayColor: const Color(0x88000000),
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
class ChildInviteQrOverlay extends StatefulWidget {
  final String? instruction;
  final Color? borderColor;

  const ChildInviteQrOverlay({
    super.key,
    this.instruction,
    this.borderColor,
  });

  @override
  State<ChildInviteQrOverlay> createState() => _ChildInviteQrOverlayState();
}

class _ChildInviteQrOverlayState extends State<ChildInviteQrOverlay>
    with TickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Instruction text with beautiful styling
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.softShadow,
            ),
            child: Text(
              widget.instruction ?? 'Point camera at QR code! ✨',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: -0.3, end: 0),

        // Scanning progress indicator
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatController.value * 6 - 3),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .scale(duration: 1000.ms, curve: Curves.easeInOut)
                            .then()
                            .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(0.5, 0.5),
                                duration: 1000.ms),
                        const SizedBox(width: 6),
                        Text(
                          'Scanning...',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Bottom tip with colorful design
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.yellow, AppTheme.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Keep QR code well-lit! 💡',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0),

        // Corner decorations
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppTheme.secondary,
              size: 16,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 800.ms, duration: 500.ms)
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),

        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: AppTheme.green,
              size: 16,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 1000.ms, duration: 500.ms)
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
      ],
    );
  }
}
