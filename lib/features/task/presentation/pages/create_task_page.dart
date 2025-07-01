import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/shared/widgets/widgets.dart';
// import 'package:jhonny/features/family/data/models/family_member_model.dart';

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

  @override
  void initState() {
    super.initState();

    // Set initial assignment to current user without triggering provider changes
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _assignedTo = user.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = ref.watch(taskCreatingProvider);
    // final familyMembers = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTaskInfoSection(),
                        const SizedBox(height: 24),
                        _buildAssignmentSection(),
                        const SizedBox(height: 24),
                        _buildSchedulingSection(),
                        const SizedBox(height: 24),
                        _buildPointsSection(),
                        const SizedBox(height: 32),
                        _buildActionButtons(isCreating),
                        const SizedBox(height: 16), // Extra bottom padding
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskInfoSection() {
    return EnhancedCard.elevated(
      title: 'Task Information',
      child: Column(
        children: [
          EnhancedInput(
            label: 'Task Title',
            placeholder: 'e.g., Clean your room',
            controller: _titleController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a task title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          EnhancedInput.multiline(
            label: 'Description',
            placeholder: 'Describe what needs to be done',
            controller: _descriptionController,
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
    );
  }

  List<Map<String, dynamic>> _getAssignmentOptions() {
    try {
      final familyMembers = ref.read(familyMembersProvider);
      final currentUser = ref.read(currentUserProvider);
      final assignmentOptions = <Map<String, dynamic>>[];

      if (currentUser != null) {
        // Always include current user as first option
        assignmentOptions.add({
          'id': currentUser.id,
          'displayName': currentUser.displayName.isNotEmpty
              ? currentUser.displayName
              : 'Me',
          'role': currentUser.role.name,
        });
      }

      // Add other family members (avoiding duplicates)
      for (final member in familyMembers) {
        if (currentUser == null || member.id != currentUser.id) {
          assignmentOptions.add({
            'id': member.id,
            'displayName': member.displayName.isNotEmpty
                ? member.displayName
                : 'Family Member',
            'role': member.role.name,
          });
        }
      }

      return assignmentOptions;
    } catch (e) {
      // Fallback to ensure we always have valid options
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        return [
          {
            'id': currentUser.id,
            'displayName': currentUser.displayName.isNotEmpty
                ? currentUser.displayName
                : 'Me',
            'role': currentUser.role.name,
          }
        ];
      }
      return [];
    }
  }

  Widget _buildAssignmentSection() {
    final hasFamily = ref.watch(hasFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Get assignment options safely
    List<Map<String, dynamic>> assignmentOptions = [];
    try {
      assignmentOptions = _getAssignmentOptions();
    } catch (e) {
      assignmentOptions = [];
    }

    return EnhancedCard.elevated(
      title: 'Assignment',
      child: Column(
        children: [
          if (!hasFamily)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You need to create or join a family first',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (assignmentOptions.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            DropdownButtonFormField<String>(
              value:
                  assignmentOptions.any((option) => option['id'] == _assignedTo)
                      ? _assignedTo
                      : null,
              decoration: const InputDecoration(
                labelText: 'Assign to',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: assignmentOptions.map<DropdownMenuItem<String>>((option) {
                final isCurrentUser = currentUser?.id == option['id'];
                final displayText = isCurrentUser
                    ? '${option['displayName']} (You)'
                    : option['displayName'];

                return DropdownMenuItem<String>(
                  value: option['id'] as String,
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isCurrentUser
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: hasFamily
                  ? (value) {
                      setState(() {
                        _assignedTo = value;
                      });
                    }
                  : null,
              validator: (value) {
                if (!hasFamily) {
                  return 'Please create or join a family first';
                }
                if (value == null) {
                  return 'Please select who to assign this task to';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return EnhancedCard.elevated(
      title: 'Scheduling',
      child: Column(
        children: [
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
    );
  }

  Widget _buildPointsSection() {
    return EnhancedCard.elevated(
      title: 'Reward Points',
      child: Column(
        children: [
          EnhancedInput(
            label: 'Points',
            placeholder: '10',
            type: EnhancedInputType.number,
            controller: _pointsController,
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
    );
  }

  Widget _buildActionButtons(bool isCreating) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EnhancedButton.primary(
          text: isCreating ? 'Creating...' : 'Create Task',
          leadingIcon: Icons.add_task,
          isLoading: isCreating,
          isExpanded: true,
          onPressed: isCreating ? null : _createTask,
        ),
        const SizedBox(height: 12),
        EnhancedButton.outline(
          text: 'Cancel',
          isExpanded: true,
          onPressed: isCreating ? null : () => Navigator.of(context).pop(),
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
