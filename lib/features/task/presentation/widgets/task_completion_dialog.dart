import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/widgets/photo_verification_widget.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';

class TaskCompletionDialog extends ConsumerStatefulWidget {
  final Task task;
  final Function(List<String> imageUrls) onCompleted;

  const TaskCompletionDialog({
    super.key,
    required this.task,
    required this.onCompleted,
  });

  @override
  ConsumerState<TaskCompletionDialog> createState() =>
      _TaskCompletionDialogState();
}

class _TaskCompletionDialogState extends ConsumerState<TaskCompletionDialog> {
  List<String> _uploadedImageUrls = [];
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Task',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          widget.task.title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great job! You\'re about to mark this task as completed.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),

                    const SizedBox(height: 16),

                    // Photo verification widget
                    PhotoVerificationWidget(
                      task: widget.task,
                      isRequired: false,
                      onPhotosUploaded: (imageUrls) {
                        setState(() {
                          _uploadedImageUrls = imageUrls;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: EnhancedButton.outline(
                      text: 'Cancel',
                      onPressed: _isCompleting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: EnhancedButton.primary(
                      text: _isCompleting ? 'Completing...' : 'Complete Task',
                      leadingIcon: _isCompleting ? null : Icons.check,
                      isLoading: _isCompleting,
                      onPressed: _isCompleting ? null : _completeTask,
                      backgroundColor: Colors.green,
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

  Future<void> _completeTask() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      // Call the completion callback with uploaded image URLs
      await widget.onCompleted(_uploadedImageUrls);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Task "${widget.task.title}" completed successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete task: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isCompleting = false;
      });
    }
  }
}
