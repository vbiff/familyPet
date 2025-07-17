import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeService {
  static const String _appScheme = 'jhonny://';
  static const String _childInviteAction = 'child-invite';

  /// Generates QR code data for child invitation
  static String generateChildInviteQrData({
    required String token,
    required String familyName,
    String? childDisplayName,
  }) {
    final data = {
      'action': _childInviteAction,
      'token': token,
      'familyName': familyName,
      'childDisplayName': childDisplayName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final jsonData = jsonEncode(data);
    return '$_appScheme$jsonData';
  }

  /// Parses QR code data to extract child invitation information
  static ChildInviteQrData? parseChildInviteQrData(String qrData) {
    try {
      print('🔍 Raw QR data: $qrData');

      // Remove app scheme if present
      String jsonData = qrData;
      if (qrData.startsWith(_appScheme)) {
        jsonData = qrData.substring(_appScheme.length);
      }

      print('🔍 JSON data after scheme removal: $jsonData');

      final Map<String, dynamic> data = jsonDecode(jsonData);
      print('🔍 Parsed QR data: $data');
      print('🔍 Extracted token: ${data['token']}');

      // Validate required fields
      if (data['action'] != _childInviteAction ||
          data['token'] == null ||
          data['familyName'] == null) {
        print('❌ QR validation failed - missing required fields');
        print('   Action: ${data['action']} (expected: $_childInviteAction)');
        print('   Token: ${data['token']}');
        print('   Family Name: ${data['familyName']}');
        return null;
      }

      print('✅ QR parsed successfully - Token: ${data['token']}');
      return ChildInviteQrData(
        token: data['token'],
        familyName: data['familyName'],
        childDisplayName: data['childDisplayName'],
        timestamp: data['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
            : DateTime.now(),
      );
    } catch (e) {
      print('❌ QR parsing error: $e');
      return null;
    }
  }

  /// Creates a QR code widget for child invitation
  static Widget buildChildInviteQrCode({
    required String token,
    required String familyName,
    String? childDisplayName,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
    String? logo,
  }) {
    final qrData = generateChildInviteQrData(
      token: token,
      familyName: familyName,
      childDisplayName: childDisplayName,
    );

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      embeddedImage: logo != null ? AssetImage(logo) : null,
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(40, 40),
      ),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      padding: const EdgeInsets.all(10),
    );
  }

  /// Validates if QR data is a valid child invitation
  static bool isValidChildInviteQr(String qrData) {
    final parsed = parseChildInviteQrData(qrData);
    return parsed != null;
  }

  /// Creates a shareable QR code image
  static Widget buildShareableQrCode({
    required String token,
    required String familyName,
    String? childDisplayName,
    double size = 300.0,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Family name header
          Text(
            'Join $familyName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (childDisplayName != null) ...[
            Text(
              'as $childDisplayName',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 16),
          ],

          // QR Code
          buildChildInviteQrCode(
            token: token,
            familyName: familyName,
            childDisplayName: childDisplayName,
            size: size,
          ),

          const SizedBox(height: 16),

          // Instructions
          const Text(
            'Scan this QR code to join the family!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // App branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                size: 16,
                color: Colors.blue.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                'Jhonny Family App',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Data class for parsed child invitation QR codes
class ChildInviteQrData {
  final String token;
  final String familyName;
  final String? childDisplayName;
  final DateTime timestamp;

  const ChildInviteQrData({
    required this.token,
    required this.familyName,
    this.childDisplayName,
    required this.timestamp,
  });

  /// Checks if the QR code is still valid (not too old)
  bool isExpired({Duration maxAge = const Duration(hours: 24)}) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  @override
  String toString() {
    return 'ChildInviteQrData(token: $token, familyName: $familyName, childDisplayName: $childDisplayName, timestamp: $timestamp)';
  }
}

/// QR Code generation result for error handling
class QrGenerationResult {
  final bool success;
  final String? qrData;
  final String? error;

  const QrGenerationResult({
    required this.success,
    this.qrData,
    this.error,
  });

  factory QrGenerationResult.success(String qrData) {
    return QrGenerationResult(
      success: true,
      qrData: qrData,
    );
  }

  factory QrGenerationResult.failure(String error) {
    return QrGenerationResult(
      success: false,
      error: error,
    );
  }
}
