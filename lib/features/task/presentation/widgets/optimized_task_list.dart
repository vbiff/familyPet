import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/pages/create_task_page.dart';
import 'package:jhonny/features/task/presentation/pages/task_detail_page.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/task/presentation/providers/task_state.dart';
import 'package:jhonny/shared/widgets/widgets.dart';
import 'package:jhonny/features/family/presentation/pages/family_setup_page.dart';
import 'package:jhonny/features/task/domain/usecases/update_task.dart';
import 'package:jhonny/features/task/presentation/widgets/task_completion_dialog.dart';
import 'package:jhonny/features/task/presentation/widgets/swipe_to_archive_widget.dart';
import 'package:jhonny/shared/widgets/confetti_animation.dart';
import 'package:jhonny/shared/widgets/animated_task_card.dart';
import 'package:jhonny/shared/widgets/performance_widgets.dart';
import 'package:jhonny/core/theme/app_theme.dart';
import 'package:jhonny/core/services/cache_service.dart';

/// Optimized task provider for filtered tasks with caching
final filteredTasksProvider =
    Provider.family<List<Task>, TaskFilter>((ref, filter) {
  final tasks = ref.watch(tasksProvider);

  // Use cache for filtered results
  final cacheKey =
      'filtered_tasks_${filter.userId}_${filter.isMyTasks}_${tasks.length}';
  final cached = cacheService.get<List<Task>>(cacheKey);
  if (cached != null) return cached;

  List<Task> filtered = tasks.where((task) => !task.isArchived).toList();

  if (filter.isMyTasks && filter.userId != null) {
    filtered =
        filtered.where((task) => task.assignedTo == filter.userId).toList();
  }

  // Cache the result for 30 seconds
  cacheService.set(cacheKey, filtered, ttl: const Duration(seconds: 30));
  return filtered;
});

/// Task filter configuration
class TaskFilter {
  final String? userId;
  final bool isMyTasks;

  const TaskFilter({this.userId, this.isMyTasks = false});
}

/// Cached task sections provider for optimized list building
final taskSectionsProvider =
    Provider.family<TaskSections, TaskFilter>((ref, filter) {
  final tasks = ref.watch(filteredTasksProvider(filter));

  final cacheKey =
      'task_sections_${filter.userId}_${filter.isMyTasks}_${tasks.length}';
  final cached = cacheService.get<TaskSections>(cacheKey);
  if (cached != null) return cached;

  final currentTasks = tasks
      .where((task) => task.status.isPending || task.status.isInProgress)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  final completedTasks = tasks.where((task) => task.status.isCompleted).toList()
    ..sort((a, b) => (b.completedAt ?? b.updatedAt ?? b.createdAt)
        .compareTo(a.completedAt ?? a.updatedAt ?? a.createdAt));

  final sections = TaskSections(
    currentTasks: currentTasks,
    completedTasks: completedTasks,
  );

  // Cache for 30 seconds
  cacheService.set(cacheKey, sections, ttl: const Duration(seconds: 30));
  return sections;
});

/// Task sections data class
class TaskSections {
  final List<Task> currentTasks;
  final List<Task> completedTasks;

  const TaskSections({
    required this.currentTasks,
    required this.completedTasks,
  });
}

/// Optimized task list widget
class OptimizedTaskList extends ConsumerStatefulWidget {
  const OptimizedTaskList({super.key});

  @override
  ConsumerState<OptimizedTaskList> createState() => _OptimizedTaskListState();
}

