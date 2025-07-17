import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/shared/widgets/enhanced_card.dart';
import 'package:jhonny/shared/widgets/loading_indicators.dart';
import 'package:jhonny/shared/widgets/delightful_button.dart';
import 'package:jhonny/core/theme/app_theme.dart';
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Archived Tasks',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AnimatedIconButton(
            icon: Icons.arrow_back,
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
            color: AppTheme.textPrimary,
          ),
          actions: [
            if (archivedTasks.isNotEmpty && isParent)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog();
                  }
                },
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.textPrimary,
                ).animate().scale(delay: 200.ms).shake(),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: AppTheme.error),
                        SizedBox(width: 12),
                        Text(
                          'Clear All',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadArchivedTasks,
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              child: _isLoading
                  ? const Center(child: PulsingLoadingIndicator())
                  : _buildContent(archivedTasks, isParent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Task> archivedTasks, bool isParent) {
    if (archivedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Icon(
                  Icons.archive_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ).animate().scale(delay: 100.ms).shimmer(
                    duration: 2.seconds,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
              const SizedBox(height: 24),
              Text(
                'No Archived Tasks',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'Tasks you archive will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      itemCount: archivedTasks.length,
      itemBuilder: (context, index) {
        final task = archivedTasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildArchivedTaskCard(task, isParent),
        );
      },
    );
  }

  Widget _buildArchivedTaskCard(Task task, bool isParent) {
    return EnhancedCard(
      type: EnhancedCardType.outline,
      backgroundColor: AppTheme.surface,
      showShimmer: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.15),
                        AppTheme.accent.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.archive,
                    color: AppTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                              color:
                                  AppTheme.textPrimary.withValues(alpha: 0.6),
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Archived • ${_formatDate(task.updatedAt ?? task.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lavender.withValues(alpha: 0.2),
                        AppTheme.lavender.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${task.points} pts',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lavender,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            if (task.description.isNotEmpty) ...[
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 4),

            // Action buttons (only for parents)
            if (isParent)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => _restoreTask(task),
                        icon: const Icon(Icons.restore, size: 14),
                        label: const Text('Restore'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          side: const BorderSide(
                              color: AppTheme.accent, width: 1.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteTaskPermanently(task),
                        icon: const Icon(Icons.delete_forever, size: 14),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(
                              color: AppTheme.error, width: 1.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
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
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Delete Permanently',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${task.title}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
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
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(
          'Clear All Archived Tasks',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        content: Text(
          'Are you sure you want to permanently delete ALL archived tasks? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
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
