import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/shared/widgets/enhanced_card.dart';
import 'package:jhonny/shared/widgets/loading_indicators.dart';
import 'package:jhonny/features/task/domain/usecases/update_task.dart';

class ArchivePage extends ConsumerStatefulWidget {
  final VoidCallback? onTasksChanged;

  const ArchivePage({
    super.key,
    this.onTasksChanged,
  });

  @override
  ConsumerState<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends ConsumerState<ArchivePage>
    with WidgetsBindingObserver {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use addPostFrameCallback to ensure this happens after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArchivedTasks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // CRITICAL: Refresh main task list when disposing Archive page
    debugPrint('🔄 Archive: Page disposing, triggering final refresh');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshMainTaskList();
      }
    });

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      _loadArchivedTasks();
    }
  }

  Future<void> _loadArchivedTasks() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔄 Archive: Loading archived tasks');
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.familyId != null) {
        await ref.read(taskNotifierProvider.notifier).loadArchivedTasks(
              familyId: currentUser!.familyId!,
            );
        debugPrint('✅ Archive: Archived tasks loaded');
      } else {
        debugPrint('⚠️ Archive: Cannot load - no current user or family ID');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshMainTaskList() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.familyId != null) {
      debugPrint(
          '🔄 Archive: Refreshing main task list for family ${currentUser!.familyId}');

      // Force complete refresh using invalidation and reload
      ref.invalidate(taskNotifierProvider);
      await ref.read(taskNotifierProvider.notifier).loadTasks(
            familyId: currentUser.familyId!,
          );

      debugPrint('✅ Archive: Main task list refresh completed');

      // Add a small delay to ensure state propagation
      await Future.delayed(const Duration(milliseconds: 100));
    } else {
      debugPrint('⚠️ Archive: Cannot refresh - no current user or family ID');
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isParent = currentUser?.role == UserRole.parent;

    // Filter archived tasks
    final archivedTasks =
        taskState.tasks.where((task) => task.isArchived).toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          debugPrint('🔄 Archive: PopScope triggered - refreshing main tasks');

          // Use addPostFrameCallback to ensure this runs after the pop
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              final currentUser = ref.read(currentUserProvider);
              if (currentUser?.familyId != null) {
                debugPrint('🔄 Archive: Executing post-frame refresh');
                ref.invalidate(taskNotifierProvider);
                await ref.read(taskNotifierProvider.notifier).loadTasks(
                      familyId: currentUser!.familyId!,
                    );
                debugPrint('✅ Archive: Post-pop refresh completed');
              }
            } catch (e) {
              debugPrint('❌ Archive: Error in post-pop refresh: $e');
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Archived Tasks'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              debugPrint(
                  '🔄 Archive: Custom back button pressed - refreshing before pop');

              try {
                await _refreshMainTaskList();
                debugPrint('✅ Archive: Refresh completed, now popping');
              } catch (e) {
                debugPrint('❌ Archive: Error during back button refresh: $e');
              }

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (archivedTasks.isNotEmpty && isParent)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear All', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadArchivedTasks,
          child: _isLoading
              ? const Center(child: PulsingLoadingIndicator())
              : _buildContent(archivedTasks, isParent),
        ),
      ),
    );
  }

  Widget _buildContent(List<Task> archivedTasks, bool isParent) {
    if (archivedTasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Archived Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tasks you archive will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: archivedTasks.length,
      itemBuilder: (context, index) {
        final task = archivedTasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildArchivedTaskCard(task, isParent),
        );
      },
    );
  }

  Widget _buildArchivedTaskCard(Task task, bool isParent) {
    return EnhancedCard(
      type: EnhancedCardType.outline,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.archive,
                    color: Colors.grey,
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                      ),
                      Text(
                        'Archived • ${_formatDate(task.updatedAt ?? task.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${task.points} pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 16),

            // Action buttons (only for parents)
            if (isParent)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreTask(task),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteTaskPermanently(task),
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _restoreTask(Task task) async {
    try {
      debugPrint('🔄 Archive: Starting task restore for "${task.title}"');

      // Use Future.microtask to ensure this happens outside the current build cycle
      await Future.microtask(() async {
        if (!context.mounted) return;

        debugPrint('🔄 Archive: Updating task to non-archived');
        await ref.read(taskNotifierProvider.notifier).updateTask(
              UpdateTaskParams(
                taskId: task.id,
                isArchived: false,
              ),
            );

        debugPrint(
            '🔄 Archive: Task update completed, refreshing main task list');
        // Refresh main task list to show restored task
        if (context.mounted) {
          await _refreshMainTaskList();

          // Force provider invalidation to ensure UI refresh
          ref.invalidate(taskNotifierProvider);

          // Reload archived tasks to update this page
          await _loadArchivedTasks();
        }

        // Call callback if provided
        widget.onTasksChanged?.call();
        debugPrint('✅ Archive: Task restore completed successfully');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Archive: Failed to restore task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTaskPermanently(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text(
          'Are you sure you want to permanently delete "${task.title}"? This action cannot be undone.',
        ),
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
      try {
        // Use Future.microtask to ensure this happens outside the current build cycle
        await Future.microtask(() async {
          if (!context.mounted) return;

          await ref.read(taskNotifierProvider.notifier).deleteTask(task.id);

          // Refresh main task list
          if (context.mounted) {
            await _refreshMainTaskList();

            // Force provider invalidation to ensure UI refresh
            ref.invalidate(taskNotifierProvider);

            // Reload archived tasks to update this page
            await _loadArchivedTasks();
          }

          // Call callback if provided
          widget.onTasksChanged?.call();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Task deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Archived Tasks'),
        content: const Text(
          'Are you sure you want to permanently delete ALL archived tasks? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final archivedTasks = ref
            .read(taskNotifierProvider)
            .tasks
            .where((task) => task.isArchived)
            .toList();

        // Use Future.microtask to ensure this happens outside the current build cycle
        await Future.microtask(() async {
          if (!context.mounted) return;

          for (final task in archivedTasks) {
            await ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
          }

          // Refresh main task list
          if (context.mounted) {
            await _refreshMainTaskList();
          }

          // Call callback if provided
          widget.onTasksChanged?.call();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ All archived tasks cleared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear archived tasks: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
