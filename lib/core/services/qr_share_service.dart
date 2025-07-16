import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class QrShareService {
  /// Shares QR code as text with family invitation details
  static Future<void> shareInvitationText({
    required String familyName,
    required String token,
    String? childDisplayName,
  }) async {
    final message = _buildInvitationMessage(
      familyName: familyName,
      token: token,
      childDisplayName: childDisplayName,
    );

    await Share.share(
      message,
      subject: 'Join our family in Jhonny!',
    );
  }

  /// Captures QR code widget and shares as image
  static Future<void> shareQrCodeImage({
    required GlobalKey qrKey,
    required String familyName,
    String? childDisplayName,
  }) async {
    try {
      // Capture the QR code widget as image
      final imageBytes = await _captureQrCodeImage(qrKey);
      if (imageBytes == null) {
        throw Exception('Failed to capture QR code image');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/family_invite_qr.png');
      await tempFile.writeAsBytes(imageBytes);

      // Share the image
      final message = _buildInvitationMessage(
        familyName: familyName,
        token: null, // Don't include token in image share for security
        childDisplayName: childDisplayName,
      );

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: message,
        subject: 'Join our family in Jhonny!',
      );

      // Clean up temporary file
      await tempFile.delete();
    } catch (e) {
      throw Exception('Failed to share QR code: $e');
    }
  }

  /// Saves QR code image to device gallery
  static Future<bool> saveQrCodeToGallery({
    required GlobalKey qrKey,
    required String familyName,
    String? childDisplayName,
  }) async {
    try {
      // Request storage permission
      final permission = await _requestStoragePermission();
      if (!permission) {
        throw Exception('Storage permission denied');
      }

      // Capture the QR code widget as image
      final imageBytes = await _captureQrCodeImage(qrKey);
      if (imageBytes == null) {
        throw Exception('Failed to capture QR code image');
      }

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: 'jhonny_family_invite_${DateTime.now().millisecondsSinceEpoch}',
        quality: 100,
      );

      return result['isSuccess'] == true;
    } catch (e) {
      throw Exception('Failed to save QR code: $e');
    }
  }

  /// Shares invitation details with multiple options
  static Future<void> shareInvitationWithOptions({
    required BuildContext context,
    required GlobalKey qrKey,
    required String familyName,
    required String token,
    String? childDisplayName,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Invitation'),
        content: const Text('How would you like to share the invitation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await shareInvitationText(
                  familyName: familyName,
                  token: token,
                  childDisplayName: childDisplayName,
                );
              } catch (e) {
                _showErrorMessage(context, 'Failed to share text: $e');
              }
            },
            child: const Text('Share Text'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await copyInvitationLink(
                  token: token,
                  familyName: familyName,
                  childDisplayName: childDisplayName,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invitation link copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showErrorMessage(context, 'Failed to copy link: $e');
              }
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await shareQrCodeImage(
                  qrKey: qrKey,
                  familyName: familyName,
                  childDisplayName: childDisplayName,
                );
              } catch (e) {
                _showErrorMessage(context, 'Failed to share image: $e');
              }
            },
            child: const Text('Share QR Image'),
          ),
        ],
      ),
    );
  }

  /// Copies invitation link to clipboard
  static Future<void> copyInvitationLink({
    required String token,
    required String familyName,
    String? childDisplayName,
  }) async {
    final link = buildInvitationLink(
      token: token,
      familyName: familyName,
      childDisplayName: childDisplayName,
    );

    await Clipboard.setData(ClipboardData(text: link));
  }

  /// Builds invitation link URL
  static String buildInvitationLink({
    required String token,
    required String familyName,
    String? childDisplayName,
  }) {
    // Build a deep link URL that the app can handle
    const baseUrl = 'https://jhonny.app/invite';
    final params = <String, String>{
      'token': token,
      'family': Uri.encodeComponent(familyName),
    };

    if (childDisplayName != null) {
      params['child'] = Uri.encodeComponent(childDisplayName);
    }

    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');

    return '$baseUrl?$queryString';
  }

  /// Private helper to capture QR code widget as image bytes
  static Future<Uint8List?> _captureQrCodeImage(GlobalKey qrKey) async {
    try {
      // Check if the context and render object exist
      final context = qrKey.currentContext;
      if (context == null) {
        return null;
      }

      final renderObject = context.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return null;
      }

      final boundary = renderObject as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Private helper to request storage permission
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), photos permission is sufficient
      final permission =
          Platform.isAndroid && await _getAndroidSdkVersion() >= 33
              ? Permission.photos
              : Permission.storage;

      final status = await permission.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return true; // For other platforms, assume permission is granted
  }

  /// Helper to get Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    // This is a simplified version. In a real app, you'd use device_info_plus
    return 33; // Default to API 33 for modern Android
  }

  /// Private helper to build invitation message
  static String _buildInvitationMessage({
    required String familyName,
    String? token,
    String? childDisplayName,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🎉 You\'re invited to join our family!');
    buffer.writeln();
    buffer.writeln('Family: $familyName');

    if (childDisplayName != null) {
      buffer.writeln('For: $childDisplayName');
    }

    buffer.writeln();
    buffer.writeln('📱 To join:');
    buffer.writeln('1. Download the Jhonny Family App');

    if (token != null) {
      buffer.writeln('2. Use this invitation code: $token');
      buffer.writeln('3. Or scan the QR code if available');
    } else {
      buffer.writeln('2. Scan the QR code with the app');
    }

    buffer.writeln();
    buffer.writeln('✨ Join us in creating healthy family habits!');

    return buffer.toString();
  }

  /// Private helper to show error messages
  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
