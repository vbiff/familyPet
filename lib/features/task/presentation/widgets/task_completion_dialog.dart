import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/widgets/photo_verification_widget.dart';
import 'package:jhonny/shared/widgets/enhanced_button.dart';
import 'package:jhonny/shared/widgets/confetti_animation.dart';

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
                padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(16),
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
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: _isCompleting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _isCompleting ? null : _completeTask,
                        icon: _isCompleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 16),
                        label: Text(
                          _isCompleting ? 'Completing...' : 'Complete Task',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
        // Show confetti animation first
        ConfettiOverlay.show(
          context,
          duration: const Duration(seconds: 2),
          onComplete: () {
            // Show success message after confetti
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '🎉 Task "${widget.task.title}" completed! Great job!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        );

        // Close dialog after a short delay to let confetti show
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
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
