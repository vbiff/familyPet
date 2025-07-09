import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/features/task/domain/entities/task_comment.dart';
import 'package:jhonny/features/task/presentation/providers/task_comment_provider.dart';
import 'package:jhonny/shared/widgets/enhanced_card.dart';

class TaskCommentsSection extends ConsumerStatefulWidget {
  final String taskId;

  const TaskCommentsSection({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskCommentsSection> createState() =>
      _TaskCommentsSectionState();
}

class _TaskCommentsSectionState extends ConsumerState<TaskCommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add listener to update the Post button state in real-time as the user types.
    _commentController.addListener(_onCommentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(taskCommentNotifierProvider.notifier)
          .loadComments(widget.taskId);
    });
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    // Rebuild the widget to update the UI based on the text controller's state.
    setState(() {});
  }

  String _getMemberName(String userId) {
    final currentUser = ref.read(currentUserProvider);
    final familyMembers = ref.read(familyMembersProvider);

    // Check if it's the current user
    if (currentUser != null && userId == currentUser.id) {
      return 'You';
    }

    // Find the user in family members
    for (final member in familyMembers) {
      if (member.id == userId) {
        return member.displayName.isNotEmpty
            ? member.displayName
            : 'Family Member';
      }
    }

    return 'Unknown User';
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final success =
        await ref.read(taskCommentNotifierProvider.notifier).createComment(
              taskId: widget.taskId,
              authorId: currentUser.id,
              content: content,
            );

    if (success) {
      _commentController.clear();
      _commentFocusNode.unfocus();
    } else {
      // Show error if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(TaskComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
      final success = await ref
          .read(taskCommentNotifierProvider.notifier)
          .deleteComment(comment.id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete comment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(taskCommentNotifierProvider);
    final isCreating = ref.watch(taskCommentCreatingProvider);

    return EnhancedCard(
      title: 'Comments',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Comment input
          _buildCommentInput(isCreating),

          const SizedBox(height: 16),

          // Comments list
          _buildCommentsList(commentsState.comments),
        ],
      ),
    );
  }

  Widget _buildCommentInput(bool isCreating) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            maxLines: 3,
            minLines: 1,
            maxLength: 1000,
            enabled: !isCreating,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              border: InputBorder.none,
              counterText: '',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            onSubmitted: (_) => _submitComment(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_commentController.text.length}/1000',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              FilledButton.icon(
                onPressed: isCreating || _commentController.text.trim().isEmpty
                    ? null
                    : _submitComment,
                icon: isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(isCreating ? 'Posting...' : 'Post'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(80, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<TaskComment> comments) {
    if (comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to add a comment!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(TaskComment comment) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnComment = currentUser?.id == comment.authorId;
    final memberName = _getMemberName(comment.authorId);

    return Container(
      decoration: BoxDecoration(
        color: isOwnComment
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwnComment
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author and time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOwnComment
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  memberName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isOwnComment
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _formatCommentTime(comment.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),

              if (comment.isEdited) ...[
                const SizedBox(width: 4),
                Text(
                  '(edited)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],

              const Spacer(),

              // Delete button for own comments
              if (isOwnComment)
                IconButton(
                  onPressed: () => _deleteComment(comment),
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 18,
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Comment content
          Text(
            comment.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }
}
