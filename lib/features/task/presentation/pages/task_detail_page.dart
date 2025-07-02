import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';

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
            _buildTaskInfo(context, ref),
            const SizedBox(height: 24),
            _buildTaskSchedule(context),
            const SizedBox(height: 24),
            _buildTaskStatus(context, currentTask),
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

  Widget _buildTaskInfo(BuildContext context, WidgetRef ref) {
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
              _getMemberName(ref, task.assignedTo),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.person_add,
              'Created by',
              _getMemberName(ref, task.createdBy),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.repeat,
              'Frequency',
              _getFrequencyText(task.frequency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSchedule(BuildContext context) {
    final now = DateTime.now();
    final isOverdue =
        task.dueDate.isBefore(now) && task.status == TaskStatus.pending;

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
              'Created',
              DateFormat('MMM dd, yyyy - HH:mm').format(task.createdAt),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.schedule,
              'Due date',
              DateFormat('MMM dd, yyyy - HH:mm').format(task.dueDate),
              isHighlight: isOverdue,
              highlightColor: Colors.red,
            ),
            if (task.completedAt != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.check_circle,
                'Completed',
                DateFormat('MMM dd, yyyy - HH:mm').format(task.completedAt!),
                highlightColor: Colors.green,
              ),
            ],
            if (task.verifiedAt != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.verified,
                'Verified',
                DateFormat('MMM dd, yyyy - HH:mm').format(task.verifiedAt!),
                highlightColor: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatus(BuildContext context, Task currentTask) {
    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (currentTask.isVerifiedByParent) {
      statusText = 'Verified';
      statusIcon = Icons.verified;
      statusColor = Colors.green;
    } else if (currentTask.needsVerification) {
      statusText = 'Needs Verification';
      statusIcon = Icons.visibility;
      statusColor = Colors.blue;
    } else {
      statusText = _getStatusText(currentTask.status);
      statusIcon = _getStatusIcon(currentTask.status);
      statusColor = _getStatusColor(currentTask.status);
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 12),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, bool isUpdating, Task currentTask) {
    if (currentTask.isVerifiedByParent) {
      return _buildVerifiedActions(context, ref, isUpdating, currentTask);
    } else if (currentTask.needsVerification) {
      return _buildVerificationActions(context, ref, isUpdating);
    } else {
      switch (currentTask.status) {
        case TaskStatus.pending:
        case TaskStatus.inProgress:
          return _buildPendingActions(context, ref, isUpdating);
        case TaskStatus.completed:
          return _buildCompletedActions(context, ref, isUpdating);
        case TaskStatus.expired:
          return _buildExpiredActions(context, ref, isUpdating);
      }
    }
  }

  Widget _buildPendingActions(
      BuildContext context, WidgetRef ref, bool isUpdating) {
    return FilledButton.icon(
      onPressed: isUpdating ? null : () => _markAsCompleted(ref),
      icon: isUpdating
          ? const SizedBox(
              width: 16,
              height: 16,
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

  Widget _buildCompletedActions(
      BuildContext context, WidgetRef ref, bool isUpdating) {
    return OutlinedButton.icon(
      onPressed: isUpdating ? null : () => _markAsPending(ref),
      icon: const Icon(Icons.undo),
      label: const Text('Mark as Pending'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }

  Widget _buildVerificationActions(
      BuildContext context, WidgetRef ref, bool isUpdating) {
    final currentUser = ref.watch(currentUserProvider);
    final isParent = currentUser?.role == UserRole.parent;

    // Only parents can verify tasks
    if (!isParent) {
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
            const SizedBox(width: 8),
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

    return Column(
      children: [
        FilledButton.icon(
          onPressed: isUpdating ? null : () => _verifyTask(ref),
          icon: const Icon(Icons.verified),
          label: const Text('Verify & Award Points'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isUpdating ? null : () => _rejectTask(ref),
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

  Widget _buildExpiredActions(
      BuildContext context, WidgetRef ref, bool isUpdating) {
    return OutlinedButton.icon(
      onPressed: isUpdating ? null : () => _markAsPending(ref),
      icon: const Icon(Icons.restore),
      label: const Text('Restore Task'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
      ),
    );
  }

  Widget _buildVerifiedActions(
      BuildContext context, WidgetRef ref, bool isUpdating, Task currentTask) {
    final currentUser = ref.watch(currentUserProvider);
    final isParent = currentUser?.role == UserRole.parent;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Task Verified & Points Awarded',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        // Only parents can remove verification
        if (isParent) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isUpdating ? null : () => _unverifyTask(ref),
            icon: const Icon(Icons.cancel),
            label: const Text('Remove Verification'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    final textColor = isHighlight
        ? (highlightColor ?? Theme.of(context).colorScheme.error)
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(
          icon,
          color: isHighlight
              ? (highlightColor ?? Theme.of(context).colorScheme.error)
              : Theme.of(context).colorScheme.primary,
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
                  fontWeight: isHighlight ? FontWeight.bold : null,
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

  String _getStatusText(TaskStatus status) {
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

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.inProgress:
        return Icons.hourglass_empty;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.expired:
        return Icons.error;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.expired:
        return Colors.red;
    }
  }

  // Action methods
  Future<void> _markAsCompleted(WidgetRef ref) async {
    await ref
        .read(taskNotifierProvider.notifier)
        .updateTaskStatus(taskId: task.id, status: TaskStatus.completed);
  }

  Future<void> _markAsPending(WidgetRef ref) async {
    await ref
        .read(taskNotifierProvider.notifier)
        .updateTaskStatus(taskId: task.id, status: TaskStatus.pending);
  }

  Future<void> _verifyTask(WidgetRef ref) async {
    try {
      final currentTask = _getCurrentTask(ref);
      final currentUser = ref.read(currentUserProvider);

      // Validate user is a parent
      if (currentUser?.role != UserRole.parent) {
        _logger.w('Non-parent user attempted to verify task');
        if (ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
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
              taskId: task.id,
              status: TaskStatus.completed,
              verifiedById: verifiedById,
            );

        _logger.i('Verification request sent');

        // Show success feedback
        if (ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
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
        if (ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
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
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to verify task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unverifyTask(WidgetRef ref) async {
    try {
      final currentTask = _getCurrentTask(ref);
      final currentUser = ref.read(currentUserProvider);

      // Validate user is a parent
      if (currentUser?.role != UserRole.parent) {
        _logger.w('Non-parent user attempted to unverify task');
        if (ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
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
              taskId: task.id,
              status: TaskStatus.completed,
              clearVerification: true, // Clear verification
            );

        // Show success feedback
        if (ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            const SnackBar(
              content: Text('🔄 Task verification removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Show error feedback
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to unverify task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectTask(WidgetRef ref) async {
    await ref
        .read(taskNotifierProvider.notifier)
        .updateTaskStatus(taskId: task.id, status: TaskStatus.pending);
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
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
}
