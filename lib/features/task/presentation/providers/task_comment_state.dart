import 'package:equatable/equatable.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';

enum TaskCommentStateStatus {
  initial,
  loading,
  success,
  error,
}

class TaskCommentState extends Equatable {
  final TaskCommentStateStatus status;
  final List<TaskComment> comments;
  final Failure? failure;
  final bool isCreating;
  final bool isDeleting;

  const TaskCommentState({
    this.status = TaskCommentStateStatus.initial,
    this.comments = const [],
    this.failure,
    this.isCreating = false,
    this.isDeleting = false,
  });

  TaskCommentState copyWith({
    TaskCommentStateStatus? status,
    List<TaskComment>? comments,
    Failure? failure,
    bool? isCreating,
    bool? isDeleting,
    bool clearFailure = false,
  }) {
    return TaskCommentState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      failure: clearFailure ? null : (failure ?? this.failure),
      isCreating: isCreating ?? this.isCreating,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  @override
  List<Object?> get props => [
        status,
        comments,
        failure,
        isCreating,
        isDeleting,
      ];
}
