import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jhonny/features/task/data/models/task_model.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:logger/logger.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
  });

  Future<TaskModel> getTaskById(String taskId);

  Future<TaskModel> createTask(TaskModel task);

  Future<TaskModel> updateTask(TaskModel task);

  Future<void> deleteTask(String taskId);

  Future<TaskModel> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    String? verifiedById,
    DateTime? completedAt,
    DateTime? verifiedAt,
  });

  Stream<List<TaskModel>> watchTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
  });
}

class SupabaseTaskRemoteDataSource implements TaskRemoteDataSource {
  final SupabaseClient _client;
  static const String _tableName = 'tasks';
  static final _logger = Logger();

  SupabaseTaskRemoteDataSource(this._client);

  @override
  Future<List<TaskModel>> getTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
  }) async {
    try {
      var query = _client
          .from(_tableName)
          .select()
          .eq('family_id', familyId)
          .eq('is_archived', false);

      if (assignedTo != null) {
        query = query.eq('assigned_to_id', assignedTo);
      }

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final data = await query.order('created_at', ascending: false);
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  @override
  Future<TaskModel> getTaskById(String taskId) async {
    try {
      final data =
          await _client.from(_tableName).select().eq('id', taskId).single();

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final data = await _client
          .from(_tableName)
          .insert(task.toCreateJson())
          .select()
          .single();

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final data = await _client
          .from(_tableName)
          .update(task.toJson())
          .eq('id', task.id)
          .select()
          .single();

      return TaskModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _client
          .from(_tableName)
          .update({'is_archived': true}).eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  Future<TaskModel> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    String? verifiedById,
    DateTime? completedAt,
    DateTime? verifiedAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (completedAt != null) {
      updates['completed_at'] = completedAt.toIso8601String();
    }

    if (verifiedById != null) {
      updates['verified_by_id'] = verifiedById;
      updates['verified_at'] = verifiedAt?.toIso8601String();
    }

    _logger.d('Database update - Task ID: $taskId');
    _logger.d('Database update - Updates: $updates');

    try {
      final response = await _client
          .from(_tableName)
          .update(updates)
          .eq('id', taskId)
          .select();

      if (response.isNotEmpty) {
        final data = response.first;
        _logger.i('Database update successful');
        _logger.d('Updated task data: $data');
        return TaskModel.fromJson(data);
      } else {
        throw Exception('No data returned from database update');
      }
    } catch (e) {
      _logger.e('Database update failed: $e');
      throw Exception('Failed to update task status: $e');
    }
  }

  @override
  Stream<List<TaskModel>> watchTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
  }) {
    try {
      return _client.from(_tableName).stream(primaryKey: ['id']).map(
          (data) => data.map((json) => TaskModel.fromJson(json)).where((task) {
                if (task.familyId != familyId) return false;
                if (task.metadata?['is_archived'] == true) return false;
                if (assignedTo != null && task.assignedTo != assignedTo) {
                  return false;
                }
                if (status != null && task.status != status) {
                  return false;
                }
                return true;
              }).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    } catch (e) {
      throw Exception('Failed to watch tasks: $e');
    }
  }
}
