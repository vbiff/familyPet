import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';

class TaskList extends ConsumerWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual task provider
    final tasks = [
      Task(
        id: '1',
        title: 'Clean your room',
        description: 'Make your bed and organize your toys',
        points: 10,
        status: TaskStatus.pending,
        assignedTo: 'child1',
        createdBy: 'parent1',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        frequency: TaskFrequency.once,
        familyId: 'family1',
        createdAt: DateTime.now(),
      ),
      Task(
        id: '2',
        title: 'Do your homework',
        description: 'Complete math exercises',
        points: 15,
        status: TaskStatus.completed,
        assignedTo: 'child1',
        createdBy: 'parent1',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        frequency: TaskFrequency.daily,
        familyId: 'family1',
        createdAt: DateTime.now(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Tasks',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
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
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.task_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: task.status.isCompleted
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      task.status.isCompleted ? 'Completed' : 'In Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: task.status.isCompleted
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
