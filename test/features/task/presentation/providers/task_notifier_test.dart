import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/usecases/create_task.dart';
import 'package:jhonny/features/task/domain/usecases/delete_task.dart';
import 'package:jhonny/features/task/domain/usecases/get_tasks.dart';
import 'package:jhonny/features/task/domain/usecases/update_task_status.dart';
import 'package:jhonny/features/task/presentation/providers/task_notifier.dart';
import 'package:jhonny/features/task/presentation/providers/task_state.dart';

// Mock classes
class MockGetTasks extends Mock implements GetTasks {
  @override
  Future<Either<Failure, List<Task>>> call(GetTasksParams params) =>
      super.noSuchMethod(
        Invocation.method(#call, [params]),
        returnValue: Future.value(const Right([])),
      );
}

class MockCreateTask extends Mock implements CreateTask {
  @override
  Future<Either<Failure, Task>> call(CreateTaskParams params) =>
      super.noSuchMethod(
        Invocation.method(#call, [params]),
        returnValue: Future.value(Right(Task(
          id: 'mock',
          title: 'mock',
          description: 'mock',
          points: 0,
          status: TaskStatus.pending,
          assignedTo: 'mock',
          createdBy: 'mock',
          dueDate: DateTime.now(),
          frequency: TaskFrequency.once,
          familyId: 'mock',
          imageUrls: const [],
          createdAt: DateTime.now(),
        ))),
      );
}

class MockUpdateTaskStatus extends Mock implements UpdateTaskStatus {
  @override
  Future<Either<Failure, Task>> call(UpdateTaskStatusParams params) =>
      super.noSuchMethod(
        Invocation.method(#call, [params]),
        returnValue: Future.value(Right(Task(
          id: 'mock',
          title: 'mock',
          description: 'mock',
          points: 0,
          status: TaskStatus.pending,
          assignedTo: 'mock',
          createdBy: 'mock',
          dueDate: DateTime.now(),
          frequency: TaskFrequency.once,
          familyId: 'mock',
          imageUrls: const [],
          createdAt: DateTime.now(),
        ))),
      );
}

class MockDeleteTask extends Mock implements DeleteTask {
  @override
  Future<Either<Failure, void>> call(DeleteTaskParams params) =>
      super.noSuchMethod(
        Invocation.method(#call, [params]),
        returnValue: Future.value(const Right(null)),
      );
}

void main() {
  group('TaskNotifier Tests', () {
    late TaskNotifier taskNotifier;
    late MockGetTasks mockGetTasks;
    late MockCreateTask mockCreateTask;
    late MockUpdateTaskStatus mockUpdateTaskStatus;
    late MockDeleteTask mockDeleteTask;

    setUp(() {
      mockGetTasks = MockGetTasks();
      mockCreateTask = MockCreateTask();
      mockUpdateTaskStatus = MockUpdateTaskStatus();
      mockDeleteTask = MockDeleteTask();

      taskNotifier = TaskNotifier(
        getTasks: mockGetTasks,
        createTask: mockCreateTask,
        updateTaskStatus: mockUpdateTaskStatus,
        deleteTask: mockDeleteTask,
      );
    });

    final DateTime testDate = DateTime(2024, 1, 1, 12, 0);
    final List<Task> testTasks = [
      Task(
        id: 'task-1',
        title: 'Clean Room',
        description: 'Clean and organize bedroom',
        points: 50,
        status: TaskStatus.pending,
        assignedTo: 'child-1',
        createdBy: 'parent-1',
        dueDate: testDate.add(const Duration(days: 1)),
        frequency: TaskFrequency.weekly,
        familyId: 'family-123',
        imageUrls: const [],
        createdAt: testDate,
      ),
      Task(
        id: 'task-2',
        title: 'Do Homework',
        description: 'Complete math homework',
        points: 30,
        status: TaskStatus.completed,
        assignedTo: 'child-1',
        createdBy: 'parent-1',
        dueDate: testDate.add(const Duration(days: 2)),
        frequency: TaskFrequency.daily,
        familyId: 'family-123',
        imageUrls: const [],
        createdAt: testDate,
        completedAt: testDate,
        verifiedById: 'parent-1',
        verifiedAt: testDate,
      ),
    ];

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(taskNotifier.state.status, TaskStateStatus.initial);
        expect(taskNotifier.state.tasks, isEmpty);
        expect(taskNotifier.state.selectedTask, isNull);
        expect(taskNotifier.state.failure, isNull);
        expect(taskNotifier.state.isCreating, isFalse);
        expect(taskNotifier.state.isUpdating, isFalse);
      });
    });

