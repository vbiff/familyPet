import 'package:test/test.dart';
import 'package:jhonny/features/task/data/models/task_model.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';

void main() {
  group('TaskModel Tests', () {
    final DateTime testCreatedAt = DateTime(2024, 1, 1, 10, 0);
    final DateTime testDueDate = DateTime(2024, 1, 2, 15, 30);
    final DateTime testCompletedAt = DateTime(2024, 1, 2, 14, 0);
    final DateTime testVerifiedAt = DateTime(2024, 1, 2, 16, 0);

    const Map<String, dynamic> validJson = {
      'id': 'task-123',
      'title': 'Clean Room',
      'description': 'Clean and organize your bedroom',
      'points': 50,
      'status': 'pending',
      'assigned_to_id': 'child-1',
      'created_by_id': 'parent-1',
      'due_date': '2024-01-02T15:30:00.000Z',
      'frequency': 'weekly',
      'family_id': 'family-123',
      'image_urls': ['before.jpg', 'after.jpg'],
      'created_at': '2024-01-01T10:00:00.000Z',
      'completed_at': '2024-01-02T14:00:00.000Z',
      'verified_at': '2024-01-02T16:00:00.000Z',
      'verified_by_id': 'parent-1',
    };

    const Map<String, dynamic> minimalJson = {
      'id': 'task-minimal',
      'title': 'Simple Task',
      'description': 'A simple task',
      'points': 10,
      'status': 'pending',
      'assigned_to_id': 'child-2',
      'created_by_id': 'parent-2',
      'due_date': '2024-01-02T15:30:00.000Z',
      'frequency': 'once',
      'family_id': 'family-456',
      'created_at': '2024-01-01T10:00:00.000Z',
    };

    final TaskModel testTaskModel = TaskModel(
      id: 'task-123',
      title: 'Clean Room',
      description: 'Clean and organize your bedroom',
      points: 50,
      status: TaskStatus.pending,
      assignedTo: 'child-1',
      createdBy: 'parent-1',
      dueDate: testDueDate,
      frequency: TaskFrequency.weekly,
      familyId: 'family-123',
      imageUrls: const ['before.jpg', 'after.jpg'],
      createdAt: testCreatedAt,
      completedAt: testCompletedAt,
      verifiedAt: testVerifiedAt,
      verifiedById: 'parent-1',
      metadata: const {'difficulty': 'medium'},
    );

    group('fromJson', () {
      test('should create TaskModel from complete JSON', () {
        // act
        final result = TaskModel.fromJson(validJson);

        // assert
        expect(result.id, 'task-123');
        expect(result.title, 'Clean Room');
        expect(result.description, 'Clean and organize your bedroom');
        expect(result.points, 50);
        expect(result.status, TaskStatus.pending);
        expect(result.assignedTo, 'child-1');
        expect(result.createdBy, 'parent-1');
        expect(result.dueDate, DateTime.parse('2024-01-02T15:30:00.000Z'));
        expect(result.frequency, TaskFrequency.weekly);
        expect(result.familyId, 'family-123');
        expect(result.imageUrls, ['before.jpg', 'after.jpg']);
        expect(result.createdAt, DateTime.parse('2024-01-01T10:00:00.000Z'));
        expect(result.completedAt, DateTime.parse('2024-01-02T14:00:00.000Z'));
        expect(result.verifiedAt, DateTime.parse('2024-01-02T16:00:00.000Z'));
        expect(result.verifiedById, 'parent-1');
      });

      test('should create TaskModel from minimal JSON', () {
        // act
        final result = TaskModel.fromJson(minimalJson);

        // assert
        expect(result.id, 'task-minimal');
        expect(result.title, 'Simple Task');
        expect(result.status, TaskStatus.pending);
        expect(result.frequency, TaskFrequency.once);
        expect(result.imageUrls, isEmpty);
        expect(result.completedAt, isNull);
        expect(result.verifiedAt, isNull);
        expect(result.verifiedById, isNull);
        expect(result.metadata, isNull);
      });

      test('should handle null image_urls', () {
        final jsonWithNullImages = Map<String, dynamic>.from(minimalJson);
        jsonWithNullImages['image_urls'] = null;

        // act
        final result = TaskModel.fromJson(jsonWithNullImages);

        // assert
        expect(result.imageUrls, isEmpty);
      });

      test('should handle missing optional fields', () {
        final jsonWithMissingFields = Map<String, dynamic>.from(minimalJson);
        jsonWithMissingFields.remove('completed_at');
        jsonWithMissingFields.remove('verified_at');
        jsonWithMissingFields.remove('verified_by_id');

        // act
        final result = TaskModel.fromJson(jsonWithMissingFields);

        // assert
        expect(result.completedAt, isNull);
        expect(result.verifiedAt, isNull);
        expect(result.verifiedById, isNull);
      });

      test('should parse all TaskStatus enum values correctly', () {
        final statuses = ['pending', 'inProgress', 'completed', 'expired'];
        final expectedStatuses = [
          TaskStatus.pending,
          TaskStatus.inProgress,
          TaskStatus.completed,
          TaskStatus.expired
        ];

        for (int i = 0; i < statuses.length; i++) {
          final json = Map<String, dynamic>.from(minimalJson);
          json['status'] = statuses[i];

          final result = TaskModel.fromJson(json);
          expect(result.status, expectedStatuses[i]);
        }
      });

      test('should parse all TaskFrequency enum values correctly', () {
        final frequencies = ['once', 'daily', 'weekly', 'monthly'];
        final expectedFrequencies = [
          TaskFrequency.once,
          TaskFrequency.daily,
          TaskFrequency.weekly,
          TaskFrequency.monthly
        ];

        for (int i = 0; i < frequencies.length; i++) {
          final json = Map<String, dynamic>.from(minimalJson);
          json['frequency'] = frequencies[i];

          final result = TaskModel.fromJson(json);
          expect(result.frequency, expectedFrequencies[i]);
        }
      });
    });

    group('toJson', () {
      test('should convert TaskModel to JSON correctly', () {
        // act
        final result = testTaskModel.toJson();

        // assert
        expect(result['id'], 'task-123');
        expect(result['title'], 'Clean Room');
        expect(result['description'], 'Clean and organize your bedroom');
        expect(result['points'], 50);
        expect(result['status'], 'pending');
        expect(result['assigned_to_id'], 'child-1');
        expect(result['created_by_id'], 'parent-1');
        expect(result['due_date'], testDueDate.toIso8601String());
        expect(result['frequency'], 'weekly');
        expect(result['family_id'], 'family-123');
        expect(result['image_urls'], ['before.jpg', 'after.jpg']);
        expect(result['created_at'], testCreatedAt.toIso8601String());
        expect(result['completed_at'], testCompletedAt.toIso8601String());
        expect(result['verified_at'], testVerifiedAt.toIso8601String());
        expect(result['verified_by_id'], 'parent-1');
      });

      test('should handle null values in toJson', () {
        final modelWithNulls = TaskModel(
          id: 'task-null',
          title: 'Null Task',
          description: 'Task with null values',
          points: 10,
          status: TaskStatus.pending,
          assignedTo: 'child-1',
          createdBy: 'parent-1',
          dueDate: testDueDate,
          frequency: TaskFrequency.once,
          familyId: 'family-123',
          imageUrls: const [],
          createdAt: testCreatedAt,
        );

        // act
        final result = modelWithNulls.toJson();

        // assert
        expect(result['completed_at'], isNull);
        expect(result['verified_at'], isNull);
        expect(result['verified_by_id'], isNull);
        expect(result['image_urls'], []);
      });
    });

    group('toCreateJson', () {
      test('should create JSON suitable for database insertion', () {
        // act
        final result = testTaskModel.toCreateJson();

        // assert
        expect(result['id'], 'task-123');
        expect(result['title'], 'Clean Room');
        expect(result['status'], 'pending');
        expect(result['assigned_to_id'], 'child-1');
        expect(result['created_by_id'], 'parent-1');
        expect(result['family_id'], 'family-123');
        expect(result['created_at'], testCreatedAt.toIso8601String());

        // Should not include auto-generated or computed fields
        expect(result.containsKey('completed_at'), isFalse);
        expect(result.containsKey('verified_at'), isFalse);
        expect(result.containsKey('verified_by_id'), isFalse);
      });
    });

    group('Entity conversion', () {
      test('should convert TaskModel to Task entity correctly', () {
        // act
        final result = testTaskModel.toEntity();

        // assert
        expect(result, isA<Task>());
        expect(result.id, testTaskModel.id);
        expect(result.title, testTaskModel.title);
        expect(result.description, testTaskModel.description);
        expect(result.points, testTaskModel.points);
        expect(result.status, testTaskModel.status);
        expect(result.assignedTo, testTaskModel.assignedTo);
        expect(result.createdBy, testTaskModel.createdBy);
        expect(result.dueDate, testTaskModel.dueDate);
        expect(result.frequency, testTaskModel.frequency);
        expect(result.familyId, testTaskModel.familyId);
        expect(result.imageUrls, testTaskModel.imageUrls);
        expect(result.createdAt, testTaskModel.createdAt);
        expect(result.completedAt, testTaskModel.completedAt);
        expect(result.verifiedAt, testTaskModel.verifiedAt);
        expect(result.verifiedById, testTaskModel.verifiedById);
        expect(result.metadata, testTaskModel.metadata);
      });

      test('should create TaskModel from Task entity correctly', () {
        final task = Task(
          id: 'entity-task',
          title: 'Entity Task',
          description: 'Task from entity',
          points: 75,
          status: TaskStatus.completed,
          assignedTo: 'child-2',
          createdBy: 'parent-2',
          dueDate: testDueDate,
          frequency: TaskFrequency.daily,
          familyId: 'family-456',
          imageUrls: const ['image1.jpg'],
          createdAt: testCreatedAt,
          completedAt: testCompletedAt,
          verifiedAt: testVerifiedAt,
          verifiedById: 'parent-2',
          metadata: const {'priority': 'high'},
        );

        // act
        final result = TaskModel.fromEntity(task);

        // assert
        expect(result, isA<TaskModel>());
        expect(result.id, task.id);
        expect(result.title, task.title);
        expect(result.description, task.description);
        expect(result.points, task.points);
        expect(result.status, task.status);
        expect(result.assignedTo, task.assignedTo);
        expect(result.createdBy, task.createdBy);
        expect(result.dueDate, task.dueDate);
        expect(result.frequency, task.frequency);
        expect(result.familyId, task.familyId);
        expect(result.imageUrls, task.imageUrls);
        expect(result.createdAt, task.createdAt);
        expect(result.completedAt, task.completedAt);
        expect(result.verifiedAt, task.verifiedAt);
        expect(result.verifiedById, task.verifiedById);
        expect(result.metadata, task.metadata);
      });
    });

    group('Edge cases', () {
      test('should handle empty strings in enum parsing', () {
        expect(() {
          final json = Map<String, dynamic>.from(minimalJson);
          json['status'] = '';
          TaskModel.fromJson(json);
        }, throwsA(isA<ArgumentError>()));
      });

      test('should handle invalid enum values', () {
        expect(() {
          final json = Map<String, dynamic>.from(minimalJson);
          json['status'] = 'invalid_status';
          TaskModel.fromJson(json);
        }, throwsA(isA<ArgumentError>()));
      });

      test('should handle very large points values', () {
        final json = Map<String, dynamic>.from(minimalJson);
        json['points'] = 999999;

        final result = TaskModel.fromJson(json);
        expect(result.points, 999999);
      });

      test('should handle very long strings', () {
        final longTitle = 'A' * 1000;
        final longDescription = 'B' * 2000;

        final json = Map<String, dynamic>.from(minimalJson);
        json['title'] = longTitle;
        json['description'] = longDescription;

        final result = TaskModel.fromJson(json);
        expect(result.title, longTitle);
        expect(result.description, longDescription);
      });

      test('should handle many image URLs', () {
        final manyImages = List.generate(50, (i) => 'image$i.jpg');
        final json = Map<String, dynamic>.from(minimalJson);
        json['image_urls'] = manyImages;

        final result = TaskModel.fromJson(json);
        expect(result.imageUrls, manyImages);
      });
    });

    group('Round-trip conversion', () {
      test('should maintain data integrity through JSON round-trip', () {
        // act
        final json = testTaskModel.toJson();
        final reconstructed = TaskModel.fromJson(json);

        // assert
        expect(reconstructed.id, testTaskModel.id);
        expect(reconstructed.title, testTaskModel.title);
        expect(reconstructed.status, testTaskModel.status);
        expect(reconstructed.points, testTaskModel.points);
        expect(reconstructed.verifiedById, testTaskModel.verifiedById);
        expect(reconstructed.metadata, testTaskModel.metadata);
      });

      test('should maintain data integrity through Entity round-trip', () {
        // act
        final entity = testTaskModel.toEntity();
        final reconstructed = TaskModel.fromEntity(entity);

        // assert
        expect(reconstructed.id, testTaskModel.id);
        expect(reconstructed.title, testTaskModel.title);
        expect(reconstructed.status, testTaskModel.status);
        expect(reconstructed.points, testTaskModel.points);
        expect(reconstructed.verifiedById, testTaskModel.verifiedById);
        expect(reconstructed.metadata, testTaskModel.metadata);
      });
    });
  });
}
