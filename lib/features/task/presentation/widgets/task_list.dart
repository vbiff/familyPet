import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/pages/create_task_page.dart';
import 'package:jhonny/features/task/presentation/pages/task_detail_page.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/task/presentation/providers/task_state.dart';

class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  void _loadTasks() {
    final user = ref.read(currentUserProvider);
    // Use test family ID as fallback until proper family management is implemented
    final familyId = user?.familyId ?? '88888888-8888-8888-8888-888888888888';

    ref.read(taskNotifierProvider.notifier).loadTasks(
          familyId: familyId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskNotifierProvider);
    final tasks = taskState.tasks;

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
              'Today\'s Tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateTaskPage(),
                    ),
                  ),
                  tooltip: 'Create Task',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTasks,
                  tooltip: 'Refresh',
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
            FilledButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTaskDisplayColor(context, task)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTaskDisplayIcon(task),
                    color: _getTaskDisplayColor(context, task),
                  ),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task.status.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatDueDate(task.dueDate),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: task.isOverdue
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.stars,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.points}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Assigned to row
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to: ${_getAssignedUserName(task.assignedTo)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTaskDisplayColor(context, task)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getTaskDisplayText(task),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getTaskDisplayColor(context, task),
                    ),
                  ),
                ),
                onTap: () => onTaskTap(task),
              ),
              // Quick Action Buttons
              _buildQuickActions(context, task),
            ],
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
      return Theme.of(context).colorScheme.primary; // Green for verified
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

    // Don't show actions if task is verified
    if (task.isVerifiedByParent) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (task.status == TaskStatus.pending) ...[
            // Mark as Complete button for pending tasks
            FilledButton.icon(
              onPressed: isUpdating ? null : () => _markAsCompleted(task),
              icon: isUpdating
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 16),
              label: const Text('Complete'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ] else if (task.needsVerification && currentUser != null) ...[
            // Verify button for completed but unverified tasks
            FilledButton.icon(
              onPressed: isUpdating ? null : () => _verifyTask(task),
              icon: const Icon(Icons.verified, size: 16),
              label: const Text('Verify'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: isUpdating ? null : () => _markAsPending(task),
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('Undo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ] else if (task.status == TaskStatus.completed) ...[
            // Undo button for completed tasks
            OutlinedButton.icon(
              onPressed: isUpdating ? null : () => _markAsPending(task),
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('Mark Pending'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markAsCompleted(Task task) async {
    await ref
        .read(taskNotifierProvider.notifier)
        .updateTaskStatus(taskId: task.id, status: TaskStatus.completed);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${task.title}" marked as completed!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markAsPending(Task task) async {
    await ref
        .read(taskNotifierProvider.notifier)
        .updateTaskStatus(taskId: task.id, status: TaskStatus.pending);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 "${task.title}" marked as pending'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _verifyTask(Task task) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

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
  }

  void onTaskTap(Task task) {
    ref.read(taskNotifierProvider.notifier).selectTask(task);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }
}
