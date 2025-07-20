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
import 'package:jhonny/core/theme/app_theme.dart';

class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList>
    with WidgetsBindingObserver {
  bool _isMyTasks = true;
  List<Task>? _reorderedTasks; // Local state for reordering

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('🔄 TaskList: App resumed, refreshing tasks');
      _loadTasks();
    }
  }

  void _loadTasks() {
    final user = ref.read(currentUserProvider);

    // Reset reordered state when loading fresh tasks
    setState(() {
      _reorderedTasks = null;
    });

    // Only load tasks if user has a real family
    if (user?.familyId != null) {
      debugPrint('🔄 TaskList: Loading tasks for family ${user!.familyId}');
      debugPrint('🔄 TaskList: User ${user.displayName} (${user.role.name})');

      ref.read(taskNotifierProvider.notifier).loadTasks(
            familyId: user.familyId!,
          );
    } else {
      debugPrint('⚠️ TaskList: Cannot load tasks - no user or family ID');
      if (user != null) {
        debugPrint(
            '⚠️ TaskList: User ${user.displayName} (${user.role.name}) has no family');

        // For child users, this might indicate they haven't properly joined a family
        if (user.role == UserRole.child) {
          debugPrint(
              '👶 Child user ${user.displayName} needs to join a family first');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskNotifierProvider);
    List<Task> tasks = taskState.tasks;
    final user = ref.watch(currentUserProvider);

    // Show family setup message if user doesn't have a family
    if (user?.familyId == null) {
      return _buildNoFamilyContent(context);
    }

    // Listen for auth changes and reload tasks when user profile is updated
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.familyId != next?.familyId) {
        debugPrint('🔄 TaskList: Family ID changed, reloading tasks');
        _reorderedTasks = null; // Reset reordered state
        _loadTasks();
      }
    });

    // Listen for task state changes to detect when provider is invalidated
    ref.listen(taskNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        debugPrint(
            '📋 TaskList: Task state changed from ${previous?.status} to ${next.status}');
      }

      // Reset reordered state when tasks are reloaded or updated significantly
      if (previous?.tasks.length != next.tasks.length) {
        _reorderedTasks = null;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, user),
        const SizedBox(height: 16),
        Expanded(
          child: buildTaskContent(context, taskState, tasks),
        ),
      ],
    );
  }

  Widget buildTaskContent(
      BuildContext context, TaskState taskState, List<Task> tasks) {
    final user = ref.watch(currentUserProvider);
    if (taskState.status == TaskStateStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (taskState.status == TaskStateStatus.error) {
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

    if (tasks.isEmpty) {
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
                  : null, // Disable button if no family
            ),
          ],
        ),
      );
    }

    return buildTaskListContent(context, taskState, tasks);
  }

  Widget buildTaskListContent(
      BuildContext context, TaskState taskState, List<Task> tasks) {
    final user = ref.read(currentUserProvider);

    // Use reordered tasks if available, otherwise use original tasks
    List<Task> displayTasks = _reorderedTasks ?? tasks;

    // Filter tasks based on user preferences and archived status
    displayTasks = displayTasks
        .where((task) => !task.isArchived)
        .toList(); // Exclude archived tasks

    debugPrint(
        '📋 TaskList: Total tasks: ${tasks.length}, Non-archived: ${displayTasks.length}');

    if (_isMyTasks && user != null) {
      displayTasks =
          displayTasks.where((task) => task.assignedTo == user.id).toList();
      debugPrint('📋 TaskList: Filtered to my tasks: ${displayTasks.length}');
    }

    // Separate current tasks from completed tasks
    List<Task> currentTasks = displayTasks
        .where((task) => task.status.isPending || task.status.isInProgress)
        .toList();

    List<Task> completedTasks =
        displayTasks.where((task) => task.status.isCompleted).toList();

    // Only sort if we don't have reordered tasks (maintain user order)
    if (_reorderedTasks == null) {
      currentTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      completedTasks.sort((a, b) =>
          (b.completedAt ?? b.updatedAt ?? b.createdAt)
              .compareTo(a.completedAt ?? a.updatedAt ?? a.createdAt));
    }

    // Build list items with proper keys
    List<Widget> listItems = [];

    // Add current tasks
    for (final task in currentTasks) {
      listItems.add(Container(
        key: ValueKey('current_${task.id}'),
        child: SwipeToArchiveWidget(
          task: task,
          onArchived: null,
          child: TaskCard(
            task: task,
            user: user,
            onTaskTap: onTaskTap,
            onCompleteTask: _markAsCompleted,
            onUncompleteTask: _markAsUncompleted,
          ),
        ),
      ));
    }

    // Add divider if both current and completed tasks exist
    if (currentTasks.isNotEmpty && completedTasks.isNotEmpty) {
      listItems.add(
        Container(
          key: const ValueKey('divider'),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Completed (${completedTasks.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add completed tasks
    for (final task in completedTasks) {
      listItems.add(Container(
        key: ValueKey('completed_${task.id}'),
        child: SwipeToArchiveWidget(
          task: task,
          onArchived: null,
          child: TaskCard(
            task: task,
            user: user,
            onTaskTap: onTaskTap,
            onCompleteTask: _markAsCompleted,
            onUncompleteTask: _markAsUncompleted,
          ),
        ),
      ));
    }

    return ReorderableListView(
      onReorder: (oldIndex, newIndex) =>
          _onReorder(oldIndex, newIndex, currentTasks, completedTasks),
      padding: const EdgeInsets.only(bottom: 16),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.05, // Slightly larger during drag
              child: Material(
                elevation: 8.0,
                shadowColor: Colors.black.withOpacity(0.3),
                borderRadius:
                    BorderRadius.circular(16), // Match task card radius
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
      children: listItems,
    );
  }

  void _onReorder(int oldIndex, int newIndex, List<Task> currentTasks,
      List<Task> completedTasks) {
    // Calculate section boundaries
    final currentTasksEnd = currentTasks.length;
    final dividerIndex = currentTasks.isNotEmpty && completedTasks.isNotEmpty
        ? currentTasksEnd
        : -1;
    final completedTasksStart =
        dividerIndex != -1 ? dividerIndex + 1 : currentTasksEnd;

    // Prevent moving the divider or moving between sections
    if (oldIndex == dividerIndex || newIndex == dividerIndex) return;

    // Determine which section we're reordering in
    if (oldIndex < currentTasksEnd && newIndex < currentTasksEnd) {
      // Reordering within current tasks
      setState(() {
        final task = currentTasks.removeAt(oldIndex);
        if (newIndex > oldIndex) newIndex--;
        currentTasks.insert(newIndex, task);
        _updateLocalTaskOrder(currentTasks, completedTasks);
      });
    } else if (oldIndex >= completedTasksStart &&
        newIndex >= completedTasksStart) {
      // Reordering within completed tasks
      final adjustedOldIndex = oldIndex - completedTasksStart;
      final adjustedNewIndex = newIndex - completedTasksStart;

      setState(() {
        final task = completedTasks.removeAt(adjustedOldIndex);
        final finalNewIndex = adjustedNewIndex > adjustedOldIndex
            ? adjustedNewIndex - 1
            : adjustedNewIndex;
        completedTasks.insert(finalNewIndex, task);
        _updateLocalTaskOrder(currentTasks, completedTasks);
      });
    }
    // Ignore moves between sections
  }

  void _updateLocalTaskOrder(
      List<Task> currentTasks, List<Task> completedTasks) {
    // Update our local reordered state
    final user = ref.read(currentUserProvider);
    final allTasks = ref.read(taskNotifierProvider).tasks;

    // Get all tasks that aren't in our display (archived, other users' tasks if filtered)
    final displayTaskIds =
        [...currentTasks, ...completedTasks].map((t) => t.id).toSet();
    final otherTasks =
        allTasks.where((task) => !displayTaskIds.contains(task.id)).toList();

    // Combine in the new order
    _reorderedTasks = [...currentTasks, ...completedTasks, ...otherTasks];
  }

  Future<void> _markAsCompleted(Task task) async {
    // Check if widget is still mounted before starting async operation
    if (!mounted) return;

    // Show completion dialog with optional photo verification
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return TaskCompletionDialog(
          task: task,
          onCompleted: (List<String> imageUrls) async {
            // Check if widget is still mounted before using ref
            if (!mounted) return;

            try {
              // Store the notifier reference before async operations
              final taskNotifier = ref.read(taskNotifierProvider.notifier);

              // Check mounted status again right before async operations
              if (!mounted) return;

              await taskNotifier.updateTaskStatus(
                  taskId: task.id, status: TaskStatus.completed);

              // Reset reordered state since task status changed
              setState(() {
                _reorderedTasks = null;
              });

              // If there are new images, update the task with them
              if (imageUrls.isNotEmpty && mounted) {
                await taskNotifier.updateTask(
                  UpdateTaskParams(
                    taskId: task.id,
                    imageUrls: [...task.imageUrls, ...imageUrls],
                  ),
                );
              }

              // Show confetti when task is completed successfully
              if (context.mounted) {
                ConfettiOverlay.show(
                  context,
                  duration: const Duration(seconds: 2),
                );
              }
            } catch (e) {
              // Check for disposed ref errors specifically
              if (e.toString().contains('disposed') ||
                  e.toString().contains('Bad state')) {
                debugPrint('Widget or ref was disposed during task complete');
                return; // Silently return for disposed ref errors
              }

              // Handle errors gracefully - only show critical errors
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
    // Check if widget is still mounted before starting async operation
    if (!mounted) return;

    try {
      // Store the notifier reference before async operation
      final taskNotifier = ref.read(taskNotifierProvider.notifier);

      // Check mounted status again right before async operation
      if (!mounted) return;

      await taskNotifier.updateTaskStatus(
          taskId: task.id, status: TaskStatus.pending);

      // Reset reordered state since task status changed
      setState(() {
        _reorderedTasks = null;
      });

      // No need to update imageUrls here as uncompleting doesn't add new images
    } catch (e) {
      // Check for disposed ref errors specifically
      if (e.toString().contains('disposed') ||
          e.toString().contains('Bad state')) {
        debugPrint('Widget or ref was disposed during task uncomplete');
        return; // Silently return for disposed ref errors
      }

      if (mounted && context.mounted) {
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

  void onTaskTap(Task task) {
    ref.read(taskNotifierProvider.notifier).selectTask(task);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Row(
            children: [
              // Filter button for toggling my tasks
              IconButton(
                icon: Icon(_isMyTasks ? Icons.person : Icons.group),
                tooltip: _isMyTasks ? 'Show all tasks' : 'Show my tasks',
                onPressed: () {
                  setState(() {
                    _isMyTasks = !_isMyTasks;
                    _reorderedTasks = null; // Reset reorder when filter changes
                  });
                },
              ),
              EnhancedButton.ghost(
                leadingIcon: Icons.add,
                text: 'Create',
                size: EnhancedButtonSize.small,
                onPressed: user?.familyId != null
                    ? () {
                        debugPrint(
                            '🎯 Creating task - User: ${user!.displayName} (${user.role.name}), Family: ${user.familyId}');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateTaskPage(),
                          ),
                        );
                      }
                    : () {
                        // Show helpful message when family is not set up
                        final isChild = user?.role == UserRole.child;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isChild
                                ? 'Ask your parent to invite you to the family first'
                                : 'Create or join a family to start creating tasks'),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
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

  Widget _buildNoFamilyContent(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isChild = user?.role == UserRole.child;

    return Center(
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
            isChild ? 'No family joined yet' : 'No family setup',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isChild
                ? 'Ask your parent for the family invite code to see and complete tasks'
                : 'Create or join a family to start managing tasks together',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!isChild)
            EnhancedButton.primary(
              leadingIcon: Icons.add,
              text: 'Set Up Family',
              onPressed: () {
                // Navigate to family setup
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FamilySetupPage(),
                  ),
                );
              },
            )
          else
            EnhancedButton.secondary(
              leadingIcon: Icons.qr_code_scanner,
              text: 'Join Family',
              onPressed: () {
                // Navigate to family setup (join family tab)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FamilySetupPage(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final User? user;
  final void Function(Task) onTaskTap;
  final void Function(Task) onCompleteTask;
  final void Function(Task) onUncompleteTask; // New callback for uncompleting

  const TaskCard({
    super.key,
    required this.task,
    required this.user,
    required this.onTaskTap,
    required this.onCompleteTask,
    required this.onUncompleteTask, // Required parameter
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTaskCard(
      onTap: () => onTaskTap(task),
      isCompleted: task.status.isCompleted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Round complete button on the left
          BouncyInteraction(
            onTap: _getCompleteAction(),
            child: _buildCompleteButton(context),
          ),
          const SizedBox(width: 16),
          // Task title
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.2, // Better line height for alignment
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
          // Difficulty indicator
          _buildDifficultyIcon(context),
          // Status indicator
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
    final bool canUncomplete = isCompleted &&
        (user?.id == task.assignedTo) &&
        !task.isVerifiedByParent;

    if (canComplete) {
      return () => onCompleteTask(task);
    } else if (canUncomplete) {
      return () => onUncompleteTask(task);
    }
    return null;
  }

  Widget _buildCompleteButton(BuildContext context) {
    final bool isCompleted = task.status.isCompleted;
    final bool canComplete =
        task.status == TaskStatus.pending && (user?.id == task.assignedTo);
    final bool isVerified = task.isVerifiedByParent;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCompleted
            ? LinearGradient(
                colors: isVerified
                    ? [
                        Colors.green,
                        Colors.green.withValues(alpha: 0.8)
                      ] // Different color for verified tasks
                    : [AppTheme.success, AppTheme.success.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : canComplete
                ? LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
        color: !isCompleted && !canComplete
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
        border: Border.all(
          color: isCompleted
              ? (isVerified ? Colors.green : AppTheme.success)
              : canComplete
                  ? AppTheme.primary
                  : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        boxShadow: (isCompleted || canComplete) ? AppTheme.softShadow : null,
      ),
      child: Icon(
        isCompleted
            ? (isVerified ? Icons.verified : Icons.check)
            : Icons.circle_outlined,
        color: isCompleted
            ? Colors.white
            : canComplete
                ? Colors.white
                : Theme.of(context).colorScheme.outline,
        size: 20,
      ),
    );
  }

  Widget _buildDifficultyIcon(BuildContext context) {
    late Color iconColor;
    late String tooltip;
    late int dotCount;

    switch (task.difficulty) {
      case TaskDifficulty.easy:
        iconColor = AppTheme.success;
        tooltip = 'Easy';
        dotCount = 1;
        break;
      case TaskDifficulty.medium:
        iconColor = AppTheme.warning;
        tooltip = 'Medium';
        dotCount = 2;
        break;
      case TaskDifficulty.hard:
        iconColor = AppTheme.error;
        tooltip = 'Hard';
        dotCount = 3;
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              iconColor,
              iconColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            dotCount,
            (index) => Container(
              width: 4,
              height: 4,
              margin: EdgeInsets.only(right: index < dotCount - 1 ? 2 : 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
