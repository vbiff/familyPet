import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  const CreateTaskPage({super.key});

  @override
  ConsumerState<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends ConsumerState<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TaskFrequency _frequency = TaskFrequency.once;
  String? _assignedTo;
  List<String> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _loadFamilyMembers() {
    // TODO: Load family members from family provider
    // For now, using mock UUIDs (temporary for testing)
    _familyMembers = [
      '11111111-1111-1111-1111-111111111111', // child1
      '22222222-2222-2222-2222-222222222222', // child2
      '33333333-3333-3333-3333-333333333333', // parent1
    ];
    if (_familyMembers.isNotEmpty) {
      _assignedTo = _familyMembers.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = ref.watch(taskCreatingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTaskInfoSection(),
              const SizedBox(height: 24),
              _buildAssignmentSection(),
              const SizedBox(height: 24),
              _buildSchedulingSection(),
              const SizedBox(height: 24),
              _buildPointsSection(),
              const SizedBox(height: 32),
              _buildActionButtons(isCreating),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoSection() {
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g., Clean your room',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what needs to be done',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _assignedTo,
              decoration: const InputDecoration(
                labelText: 'Assign to',
                border: OutlineInputBorder(),
              ),
              items: _familyMembers.map((member) {
                // TODO: Replace with actual family member names
                String displayName;
                switch (member) {
                  case '11111111-1111-1111-1111-111111111111':
                    displayName = 'Child 1';
                    break;
                  case '22222222-2222-2222-2222-222222222222':
                    displayName = 'Child 2';
                    break;
                  case '33333333-3333-3333-3333-333333333333':
                    displayName = 'Parent 1';
                    break;
                  default:
                    displayName = 'Unknown';
                }
                return DropdownMenuItem(
                  value: member,
                  child: Text(displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _assignedTo = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select who to assign this task to';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduling',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Due Date'),
              subtitle: Text(
                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year} at ${_dueDate.hour.toString().padLeft(2, '0')}:${_dueDate.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDueDate,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.repeat,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Frequency'),
              subtitle: Text(_getFrequencyText(_frequency)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectFrequency,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reward Points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsController,
              decoration: const InputDecoration(
                labelText: 'Points',
                hintText: '10',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.stars),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter points';
                }
                final points = int.tryParse(value);
                if (points == null || points < 0) {
                  return 'Please enter a valid number (0 or greater)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isCreating) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: isCreating ? null : _createTask,
          icon: isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_task),
          label: Text(isCreating ? 'Creating...' : 'Create Task'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: isCreating ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );

      if (time != null) {
        setState(() {
          _dueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectFrequency() async {
    final frequency = await showDialog<TaskFrequency>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskFrequency.values.map((freq) {
            return RadioListTile<TaskFrequency>(
              title: Text(_getFrequencyText(freq)),
              value: freq,
              groupValue: _frequency,
              onChanged: (value) => Navigator.of(context).pop(value),
            );
          }).toList(),
        ),
      ),
    );

    if (frequency != null) {
      setState(() {
        _frequency = frequency;
      });
    }
  }

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

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);

    // TODO: Remove this temporary fix when family management is implemented
    // For now, use mock UUIDs to enable testing
    final mockUserId = user?.id ?? '99999999-9999-9999-9999-999999999999';
    final mockFamilyId =
        user?.familyId ?? '88888888-8888-8888-8888-888888888888';

    if (_assignedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select who to assign this task to')),
      );
      return;
    }

    await ref.read(taskNotifierProvider.notifier).createNewTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          points: int.parse(_pointsController.text),
          assignedTo: _assignedTo!,
          createdBy: mockUserId,
          dueDate: _dueDate,
          frequency: _frequency,
          familyId: mockFamilyId,
        );

    final taskState = ref.read(taskNotifierProvider);
    if (taskState.failure == null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully!')),
      );
    } else if (taskState.failure != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(taskState.failure!.message)),
      );
    }
  }
}
