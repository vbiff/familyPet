import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jhonny/features/task/data/models/task_comment_model.dart';
import 'package:logger/logger.dart';

abstract class TaskCommentRemoteDataSource {
  Future<List<TaskCommentModel>> getComments(String taskId);
  Future<TaskCommentModel> createComment(TaskCommentModel comment);
  Future<TaskCommentModel> updateComment(String commentId, String content);
  Future<void> deleteComment(String commentId);
  Stream<List<TaskCommentModel>> watchComments(String taskId);
}

class SupabaseTaskCommentRemoteDataSource
    implements TaskCommentRemoteDataSource {
  final SupabaseClient _client;
  final Logger _logger;
  static const String _tableName = 'task_comments';

  SupabaseTaskCommentRemoteDataSource(this._client, this._logger);

  @override
  Future<List<TaskCommentModel>> getComments(String taskId) async {
    try {
      _logger.d('Fetching comments for task: $taskId');

      final response = await _client
          .from(_tableName)
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      _logger.d('Comments fetched: ${response.length} items');

      return response.map((json) => TaskCommentModel.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to fetch comments: $e');
      throw Exception('Failed to fetch comments: $e');
    }
  }

  @override
  Future<TaskCommentModel> createComment(TaskCommentModel comment) async {
    try {
      _logger.d('Creating comment for task: ${comment.taskId}');

      final response = await _client
          .from(_tableName)
          .insert(comment.toCreateJson())
          .select()
          .single();

      _logger.i('Comment created successfully');
      return TaskCommentModel.fromJson(response);
    } catch (e) {
      _logger.e('Failed to create comment: $e');
      throw Exception('Failed to create comment: $e');
    }
  }

  @override
  Future<TaskCommentModel> updateComment(
      String commentId, String content) async {
    try {
      _logger.d('Updating comment: $commentId');

      final response = await _client
          .from(_tableName)
          .update({
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId)
          .select()
          .single();

      _logger.i('Comment updated successfully');
      return TaskCommentModel.fromJson(response);
    } catch (e) {
      _logger.e('Failed to update comment: $e');
      throw Exception('Failed to update comment: $e');
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      _logger.d('Deleting comment: $commentId');

      await _client.from(_tableName).delete().eq('id', commentId);

      _logger.i('Comment deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }

  @override
  Stream<List<TaskCommentModel>> watchComments(String taskId) {
    try {
      _logger.d('Watching comments for task: $taskId');

      return _client
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('task_id', taskId)
          .order('created_at', ascending: false)
          .map((data) =>
              data.map((json) => TaskCommentModel.fromJson(json)).toList());
    } catch (e) {
      _logger.e('Failed to watch comments: $e');
      throw Exception('Failed to watch comments: $e');
    }
  }
}
