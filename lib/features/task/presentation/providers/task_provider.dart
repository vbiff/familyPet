import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';
import 'package:jhonny/features/task/data/datasources/task_remote_datasource.dart';
import 'package:jhonny/features/task/data/repositories/supabase_task_repository.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';
import 'package:jhonny/features/task/domain/usecases/create_task.dart';
import 'package:jhonny/features/task/domain/usecases/delete_task.dart';
import 'package:jhonny/features/task/domain/usecases/delete_task_permanently.dart';
import 'package:jhonny/features/task/domain/usecases/get_tasks.dart';
import 'package:jhonny/features/task/domain/usecases/update_task_status.dart';
import 'package:jhonny/features/task/domain/usecases/update_task.dart';
import 'package:jhonny/features/task/presentation/providers/task_notifier.dart';
import 'package:jhonny/features/task/presentation/providers/task_state.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_provider.dart';

// Data Source Provider
final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseTaskRemoteDataSource(supabaseClient);
});

// UUID Provider
final uuidProvider = Provider<Uuid>((ref) => const Uuid());

// Repository Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remoteDataSource = ref.watch(taskRemoteDataSourceProvider);
  final uuid = ref.watch(uuidProvider);
  return SupabaseTaskRepository(remoteDataSource, uuid);
});

// Use Case Providers
final getTasksUseCaseProvider = Provider<GetTasks>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetTasks(repository);
});

final createTaskUseCaseProvider = Provider<CreateTask>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return CreateTask(repository);
});

final updateTaskStatusUseCaseProvider = Provider<UpdateTaskStatus>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return UpdateTaskStatus(repository);
});

final updateTaskUseCaseProvider = Provider<UpdateTask>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return UpdateTask(repository);
});

final deleteTaskUseCaseProvider = Provider<DeleteTask>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return DeleteTask(repository);
});

final deleteTaskPermanentlyUseCaseProvider =
    Provider<DeleteTaskPermanently>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return DeleteTaskPermanently(repository);
});

// Main Task Notifier Provider
final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final getTasks = ref.watch(getTasksUseCaseProvider);
  final createTask = ref.watch(createTaskUseCaseProvider);
  final updateTaskStatus = ref.watch(updateTaskStatusUseCaseProvider);
  final deleteTask = ref.watch(deleteTaskUseCaseProvider);
  final deleteTaskPermanently = ref.watch(deleteTaskPermanentlyUseCaseProvider);
  final updateTask = ref.watch(updateTaskUseCaseProvider);

  return TaskNotifier(
    getTasks: getTasks,
    createTask: createTask,
    updateTaskStatus: updateTaskStatus,
    deleteTask: deleteTask,
    deleteTaskPermanently: deleteTaskPermanently,
    updateTask: updateTask,
    onTaskCompleted: (experiencePoints, taskTitle) async {
      // Award pet experience when task is completed
      try {
        await ref.read(petNotifierProvider.notifier).addExperienceFromTask(
              experiencePoints: experiencePoints,
              taskTitle: taskTitle,
            );
      } catch (e) {
        // Check for disposed ref errors specifically and handle silently
        if (e.toString().contains('disposed') ||
            e.toString().contains('Bad state')) {
          debugPrint('Provider was disposed during pet experience award');
          return; // Silently return for disposed ref errors
        }

        // Only log other types of errors
        debugPrint('Error awarding pet experience: $e');
      }
    },
  );
});

// Convenience providers for accessing specific state
final tasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskNotifierProvider).tasks;
});

final pendingTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskNotifierProvider).tasks;
  return tasks.where((task) => task.status.isPending).toList();
});

final completedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskNotifierProvider).tasks;
  return tasks.where((task) => task.status.isCompleted).toList();
});

final overdueTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskNotifierProvider).tasks;
  return tasks.where((task) => task.isOverdue).toList();
});

final tasksNeedingVerificationProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskNotifierProvider).tasks;
  return tasks.where((task) => task.needsVerification).toList();
});

final selectedTaskProvider = Provider<Task?>((ref) {
  return ref.watch(taskNotifierProvider).selectedTask;
});

final taskLoadingProvider = Provider<bool>((ref) {
  return ref.watch(taskNotifierProvider).status == TaskStateStatus.loading;
});

final taskCreatingProvider = Provider<bool>((ref) {
  return ref.watch(taskNotifierProvider).isCreating;
});

final taskUpdatingProvider = Provider<bool>((ref) {
  return ref.watch(taskNotifierProvider).isUpdating;
});

// User-specific task providers
final userTasksProvider = Provider.family<List<Task>, String>((ref, userId) {
  final tasks = ref.watch(taskNotifierProvider).tasks;
  return tasks.where((task) => task.assignedTo == userId).toList();
});

// Real-time task stream provider
final taskStreamProvider =
    StreamProvider.family<List<Task>, String>((ref, familyId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasks(familyId: familyId);
});
