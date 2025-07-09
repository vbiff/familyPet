import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';

abstract class TaskCommentRepository {
  Future<Either<Failure, List<TaskComment>>> getComments(String taskId);

  Future<Either<Failure, TaskComment>> createComment({
    required String taskId,
    required String authorId,
    required String content,
  });

  Future<Either<Failure, TaskComment>> updateComment({
    required String commentId,
    required String content,
  });

  Future<Either<Failure, void>> deleteComment(String commentId);

  Stream<List<TaskComment>> watchComments(String taskId);
}
