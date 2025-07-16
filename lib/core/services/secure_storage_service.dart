import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'jhonny_secure_prefs',
      preferencesKeyPrefix: 'jhonny_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.jhonny.family',
      accountName: 'jhonny_account',
    ),
  );

  // Storage keys
  static const String _keyChildCredentials = 'child_credentials';
  static const String _keyLastActiveChild = 'last_active_child';
  static const String _keyFamilyData = 'family_data';
  static const String _keyAppSettings = 'app_settings';
  static const String _keyDeviceId = 'device_id';

  /// Stores child user credentials securely
  static Future<void> storeChildCredentials(User user) async {
    try {
      final credentialData = {
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'role': user.role.name,
        'authMethod': user.authMethod.name,
        'familyId': user.familyId,
        'avatarUrl': user.avatarUrl,
        'isPinSetup': user.isPinSetup,
        'lastPinUpdate': user.lastPinUpdate?.toIso8601String(),
        'createdAt': user.createdAt.toIso8601String(),
        'lastLoginAt': user.lastLoginAt.toIso8601String(),
        'metadata': user.metadata,
        'storedAt': DateTime.now().toIso8601String(),
      };

      await _storage.write(
        key: _keyChildCredentials,
        value: jsonEncode(credentialData),
      );

      // Also store as last active child
      await _storage.write(
        key: _keyLastActiveChild,
        value: user.displayName,
      );
    } catch (e) {
      throw SecureStorageException('Failed to store child credentials: $e');
    }
  }

  /// Retrieves stored child credentials
  static Future<User?> getChildCredentials() async {
    try {
      final credentialsJson = await _storage.read(key: _keyChildCredentials);
      if (credentialsJson == null) return null;

      final data = jsonDecode(credentialsJson) as Map<String, dynamic>;

      return User(
        id: data['id'],
        email: data['email'],
        displayName: data['displayName'],
        role: UserRole.values.firstWhere(
          (role) => role.name == data['role'],
          orElse: () => UserRole.child,
        ),
        authMethod: AuthMethod.values.firstWhere(
          (method) => method.name == data['authMethod'],
          orElse: () => AuthMethod.pin,
        ),
        familyId: data['familyId'],
        avatarUrl: data['avatarUrl'],
        isPinSetup: data['isPinSetup'] ?? false,
        lastPinUpdate: data['lastPinUpdate'] != null
            ? DateTime.parse(data['lastPinUpdate'])
            : null,
        createdAt: DateTime.parse(data['createdAt']),
        lastLoginAt: DateTime.parse(data['lastLoginAt']),
        metadata: data['metadata'],
      );
    } catch (e) {
      throw SecureStorageException('Failed to retrieve child credentials: $e');
    }
  }

  /// Removes child credentials from secure storage
  static Future<void> clearChildCredentials() async {
    try {
      await _storage.delete(key: _keyChildCredentials);
      await _storage.delete(key: _keyLastActiveChild);
    } catch (e) {
      throw SecureStorageException('Failed to clear child credentials: $e');
    }
  }

  /// Checks if child credentials exist
  static Future<bool> hasChildCredentials() async {
    try {
      final credentials = await _storage.read(key: _keyChildCredentials);
      return credentials != null;
    } catch (e) {
      return false;
    }
  }

  /// Gets the last active child's display name
  static Future<String?> getLastActiveChildName() async {
    try {
      return await _storage.read(key: _keyLastActiveChild);
    } catch (e) {
      return null;
    }
  }

  /// Stores family data for offline access
  static Future<void> storeFamilyData(Map<String, dynamic> familyData) async {
    try {
      await _storage.write(
        key: _keyFamilyData,
        value: jsonEncode({
          ...familyData,
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      throw SecureStorageException('Failed to store family data: $e');
    }
  }

  /// Retrieves cached family data
  static Future<Map<String, dynamic>?> getFamilyData() async {
    try {
      final familyJson = await _storage.read(key: _keyFamilyData);
      if (familyJson == null) return null;

      final data = jsonDecode(familyJson) as Map<String, dynamic>;

      // Check if data is not too old (24 hours)
      if (data['cachedAt'] != null) {
        final cachedAt = DateTime.parse(data['cachedAt']);
        final age = DateTime.now().difference(cachedAt);
        if (age.inHours > 24) {
          await _storage.delete(key: _keyFamilyData);
          return null;
        }
      }

      return data;
    } catch (e) {
      return null;
    }
  }

  /// Stores app settings
  static Future<void> storeAppSettings(Map<String, dynamic> settings) async {
    try {
      await _storage.write(
        key: _keyAppSettings,
        value: jsonEncode(settings),
      );
    } catch (e) {
      throw SecureStorageException('Failed to store app settings: $e');
    }
  }

  /// Retrieves app settings
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final settingsJson = await _storage.read(key: _keyAppSettings);
      if (settingsJson == null) return {};

      return jsonDecode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Generates and stores a unique device ID
  static Future<String> getOrCreateDeviceId() async {
    try {
      String? deviceId = await _storage.read(key: _keyDeviceId);

      if (deviceId == null) {
        // Generate a new UUID-like device ID
        deviceId = _generateDeviceId();
        await _storage.write(key: _keyDeviceId, value: deviceId);
      }

      return deviceId;
    } catch (e) {
      // Fallback to a session-based ID if secure storage fails
      return _generateDeviceId();
    }
  }

  /// Checks if device has been used for child login before
  static Future<bool> isKnownChildDevice() async {
    try {
      return await hasChildCredentials();
    } catch (e) {
      return false;
    }
  }

  /// Stores offline session data for quick app startup
  static Future<void> storeOfflineSession({
    required String userId,
    required String displayName,
    required String familyId,
  }) async {
    try {
      final sessionData = {
        'userId': userId,
        'displayName': displayName,
        'familyId': familyId,
        'sessionStarted': DateTime.now().toIso8601String(),
        'deviceId': await getOrCreateDeviceId(),
      };

      await _storage.write(
        key: 'offline_session',
        value: jsonEncode(sessionData),
      );
    } catch (e) {
      throw SecureStorageException('Failed to store offline session: $e');
    }
  }

  /// Retrieves offline session data
  static Future<Map<String, dynamic>?> getOfflineSession() async {
    try {
      final sessionJson = await _storage.read(key: 'offline_session');
      if (sessionJson == null) return null;

      final session = jsonDecode(sessionJson) as Map<String, dynamic>;

      // Check if session is not too old (7 days)
      if (session['sessionStarted'] != null) {
        final sessionStart = DateTime.parse(session['sessionStarted']);
        final age = DateTime.now().difference(sessionStart);
        if (age.inDays > 7) {
          await _storage.delete(key: 'offline_session');
          return null;
        }
      }

      return session;
    } catch (e) {
      return null;
    }
  }

  /// Clears offline session
  static Future<void> clearOfflineSession() async {
    try {
      await _storage.delete(key: 'offline_session');
    } catch (e) {
      throw SecureStorageException('Failed to clear offline session: $e');
    }
  }

  /// Completely clears all stored data (for logout/reset)
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear all data: $e');
    }
  }

  /// Backs up critical data before major operations
  static Future<Map<String, String>> backupCriticalData() async {
    try {
      final backup = <String, String>{};

      final keys = [
        _keyChildCredentials,
        _keyLastActiveChild,
        _keyFamilyData,
        _keyDeviceId,
      ];

      for (final key in keys) {
        final value = await _storage.read(key: key);
        if (value != null) {
          backup[key] = value;
        }
      }

      return backup;
    } catch (e) {
      throw SecureStorageException('Failed to backup critical data: $e');
    }
  }

  /// Restores data from backup
  static Future<void> restoreFromBackup(Map<String, String> backup) async {
    try {
      for (final entry in backup.entries) {
        await _storage.write(key: entry.key, value: entry.value);
      }
    } catch (e) {
      throw SecureStorageException('Failed to restore from backup: $e');
    }
  }

  /// Validates stored data integrity
  static Future<bool> validateDataIntegrity() async {
    try {
      // Check if child credentials are valid
      final credentials = await getChildCredentials();
      if (credentials == null) return true; // No data to validate

      // Basic validation
      if (credentials.id.isEmpty ||
          credentials.displayName.isEmpty ||
          credentials.role != UserRole.child) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generates a unique device ID
  static String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 37) % 1000000; // Simple random component
    return 'child_device_${timestamp}_$random';
  }
}

/// Exception class for secure storage operations
class SecureStorageException implements Exception {
  final String message;

  const SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}

/// Data class for offline child session
class OfflineChildSession {
  final String userId;
  final String displayName;
  final String familyId;
  final DateTime sessionStarted;
  final String deviceId;

  const OfflineChildSession({
    required this.userId,
    required this.displayName,
    required this.familyId,
    required this.sessionStarted,
    required this.deviceId,
  });

  factory OfflineChildSession.fromJson(Map<String, dynamic> json) {
    return OfflineChildSession(
      userId: json['userId'],
      displayName: json['displayName'],
      familyId: json['familyId'],
      sessionStarted: DateTime.parse(json['sessionStarted']),
      deviceId: json['deviceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'familyId': familyId,
      'sessionStarted': sessionStarted.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  bool get isExpired {
    final age = DateTime.now().difference(sessionStarted);
    return age.inDays > 7;
  }
}
