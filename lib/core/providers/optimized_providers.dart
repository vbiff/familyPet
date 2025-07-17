import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/task/presentation/providers/task_state.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_provider.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import '../services/cache_service.dart';

/// Optimized user profile provider with caching
final optimizedUserProfileProvider = Provider<User?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user != null) {
    // Cache user profile for 10 minutes
    cacheService.set(
      CacheKeys.userProfile,
      user,
      ttl: const Duration(minutes: 10),
    );
  }

  return user;
});

/// Selective user ID provider (only rebuilds when user ID changes)
final userIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider.select((user) => user?.id));
});

/// Selective user role provider (only rebuilds when user role changes)
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider.select((user) => user?.role));
});

/// Selective family ID provider (only rebuilds when family ID changes)
final familyIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider.select((user) => user?.familyId));
});

/// Cached task count providers for performance
final taskCountProvider = Provider<TaskCounts>((ref) {
  final tasks = ref.watch(tasksProvider);
  final cacheKey = 'task_counts_${tasks.length}';

  final cached = cacheService.get<TaskCounts>(cacheKey);
  if (cached != null) return cached;

  final counts = TaskCounts(
    total: tasks.length,
    pending: tasks.where((t) => t.status.isPending).length,
    inProgress: tasks.where((t) => t.status.isInProgress).length,
    completed: tasks.where((t) => t.status.isCompleted).length,
    overdue: tasks.where((t) => t.isOverdue).length,
    needingVerification: tasks.where((t) => t.needsVerification).length,
  );

  // Cache for 1 minute
  cacheService.set(cacheKey, counts, ttl: const Duration(minutes: 1));
  return counts;
});

/// Task counts data class
class TaskCounts {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;
  final int needingVerification;

  const TaskCounts({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
    required this.needingVerification,
  });
}

/// Optimized task loading state provider
final taskLoadingStateProvider = Provider<bool>((ref) {
  return ref.watch(taskNotifierProvider
      .select((state) => state.status == TaskStateStatus.loading));
});

/// Optimized task error provider
final taskErrorProvider = Provider<String?>((ref) {
  return ref
      .watch(taskNotifierProvider.select((state) => state.failure?.message));
});

/// Scoped task list providers for specific users
final userTasksOptimizedProvider =
    Provider.family<List<Task>, String>((ref, userId) {
  final tasks = ref.watch(tasksProvider);
  final cacheKey = 'user_tasks_${userId}_${tasks.length}';

  final cached = cacheService.get<List<Task>>(cacheKey);
  if (cached != null) return cached;

  final userTasks = tasks.where((task) => task.assignedTo == userId).toList();

  // Cache for 30 seconds
  cacheService.set(cacheKey, userTasks, ttl: const Duration(seconds: 30));
  return userTasks;
});

/// Optimized pending tasks provider
final pendingTasksOptimizedProvider = Provider<List<Task>>((ref) {
  return ref.watch(tasksProvider
      .select((tasks) => tasks.where((t) => t.status.isPending).toList()));
});

/// Optimized completed tasks provider
final completedTasksOptimizedProvider = Provider<List<Task>>((ref) {
  return ref.watch(tasksProvider
      .select((tasks) => tasks.where((t) => t.status.isCompleted).toList()));
});

/// Pet stats provider with caching
final petStatsProvider = Provider<PetStats?>((ref) {
  final petState = ref.watch(petNotifierProvider);

  if (!petState.hasPet || petState.pet == null) return null;

  final pet = petState.pet!;
  final cacheKey = 'pet_stats_${pet.id}_${pet.experience}';
  final cached = cacheService.get<PetStats>(cacheKey);
  if (cached != null) return cached;

  final stats = PetStats(
    level: pet.level,
    experience: pet.experience,
    happiness: pet.happiness,
    health: pet.health,
    stage: pet.stage,
  );

  // Cache for 2 minutes
  cacheService.set(cacheKey, stats, ttl: const Duration(minutes: 2));
  return stats;
});

