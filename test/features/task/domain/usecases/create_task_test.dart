import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';
import 'package:jhonny/features/task/domain/usecases/create_task.dart';

// Mock class
class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late CreateTask usecase;
  late MockTaskRepository mockRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    usecase = CreateTask(mockRepository);
  });

  group('CreateTask UseCase', () {
    const String testTaskId = 'task-123';
    const String testTitle = 'Clean Room';
    const String testDescription = 'Clean and organize your bedroom';
    const int testPoints = 50;
    const String testAssignedTo = 'child-1';
    const String testCreatedBy = 'parent-1';
    const String testFamilyId = 'family-123';
    final DateTime testDueDate = DateTime(2024, 12, 31, 23, 59);
    const TaskFrequency testFrequency = TaskFrequency.weekly;
    const List<String> testImageUrls = ['before.jpg', 'after.jpg'];
    const Map<String, dynamic> testMetadata = {'difficulty': 'medium'};

    final tTask = Task(
      id: testTaskId,
      title: testTitle,
      description: testDescription,
      points: testPoints,
      status: TaskStatus.pending,
      assignedTo: testAssignedTo,
      createdBy: testCreatedBy,
      dueDate: testDueDate,
      frequency: testFrequency,
      familyId: testFamilyId,
      imageUrls: testImageUrls,
      createdAt: DateTime.now(),
      metadata: testMetadata,
    );

    test('should create task successfully when all parameters are valid',
        () async {
      // arrange
      when(mockRepository.createTask(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
        imageUrls: testImageUrls,
        metadata: testMetadata,
      )).thenAnswer((_) async => Right(tTask));

      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
        imageUrls: testImageUrls,
        metadata: testMetadata,
      ));

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (task) {
          expect(task.title, testTitle);
          expect(task.description, testDescription);
          expect(task.points, testPoints);
          expect(task.assignedTo, testAssignedTo);
          expect(task.createdBy, testCreatedBy);
          expect(task.status, TaskStatus.pending);
        },
      );

      verify(mockRepository.createTask(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
        imageUrls: testImageUrls,
        metadata: testMetadata,
      ));
    });

    test('should return ValidationFailure when title is empty', () async {
      // act
      final result = await usecase(CreateTaskParams(
        title: '',
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('title'));
        },
        (task) => fail('Expected failure but got success'),
      );

      verifyNever(mockRepository.createTask(
        title: '',
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));
    });

    test('should return ValidationFailure when description is empty', () async {
      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: '',
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(
              (failure as ValidationFailure).message, contains('description'));
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should return ValidationFailure when points are negative', () async {
      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: -10,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('points'));
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should return ValidationFailure when points are zero', () async {
      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: 0,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('points'));
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should return ValidationFailure when assignedTo is empty', () async {
      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: '',
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('assigned'));
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should return ValidationFailure when createdBy is empty', () async {
      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: '',
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('creator'));
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should return ValidationFailure when familyId is empty', () async {
      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: '',
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('family'));
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should return ValidationFailure when due date is in the past',
        () async {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));

      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: pastDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).message, contains('due date'));
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should return ServerFailure when repository throws exception',
        () async {
      // arrange
      when(mockRepository.createTask(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
        imageUrls: null,
        metadata: null,
      )).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Database error')));

      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Database error');
        },
        (task) => fail('Expected failure but got success'),
      );
    });

    test('should create task with optional parameters set to null', () async {
      // arrange
      final minimalTask = Task(
        id: testTaskId,
        title: testTitle,
        description: testDescription,
        points: testPoints,
        status: TaskStatus.pending,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
        imageUrls: const [],
        createdAt: DateTime.now(),
      );

      when(mockRepository.createTask(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
        imageUrls: null,
        metadata: null,
      )).thenAnswer((_) async => Right(minimalTask));

      // act
      final result = await usecase(CreateTaskParams(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
      ));

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (task) {
          expect(task.imageUrls, isEmpty);
          expect(task.metadata, isNull);
        },
      );

      verify(mockRepository.createTask(
        title: testTitle,
        description: testDescription,
        points: testPoints,
        assignedTo: testAssignedTo,
        createdBy: testCreatedBy,
        dueDate: testDueDate,
        frequency: testFrequency,
        familyId: testFamilyId,
        imageUrls: null,
        metadata: null,
      ));
    });
  });
}
