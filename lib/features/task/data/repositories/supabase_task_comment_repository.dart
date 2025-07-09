import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/data/datasources/task_comment_remote_datasource.dart';
import 'package:jhonny/features/task/data/models/task_comment_model.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';
import 'package:jhonny/features/task/domain/repositories/task_comment_repository.dart';

class SupabaseTaskCommentRepository implements TaskCommentRepository {
  final TaskCommentRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  SupabaseTaskCommentRepository(this._remoteDataSource, this._uuid);

  @override
  Future<Either<Failure, List<TaskComment>>> getComments(String taskId) async {
    try {
      final commentModels = await _remoteDataSource.getComments(taskId);
      return right(commentModels.map((model) => model.toEntity()).toList());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskComment>> createComment({
    required String taskId,
    required String authorId,
    required String content,
  }) async {
    try {
      final commentId = _uuid.v4();
      final now = DateTime.now();

      final commentModel = TaskCommentModel(
        id: commentId,
        taskId: taskId,
        authorId: authorId,
        content: content,
        createdAt: now,
      );

      final createdComment =
          await _remoteDataSource.createComment(commentModel);
      return right(createdComment.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskComment>> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final updatedComment =
          await _remoteDataSource.updateComment(commentId, content);
      return right(updatedComment.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(String commentId) async {
    try {
      await _remoteDataSource.deleteComment(commentId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<TaskComment>> watchComments(String taskId) {
    return _remoteDataSource.watchComments(taskId).map((commentModels) =>
        commentModels.map((model) => model.toEntity()).toList());
  }
}
