import 'package:fpdart/fpdart.dart' hide Task;
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/data/datasources/task_remote_datasource.dart';
import 'package:jhonny/features/task/data/models/task_model.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';

class SupabaseTaskRepository implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  SupabaseTaskRepository(this._remoteDataSource, this._uuid);

  @override
  Future<Either<Failure, List<Task>>> getTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
  }) async {
    try {
      final taskModels = await _remoteDataSource.getTasks(
        familyId: familyId,
        assignedTo: assignedTo,
        status: status,
      );

      return right(taskModels.map((model) => model.toEntity()).toList());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> getTaskById(String taskId) async {
    try {
      final taskModel = await _remoteDataSource.getTaskById(taskId);
      return right(taskModel.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final taskId = _uuid.v4();
      final now = DateTime.now();

      final taskModel = TaskModel(
        id: taskId,
        title: title,
        description: description,
        points: points,
        status: TaskStatus.pending,
        assignedTo: assignedTo,
        createdBy: createdBy,
        dueDate: dueDate,
        frequency: frequency,
        familyId: familyId,
        imageUrls: imageUrls ?? [],
        createdAt: now,
        metadata: metadata,
      );

      final createdTask = await _remoteDataSource.createTask(taskModel);
      return right(createdTask.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final updatedTask = await _remoteDataSource.updateTask(taskModel);
      return right(updatedTask.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    try {
      await _remoteDataSource.deleteTask(taskId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    String? verifiedById,
    DateTime? completedAt,
    DateTime? verifiedAt,
    bool clearVerification = false,
  }) async {
    try {
      final updatedTask = await _remoteDataSource.updateTaskStatus(
        taskId: taskId,
        status: status,
        verifiedById: verifiedById,
        completedAt: completedAt,
        verifiedAt: verifiedAt,
        clearVerification: clearVerification,
      );

      return right(updatedTask.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Task>> watchTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
  }) {
    return _remoteDataSource
        .watchTasks(
          familyId: familyId,
          assignedTo: assignedTo,
          status: status,
        )
        .map((taskModels) =>
            taskModels.map((model) => model.toEntity()).toList());
  }
}
