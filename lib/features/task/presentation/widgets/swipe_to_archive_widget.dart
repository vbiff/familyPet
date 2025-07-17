import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/task/domain/usecases/update_task.dart';

class SwipeToArchiveWidget extends ConsumerWidget {
  final Task task;
  final Widget child;
  final VoidCallback? onArchived;

  const SwipeToArchiveWidget({
    super.key,
    required this.task,
    required this.child,
    this.onArchived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Archive',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirmed = await _showArchiveConfirmation(context);
          if (confirmed == true) {
            // Archive the task immediately when confirmed
            await _archiveTask(ref, context);
          }
          // Always return false to prevent automatic dismissal
          // We handle the removal through state management
          return false;
        }
        return false;
      },
      child: child,
    );
  }

  Future<bool?> _showArchiveConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Task'),
        content: Text(
          'Are you sure you want to archive "${task.title}"? You can restore it later from the Archive page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveTask(WidgetRef ref, BuildContext context) async {
    try {
      // Check if context is mounted before proceeding
      if (!context.mounted) return;

      // Store notifier reference before async operation
      final taskNotifier = ref.read(taskNotifierProvider.notifier);

      // Check mounted again right before async operation
      if (!context.mounted) return;

      await taskNotifier.updateTask(
        UpdateTaskParams(
          taskId: task.id,
          isArchived: true,
        ),
      );

      onArchived?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