    group('loadTasks', () {
      test('should emit loading then success when getTasks succeeds', () async {
        // arrange
        when(mockGetTasks.call(const GetTasksParams(familyId: 'family-123')))
            .thenAnswer((_) async => Right(testTasks));

        // act
        await taskNotifier.loadTasks(familyId: 'family-123');

        // assert
        expect(taskNotifier.state.status, TaskStateStatus.success);
        expect(taskNotifier.state.tasks, testTasks);
        expect(taskNotifier.state.failure, isNull);

        verify(mockGetTasks.call(const GetTasksParams(familyId: 'family-123')))
            .called(1);
      });

      test('should emit loading then error when getTasks fails', () async {
        const failure = ServerFailure(message: 'Network error');

        // arrange
        when(mockGetTasks.call(const GetTasksParams(familyId: 'family-123')))
            .thenAnswer((_) async => const Left(failure));

        // act
        await taskNotifier.loadTasks(familyId: 'family-123');

        // assert
        expect(taskNotifier.state.status, TaskStateStatus.error);
        expect(taskNotifier.state.tasks, isEmpty);
        expect(taskNotifier.state.failure, failure);
      });

      test('should pass correct parameters to getTasks', () async {
        const params = GetTasksParams(
          familyId: 'family-123',
          assignedTo: 'child-1',
          status: TaskStatus.pending,
        );

        // arrange
        when(mockGetTasks.call(params))
            .thenAnswer((_) async => Right(testTasks));

        // act
        await taskNotifier.loadTasks(
          familyId: 'family-123',
          assignedTo: 'child-1',
          status: TaskStatus.pending,
        );

        // assert
        verify(mockGetTasks.call(params)).called(1);
      });
    });

    group('createNewTask', () {
      test('should emit creating then success when createTask succeeds',
          () async {
        final newTask = testTasks.first;
        final params = CreateTaskParams(
          title: 'New Task',
          description: 'New task description',
          points: 25,
          assignedTo: 'child-1',
          createdBy: 'parent-1',
          dueDate: testDate.add(const Duration(days: 1)),
          frequency: TaskFrequency.once,
          familyId: 'family-123',
        );

        // arrange
        when(mockCreateTask.call(params))
            .thenAnswer((_) async => Right(newTask));
        taskNotifier.state = taskNotifier.state.copyWith(tasks: []);

        // act
        await taskNotifier.createNewTask(
          title: 'New Task',
          description: 'New task description',
          points: 25,
          assignedTo: 'child-1',
          createdBy: 'parent-1',
          dueDate: testDate.add(const Duration(days: 1)),
          frequency: TaskFrequency.once,
          familyId: 'family-123',
        );

        // assert
        expect(taskNotifier.state.isCreating, isFalse);
        expect(taskNotifier.state.tasks, contains(newTask));
        expect(taskNotifier.state.selectedTask, newTask);
        expect(taskNotifier.state.failure, isNull);

        verify(mockCreateTask.call(params)).called(1);
      });

      test('should emit creating then error when createTask fails', () async {
        const failure = ValidationFailure(message: 'Title is required');
        final failParams = CreateTaskParams(
          title: '',
          description: 'Task description',
          points: 25,
          assignedTo: 'child-1',
          createdBy: 'parent-1',
          dueDate: testDate.add(const Duration(days: 1)),
          frequency: TaskFrequency.once,
          familyId: 'family-123',
        );

        // arrange
        when(mockCreateTask.call(failParams))
            .thenAnswer((_) async => const Left(failure));

        // act
        await taskNotifier.createNewTask(
          title: '',
          description: 'Task description',
          points: 25,
          assignedTo: 'child-1',
          createdBy: 'parent-1',
          dueDate: testDate.add(const Duration(days: 1)),
          frequency: TaskFrequency.once,
          familyId: 'family-123',
        );

        // assert
        expect(taskNotifier.state.isCreating, isFalse);
        expect(taskNotifier.state.failure, failure);
        expect(taskNotifier.state.tasks, isEmpty);
      });
    });

