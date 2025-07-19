import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';

class DeleteTaskPermanentlyParams {
  final String taskId;

  const DeleteTaskPermanentlyParams({
    required this.taskId,
  });
}

class DeleteTaskPermanently {
  final TaskRepository _repository;

  DeleteTaskPermanently(this._repository);

  Future<Either<Failure, void>> call(DeleteTaskPermanentlyParams params) async {
    if (params.taskId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'Task ID cannot be empty'));
    }

    return await _repository.deletePermanently(params.taskId);
  }
}
