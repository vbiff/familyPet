import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
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
    if (user?.familyId != null) {
      ref.read(taskNotifierProvider.notifier).loadTasks(
            familyId: user!.familyId!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskNotifierProvider);
    final tasks = taskState.tasks;

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
          child: _buildTaskContent(context, taskState, tasks),
        ),
      ],
    );
  }

  Widget _buildTaskContent(
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTaskStatusColor(context, task.status)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTaskStatusIcon(task.status),
                color: _getTaskStatusColor(context, task.status),
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration:
                    task.status.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        _formatDueDate(task.dueDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTaskStatusColor(context, task.status)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getTaskStatusText(task.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTaskStatusColor(context, task.status),
                ),
              ),
            ),
            onTap: () => _onTaskTap(task),
          ),
        );
      },
    );
  }

  Color _getTaskStatusColor(BuildContext context, TaskStatus status) {
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

  IconData _getTaskStatusIcon(TaskStatus status) {
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

  String _getTaskStatusText(TaskStatus status) {
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

  String _formatDueDate(DateTime dueDate) {
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

  void _onTaskTap(Task task) {
    ref.read(taskNotifierProvider.notifier).selectTask(task);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }
}
