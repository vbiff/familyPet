import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      if (kDebugMode) {
        print(
            'Warning: .env file not found. Using placeholder values for development.');
      }
    }

    // Initialize Supabase with fallback values for development
    final url = supabaseUrl.isNotEmpty
        ? supabaseUrl
        : 'https://placeholder.supabase.co';
    final key =
        supabaseAnonKey.isNotEmpty ? supabaseAnonKey : 'placeholder-anon-key';

    try {
      await Supabase.initialize(
        url: url,
        anonKey: key,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
            'Warning: Supabase initialization failed. Running in offline mode: $e');
      }
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
