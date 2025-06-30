import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';

class CreateTaskParams {
  final String title;
  final String description;
  final int points;
  final String assignedTo;
  final String createdBy;
  final DateTime dueDate;
  final TaskFrequency frequency;
  final String familyId;
  final List<String>? imageUrls;
  final Map<String, dynamic>? metadata;

  const CreateTaskParams({
    required this.title,
    required this.description,
    required this.points,
    required this.assignedTo,
    required this.createdBy,
    required this.dueDate,
    required this.frequency,
    required this.familyId,
    this.imageUrls,
    this.metadata,
  });
}

class CreateTask {
  final TaskRepository _repository;

  CreateTask(this._repository);

  Future<Either<Failure, Task>> call(CreateTaskParams params) async {
    // Validate input parameters
    if (params.title.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Task title cannot be empty'));
    }

    if (params.description.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Task description cannot be empty'));
    }

    if (params.points < 0) {
      return left(
          const ValidationFailure(message: 'Task points cannot be negative'));
    }

    if (params.dueDate.isBefore(DateTime.now())) {
      return left(
          const ValidationFailure(message: 'Due date cannot be in the past'));
    }

    return await _repository.createTask(
      title: params.title.trim(),
      description: params.description.trim(),
      points: params.points,
      assignedTo: params.assignedTo,
      createdBy: params.createdBy,
      dueDate: params.dueDate,
      frequency: params.frequency,
      familyId: params.familyId,
      imageUrls: params.imageUrls,
      metadata: params.metadata,
    );
  }
}