    group('updateTaskStatus', () {
      test('should update task in list when updateTaskStatus succeeds',
          () async {
        final originalTask = testTasks.first;
        final updatedTask = originalTask.copyWith(
          status: TaskStatus.completed,
          completedAt: testDate,
        );
        const params = UpdateTaskStatusParams(
          taskId: 'task-1',
          status: TaskStatus.completed,
        );

        // arrange
        when(mockUpdateTaskStatus.call(params))
            .thenAnswer((_) async => Right(updatedTask));
        taskNotifier.state = taskNotifier.state.copyWith(tasks: [originalTask]);

        // act
        await taskNotifier.updateTaskStatus(
          taskId: originalTask.id,
          status: TaskStatus.completed,
        );

        // assert
        expect(taskNotifier.state.isUpdating, isFalse);
        expect(taskNotifier.state.tasks.first.status, TaskStatus.completed);
        expect(taskNotifier.state.tasks.first.completedAt, testDate);
        expect(taskNotifier.state.failure, isNull);

        verify(mockUpdateTaskStatus.call(params)).called(1);
      });

      test('should update selectedTask when it matches updated task', () async {
        final originalTask = testTasks.first;
        final updatedTask = originalTask.copyWith(status: TaskStatus.completed);
        const params = UpdateTaskStatusParams(
          taskId: 'task-1',
          status: TaskStatus.completed,
        );

        // arrange
        when(mockUpdateTaskStatus.call(params))
            .thenAnswer((_) async => Right(updatedTask));
        taskNotifier.state = taskNotifier.state.copyWith(
          tasks: [originalTask],
          selectedTask: originalTask,
        );

        // act
        await taskNotifier.updateTaskStatus(
          taskId: originalTask.id,
          status: TaskStatus.completed,
        );

        // assert
        expect(taskNotifier.state.selectedTask?.status, TaskStatus.completed);
      });

      test('should handle verification with clearVerification flag', () async {
        final verifiedTask = testTasks[1]; // Already verified task
        final unverifiedTask = verifiedTask.copyWith(
          verifiedById: null,
          verifiedAt: null,
        );
        const params = UpdateTaskStatusParams(
          taskId: 'task-2',
          status: TaskStatus.completed,
          clearVerification: true,
        );

        // arrange
        when(mockUpdateTaskStatus.call(params))
            .thenAnswer((_) async => Right(unverifiedTask));
        taskNotifier.state = taskNotifier.state.copyWith(tasks: [verifiedTask]);

        // act
        await taskNotifier.updateTaskStatus(
          taskId: verifiedTask.id,
          status: TaskStatus.completed,
          clearVerification: true,
        );

        // assert
        expect(taskNotifier.state.tasks.first.verifiedById, isNull);
        expect(taskNotifier.state.tasks.first.verifiedAt, isNull);

        verify(mockUpdateTaskStatus.call(params)).called(1);
      });

      test('should emit error when updateTaskStatus fails', () async {
        const failure = ServerFailure(message: 'Update failed');
        const params = UpdateTaskStatusParams(
          taskId: 'task-1',
          status: TaskStatus.completed,
        );

        // arrange
        when(mockUpdateTaskStatus.call(params))
            .thenAnswer((_) async => const Left(failure));

        // act
        await taskNotifier.updateTaskStatus(
          taskId: 'task-1',
          status: TaskStatus.completed,
        );

        // assert
        expect(taskNotifier.state.isUpdating, isFalse);
        expect(taskNotifier.state.failure, failure);
      });
    });

