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
  // Phase 2 fields
  final TaskCategory? category;
  final TaskDifficulty? difficulty;
  final List<String>? tags;

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
    // Phase 2 fields
    this.category,
    this.difficulty,
    this.tags,
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

    if (params.points < 0) {
      return left(
          const ValidationFailure(message: 'Task points cannot be negative'));
    }

    if (params.dueDate.isBefore(DateTime.now())) {
      return left(
          const ValidationFailure(message: 'Due date cannot be in the past'));
    }

    // Validate family membership - tasks can only be created within a family
    if (params.familyId.trim().isEmpty) {
      return left(const ValidationFailure(
          message:
              'Tasks can only be created within a family. Please join or create a family first.'));
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
      // Phase 2 fields
      category: params.category,
      difficulty: params.difficulty,
      tags: params.tags,
    );
  }
}
