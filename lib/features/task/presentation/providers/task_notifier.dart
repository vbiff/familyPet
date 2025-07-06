import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/usecases/create_task.dart';
import 'package:jhonny/features/task/domain/usecases/delete_task.dart';
import 'package:jhonny/features/task/domain/usecases/get_tasks.dart';
import 'package:jhonny/features/task/domain/usecases/update_task_status.dart';
import 'package:jhonny/features/task/presentation/providers/task_state.dart';

class TaskNotifier extends StateNotifier<TaskState> {
  final GetTasks _getTasks;
  final CreateTask _createTask;
  final UpdateTaskStatus _updateTaskStatus;
  final DeleteTask _deleteTask;

  TaskNotifier({
    required GetTasks getTasks,
    required CreateTask createTask,
    required UpdateTaskStatus updateTaskStatus,
    required DeleteTask deleteTask,
  })  : _getTasks = getTasks,
        _createTask = createTask,
        _updateTaskStatus = updateTaskStatus,
        _deleteTask = deleteTask,
        super(const TaskState());

  Future<void> loadTasks({
    required String familyId,
    String? assignedTo,
    TaskStatus? status,
  }) async {
    state = state.copyWith(
      status: TaskStateStatus.loading,
      clearFailure: true,
    );

    final result = await _getTasks(GetTasksParams(
      familyId: familyId,
      assignedTo: assignedTo,
      status: status,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        status: TaskStateStatus.error,
        failure: failure,
      ),
      (tasks) => state = state.copyWith(
        status: TaskStateStatus.success,
        tasks: tasks,
      ),
    );
  }

  Future<void> createNewTask({
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
    state = state.copyWith(
      isCreating: true,
      clearFailure: true,
    );

    final result = await _createTask(CreateTaskParams(
      title: title,
      description: description,
      points: points,
      assignedTo: assignedTo,
      createdBy: createdBy,
      dueDate: dueDate,
      frequency: frequency,
      familyId: familyId,
      imageUrls: imageUrls,
      metadata: metadata,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isCreating: false,
        failure: failure,
      ),
      (task) {
        final updatedTasks = List<Task>.from(state.tasks)..insert(0, task);
        state = state.copyWith(
          isCreating: false,
          tasks: updatedTasks,
          selectedTask: task,
        );
      },
    );
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    String? verifiedById,
    bool clearVerification = false,
  }) async {
    state = state.copyWith(
      isUpdating: true,
      clearFailure: true,
    );

    DateTime? completedAt;
    DateTime? verifiedAt;

    if (status == TaskStatus.completed) {
      completedAt = DateTime.now();
    }

    if (verifiedById != null) {
      verifiedAt = DateTime.now();
    }

    final result = await _updateTaskStatus(UpdateTaskStatusParams(
      taskId: taskId,
      status: status,
      verifiedById: verifiedById,
      completedAt: completedAt,
      verifiedAt: verifiedAt,
      clearVerification: clearVerification,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isUpdating: false,
        failure: failure,
      ),
      (updatedTask) {
        final updatedTasks = state.tasks
            .map((task) => task.id == taskId ? updatedTask : task)
            .toList();

        state = state.copyWith(
          isUpdating: false,
          tasks: updatedTasks,
          selectedTask: state.selectedTask?.id == taskId
              ? updatedTask
              : state.selectedTask,
        );
      },
    );
  }

  Future<void> deleteTask(String taskId) async {
    state = state.copyWith(
      isUpdating: true,
      clearFailure: true,
    );

    final result = await _deleteTask(DeleteTaskParams(taskId: taskId));

    result.fold(
      (failure) => state = state.copyWith(
        isUpdating: false,
        failure: failure,
      ),
      (_) {
        final updatedTasks =
            state.tasks.where((task) => task.id != taskId).toList();
        state = state.copyWith(
          isUpdating: false,
          tasks: updatedTasks,
          clearSelectedTask: state.selectedTask?.id == taskId,
        );
      },
    );
  }

  void selectTask(Task task) {
    state = state.copyWith(selectedTask: task);
  }

  void clearSelectedTask() {
    state = state.copyWith(clearSelectedTask: true);
  }

  void clearError() {
    state = state.copyWith(clearFailure: true);
  }

  // Helper getters for filtered tasks
  List<Task> get pendingTasks =>
      state.tasks.where((task) => task.status.isPending).toList();

  List<Task> get completedTasks =>
      state.tasks.where((task) => task.status.isCompleted).toList();

  List<Task> get overdueTasks =>
      state.tasks.where((task) => task.isOverdue).toList();

  List<Task> get tasksNeedingVerification =>
      state.tasks.where((task) => task.needsVerification).toList();

  List<Task> getTasksForUser(String userId) =>
      state.tasks.where((task) => task.assignedTo == userId).toList();

  // Filter methods for UI
  void filterByPerson(String personId) {
    // TODO: Implement filtering by person
    // For now, just reload tasks with the person filter
  }

  void filterByDeadline(DateTime deadline) {
    // TODO: Implement filtering by deadline
    // For now, just a placeholder
  }

  void filterByStatus(TaskStatus status) {
    // TODO: Implement filtering by status
    // For now, just a placeholder
  }
}
