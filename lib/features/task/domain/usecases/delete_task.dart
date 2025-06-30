import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';

class DeleteTaskParams {
  final String taskId;

  const DeleteTaskParams({
    required this.taskId,
  });
}

class DeleteTask {
  final TaskRepository _repository;

  DeleteTask(this._repository);

  Future<Either<Failure, void>> call(DeleteTaskParams params) async {
    if (params.taskId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'Task ID cannot be empty'));
    }

    return await _repository.deleteTask(params.taskId);
  }
}
