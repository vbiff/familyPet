import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> load() async {
    try {
      // Load the .env file
      await dotenv.load(fileName: ".env");
      if (kDebugMode) {
        print('✅ .env file loaded successfully');
        print(
            '🔗 Supabase URL: ${supabaseUrl.isNotEmpty ? "${supabaseUrl.substring(0, 20)}..." : "not found"}');
        print(
            '🔑 Supabase Key: ${supabaseAnonKey.isNotEmpty ? "${supabaseAnonKey.substring(0, 20)}..." : "not found"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load .env file: $e');
      }
    }

    // Validate and initialize Supabase
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        if (kDebugMode) {
          print('✅ Supabase initialized successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Supabase initialization failed: $e');
        }
        rethrow;
      }
    } else {
      final error =
          'Missing Supabase configuration: URL=${supabaseUrl.isEmpty ? "missing" : "found"}, Key=${supabaseAnonKey.isEmpty ? "missing" : "found"}';
      if (kDebugMode) {
        print('❌ $error');
      }
      throw Exception(error);
    }
  }

  static const String storageTaskImagesBucket = 'task_images';
  static const String storageProfileImagesBucket = 'profile_images';
  static const String storagePetImagesBucket = 'pet_images';

  // Feature flags
  static const bool enableOfflineSupport = true;
  static const bool enablePetAnimations = true;
  static const bool enableRealtimeUpdates = true;

  // App constants
  static const int maxFamilyMembers = 8;
  static const int maxTasksPerUser = 50;
  static const Duration taskRefreshInterval = Duration(minutes: 15);
  static const Duration petMoodDecayInterval = Duration(hours: 4);

  // Debug settings
  static const bool isDebugMode = kDebugMode;
  static const bool enablePerformanceMonitoring = !kDebugMode;
}
