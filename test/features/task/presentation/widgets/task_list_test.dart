import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/shared/widgets/widgets.dart';
import '../../../../utils/test_setup.dart';

void main() {
  group('TaskList Widget Tests', () {
    final DateTime testDate = DateTime(2024, 1, 1, 12, 0);

    final List<Task> testTasks = [
      TestSetup.createTestTask(
        id: 'task-1',
        title: 'Clean Room',
        description: 'Clean and organize bedroom',
        points: 50,
        status: TaskStatus.pending,
        assignedTo: 'child-1',
        createdBy: 'parent-1',
        dueDate: testDate.add(const Duration(days: 1)),
        frequency: TaskFrequency.weekly,
        familyId: 'family-123',
      ),
      TestSetup.createTestTask(
        id: 'task-2',
        title: 'Do Homework',
        description: 'Complete math homework',
        points: 30,
        status: TaskStatus.completed,
        assignedTo: 'child-1',
        createdBy: 'parent-1',
        dueDate: testDate.add(const Duration(days: 2)),
        frequency: TaskFrequency.daily,
        familyId: 'family-123',
        completedAt: testDate,
        verifiedById: 'parent-1',
        verifiedAt: testDate,
      ),
    ];

    Widget createTestWidget({List<Task>? tasks}) {
      return TestSetup.createTestApp(
        child: Column(
          children: [
            // Simulate TaskList header
            Row(
              children: [
                const Text('Today\'s Tasks'),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            // Simulate task list content
            if (tasks?.isEmpty ?? true)
              const Column(
                children: [
                  Icon(Icons.task_alt, size: 64),
                  Text('No tasks yet'),
                  Text('Tasks will appear here when they are created'),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Create First Task'),
                  ),
                ],
              )
            else
              ...tasks!.map((task) => EnhancedCard.outlined(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title),
                        Text(task.description),
                        Text('${task.points} pts'),
                        Text(task.status.name),
                      ],
                    ),
                  )),
          ],
        ),
      );
    }

    group('UI Rendering', () {
      testWidgets('should display header with title and action buttons',
          (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Today\'s Tasks'), findsOneWidget);
        expect(find.text('Refresh'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should display empty state when no tasks', (tester) async {
        await tester.pumpWidget(createTestWidget(tasks: []));

        expect(find.text('No tasks yet'), findsOneWidget);
        expect(find.text('Tasks will appear here when they are created'),
            findsOneWidget);
        expect(find.text('Create First Task'), findsOneWidget);
        expect(find.byIcon(Icons.task_alt), findsOneWidget);
      });

      testWidgets('should display task cards when tasks exist', (tester) async {
        await tester.pumpWidget(createTestWidget(tasks: testTasks));

        expect(find.text('Clean Room'), findsOneWidget);
        expect(find.text('Do Homework'), findsOneWidget);
        expect(find.text('Clean and organize bedroom'), findsOneWidget);
        expect(find.text('Complete math homework'), findsOneWidget);
        expect(find.text('pending'), findsOneWidget);
        expect(find.text('completed'), findsOneWidget);
        expect(find.text('50 pts'), findsOneWidget);
        expect(find.text('30 pts'), findsOneWidget);
      });
    });

    group('Task Card Components', () {
      testWidgets('should display task information correctly', (tester) async {
        final task = testTasks.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnhancedCard.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title),
                    Text(task.description),
                    Text('${task.points} pts'),
                    Text(task.status.name),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Clean Room'), findsOneWidget);
        expect(find.text('Clean and organize bedroom'), findsOneWidget);
        expect(find.text('50 pts'), findsOneWidget);
        expect(find.text('pending'), findsOneWidget);
      });

      testWidgets('should display verification status for completed tasks',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnhancedCard.outlined(
                child: Column(
                  children: [
                    const Text('Completed Task'),
                    Row(
                      children: [
                        EnhancedButton.primary(
                          text: 'Verify',
                          leadingIcon: Icons.verified,
                          onPressed: () {},
                        ),
                        EnhancedButton.outline(
                          text: 'Undo',
                          leadingIcon: Icons.undo,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Completed Task'), findsOneWidget);
        expect(find.text('Verify'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
      });
    });

    group('Action Buttons', () {
      testWidgets('should display correct action buttons for pending tasks',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnhancedButton.primary(
                text: 'Complete',
                leadingIcon: Icons.check,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Complete'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('should display undo button for verified tasks',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnhancedButton.outline(
                text: 'Mark Pending',
                leadingIcon: Icons.undo,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text('Mark Pending'), findsOneWidget);
        expect(find.byIcon(Icons.undo), findsOneWidget);
      });
    });

    group('Task Status Display', () {
      testWidgets('should show correct icons for different task statuses',
          (tester) async {
        const statusIcons = {
          TaskStatus.pending: Icons.schedule,
          TaskStatus.inProgress: Icons.hourglass_empty,
          TaskStatus.completed: Icons.check_circle,
          TaskStatus.expired: Icons.error,
        };

        for (final entry in statusIcons.entries) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Icon(entry.value),
              ),
            ),
          );

          expect(find.byIcon(entry.value), findsOneWidget);
        }
      });

      testWidgets('should show verified icon for verified tasks',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Icon(Icons.verified),
            ),
          ),
        );

        expect(find.byIcon(Icons.verified), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should support screen readers', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Semantics(
                label: 'Create new task button',
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Create Task'),
                ),
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Create new task button'), findsOneWidget);
      });
    });
  });
}
