import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';
import 'package:jhonny/features/task/data/datasources/task_comment_remote_datasource.dart';
import 'package:jhonny/features/task/data/repositories/supabase_task_comment_repository.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';
import 'package:jhonny/features/task/domain/repositories/task_comment_repository.dart';
import 'package:jhonny/features/task/domain/usecases/get_task_comments.dart';
import 'package:jhonny/features/task/domain/usecases/create_task_comment.dart';
import 'package:jhonny/features/task/domain/usecases/delete_task_comment.dart';
import 'package:jhonny/features/task/presentation/providers/task_comment_notifier.dart';
import 'package:jhonny/features/task/presentation/providers/task_comment_state.dart';

// Data Source
final taskCommentRemoteDataSourceProvider =
    Provider<TaskCommentRemoteDataSource>((ref) {
  final client = ref.read(supabaseClientProvider);
  final logger = Logger();
  return SupabaseTaskCommentRemoteDataSource(client, logger);
});

// Repository
final taskCommentRepositoryProvider = Provider<TaskCommentRepository>((ref) {
  final remoteDataSource = ref.read(taskCommentRemoteDataSourceProvider);
  const uuid = Uuid();
  return SupabaseTaskCommentRepository(remoteDataSource, uuid);
});

// Use Cases
final getTaskCommentsProvider = Provider<GetTaskComments>((ref) {
  final repository = ref.read(taskCommentRepositoryProvider);
  return GetTaskComments(repository);
});

final createTaskCommentProvider = Provider<CreateTaskComment>((ref) {
  final repository = ref.read(taskCommentRepositoryProvider);
  return CreateTaskComment(repository);
});

final deleteTaskCommentProvider = Provider<DeleteTaskComment>((ref) {
  final repository = ref.read(taskCommentRepositoryProvider);
  return DeleteTaskComment(repository);
});

// Notifier
final taskCommentNotifierProvider =
    StateNotifierProvider<TaskCommentNotifier, TaskCommentState>((ref) {
  final getTaskComments = ref.read(getTaskCommentsProvider);
  final createTaskComment = ref.read(createTaskCommentProvider);
  final deleteTaskComment = ref.read(deleteTaskCommentProvider);

  return TaskCommentNotifier(
    getTaskComments: getTaskComments,
    createTaskComment: createTaskComment,
    deleteTaskComment: deleteTaskComment,
  );
});

// Stream provider for real-time comments
final taskCommentsStreamProvider =
    StreamProvider.family<List<TaskComment>, String>((ref, taskId) {
  final repository = ref.read(taskCommentRepositoryProvider);
  return repository.watchComments(taskId);
});

// Helper providers
final taskCommentLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(taskCommentNotifierProvider);
  return state.status == TaskCommentStateStatus.loading;
});

final taskCommentCreatingProvider = Provider<bool>((ref) {
  final state = ref.watch(taskCommentNotifierProvider);
  return state.isCreating;
});
