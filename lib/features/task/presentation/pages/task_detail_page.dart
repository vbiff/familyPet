import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/task/presentation/pages/create_task_page.dart';

class TaskDetailPage extends ConsumerWidget {
  final Task task;
  static final _logger = Logger();

  const TaskDetailPage({
    super.key,
    required this.task,
  });

  Task _getCurrentTask(WidgetRef ref) {
    final taskState = ref.watch(taskNotifierProvider);
    return taskState.tasks.firstWhere(
      (t) => t.id == task.id,
      orElse: () => task,
    );
  }

  String _getMemberName(WidgetRef ref, String userId) {
    final familyMembers = ref.watch(familyMembersProvider);
    try {
      final member = familyMembers.firstWhere((member) => member.id == userId);
      return member.displayName;
    } catch (e) {
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(taskUpdatingProvider);
    final currentTask = _getCurrentTask(ref);
    final currentUser = ref.watch(currentUserProvider);
    final isParent = currentUser?.role == UserRole.parent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          // Only show delete option to parents
          if (isParent)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit Task', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Task', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleMenuAction(context, ref, value),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTaskHeader(context, currentTask),
            const SizedBox(height: 24),
            _buildTaskInfo(context, ref, currentTask),
            const SizedBox(height: 24),
            _buildTaskSchedule(context, currentTask),
            const SizedBox(height: 24),
            _buildTaskStatus(context, ref, currentTask),
            const SizedBox(height: 32),
            _buildActionButtons(context, ref, isUpdating, currentTask),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader(BuildContext context, Task currentTask) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(context, currentTask),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentTask.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _buildPointsBadge(context, currentTask),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentTask.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, Task currentTask) {
    IconData icon;
    Color color;

    if (currentTask.needsVerification) {
      icon = Icons.visibility;
      color = Colors.blue;
    } else if (currentTask.isVerifiedByParent) {
      icon = Icons.verified;
      color = Colors.green;
    } else {
      switch (currentTask.status) {
        case TaskStatus.pending:
          icon = Icons.pending;
          color = Colors.orange;
          break;
        case TaskStatus.inProgress:
          icon = Icons.hourglass_empty;
          color = Colors.blue;
          break;
        case TaskStatus.completed:
          icon = Icons.check_circle;
          color = Colors.green;
          break;
        case TaskStatus.expired:
          icon = Icons.error;
          color = Colors.red;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildPointsBadge(BuildContext context, Task currentTask) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${currentTask.points}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfo(BuildContext context, WidgetRef ref, Task currentTask) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.person,
              'Assigned to',
              _getMemberName(ref, currentTask.assignedTo),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.person_add,
              'Created by',
              _getMemberName(ref, currentTask.createdBy),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.repeat,
              'Frequency',
              _getFrequencyText(currentTask.frequency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSchedule(BuildContext context, Task currentTask) {
    final now = DateTime.now();
    final isOverdue = currentTask.dueDate.isBefore(now) &&
        currentTask.status == TaskStatus.pending;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Due Date',
              DateFormat.yMMMMd().add_jm().format(currentTask.dueDate),
              textColor: isOverdue ? Theme.of(context).colorScheme.error : null,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.update,
              'Last Updated',
              currentTask.updatedAt != null
                  ? DateFormat.yMMMMd().add_jm().format(currentTask.updatedAt!)
                  : 'Not updated yet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatus(
      BuildContext context, WidgetRef ref, Task currentTask) {
    final verifierName = currentTask.verifiedById != null
        ? 'by ${_getMemberName(ref, currentTask.verifiedById!)}'
        : '';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.info_outline,
              'Current Status',
              _getStatusText(currentTask),
            ),
            if (currentTask.isVerifiedByParent) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.verified_user,
                'Verified',
                currentTask.verifiedAt != null
                    ? '${DateFormat.yMMMMd().add_jm().format(currentTask.verifiedAt!)} $verifierName'
                    : 'Yes',
              ),
            ],
            if (currentTask.status.isCompleted &&
                !currentTask.isVerifiedByParent) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.hourglass_top,
                'Completed At',
                currentTask.completedAt != null
                    ? DateFormat.yMMMMd()
                        .add_jm()
                        .format(currentTask.completedAt!)
                    : 'Awaiting verification',
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    bool isUpdating,
    Task currentTask,
  ) {
    final currentUser = ref.watch(currentUserProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildChildContent(context, ref, isUpdating, currentTask),
        ),
      ),
      if (currentUser?.role == UserRole.parent &&
          currentTask.status != TaskStatus.expired)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildParentContent(context, ref, isUpdating, currentTask),
        ),
    ]);
  }

  Widget _buildChildContent(
    BuildContext context,
    WidgetRef ref,
    bool isUpdating,
    Task currentTask,
  ) {
    if (currentTask.needsVerification) {
      return _waitingForVerification(context);
    }

    switch (currentTask.status) {
      case TaskStatus.pending:
      case TaskStatus.inProgress:
        return _buildCompleteButton(context, ref, isUpdating, currentTask);
      case TaskStatus.completed:
        return _buildMarkAsPendingButton(context, ref, isUpdating, currentTask);
      case TaskStatus.expired:
        return _buildExpiredMessage(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildParentContent(
    BuildContext context,
    WidgetRef ref,
    bool isUpdating,
    Task currentTask,
  ) {
    if (currentTask.needsVerification) {
      return _buildVerificationControls(context, ref, isUpdating, currentTask);
    }

    if (currentTask.isVerifiedByParent) {
      return _buildRestoreOrUnverifyControls(
          context, ref, isUpdating, currentTask);
    }

    return const SizedBox.shrink();
  }

  // Action Buttons
  Widget _buildCompleteButton(
      BuildContext context, WidgetRef ref, bool isUpdating, Task currentTask) {
    return FilledButton.icon(
      onPressed: isUpdating
          ? null
          : () => _markAsCompleted(context, ref, currentTask, isUpdating),
      icon: isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(isUpdating ? 'Updating...' : 'Mark as Completed'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildMarkAsPendingButton(
      BuildContext context, WidgetRef ref, bool isUpdating, Task currentTask) {
    return OutlinedButton.icon(
      onPressed: isUpdating
          ? null
          : () => _markAsPending(context, ref, currentTask, isUpdating),
      icon: const Icon(Icons.undo),
      label: const Text('Mark as Pending'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }

  Widget _buildVerificationControls(
      BuildContext context, WidgetRef ref, bool isUpdating, Task currentTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed:
              isUpdating ? null : () => _verifyTask(context, ref, currentTask),
          icon: const Icon(Icons.verified),
          label: const Text('Verify & Award Points'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed:
              isUpdating ? null : () => _rejectTask(context, ref, currentTask),
          icon: const Icon(Icons.close),
          label: const Text('Mark as Pending'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildRestoreOrUnverifyControls(
      BuildContext context, WidgetRef ref, bool isUpdating, Task currentTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentTask.status == TaskStatus.expired)
          OutlinedButton.icon(
            onPressed: isUpdating
                ? null
                : () => _markAsPending(context, ref, currentTask, isUpdating),
            icon: const Icon(Icons.restore),
            label: const Text('Restore Task'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUpdating
                      ? null
                      : () => _unverifyTask(context, ref, currentTask),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Remove Verification'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: textColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getFrequencyText(TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.once:
        return 'One time only';
      case TaskFrequency.daily:
        return 'Daily';
      case TaskFrequency.weekly:
        return 'Weekly';
      case TaskFrequency.monthly:
        return 'Monthly';
    }
  }

  String _getStatusText(Task currentTask) {
    if (currentTask.needsVerification) {
      return 'Needs parent verification';
    } else if (currentTask.isVerifiedByParent) {
      return 'Completed and verified';
    } else {
      switch (currentTask.status) {
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
  }

  // Action methods
  Future<void> _markAsCompleted(BuildContext context, WidgetRef ref,
      Task currentTask, bool isUpdating) async {
    if (isUpdating) return;

    await ref.read(taskNotifierProvider.notifier).updateTaskStatus(
          taskId: currentTask.id,
          status: TaskStatus.completed,
        );
  }

  Future<void> _markAsPending(BuildContext context, WidgetRef ref,
      Task currentTask, bool isUpdating) async {
    if (isUpdating) return;

    await ref.read(taskNotifierProvider.notifier).updateTaskStatus(
          taskId: currentTask.id,
          status: TaskStatus.pending,
        );
  }

  Future<void> _verifyTask(
      BuildContext context, WidgetRef ref, Task currentTask) async {
    try {
      final currentUser = ref.read(currentUserProvider);

      // Validate user is a parent
      if (currentUser?.role != UserRole.parent) {
        _logger.w('Non-parent user attempted to verify task');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Only parents can verify tasks'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _logger.d('Current task status: ${currentTask.status.name}');
      _logger.d('Is verified: ${currentTask.isVerifiedByParent}');
      _logger.d('Needs verification: ${currentTask.needsVerification}');
      _logger.d('VerifiedById: ${currentTask.verifiedById}');

      // Only verify if task is completed but not verified yet
      if (currentTask.status == TaskStatus.completed &&
          !currentTask.isVerifiedByParent) {
        _logger.i('Attempting to verify task...');

        final verifiedById = currentUser!.id;
        _logger.d('Current user ID: $verifiedById');

        await ref.read(taskNotifierProvider.notifier).updateTaskStatus(
              taskId: currentTask.id,
              status: TaskStatus.completed,
              verifiedById: verifiedById,
            );

        _logger.i('Verification request sent');

        // Show success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Task verified and points awarded!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _logger.w('Cannot verify task');
        _logger.w('Status: ${currentTask.status.name}');
        _logger.w('Already verified: ${currentTask.isVerifiedByParent}');

        // Show why verification failed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cannot verify: Status=${currentTask.status.name}, Verified=${currentTask.isVerifiedByParent}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Verification error: $e');
      // Show error feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to verify task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unverifyTask(
      BuildContext context, WidgetRef ref, Task currentTask) async {
    try {
      final currentUser = ref.read(currentUserProvider);

      // Validate user is a parent
      if (currentUser?.role != UserRole.parent) {
        _logger.w('Non-parent user attempted to unverify task');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Only parents can remove verification'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _logger.d('Attempting to unverify task...');
      _logger.d('Current verified by: ${currentTask.verifiedById}');

      // Only unverify if task is currently verified
      if (currentTask.isVerifiedByParent) {
        await ref.read(taskNotifierProvider.notifier).updateTaskStatus(
              taskId: currentTask.id,
              status: TaskStatus.completed,
              clearVerification: true, // Clear verification
            );

        // Show success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 Task verification removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Show error feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to unverify task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectTask(
      BuildContext context, WidgetRef ref, Task currentTask) async {
    await ref.read(taskNotifierProvider.notifier).updateTaskStatus(
          taskId: currentTask.id,
          status: TaskStatus.pending,
        );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        _showEditTask(context, ref);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      }
    }
  }

  Future<void> _showEditTask(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(task: _getCurrentTask(ref)),
      ),
    );
  }

  Widget _waitingForVerification(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.orange),
          const SizedBox(width: 12),
          Text(
            'Waiting for Parent Verification',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Text(
            'Task Expired',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
