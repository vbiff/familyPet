import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';
import 'package:jhonny/features/task/domain/repositories/task_comment_repository.dart';

class CreateTaskCommentParams {
  final String taskId;
  final String authorId;
  final String content;

  const CreateTaskCommentParams({
    required this.taskId,
    required this.authorId,
    required this.content,
  });
}

class CreateTaskComment {
  final TaskCommentRepository _repository;

  CreateTaskComment(this._repository);

  Future<Either<Failure, TaskComment>> call(
      CreateTaskCommentParams params) async {
    // Validate input parameters
    if (params.taskId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'Task ID cannot be empty'));
    }

    if (params.authorId.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Author ID cannot be empty'));
    }

    if (params.content.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Comment content cannot be empty'));
    }

    if (params.content.trim().length > 1000) {
      return left(const ValidationFailure(
          message: 'Comment cannot exceed 1000 characters'));
    }

    return await _repository.createComment(
      taskId: params.taskId,
      authorId: params.authorId,
      content: params.content.trim(),
    );
  }
}
