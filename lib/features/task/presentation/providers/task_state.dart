import 'package:equatable/equatable.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';

enum TaskStateStatus {
  initial,
  loading,
  success,
  error,
}

class TaskState extends Equatable {
  final TaskStateStatus status;
  final List<Task> tasks;
  final Task? selectedTask;
  final Failure? failure;
  final bool isCreating;
  final bool isUpdating;

  const TaskState({
    this.status = TaskStateStatus.initial,
    this.tasks = const [],
    this.selectedTask,
    this.failure,
    this.isCreating = false,
    this.isUpdating = false,
  });

  TaskState copyWith({
    TaskStateStatus? status,
    List<Task>? tasks,
    Task? selectedTask,
    Failure? failure,
    bool? isCreating,
    bool? isUpdating,
    bool clearSelectedTask = false,
    bool clearFailure = false,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      selectedTask:
          clearSelectedTask ? null : (selectedTask ?? this.selectedTask),
      failure: clearFailure ? null : (failure ?? this.failure),
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        selectedTask,
        failure,
        isCreating,
        isUpdating,
      ];
}