/// Pet stats data class
class PetStats {
  final int level;
  final int experience;
  final int happiness;
  final int health;
  final PetStage stage;

  const PetStats({
    required this.level,
    required this.experience,
    required this.happiness,
    required this.health,
    required this.stage,
  });
}

/// Optimized family members provider
final familyMembersOptimizedProvider = Provider((ref) {
  try {
    final familyId = ref.watch(familyIdProvider);

    if (familyId == null) return [];

    final familyMembersAsync = ref.watch(familyMembersProvider);
    return familyMembersAsync;
  } catch (e) {
    // Handle disposed provider errors during sign out
    if (e.toString().contains('disposed') ||
        e.toString().contains('Bad state')) {
      return [];
    }
    rethrow;
  }
});

/// Family stats provider with caching
final familyStatsProvider = Provider<FamilyStats?>((ref) {
  try {
    final familyId = ref.watch(familyIdProvider);

    if (familyId == null) return null;

    final members = ref.watch(familyMembersOptimizedProvider);
    final tasks = ref.watch(tasksProvider);

    final cacheKey =
        'family_stats_${familyId}_${members.length}_${tasks.length}';
    final cached = cacheService.get<FamilyStats>(cacheKey);
    if (cached != null) return cached;

    final stats = FamilyStats(
      memberCount: members.length,
      totalTasks: tasks.length,
      completedTasks: tasks.where((t) => t.status.isCompleted).length,
      pendingTasks: tasks.where((t) => t.status.isPending).length,
      totalPoints: tasks
          .where((t) => t.status.isCompleted)
          .fold(0, (sum, task) => sum + task.points),
    );

    // Cache for 5 minutes
    cacheService.set(cacheKey, stats, ttl: const Duration(minutes: 5));
    return stats;
  } catch (e) {
    // Handle disposed provider errors during sign out
    if (e.toString().contains('disposed') ||
        e.toString().contains('Bad state')) {
      return null;
    }
    rethrow;
  }
});

/// Family stats data class
class FamilyStats {
  final int memberCount;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int totalPoints;

  const FamilyStats({
    required this.memberCount,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.totalPoints,
  });
}

/// Optimized app state provider that only rebuilds when necessary
final appStateProvider = Provider<AppState>((ref) {
  try {
    final isLoading = ref.watch(taskLoadingStateProvider);
    final userRole = ref.watch(userRoleProvider);
    final familyId = ref.watch(familyIdProvider);
    final taskCounts = ref.watch(taskCountProvider);

    return AppState(
      isLoading: isLoading,
      userRole: userRole,
      hasFamilyAccess: familyId != null,
      taskCounts: taskCounts,
    );
  } catch (e) {
    // Handle disposed provider errors during sign out
    if (e.toString().contains('disposed') ||
        e.toString().contains('Bad state')) {
      return const AppState(
        isLoading: false,
        userRole: null,
        hasFamilyAccess: false,
        taskCounts: TaskCounts(
          total: 0,
          pending: 0,
          inProgress: 0,
          completed: 0,
          overdue: 0,
          needingVerification: 0,
        ),
      );
    }
    rethrow;
  }
});

/// App state data class
class AppState {
  final bool isLoading;
  final UserRole? userRole;
  final bool hasFamilyAccess;
  final TaskCounts taskCounts;

  const AppState({
    required this.isLoading,
    required this.userRole,
    required this.hasFamilyAccess,
    required this.taskCounts,
  });
}

/// Provider scope helpers for better performance
class ProviderScopes {
  /// Task-related providers scope
  static final taskScope = ProviderScope(
    child: Container(), // Your task-related widgets
  );

  /// Pet-related providers scope
  static final petScope = ProviderScope(
    child: Container(), // Your pet-related widgets
  );

  /// Family-related providers scope
  static final familyScope = ProviderScope(
    child: Container(), // Your family-related widgets
  );
}

/// Provider listeners for cache invalidation
class OptimizedProviderListeners {
  static void setupTaskCacheInvalidation(WidgetRef ref) {
    // Clear task-related cache when tasks change
    ref.listen(tasksProvider, (previous, next) {
      if (previous?.length != next.length) {
        cacheService.removePattern('task_counts');
        cacheService.removePattern('user_tasks');
        cacheService.removePattern('family_stats');
      }
    });
  }

