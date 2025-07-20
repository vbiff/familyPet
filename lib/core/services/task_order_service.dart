import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaskOrderService {
  static const String _keyPrefix = 'task_order_';

  /// Get the storage key for a specific user and filter combination
  String _getStorageKey(
      {required String userId, required bool isMyTasks, String? familyId}) {
    return '$_keyPrefix${userId}_${isMyTasks ? 'my' : 'all'}_${familyId ?? 'no_family'}';
  }

  /// Save the task order to SharedPreferences
  Future<void> saveTaskOrder({
    required List<String> taskIds,
    required String userId,
    required bool isMyTasks,
    String? familyId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(
          userId: userId, isMyTasks: isMyTasks, familyId: familyId);

      // Convert list to JSON and save
      final jsonString = jsonEncode(taskIds);
      await prefs.setString(key, jsonString);

      print(
          '💾 TaskOrderService: Saved order for ${taskIds.length} tasks with key: $key');
    } catch (e) {
      print('❌ TaskOrderService: Failed to save task order: $e');
    }
  }

  /// Load the task order from SharedPreferences
  Future<List<String>> loadTaskOrder({
    required String userId,
    required bool isMyTasks,
    String? familyId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(
          userId: userId, isMyTasks: isMyTasks, familyId: familyId);

      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> taskIdsJson = jsonDecode(jsonString);
        final taskIds = taskIdsJson.cast<String>();

        print(
            '📖 TaskOrderService: Loaded order for ${taskIds.length} tasks with key: $key');
        return taskIds;
      }
    } catch (e) {
      print('❌ TaskOrderService: Failed to load task order: $e');
    }

    return [];
  }

  /// Clear saved task order
  Future<void> clearTaskOrder({
    required String userId,
    required bool isMyTasks,
    String? familyId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(
          userId: userId, isMyTasks: isMyTasks, familyId: familyId);
      await prefs.remove(key);

      print('🗑️ TaskOrderService: Cleared task order for key: $key');
    } catch (e) {
      print('❌ TaskOrderService: Failed to clear task order: $e');
    }
  }

  /// Clear all task orders (useful for logout)
  Future<void> clearAllTaskOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      print(
          '🗑️ TaskOrderService: Cleared all task orders (${keys.length} entries)');
    } catch (e) {
      print('❌ TaskOrderService: Failed to clear all task orders: $e');
    }
  }
}

// Global instance
final taskOrderService = TaskOrderService();
