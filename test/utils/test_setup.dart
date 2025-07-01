import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart' as app_user;
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart'
    as app_auth;
import 'package:jhonny/features/task/presentation/providers/task_state.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/family/presentation/providers/family_state.dart';
import 'package:jhonny/features/family/domain/entities/family.dart'
    as app_family;

class TestSetup {
  static Widget createTestApp({
    required Widget child,
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  static app_user.User createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    app_user.UserRole role = app_user.UserRole.parent,
    String? familyId = 'test-family-id',
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    final now = DateTime.now();
    return app_user.User(
      id: id,
      email: email,
      displayName: displayName,
      role: role,
      familyId: familyId,
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? now,
      lastLoginAt: lastLoginAt ?? now,
    );
  }

  static Task createTestTask({
    String id = 'test-task-id',
    String title = 'Test Task',
    String description = 'Test task description',
    int points = 10,
    TaskStatus status = TaskStatus.pending,
    String assignedTo = 'test-user-id',
    String createdBy = 'test-parent-id',
    String familyId = 'test-family-id',
    DateTime? dueDate,
    TaskFrequency frequency = TaskFrequency.once,
    String? verifiedById,
    DateTime? completedAt,
    DateTime? verifiedAt,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      points: points,
      status: status,
      assignedTo: assignedTo,
      createdBy: createdBy,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      frequency: frequency,
      familyId: familyId,
      createdAt: DateTime.now(),
      completedAt: completedAt,
      verifiedById: verifiedById,
      verifiedAt: verifiedAt,
    );
  }

  static app_family.Family createTestFamily({
    String id = 'test-family-id',
    String name = 'Test Family',
    String inviteCode = 'TEST123',
    String createdById = 'test-parent-id',
    List<String> parentIds = const ['test-parent-id'],
    List<String> childIds = const ['test-child-id'],
    DateTime? createdAt,
    DateTime? lastActivityAt,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return app_family.Family(
      id: id,
      name: name,
      inviteCode: inviteCode,
      createdById: createdById,
      parentIds: parentIds,
      childIds: childIds,
      createdAt: createdAt ?? DateTime.now(),
      lastActivityAt: lastActivityAt,
      settings: settings,
      metadata: metadata,
    );
  }

  /// Creates a test widget with all necessary providers mocked
  static Widget createTaskListTest({
    List<Task>? tasks,
    app_user.User? currentUser,
    TaskState? taskState,
  }) {
    return createTestApp(
      child: const Text('TaskList placeholder for testing'),
      overrides: [
        // Mock the current user provider
        if (currentUser != null) Provider<app_user.User?>((ref) => currentUser),

        // Mock the task state
        Provider<TaskState>((ref) =>
            taskState ??
            TaskState(
              tasks: tasks ?? [],
              status: TaskStateStatus.success,
            )),
      ],
    );
  }
}
