import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
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

enum _TaskFilterType { person, date }

class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  bool _isMyTasks = false;
  bool _isOverdue = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  void _loadTasks() {
    final user = ref.read(currentUserProvider);

    // Only load tasks if user has a real family
    if (user?.familyId != null) {
      ref.read(taskNotifierProvider.notifier).loadTasks(
            familyId: user!.familyId!,
          );
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
        _loadTasks();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                // Filter button with popup menu for person, deadline, and status
                PopupMenuButton<_TaskFilterType>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter Tasks',
                  onSelected: (filterType) async {
                    switch (filterType) {
                      case _TaskFilterType.person:
                        setState(() {
                          _isMyTasks = !_isMyTasks;
                        });
                        break;
                      case _TaskFilterType.date:
                        setState(() {
                          _isOverdue = !_isOverdue;
                        });
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _TaskFilterType.person,
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(_isMyTasks ? 'All tasks' : 'My tasks'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _TaskFilterType.date,
                      child: ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(_isOverdue ? 'By date' : 'By urgency'),
                      ),
                    ),
                  ],
                ),
                EnhancedButton.ghost(
                  leadingIcon: Icons.add,
                  text: 'Create',
                  size: EnhancedButtonSize.small,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateTaskPage(),
                    ),
                  ),
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
        const SizedBox(height: 16),
        Expanded(
          child: buildTaskContent(context, taskState, tasks),
        ),
      ],
    );
  }

  Widget buildTaskContent(
      BuildContext context, TaskState taskState, List<Task> tasks) {
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateTaskPage(),
                ),
              ),
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

    // Filter tasks based on user preferences and archived status
    List<Task> displayTasks = tasks
        .where((task) => !task.isArchived)
        .toList(); // Exclude archived tasks

    if (_isMyTasks && user != null) {
      displayTasks =
          displayTasks.where((task) => task.assignedTo == user.id).toList();
    }

    // Rebuild sorted tasks list based on current filters
    List<Task> sortedTasks;
    if (_isOverdue) {
      displayTasks = displayTasks.where((task) => task.isOverdue).toList();
      sortedTasks = List<Task>.from(displayTasks)
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else {
      sortedTasks = List<Task>.from(displayTasks)
        ..sort((a, b) => b.createdAt.compareTo(a.dueDate));
    }

    return ListView.builder(
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return SwipeToArchiveWidget(
          task: task,
          onArchived:
              null, // Remove the setState callback to prevent provider modification during build
          child: TaskCard(
            task: task,
            user: user,
            onTaskTap: onTaskTap,
            buildQuickActions: _buildQuickActions,
            getTaskDisplayColor: _getTaskDisplayColor,
            getTaskDisplayIcon: _getTaskDisplayIcon,
            getTaskDisplayText: _getTaskDisplayText,
            getCategoryDisplayName: _getCategoryDisplayName,
            getDifficultyColor: _getDifficultyColor,
            getDifficultyDisplayName: _getDifficultyDisplayName,
            getAssignedUserName: _getAssignedUserName,
            formatDueDate: formatDueDate,
          ),
        );
      },
    );
  }

  Color getTaskStatusColor(BuildContext context, TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Theme.of(context).colorScheme.primary;
      case TaskStatus.inProgress:
        return Theme.of(context).colorScheme.secondary;
      case TaskStatus.completed:
        return Theme.of(context).colorScheme.tertiary;
      case TaskStatus.expired:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData getTaskStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.hourglass_empty;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.expired:
        return Icons.error;
    }
  }

  String getTaskStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.expired:
        return 'Expired';
    }
  }

  // Helper methods that consider verification status
  Color _getTaskDisplayColor(BuildContext context, Task task) {
    if (task.status == TaskStatus.completed && task.isVerifiedByParent) {
      return Colors.green; // Green for verified
    }
    return getTaskStatusColor(context, task.status);
  }

  IconData _getTaskDisplayIcon(Task task) {
    if (task.status == TaskStatus.completed && task.isVerifiedByParent) {
      return Icons.verified; // Verified icon
    }
    return getTaskStatusIcon(task.status);
  }

  String _getTaskDisplayText(Task task) {
    if (task.status == TaskStatus.completed && task.isVerifiedByParent) {
      return 'Verified';
    }
    return getTaskStatusText(task.status);
  }

  String formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Today ${DateFormat('HH:mm').format(dueDate)}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${DateFormat('HH:mm').format(dueDate)}';
    } else if (taskDate.isBefore(today)) {
      return 'Overdue ${DateFormat('MMM d').format(dueDate)}';
    } else {
      return DateFormat('MMM d, HH:mm').format(dueDate);
    }
  }

  String _getAssignedUserName(String assignedUserId) {
    final currentUser = ref.read(currentUserProvider);
    final familyMembers = ref.read(familyMembersProvider);

    // Check if it's the current user
    if (currentUser != null && assignedUserId == currentUser.id) {
      return 'You';
    }

    // Find the assigned user in family members
    for (final member in familyMembers) {
      if (member.id == assignedUserId) {
        return member.displayName.isNotEmpty
            ? member.displayName
            : 'Family Member';
      }
    }

    // Fallback if user not found
    return 'Unknown User';
  }

  Widget _buildQuickActions(BuildContext context, Task task) {
    final currentUser = ref.watch(currentUserProvider);
    final isUpdating = ref.watch(taskNotifierProvider).isUpdating;

    return Row(
      children: [
        if (task.status == TaskStatus.pending) ...[
          // Mark as Complete button for pending tasks
          Expanded(
            child: EnhancedButton.primary(
              text: 'Complete',
              leadingIcon: Icons.check,
              isLoading: isUpdating,
              backgroundColor: Colors.green,
              onPressed: isUpdating ? null : () => _markAsCompleted(task),
            ),
          ),
        ] else if (task.needsVerification && currentUser != null) ...[
          // Only parents can verify tasks
          if (currentUser.role == UserRole.parent) ...[
            // Verify button for completed but unverified tasks (parents only)
            Expanded(
              flex: 2,
              child: EnhancedButton.primary(
                text: 'Verify',
                leadingIcon: Icons.verified,
                backgroundColor: Colors.blue,
                onPressed: isUpdating ? null : () => _verifyTask(task),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: EnhancedButton.outline(
                text: 'Undo',
                leadingIcon: Icons.undo,
                onPressed: isUpdating ? null : () => _markAsPending(task),
              ),
            ),
          ] else ...[
            // Children see waiting message
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_empty,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for parent verification',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ] else if (task.status == TaskStatus.completed) ...[
          // Undo button for completed tasks
          Expanded(
            child: EnhancedButton.outline(
              text: 'Mark Pending',
              leadingIcon: Icons.undo,
              onPressed: isUpdating ? null : () => _markAsPending(task),
            ),
          ),
        ],
      ],
    );
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
              await ref.read(taskNotifierProvider.notifier).updateTaskStatus(
                  taskId: task.id, status: TaskStatus.completed);

              // If there are new images, update the task with them
              if (imageUrls.isNotEmpty && mounted) {
                await ref.read(taskNotifierProvider.notifier).updateTask(
                      UpdateTaskParams(
                        taskId: task.id,
                        imageUrls: [...task.imageUrls, ...imageUrls],
                      ),
                    );
              }
            } catch (e) {
              // Handle errors gracefully
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Failed to mark task as completed: $e'),
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

  Future<void> _markAsPending(Task task) async {
    // Check if widget is still mounted before starting async operation
    if (!mounted) return;

    try {
      print('🔍 DEBUG: Marking task as pending: ${task.title}');
      print('🔍 DEBUG: Current task status: ${task.status}');
      print('🔍 DEBUG: Current image URLs: ${task.imageUrls}');

      // If task was completed and had photos, clear them when marking as pending
      if (task.status == TaskStatus.completed && task.imageUrls.isNotEmpty) {
        print('🔍 DEBUG: Task has photos, clearing them...');
        // Update both status and clear photos in one operation
        await ref.read(taskNotifierProvider.notifier).updateTask(
              UpdateTaskParams(
                taskId: task.id,
                imageUrls: [], // Clear all photos
              ),
            );
        print('🔍 DEBUG: Photos cleared successfully');
      }

      // Update the status to pending
      print('🔍 DEBUG: Updating status to pending...');
      await ref
          .read(taskNotifierProvider.notifier)
          .updateTaskStatus(taskId: task.id, status: TaskStatus.pending);
      print('🔍 DEBUG: Status updated to pending');

      // Reload tasks to ensure UI is updated
      final user = ref.read(currentUserProvider);
      if (user?.familyId != null) {
        print('🔍 DEBUG: Reloading tasks...');
        await ref.read(taskNotifierProvider.notifier).loadTasks(
              familyId: user!.familyId!,
            );
        print('🔍 DEBUG: Tasks reloaded');
      }

      // Check again if widget is still mounted before showing snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔄 "${task.title}" marked as pending'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Error in _markAsPending: $e');
      // Handle errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to mark task as pending: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _verifyTask(Task task) async {
    // Check if widget is still mounted before starting async operation
    if (!mounted) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Validate user is a parent
    if (currentUser.role != UserRole.parent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Only parents can verify tasks'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await ref.read(taskNotifierProvider.notifier).updateTaskStatus(
            taskId: task.id,
            status: TaskStatus.completed,
            verifiedById: currentUser.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🏆 "${task.title}" verified! ${task.points} points awarded'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to verify task: $e'),
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

  Widget _buildNoFamilyContent(BuildContext context) {
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
            'No family setup',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please set up your family to manage tasks',
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
    );
  }

  String _getCategoryDisplayName(String? categoryName) {
    if (categoryName == null) return '';
    try {
      final category =
          TaskCategory.values.firstWhere((c) => c.name == categoryName);
      return category.displayName;
    } catch (e) {
      return categoryName;
    }
  }

  String _getDifficultyDisplayName(String? difficultyName) {
    if (difficultyName == null) return '';
    try {
      final difficulty =
          TaskDifficulty.values.firstWhere((d) => d.name == difficultyName);
      return difficulty.displayName;
    } catch (e) {
      return difficultyName;
    }
  }

  Color _getDifficultyColor(String? difficultyName) {
    if (difficultyName == null) return Colors.grey;
    try {
      final difficulty =
          TaskDifficulty.values.firstWhere((d) => d.name == difficultyName);
      switch (difficulty) {
        case TaskDifficulty.easy:
          return Colors.green;
        case TaskDifficulty.medium:
          return Colors.orange;
        case TaskDifficulty.hard:
          return Colors.red;
      }
    } catch (e) {
      return Colors.grey;
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final User? user;
  final void Function(Task) onTaskTap;
  final Widget Function(BuildContext, Task) buildQuickActions;
  final Color Function(BuildContext, Task) getTaskDisplayColor;
  final IconData Function(Task) getTaskDisplayIcon;
  final String Function(Task) getTaskDisplayText;
  final String Function(String?) getCategoryDisplayName;
  final Color Function(String?) getDifficultyColor;
  final String Function(String?) getDifficultyDisplayName;
  final String Function(String) getAssignedUserName;
  final String Function(DateTime) formatDueDate;

  const TaskCard({
    super.key,
    required this.task,
    required this.user,
    required this.onTaskTap,
    required this.buildQuickActions,
    required this.getTaskDisplayColor,
    required this.getTaskDisplayIcon,
    required this.getTaskDisplayText,
    required this.getCategoryDisplayName,
    required this.getDifficultyColor,
    required this.getDifficultyDisplayName,
    required this.getAssignedUserName,
    required this.formatDueDate,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard.outlined(
      backgroundColor: task.assignedTo == user?.id
          ? Colors.transparent
          : const Color.fromARGB(26, 60, 60, 60),
      onTap: () => onTaskTap(task),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and points
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      getTaskDisplayColor(context, task).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  getTaskDisplayIcon(task),
                  color: getTaskDisplayColor(context, task),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: task.status.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      getTaskDisplayColor(context, task).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getTaskDisplayText(task),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: getTaskDisplayColor(context, task),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Task details
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                formatDueDate(task.dueDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: task.isOverdue
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              const Icon(
                Icons.stars,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 4),
              Text(
                '${task.points} pts',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Category and Difficulty indicators
          if (task.metadata != null &&
              (task.metadata!['category'] != null ||
                  task.metadata!['difficulty'] != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (task.metadata!['category'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        getCategoryDisplayName(task.metadata!['category']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (task.metadata!['difficulty'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: getDifficultyColor(task.metadata!['difficulty'])
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              getDifficultyColor(task.metadata!['difficulty']),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        getDifficultyDisplayName(task.metadata!['difficulty']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: getDifficultyColor(
                                  task.metadata!['difficulty']),
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_outline,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Assigned to: ${getAssignedUserName(task.assignedTo)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),

          // Quick Action Buttons
          if (!task.isVerifiedByParent) ...[
            const SizedBox(height: 16),
            buildQuickActions(context, task),
          ],
        ],
      ),
    );
  }
}
