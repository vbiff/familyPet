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
import 'package:jhonny/core/services/task_order_service.dart';
import 'package:vibration/vibration.dart';
import 'dart:async'; // Import Timer

class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList>
    with WidgetsBindingObserver {
  bool _isMyTasks = true;
  List<Task>? _reorderedTasks; // Local state for reordering
  Timer? _saveTimer; // Debounce timer for saving order

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
    _saveTimer?.cancel(); // Cancel any pending saves
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh task order when dependencies change (like coming back from navigation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reorderedTasks != null) {
        _refreshTaskOrder();
        debugPrint('🔄 TaskList: Dependencies changed, refreshed task order');
      }
    });
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

      // Load saved task order after tasks are loaded
      _loadSavedTaskOrder();
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

  /// Load saved task order from SharedPreferences and apply it
  Future<void> _loadSavedTaskOrder() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Don't load saved order if we're in the middle of reordering
    if (_saveTimer?.isActive == true) {
      debugPrint(
          '📖 TaskList: Skipping saved order load - reordering in progress');
      return;
    }

    try {
      final savedTaskIds = await taskOrderService.loadTaskOrder(
        userId: user.id,
        isMyTasks: _isMyTasks,
        familyId: user.familyId,
      );

      if (savedTaskIds.isNotEmpty && mounted && _saveTimer?.isActive != true) {
        final allTasks = ref.read(taskNotifierProvider).tasks;
        final reorderedTasks = _applyTaskOrder(allTasks, savedTaskIds);

        setState(() {
          _reorderedTasks = reorderedTasks;
        });

        debugPrint(
            '📖 TaskList: Applied saved task order (${savedTaskIds.length} tasks)');
      }
    } catch (e) {
      debugPrint('❌ TaskList: Failed to load saved task order: $e');
    }
  }

  /// Apply saved task order to current tasks
  List<Task> _applyTaskOrder(List<Task> tasks, List<String> savedTaskIds) {
    final taskMap = {for (var task in tasks) task.id: task};
    final reorderedTasks = <Task>[];

    // Add tasks in saved order
    for (final taskId in savedTaskIds) {
      if (taskMap.containsKey(taskId)) {
        reorderedTasks.add(taskMap[taskId]!);
        taskMap.remove(taskId);
      }
    }

    // Add any new tasks that weren't in the saved order
    reorderedTasks.addAll(taskMap.values);

    return reorderedTasks;
  }

  /// Save current task order to SharedPreferences
  Future<void> _saveTaskOrder(
      List<Task> currentTasks, List<Task> completedTasks) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Get task IDs in current display order
      final taskIds =
          [...currentTasks, ...completedTasks].map((task) => task.id).toList();

      await taskOrderService.saveTaskOrder(
        taskIds: taskIds,
        userId: user.id,
        isMyTasks: _isMyTasks,
        familyId: user.familyId,
      );

      debugPrint('💾 TaskList: Saved task order (${taskIds.length} tasks)');
    } catch (e) {
      debugPrint('❌ TaskList: Failed to save task order: $e');
    }
  }

  /// Clear saved task order
  Future<void> _clearSavedTaskOrder() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await taskOrderService.clearTaskOrder(
        userId: user.id,
        isMyTasks: _isMyTasks,
        familyId: user.familyId,
      );

      debugPrint('🗑️ TaskList: Cleared saved task order');
    } catch (e) {
      debugPrint('❌ TaskList: Failed to clear saved task order: $e');
    }
  }

  /// Refresh and update the current reordered state to reflect status changes
  void _refreshTaskOrder() {
    if (_reorderedTasks == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Get the current provider tasks
    final allTasks = ref.read(taskNotifierProvider).tasks;

    // Create a map for fast lookup
    final taskMap = {for (var task in allTasks) task.id: task};

    // Update our reordered tasks with the latest task data (including status changes)
    final updatedReorderedTasks = _reorderedTasks!
        .map((task) => taskMap[task.id] ?? task)
        .where((task) => taskMap.containsKey(task.id)) // Remove deleted tasks
        .toList();

    // Add any new tasks that weren't in our reordered list
    final reorderedTaskIds = updatedReorderedTasks.map((t) => t.id).toSet();
    final newTasks =
        allTasks.where((task) => !reorderedTaskIds.contains(task.id)).toList();

    setState(() {
      _reorderedTasks = [...updatedReorderedTasks, ...newTasks];
    });

    debugPrint('🔄 TaskList: Refreshed task order with status updates');
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
        // Clear saved order for old family and load tasks for new family
        _clearSavedTaskOrder();
        _loadTasks();
      }
    });

    // Listen for task state changes to detect when provider is invalidated
    ref.listen(taskNotifierProvider, (previous, next) {
      if (previous?.status != next.status) {
        debugPrint(
            '📋 TaskList: Task state changed from ${previous?.status} to ${next.status}');
      }

      // Refresh task order when tasks are updated (including verification status changes)
      if (_reorderedTasks != null && next.status == TaskStateStatus.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshTaskOrder();
            debugPrint(
                '🔄 TaskList: Refreshed task order due to provider update');
          }
        });
      }

      // Only reset reordered state when tasks are fundamentally changed (not just updated)
      if (previous?.tasks.length != next.tasks.length) {
        // Check if it's just a status update vs actually new/removed tasks
        final prevTaskIds =
            previous?.tasks.map((t) => t.id).toSet() ?? <String>{};
        final nextTaskIds = next.tasks.map((t) => t.id).toSet();

        // Only reset if tasks were actually added/removed, not just status changed
        if (prevTaskIds.length != nextTaskIds.length ||
            !prevTaskIds.containsAll(nextTaskIds) ||
            !nextTaskIds.containsAll(prevTaskIds)) {
          debugPrint('📋 TaskList: Tasks added/removed, resetting order');
          _reorderedTasks = null;
          // Reload saved order when tasks are actually added/removed
          if (next.status == TaskStateStatus.success) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) _loadSavedTaskOrder();
            });
          }
        }
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
    for (int i = 0; i < currentTasks.length; i++) {
      final task = currentTasks[i];
      listItems.add(Container(
        key: ValueKey('current_${task.id}'),
        child: SwipeToArchiveWidget(
          task: task,
          onArchived: null,
          child: ReorderableDelayedDragStartListener(
            index: listItems.length, // Use the actual list index
            child: TaskCard(
              task: task,
              user: user,
              onTaskTap: onTaskTap,
              onCompleteTask: _markAsCompleted,
              onUncompleteTask: _markAsUncompleted,
            ),
          ),
        ),
      ));
    }

    // Add divider if both current and completed tasks exist
    if (currentTasks.isNotEmpty && completedTasks.isNotEmpty) {
      listItems.add(
        Container(
          key: const ValueKey('divider'),
          margin: const EdgeInsets.symmetric(vertical: 12),
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
    for (int i = 0; i < completedTasks.length; i++) {
      final task = completedTasks[i];
      listItems.add(Container(
        key: ValueKey('completed_${task.id}'),
        child: SwipeToArchiveWidget(
          task: task,
          onArchived: null,
          child: ReorderableDelayedDragStartListener(
            index: listItems.length, // Use the actual list index
            child: TaskCard(
              task: task,
              user: user,
              onTaskTap: onTaskTap,
              onCompleteTask: _markAsCompleted,
              onUncompleteTask: _markAsUncompleted,
            ),
          ),
        ),
      ));
    }

    return ReorderableListView.builder(
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
      onReorderStart: (int index) {
        // Add vibration feedback when drag starts (when card becomes draggable)
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator ?? false) {
            Vibration.vibrate(duration: 30);
          }
        });
      },
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
                shadowColor: Colors.black.withValues(alpha: 0.3),
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
                          .withValues(alpha: 0.3),
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
    if (user == null) return;

    final allTasks = ref.read(taskNotifierProvider).tasks;

    // Get all tasks that aren't in our display (archived, other users' tasks if filtered)
    final displayTaskIds =
        [...currentTasks, ...completedTasks].map((t) => t.id).toSet();
    final otherTasks =
        allTasks.where((task) => !displayTaskIds.contains(task.id)).toList();

    // Combine in the new order
    final newReorderedTasks = [
      ...currentTasks,
      ...completedTasks,
      ...otherTasks
    ];

    // Update state immediately to prevent jumping
    setState(() {
      _reorderedTasks = newReorderedTasks;
    });

    // Debounce saving to SharedPreferences to prevent conflicts during rapid reordering
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      _saveTaskOrder(currentTasks, completedTasks).catchError((e) {
        debugPrint('❌ TaskList: Failed to save task order during reorder: $e');
      });
    });
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

              // Add vibration feedback for task completion
              if (await Vibration.hasVibrator() ?? false) {
                Vibration.vibrate(duration: 70);
              }

              // Don't reset reordered state - let the task move naturally between sections
              // The order will be preserved within each section
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted)
                  _refreshTaskOrder(); // Update task data while preserving order
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

      // Don't reset reordered state - let the task move naturally between sections
      // The order will be preserved within each section
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted)
          _refreshTaskOrder(); // Update task data while preserving order
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
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    )
        .then((_) {
      // Refresh task order when returning from task detail page
      if (mounted && _reorderedTasks != null) {
        // Small delay to ensure provider has been updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _refreshTaskOrder();
            debugPrint(
                '🔄 TaskList: Refreshed task order after returning from detail');
          }
        });
      }
    });
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
                  // Clear saved order for the new filter
                  _clearSavedTaskOrder();
                  // Load saved order for the new filter
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _loadSavedTaskOrder();
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
  final void Function(Task) onUncompleteTask;

  const TaskCard({
    super.key,
    required this.task,
    required this.user,
    required this.onTaskTap,
    required this.onCompleteTask,
    required this.onUncompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTaskCard(
      onTap: () => onTaskTap(task),
      isCompleted: task.status.isCompleted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Round complete button on the left - with enhanced gesture handling
          GestureDetector(
            onTap: _getCompleteAction(),
            onTapDown: (_) {
              // This helps prioritize the button tap over drag gestures
              debugPrint('🎯 TaskCard: Button tap down detected');
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(6), // Reduced touch target padding
              child: _buildCompleteButton(context),
            ),
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
      return () {
        debugPrint(
            '🎯 TaskCard: Complete button tapped for task: ${task.title}');
        onCompleteTask(task);
      };
    } else if (canUncomplete) {
      return () {
        debugPrint(
            '🎯 TaskCard: Uncomplete button tapped for task: ${task.title}');
        onUncompleteTask(task);
      };
    }
    return null;
  }

  Widget _buildCompleteButton(BuildContext context) {
    final bool isCompleted = task.status.isCompleted;
    final bool canComplete =
        task.status == TaskStatus.pending && (user?.id == task.assignedTo);
    final bool isVerified = task.isVerifiedByParent;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCompleted
            ? LinearGradient(
                colors: isVerified
                    ? [
                        Colors.green,
                        Colors.green.withValues(alpha: 0.8)
                      ] // Different color for verified tasks
                    : [
                        AppTheme.success,
                        AppTheme.success.withValues(alpha: 0.8)
                      ],
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
        size: 18,
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
              iconColor.withValues(alpha: 0.8),
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
