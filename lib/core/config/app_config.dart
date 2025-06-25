import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
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