  static void setupUserCacheInvalidation(WidgetRef ref) {
    // Clear user-related cache when user changes
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.id != next?.id) {
        cacheService.removePattern('user_');
        cacheService.removePattern('family_');
      }
    });
  }

  static void setupPetCacheInvalidation(WidgetRef ref) {
    // Clear pet-related cache when pet changes
    ref.listen(petNotifierProvider, (previous, next) {
      if (previous?.pet?.experience != next.pet?.experience) {
        cacheService.removePattern('pet_stats');
      }
    });
  }
}

/// Debounced providers for expensive operations
final debouncedTaskFilterProvider = StateProvider<String>((ref) => '');

final debouncedTaskSearchProvider = FutureProvider<List<Task>>((ref) async {
  final filter = ref.watch(debouncedTaskFilterProvider);
  final tasks = ref.watch(tasksProvider);

  if (filter.isEmpty) return tasks;

  // Add debounce delay
  await Future.delayed(const Duration(milliseconds: 300));

  // Check cache first
  final cacheKey = 'task_search_$filter';
  final cached = cacheService.get<List<Task>>(cacheKey);
  if (cached != null) return cached;

  final filtered = tasks
      .where((task) =>
          task.title.toLowerCase().contains(filter.toLowerCase()) ||
          task.description.toLowerCase().contains(filter.toLowerCase()))
      .toList();

  // Cache for 1 minute
  cacheService.set(cacheKey, filtered, ttl: const Duration(minutes: 1));
  return filtered;
});

/// Performance monitoring providers
final providerPerformanceProvider = StateNotifierProvider<
    ProviderPerformanceNotifier, ProviderPerformanceState>((ref) {
  return ProviderPerformanceNotifier();
});

class ProviderPerformanceState {
  final Map<String, int> providerRebuildCounts;
  final Map<String, DateTime> lastRebuildTimes;
  final Map<String, Duration> rebuildDurations;

  const ProviderPerformanceState({
    this.providerRebuildCounts = const {},
    this.lastRebuildTimes = const {},
    this.rebuildDurations = const {},
  });

  ProviderPerformanceState copyWith({
    Map<String, int>? providerRebuildCounts,
    Map<String, DateTime>? lastRebuildTimes,
    Map<String, Duration>? rebuildDurations,
  }) {
    return ProviderPerformanceState(
      providerRebuildCounts:
          providerRebuildCounts ?? this.providerRebuildCounts,
      lastRebuildTimes: lastRebuildTimes ?? this.lastRebuildTimes,
      rebuildDurations: rebuildDurations ?? this.rebuildDurations,
    );
  }
}

class ProviderPerformanceNotifier
    extends StateNotifier<ProviderPerformanceState> {
  ProviderPerformanceNotifier() : super(const ProviderPerformanceState());

  void recordRebuild(String providerName, Duration duration) {
    final currentCount = state.providerRebuildCounts[providerName] ?? 0;

    state = state.copyWith(
      providerRebuildCounts: {
        ...state.providerRebuildCounts,
        providerName: currentCount + 1,
      },
      lastRebuildTimes: {
        ...state.lastRebuildTimes,
        providerName: DateTime.now(),
      },
      rebuildDurations: {
        ...state.rebuildDurations,
        providerName: duration,
      },
    );
  }

  Map<String, dynamic> getPerformanceReport() {
    return {
      'totalProviders': state.providerRebuildCounts.length,
      'totalRebuilds':
          state.providerRebuildCounts.values.fold(0, (a, b) => a + b),
      'averageRebuildTime': state.rebuildDurations.values.isNotEmpty
          ? state.rebuildDurations.values
                  .map((d) => d.inMicroseconds)
                  .reduce((a, b) => a + b) /
              state.rebuildDurations.length
          : 0.0,
      'mostActiveProviders': state.providerRebuildCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5),
    };
  }
}
