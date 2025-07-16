import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            onCompleteTask: _markAsCompleted,
          ),
        );
      },
    );
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
            // Use Future.microtask to ensure this happens outside the current build cycle
            await Future.microtask(() async {
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
                // Handle errors gracefully - only show critical errors
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to complete task: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            });
          },
        );
      },
    );
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
}

class TaskCard extends StatelessWidget {
  final Task task;
  final User? user;
  final void Function(Task) onTaskTap;
  final void Function(Task) onCompleteTask;

  const TaskCard({
    super.key,
    required this.task,
    required this.user,
    required this.onTaskTap,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTaskTap(task),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Round complete button on the left
                _buildCompleteButton(context),
                const SizedBox(width: 16),
                // Task title
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration: task.status.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.status.isCompleted
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                // Status indicator
                if (task.isVerifiedByParent)
                  const Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 20,
                  )
                else if (task.needsVerification)
                  const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    final bool isCompleted = task.status.isCompleted;
    final bool canComplete =
        task.status == TaskStatus.pending && (user?.id == task.assignedTo);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.1)
            : canComplete
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isCompleted
              ? Colors.green
              : canComplete
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canComplete ? () => onCompleteTask(task) : null,
          borderRadius: BorderRadius.circular(20),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle_outlined,
            color: isCompleted
                ? Colors.green
                : canComplete
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
            size: 20,
          ),
        ),
      ),
    );
  }
}