class _OptimizedTaskListState extends ConsumerState<OptimizedTaskList>
    with WidgetsBindingObserver {
  bool _isDisposed = false;
  bool _isMyTasks = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    super.dispose();
  }

  /// Safe setState that checks disposal status
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('🔄 OptimizedTaskList: App resumed, refreshing tasks');
      _loadTasks();
    }
  }

  void _loadTasks() {
    final user = ref.read(currentUserProvider);
    if (user?.familyId != null) {
      debugPrint(
          '🔄 OptimizedTaskList: Loading tasks for family ${user!.familyId}');
      ref.read(taskNotifierProvider.notifier).loadTasks(
            familyId: user.familyId!,
          );
    } else {
      debugPrint(
          '⚠️ OptimizedTaskList: Cannot load tasks - no user or family ID');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    final taskState = ref.watch(taskNotifierProvider);
    final user = ref.watch(currentUserProvider);

    // Show family setup message if user doesn't have a family
    if (user?.familyId == null) {
      return _buildNoFamilyContent(context);
    }

    // Listen for auth changes and reload tasks when user profile is updated
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.familyId != next?.familyId) {
        debugPrint('🔄 OptimizedTaskList: Family ID changed, reloading tasks');
        _loadTasks();
      }
    });

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, user),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTaskContent(context, taskState, user),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tasks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isMyTasks ? Icons.person : Icons.group),
                tooltip: _isMyTasks ? 'Show all tasks' : 'Show my tasks',
                onPressed: () {
                  safeSetState(() {
                    _isMyTasks = !_isMyTasks;
                  });
                  // Clear cache when filter changes
                  cacheService.removePattern('filtered_tasks');
                  cacheService.removePattern('task_sections');
                },
              ),
              EnhancedButton.ghost(
                leadingIcon: Icons.add,
                text: 'Create',
                size: EnhancedButtonSize.small,
                onPressed: user?.familyId != null
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateTaskPage(),
                          ),
                        )
                    : null,
              ),
              const SizedBox(width: 8),
              EnhancedButton.ghost(
                leadingIcon: Icons.refresh,
                size: EnhancedButtonSize.small,
                onPressed: _loadTasks,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskContent(
      BuildContext context, TaskState taskState, User? user) {
    if (taskState.status == TaskStateStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskState.status == TaskStateStatus.error) {
      return _buildErrorContent(context, taskState);
    }

    final filter = TaskFilter(userId: user?.id, isMyTasks: _isMyTasks);
    final filteredTasks = ref.watch(filteredTasksProvider(filter));

    if (filteredTasks.isEmpty) {
      return _buildEmptyContent(context, user);
    }

    return _buildOptimizedTaskList(context, filter, user);
  }

  Widget _buildOptimizedTaskList(
      BuildContext context, TaskFilter filter, User? user) {
    final sections = ref.watch(taskSectionsProvider(filter));

    // Build flat list for optimal scrolling performance
    final listItems = <TaskListItem>[];

    // Add current tasks
    for (int i = 0; i < sections.currentTasks.length; i++) {
      listItems.add(TaskListItem.task(
        task: sections.currentTasks[i],
        user: user,
      ));
    }

    // Add divider if both sections have items
    if (sections.currentTasks.isNotEmpty &&
        sections.completedTasks.isNotEmpty) {
      listItems.add(TaskListItem.divider(sections.completedTasks.length));
    }

    // Add completed tasks
    for (int i = 0; i < sections.completedTasks.length; i++) {
      listItems.add(TaskListItem.task(
        task: sections.completedTasks[i],
        user: user,
      ));
    }

    return OptimizedListView<TaskListItem>(
      items: listItems,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, item, index) {
        if (item.isDivider) {
          return _buildSectionDivider(context, item.completedCount!);
        }

        return SwipeToArchiveWidget(
          task: item.task!,
          onArchived: null,
          child: OptimizedTaskCard(
            task: item.task!,
            user: user,
            onTaskTap: _onTaskTap,
            onCompleteTask: _markAsCompleted,
            onUncompleteTask: _markAsUncompleted,
          ),
        );
      },
    );
  }

  Widget _buildSectionDivider(BuildContext context, int completedCount) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Completed ($completedCount)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFamilyContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Join a Family First',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be part of a family to see and create tasks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            EnhancedButton.primary(
              leadingIcon: Icons.group_add,
              text: 'Set Up Family',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FamilySetupPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, TaskState taskState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load tasks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            taskState.failure?.message ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          EnhancedButton.primary(
            leadingIcon: Icons.refresh,
            text: 'Retry',
            onPressed: _loadTasks,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(BuildContext context, User? user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tasks will appear here when they are created',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          EnhancedButton.primary(
            leadingIcon: Icons.add,
            text: 'Create First Task',
            onPressed: user?.familyId != null
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateTaskPage(),
                      ),
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _markAsCompleted(Task task) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return TaskCompletionDialog(
          task: task,
          onCompleted: (List<String> imageUrls) async {
            if (!mounted) return;

            try {
              final taskNotifier = ref.read(taskNotifierProvider.notifier);
              if (!mounted) return;

              await taskNotifier.updateTaskStatus(
                  taskId: task.id, status: TaskStatus.completed);

              if (imageUrls.isNotEmpty && mounted) {
                await taskNotifier.updateTask(
                  UpdateTaskParams(
                    taskId: task.id,
                    imageUrls: [...task.imageUrls, ...imageUrls],
                  ),
                );
              }

              if (context.mounted) {
                ConfettiOverlay.show(
                  context,
                  duration: const Duration(seconds: 2),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to complete task: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Future<void> _markAsUncompleted(Task task) async {
    if (!mounted) return;

    try {
      final taskNotifier = ref.read(taskNotifierProvider.notifier);
      if (!mounted) return;

      await taskNotifier.updateTaskStatus(
          taskId: task.id, status: TaskStatus.pending);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to uncomplete task: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onTaskTap(Task task) {
    ref.read(taskNotifierProvider.notifier).selectTask(task);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }
}

/// Task list item for flat list building
class TaskListItem {
  final Task? task;
  final bool isDivider;
  final int? completedCount;

  const TaskListItem._({
    this.task,
    this.isDivider = false,
    this.completedCount,
  });

  factory TaskListItem.task({required Task task, User? user}) {
    return TaskListItem._(task: task);
  }

  factory TaskListItem.divider(int completedCount) {
    return TaskListItem._(isDivider: true, completedCount: completedCount);
  }
}

/// Optimized task card widget
class OptimizedTaskCard extends OptimizedStatelessWidget {
  final Task task;
  final User? user;
  final void Function(Task) onTaskTap;
  final void Function(Task) onCompleteTask;
  final void Function(Task) onUncompleteTask;

  const OptimizedTaskCard({
    super.key,
    required this.task,
    required this.user,
    required this.onTaskTap,
    required this.onCompleteTask,
    required this.onUncompleteTask,
  });

  @override
  Widget buildOptimized(BuildContext context) {
    return AnimatedTaskCard(
      onTap: () => onTaskTap(task),
      isCompleted: task.status.isCompleted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BouncyInteraction(
            onTap: _getCompleteAction(),
            child: _buildCompleteButton(context),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      decoration: task.status.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.status.isCompleted
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildDifficultyIcon(context),
          if (task.isVerifiedByParent) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.verified,
              color: Colors.green,
              size: 20,
            ),
          ] else if (task.needsVerification) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.hourglass_empty,
              color: Colors.orange,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _getCompleteAction() {
    final bool isCompleted = task.status.isCompleted;
    final bool canComplete =
        task.status == TaskStatus.pending && (user?.id == task.assignedTo);
    final bool canUncomplete = isCompleted && (user?.id == task.assignedTo);

    if (canComplete) {
      return () => onCompleteTask(task);
    } else if (canUncomplete) {
      return () => onUncompleteTask(task);
    }
    return null;
  }

  Widget _buildCompleteButton(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: task.status.isCompleted
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        color: task.status.isCompleted ? Colors.green : Colors.transparent,
      ),
      child: task.status.isCompleted
          ? const Icon(
              Icons.check,
              size: 18,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildDifficultyIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (task.difficulty) {
      case TaskDifficulty.easy:
        icon = Icons.circle;
        color = Colors.green;
        break;
      case TaskDifficulty.medium:
        icon = Icons.circle;
        color = Colors.orange;
        break;
      case TaskDifficulty.hard:
        icon = Icons.circle;
        color = Colors.red;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }
}
