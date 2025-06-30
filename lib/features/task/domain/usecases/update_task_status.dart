import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';

class UpdateTaskStatusParams {
  final String taskId;
  final TaskStatus status;
  final String? verifiedById;
  final DateTime? completedAt;
  final DateTime? verifiedAt;

  const UpdateTaskStatusParams({
    required this.taskId,
    required this.status,
    this.verifiedById,
    this.completedAt,
    this.verifiedAt,
  });
}

class UpdateTaskStatus {
  final TaskRepository _repository;

  UpdateTaskStatus(this._repository);

  Future<Either<Failure, Task>> call(UpdateTaskStatusParams params) async {
    if (params.taskId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'Task ID cannot be empty'));
    }

    // Validate business rules
    if (params.status == TaskStatus.completed && params.completedAt == null) {
      return left(const ValidationFailure(
        message: 'Completed at date is required when marking task as completed',
      ));
    }

    if (params.verifiedById != null && params.verifiedAt == null) {
      return left(const ValidationFailure(
        message: 'Verified at date is required when task is verified',
      ));
    }

    return await _repository.updateTaskStatus(
      taskId: params.taskId,
      status: params.status,
      verifiedById: params.verifiedById,
      completedAt: params.completedAt,
      verifiedAt: params.verifiedAt,
    );
  }
}
