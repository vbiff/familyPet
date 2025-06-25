import 'package:test/test.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';

void main() {
  group('Task Entity Tests', () {
    group('TaskStatus enum', () {
      test('should identify status correctly', () {
        expect(TaskStatus.pending.isPending, isTrue);
        expect(TaskStatus.inProgress.isInProgress, isTrue);
        expect(TaskStatus.completed.isCompleted, isTrue);
        expect(TaskStatus.expired.isExpired, isTrue);

        expect(TaskStatus.pending.isCompleted, isFalse);
        expect(TaskStatus.inProgress.isPending, isFalse);
        expect(TaskStatus.completed.isExpired, isFalse);
        expect(TaskStatus.expired.isInProgress, isFalse);
      });
    });

    group('TaskFrequency enum', () {
      test('should identify recurring tasks correctly', () {
        expect(TaskFrequency.once.isRecurring, isFalse);
        expect(TaskFrequency.daily.isRecurring, isTrue);
        expect(TaskFrequency.weekly.isRecurring, isTrue);
        expect(TaskFrequency.monthly.isRecurring, isTrue);
      });
    });

    group('Task class', () {
      late Task testTask;
      late DateTime testDate;
      late DateTime futureDate;
      late DateTime pastDate;

      setUp(() {
        testDate = DateTime(2024, 1, 1, 12, 0, 0);
        futureDate = testDate.add(const Duration(days: 7));
        pastDate = testDate.subtract(const Duration(days: 1));

        testTask = Task(
          id: 'task-123',
          title: 'Clean Room',
          description: 'Clean and organize your bedroom',
          points: 50,
          status: TaskStatus.pending,
          assignedTo: 'child-1',
          createdBy: 'parent-1',
          dueDate: futureDate,
          frequency: TaskFrequency.weekly,
          verifiedById: null,
          familyId: 'family-123',
          imageUrls: const ['before.jpg', 'after.jpg'],
          createdAt: testDate,
          completedAt: null,
          verifiedAt: null,
          metadata: const {'difficulty': 'medium'},
        );
      });

      test('should create task with all properties', () {
        expect(testTask.id, 'task-123');
        expect(testTask.title, 'Clean Room');
        expect(testTask.description, 'Clean and organize your bedroom');
        expect(testTask.points, 50);
        expect(testTask.status, TaskStatus.pending);
        expect(testTask.assignedTo, 'child-1');
        expect(testTask.createdBy, 'parent-1');
        expect(testTask.dueDate, futureDate);
        expect(testTask.frequency, TaskFrequency.weekly);
        expect(testTask.verifiedById, isNull);
        expect(testTask.familyId, 'family-123');
        expect(testTask.imageUrls, ['before.jpg', 'after.jpg']);
        expect(testTask.createdAt, testDate);
        expect(testTask.completedAt, isNull);
        expect(testTask.verifiedAt, isNull);
        expect(testTask.metadata, {'difficulty': 'medium'});
      });

      test('should create task with minimal properties', () {
        final minimalTask = Task(
          id: 'minimal-task',
          title: 'Simple Task',
          description: 'A simple task',
          points: 10,
          status: TaskStatus.pending,
          assignedTo: 'child-2',
          createdBy: 'parent-2',
          dueDate: futureDate,
          frequency: TaskFrequency.once,
          familyId: 'family-456',
          createdAt: testDate,
        );

        expect(minimalTask.verifiedById, isNull);
        expect(minimalTask.imageUrls, isEmpty);
        expect(minimalTask.completedAt, isNull);
        expect(minimalTask.verifiedAt, isNull);
        expect(minimalTask.metadata, isNull);
      });

      group('Computed properties', () {
        test('isOverdue should return false for future dates', () {
          final futureTask = testTask.copyWith(
            dueDate: DateTime.now().add(const Duration(days: 1)),
          );
          expect(futureTask.isOverdue, isFalse);
        });

        test('isOverdue should return true for past dates', () {
          final overdueTask = testTask.copyWith(dueDate: pastDate);
          expect(overdueTask.isOverdue, isTrue);
        });

        test('hasImages should return true when images exist', () {
          expect(testTask.hasImages, isTrue);
        });

        test('hasImages should return false when no images', () {
          final noImagesTask = testTask.copyWith(imageUrls: []);
          expect(noImagesTask.hasImages, isFalse);
        });

        test('isVerifiedByParent should return false when not verified', () {
          expect(testTask.isVerifiedByParent, isFalse);
        });

        test('isVerifiedByParent should return true when verified', () {
          final verifiedTask = testTask.copyWith(verifiedById: 'parent-1');
          expect(verifiedTask.isVerifiedByParent, isTrue);
        });

        test('needsVerification should return false for pending tasks', () {
          expect(testTask.needsVerification, isFalse);
        });

        test(
            'needsVerification should return true for completed unverified tasks',
            () {
          final completedTask = testTask.copyWith(
            status: TaskStatus.completed,
            completedAt: testDate,
          );
          expect(completedTask.needsVerification, isTrue);
        });

        test(
            'needsVerification should return false for completed verified tasks',
            () {
          final verifiedCompletedTask = testTask.copyWith(
            status: TaskStatus.completed,
            completedAt: testDate,
            verifiedById: 'parent-1',
            verifiedAt: testDate,
          );
          expect(verifiedCompletedTask.needsVerification, isFalse);
        });
      });

      group('copyWith method', () {
        test('should create copy with updated properties', () {
          final updatedTask = testTask.copyWith(
            title: 'Updated Clean Room',
            status: TaskStatus.completed,
            points: 75,
            completedAt: testDate,
            verifiedById: 'parent-1',
            verifiedAt: testDate,
          );

          expect(updatedTask.id, testTask.id);
          expect(updatedTask.title, 'Updated Clean Room');
          expect(updatedTask.status, TaskStatus.completed);
          expect(updatedTask.points, 75);
          expect(updatedTask.completedAt, testDate);
          expect(updatedTask.verifiedById, 'parent-1');
          expect(updatedTask.verifiedAt, testDate);
          expect(updatedTask.assignedTo, testTask.assignedTo);
        });

        test(
            'should preserve existing values when copyWith called without changes',
            () {
          final updatedTask = testTask.copyWith();

          expect(updatedTask.verifiedById, testTask.verifiedById);
          expect(updatedTask.metadata, testTask.metadata);
          expect(updatedTask.title, testTask.title);
          expect(updatedTask.status, testTask.status);
        });
      });

      group('Task lifecycle scenarios', () {
        test('should handle task creation to completion flow', () {
          // Start with pending task
          expect(testTask.status, TaskStatus.pending);
          expect(testTask.needsVerification, isFalse);
          expect(testTask.isVerifiedByParent, isFalse);

          // Move to in progress
          final inProgressTask = testTask.copyWith(
            status: TaskStatus.inProgress,
          );
          expect(inProgressTask.status.isInProgress, isTrue);
          expect(inProgressTask.needsVerification, isFalse);

          // Complete the task
          final completedTask = inProgressTask.copyWith(
            status: TaskStatus.completed,
            completedAt: testDate,
          );
          expect(completedTask.status.isCompleted, isTrue);
          expect(completedTask.needsVerification, isTrue);
          expect(completedTask.isVerifiedByParent, isFalse);

          // Verify the task
          final verifiedTask = completedTask.copyWith(
            verifiedById: 'parent-1',
            verifiedAt: testDate,
          );
          expect(verifiedTask.needsVerification, isFalse);
          expect(verifiedTask.isVerifiedByParent, isTrue);
        });

        test('should handle task expiration', () {
          final expiredTask = testTask.copyWith(
            status: TaskStatus.expired,
            dueDate: pastDate,
          );

          expect(expiredTask.status.isExpired, isTrue);
          expect(expiredTask.isOverdue, isTrue);
          expect(expiredTask.needsVerification, isFalse);
        });
      });

      group('Equality and hashCode', () {
        test('should be equal when all properties are same', () {
          final sameTask = Task(
            id: 'task-123',
            title: 'Clean Room',
            description: 'Clean and organize your bedroom',
            points: 50,
            status: TaskStatus.pending,
            assignedTo: 'child-1',
            createdBy: 'parent-1',
            dueDate: futureDate,
            frequency: TaskFrequency.weekly,
            verifiedById: null,
            familyId: 'family-123',
            imageUrls: const ['before.jpg', 'after.jpg'],
            createdAt: testDate,
            completedAt: null,
            verifiedAt: null,
            metadata: const {'difficulty': 'medium'},
          );

          expect(testTask, equals(sameTask));
          expect(testTask.hashCode, equals(sameTask.hashCode));
        });

        test('should not be equal when properties differ', () {
          final differentTask = testTask.copyWith(title: 'Different Task');

          expect(testTask, isNot(equals(differentTask)));
          expect(testTask.hashCode, isNot(equals(differentTask.hashCode)));
        });

        test('should include all properties in props', () {
          expect(testTask.props, [
            'task-123',
            'Clean Room',
            'Clean and organize your bedroom',
            50,
            TaskStatus.pending,
            'child-1',
            'parent-1',
            futureDate,
            TaskFrequency.weekly,
            null,
            'family-123',
            ['before.jpg', 'after.jpg'],
            testDate,
            null,
            null,
            {'difficulty': 'medium'},
          ]);
        });
      });
    });
  });
}