    group('deleteTask', () {
      test('should remove task from list when deleteTask succeeds', () async {
        final taskToDelete = testTasks.first;
        const params = DeleteTaskParams(taskId: 'task-1');

        // arrange
        when(mockDeleteTask.call(params))
            .thenAnswer((_) async => const Right(null));
        taskNotifier.state = taskNotifier.state.copyWith(tasks: testTasks);

        // act
        await taskNotifier.deleteTask(taskToDelete.id);

        // assert
        expect(taskNotifier.state.isUpdating, isFalse);
        expect(taskNotifier.state.tasks, hasLength(1));
        expect(
            taskNotifier.state.tasks.any((task) => task.id == taskToDelete.id),
            isFalse);
        expect(taskNotifier.state.failure, isNull);

        verify(mockDeleteTask.call(params)).called(1);
      });

      test('should clear selectedTask when deleted task was selected',
          () async {
        final taskToDelete = testTasks.first;
        const params = DeleteTaskParams(taskId: 'task-1');

        // arrange
        when(mockDeleteTask.call(params))
            .thenAnswer((_) async => const Right(null));
        taskNotifier.state = taskNotifier.state.copyWith(
          tasks: [taskToDelete],
          selectedTask: taskToDelete,
        );

        // act
        await taskNotifier.deleteTask(taskToDelete.id);

        // assert
        expect(taskNotifier.state.selectedTask, isNull);
      });

      test('should not clear selectedTask when different task is deleted',
          () async {
        final taskToDelete = testTasks.first;
        final selectedTask = testTasks[1];
        const params = DeleteTaskParams(taskId: 'task-1');

        // arrange
        when(mockDeleteTask.call(params))
            .thenAnswer((_) async => const Right(null));
        taskNotifier.state = taskNotifier.state.copyWith(
          tasks: testTasks,
          selectedTask: selectedTask,
        );

        // act
        await taskNotifier.deleteTask(taskToDelete.id);

        // assert
        expect(taskNotifier.state.selectedTask, selectedTask);
      });
    });

    group('Helper methods', () {
      test('selectTask should set selectedTask', () {
        final task = testTasks.first;

        // act
        taskNotifier.selectTask(task);

        // assert
        expect(taskNotifier.state.selectedTask, task);
      });

      test('clearSelectedTask should set selectedTask to null', () {
        // arrange
        taskNotifier.state =
            taskNotifier.state.copyWith(selectedTask: testTasks.first);

        // act
        taskNotifier.clearSelectedTask();

        // assert
        expect(taskNotifier.state.selectedTask, isNull);
      });

      test('clearError should set failure to null', () {
        const failure = ServerFailure(message: 'Test error');

        // arrange
        taskNotifier.state = taskNotifier.state.copyWith(failure: failure);

        // act
        taskNotifier.clearError();

        // assert
        expect(taskNotifier.state.failure, isNull);
      });
    });

    group('Filtered task getters', () {
      setUp(() {
        taskNotifier.state = taskNotifier.state.copyWith(tasks: testTasks);
      });

      test('pendingTasks should return only pending tasks', () {
        final pendingTasks = taskNotifier.pendingTasks;

        expect(pendingTasks, hasLength(1));
        expect(pendingTasks.first.status, TaskStatus.pending);
      });

      test('completedTasks should return only completed tasks', () {
        final completedTasks = taskNotifier.completedTasks;

        expect(completedTasks, hasLength(1));
        expect(completedTasks.first.status, TaskStatus.completed);
      });

      test('overdueTasks should return only overdue tasks', () {
        final overdueTask = testTasks.first.copyWith(
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        taskNotifier.state = taskNotifier.state.copyWith(tasks: [overdueTask]);

        final overdueTasks = taskNotifier.overdueTasks;

        expect(overdueTasks, hasLength(1));
        expect(overdueTasks.first.isOverdue, isTrue);
      });

      test('tasksNeedingVerification should return completed unverified tasks',
          () {
        final unverifiedTask = testTasks[1].copyWith(
          verifiedById: null,
          verifiedAt: null,
        );
        taskNotifier.state =
            taskNotifier.state.copyWith(tasks: [unverifiedTask]);

        final needingVerification = taskNotifier.tasksNeedingVerification;

        expect(needingVerification, hasLength(1));
        expect(needingVerification.first.needsVerification, isTrue);
      });

      test('getTasksForUser should return tasks for specific user', () {
        final userTasks = taskNotifier.getTasksForUser('child-1');

        expect(userTasks, hasLength(2));
        expect(userTasks.every((task) => task.assignedTo == 'child-1'), isTrue);
      });
    });
  });
}
