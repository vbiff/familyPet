import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';
import 'package:jhonny/features/task/domain/repositories/task_comment_repository.dart';

class GetTaskComments {
  final TaskCommentRepository _repository;

  GetTaskComments(this._repository);

  Future<Either<Failure, List<TaskComment>>> call(String taskId) async {
    if (taskId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'Task ID cannot be empty'));
    }

    return await _repository.getComments(taskId);
  }
}
