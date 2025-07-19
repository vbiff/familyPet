import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
    bool includeArchived = false,
  });

  Future<Either<Failure, Task>> getTaskById(String taskId);

  Future<Either<Failure, Task>> createTask({
    required String title,
    required String description,
    required int points,
    required String assignedTo,
    required String createdBy,
    required DateTime dueDate,
    required TaskFrequency frequency,
    required String familyId,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
    // Phase 2 fields
    TaskCategory? category,
    TaskDifficulty? difficulty,
    List<String>? tags,
  });

  Future<Either<Failure, Task>> updateTask(
      String taskId, Map<String, dynamic> data);

  Future<Either<Failure, void>> deleteTask(String taskId);

  Future<Either<Failure, void>> deletePermanently(String taskId);

  Future<Either<Failure, Task>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    String? verifiedById,
    DateTime? completedAt,
    DateTime? verifiedAt,
    bool clearVerification = false,
  });

  Stream<List<Task>> watchTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
    bool includeArchived = false,
  });
}
