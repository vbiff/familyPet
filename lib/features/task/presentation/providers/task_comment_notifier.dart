import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';
import 'package:jhonny/features/task/domain/usecases/get_task_comments.dart';
import 'package:jhonny/features/task/domain/usecases/create_task_comment.dart';
import 'package:jhonny/features/task/domain/usecases/delete_task_comment.dart';
import 'package:jhonny/features/task/presentation/providers/task_comment_state.dart';

class TaskCommentNotifier extends StateNotifier<TaskCommentState> {
  final GetTaskComments _getTaskComments;
  final CreateTaskComment _createTaskComment;
  final DeleteTaskComment _deleteTaskComment;

  TaskCommentNotifier({
    required GetTaskComments getTaskComments,
    required CreateTaskComment createTaskComment,
    required DeleteTaskComment deleteTaskComment,
  })  : _getTaskComments = getTaskComments,
        _createTaskComment = createTaskComment,
        _deleteTaskComment = deleteTaskComment,
        super(const TaskCommentState());

  Future<void> loadComments(String taskId) async {
    state = state.copyWith(
      status: TaskCommentStateStatus.loading,
      clearFailure: true,
    );

    final result = await _getTaskComments(taskId);

    result.fold(
      (failure) => state = state.copyWith(
        status: TaskCommentStateStatus.error,
        failure: failure,
      ),
      (comments) => state = state.copyWith(
        status: TaskCommentStateStatus.success,
        comments: comments,
      ),
    );
  }

  Future<bool> createComment({
    required String taskId,
    required String authorId,
    required String content,
  }) async {
    state = state.copyWith(
      isCreating: true,
      clearFailure: true,
    );

    final result = await _createTaskComment(CreateTaskCommentParams(
      taskId: taskId,
      authorId: authorId,
      content: content,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          failure: failure,
        );
        return false;
      },
      (comment) {
        final updatedComments = List<TaskComment>.from(state.comments)
          ..insert(0, comment);
        state = state.copyWith(
          isCreating: false,
          comments: updatedComments,
        );
        return true;
      },
    );
  }

  Future<bool> deleteComment(String commentId) async {
    state = state.copyWith(
      isDeleting: true,
      clearFailure: true,
    );

    final result = await _deleteTaskComment(commentId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          failure: failure,
        );
        return false;
      },
      (_) {
        final updatedComments =
            state.comments.where((comment) => comment.id != commentId).toList();
        state = state.copyWith(
          isDeleting: false,
          comments: updatedComments,
        );
        return true;
      },
    );
  }

  void clearState() {
    state = const TaskCommentState();
  }
}
