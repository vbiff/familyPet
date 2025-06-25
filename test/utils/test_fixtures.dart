import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';

/// Test fixtures for consistent test data across all test files
class TestFixtures {
  static final DateTime baseDate = DateTime(2024, 1, 1, 12, 0, 0);

  // User fixtures
  static User get testParent => User(
        id: 'parent-1',
        email: 'parent@example.com',
        displayName: 'Test Parent',
        role: UserRole.parent,
        createdAt: baseDate,
        lastLoginAt: baseDate,
        familyId: 'family-123',
        avatarUrl: 'https://example.com/parent-avatar.jpg',
        metadata: const {'role': 'primary'},
      );

  static User get testChild => User(
        id: 'child-1',
        email: 'child@example.com',
        displayName: 'Test Child',
        role: UserRole.child,
        createdAt: baseDate,
        lastLoginAt: baseDate,
        familyId: 'family-123',
        avatarUrl: 'https://example.com/child-avatar.jpg',
        metadata: const {'age': '8'},
      );

  static User get testUser => testParent;

  // Family fixtures
  static Family get testFamily => Family(
        id: 'family-123',
        name: 'Test Family',
        inviteCode: 'TEST123',
        createdById: 'parent-1',
        parentIds: const ['parent-1', 'parent-2'],
        childIds: const ['child-1', 'child-2'],
        createdAt: baseDate,
        lastActivityAt: baseDate,
        settings: const {'theme': 'light', 'notifications': true},
        metadata: const {'version': '1.0'},
      );

  // Pet fixtures
  static Pet get testPet => Pet(
        id: 'pet-123',
        name: 'Fluffy',
        familyId: 'family-123',
        ownerId: 'child-1',
        stage: PetStage.child,
        mood: PetMood.happy,
        experience: 350,
        level: 4,
        currentImageUrl: 'https://example.com/fluffy.jpg',
        unlockedImageUrls: const ['image1.jpg', 'image2.jpg'],
        lastFedAt: baseDate.subtract(const Duration(hours: 2)),
        lastPlayedAt: baseDate.subtract(const Duration(hours: 3)),
        createdAt: baseDate,
        stats: const {'health': 85, 'happiness': 90, 'energy': 75},
        metadata: const {'color': 'orange', 'breed': 'virtual'},
      );

  // Task fixtures
  static Task get testTask => Task(
        id: 'task-123',
        title: 'Clean Bedroom',
        description: 'Clean and organize your bedroom completely',
        points: 50,
        status: TaskStatus.pending,
        assignedTo: 'child-1',
        createdBy: 'parent-1',
        dueDate: baseDate.add(const Duration(days: 3)),
        frequency: TaskFrequency.weekly,
        familyId: 'family-123',
        imageUrls: const ['before.jpg', 'after.jpg'],
        createdAt: baseDate,
        metadata: const {'difficulty': 'medium', 'category': 'chores'},
      );

  static Task get testCompletedTask => testTask.copyWith(
        id: 'task-completed',
        status: TaskStatus.completed,
        completedAt: baseDate.add(const Duration(hours: 2)),
        verifiedById: 'parent-1',
        verifiedAt: baseDate.add(const Duration(hours: 3)),
      );

  static Task get testOverdueTask => testTask.copyWith(
        id: 'task-overdue',
        status: TaskStatus.expired,
        dueDate: baseDate.subtract(const Duration(days: 1)),
      );

  // List fixtures for testing collections
  static List<User> get testUsers => [testParent, testChild];

  static List<Task> get testTasks => [
        testTask,
        testCompletedTask,
        testOverdueTask,
      ];

  // Pet evolution fixtures
  static Pet get eggPet => testPet.copyWith(
        id: 'pet-egg',
        name: 'Baby Pet',
        stage: PetStage.egg,
        experience: 0,
        level: 1,
        mood: PetMood.neutral,
      );

  static Pet get adultPet => testPet.copyWith(
        id: 'pet-adult',
        name: 'Mature Fluffy',
        stage: PetStage.adult,
        experience: 1500,
        level: 20,
        mood: PetMood.content,
      );

  // Task status fixtures
  static Task get pendingTask => testTask.copyWith(
        id: 'task-pending',
        status: TaskStatus.pending,
      );

  static Task get inProgressTask => testTask.copyWith(
        id: 'task-progress',
        status: TaskStatus.inProgress,
      );

  // Family member fixtures
  static Family get singleParentFamily => testFamily.copyWith(
        id: 'family-single',
        parentIds: ['parent-1'],
        childIds: ['child-1'],
      );

  static Family get largeFamily => testFamily.copyWith(
        id: 'family-large',
        parentIds: ['parent-1', 'parent-2'],
        childIds: ['child-1', 'child-2', 'child-3', 'child-4'],
      );

  // Date utilities for tests
  static DateTime get futureDate => baseDate.add(const Duration(days: 7));
  static DateTime get pastDate => baseDate.subtract(const Duration(days: 7));
  static DateTime get recentDate => baseDate.subtract(const Duration(hours: 2));

  // Helper methods for creating test variations
  static User createUser({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    String? familyId,
  }) =>
      testUser.copyWith(
        id: id,
        email: email,
        displayName: displayName,
        role: role,
        familyId: familyId,
      );

  static Family createFamily({
    String? id,
    String? name,
    List<String>? parentIds,
    List<String>? childIds,
  }) =>
      testFamily.copyWith(
        id: id,
        name: name,
        parentIds: parentIds,
        childIds: childIds,
      );

  static Pet createPet({
    String? id,
    String? name,
    PetStage? stage,
    PetMood? mood,
    int? experience,
    int? level,
  }) =>
      testPet.copyWith(
        id: id,
        name: name,
        stage: stage,
        mood: mood,
        experience: experience,
        level: level,
      );

  static Task createTask({
    String? id,
    String? title,
    TaskStatus? status,
    String? assignedTo,
    DateTime? dueDate,
    int? points,
  }) =>
      testTask.copyWith(
        id: id,
        title: title,
        status: status,
        assignedTo: assignedTo,
        dueDate: dueDate,
        points: points,
      );
}
