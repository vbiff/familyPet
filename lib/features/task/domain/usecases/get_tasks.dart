import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';

class GetTasksParams {
  final String familyId;
  final String? assignedTo;
  final TaskStatus? status;

  const GetTasksParams({
    required this.familyId,
    this.assignedTo,
    this.status,
  });
}

class GetTasks {
  final TaskRepository _repository;

  GetTasks(this._repository);

  Future<Either<Failure, List<Task>>> call(GetTasksParams params) async {
    if (params.familyId.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Family ID cannot be empty'));
    }

    return await _repository.getTasks(
      familyId: params.familyId,
      assignedTo: params.assignedTo,
      status: params.status,
    );
  }
}
