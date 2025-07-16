import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/usecases/update_task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/shared/widgets/widgets.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  final Task? task;
  const CreateTaskPage({super.key, this.task});

  @override
  ConsumerState<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends ConsumerState<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TaskFrequency _frequency = TaskFrequency.once;
  TaskCategory _category = TaskCategory.other;
  TaskDifficulty _difficulty = TaskDifficulty.medium;
  final List<String> _selectedTags = [];
  String? _assignedTo;

  bool get _isEditMode => widget.task != null;

  int _getPointsForDifficulty(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 5;
      case TaskDifficulty.medium:
        return 10;
      case TaskDifficulty.hard:
        return 15;
    }
  }

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _pointsController.text = task.points.toString();
      _dueDate = task.dueDate;
      _frequency = task.frequency;
      _assignedTo = task.assignedTo;

      if (task.metadata != null) {
        _category = TaskCategory.values.firstWhere(
          (c) => c.name == task.metadata!['category'],
          orElse: () => TaskCategory.other,
        );
        _difficulty = TaskDifficulty.values.firstWhere(
          (d) => d.name == task.metadata!['difficulty'],
          orElse: () => TaskDifficulty.medium,
        );
        if (task.metadata!['tags'] is List) {
          _selectedTags.addAll(List<String>.from(task.metadata!['tags']));
        }
      }
      // Override points with difficulty-based points for consistency
      _pointsController.text = _getPointsForDifficulty(_difficulty).toString();
    } else {
      // Set initial assignment to current user for new tasks
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _assignedTo = user.id;
      }
      // Set points based on default difficulty
      _pointsController.text = _getPointsForDifficulty(_difficulty).toString();
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
    final isProcessing =
        ref.watch(_isEditMode ? taskUpdatingProvider : taskCreatingProvider);
    // final familyMembers = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'Create New Task'),
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
                        _buildCategorySection(),
                        const SizedBox(height: 24),
                        _buildTaskInfoSection(),
                        const SizedBox(height: 24),
                        _buildAssignmentSection(),
                        const SizedBox(height: 24),
                        _buildSchedulingSection(),
                        const SizedBox(height: 24),
                        _buildDifficultySection(),
                        const SizedBox(height: 32),
                        _buildActionButtons(isProcessing),
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
              '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
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

  Widget _buildCategorySection() {
    return EnhancedCard.elevated(
      title: 'Category',
      child: Column(
        children: [
          DropdownButtonFormField<TaskCategory>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
            items: TaskCategory.values
                .map<DropdownMenuItem<TaskCategory>>((category) {
              return DropdownMenuItem<TaskCategory>(
                value: category,
                child: Row(
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              _category = value!;
            }),
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection() {
    return EnhancedCard.elevated(
      title: 'Difficulty & Points',
      child: Column(
        children: [
          DropdownButtonFormField<TaskDifficulty>(
            value: _difficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
            items: TaskDifficulty.values
                .map<DropdownMenuItem<TaskDifficulty>>((difficulty) {
              final points = _getPointsForDifficulty(difficulty);
              return DropdownMenuItem<TaskDifficulty>(
                value: difficulty,
                child: Row(
                  children: [
                    Icon(
                      difficulty == TaskDifficulty.easy
                          ? Icons.emoji_emotions
                          : difficulty == TaskDifficulty.medium
                              ? Icons.radio_button_unchecked
                              : Icons.local_fire_department,
                      color: difficulty == TaskDifficulty.easy
                          ? Colors.green
                          : difficulty == TaskDifficulty.medium
                              ? Colors.orange
                              : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${difficulty.displayName} ($points pts)',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() {
              _difficulty = value!;
              _pointsController.text =
                  _getPointsForDifficulty(value).toString();
            }),
            validator: (value) {
              if (value == null) {
                return 'Please select a difficulty';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Points: ${_getPointsForDifficulty(_difficulty)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isProcessing) {
    return EnhancedButton.primary(
      text: _isEditMode ? 'Save Changes' : 'Create Task',
      onPressed: isProcessing ? null : _submitForm,
      isLoading: isProcessing,
    );
  }

  Future<void> _selectDueDate() async {
    // Simple date picker - just pick the date, time defaults to end of day
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'When is this due?',
    );

    if (date != null && mounted) {
      setState(() {
        // Set time to 11:59 PM of the selected date
        _dueDate = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
        );
      });
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not found')),
      );
      return;
    }

    // Use Future.microtask to ensure this happens outside the current build cycle
    await Future.microtask(() async {
      if (!context.mounted) return;

      try {
        if (_isEditMode) {
          final params = UpdateTaskParams(
            taskId: widget.task!.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            points: int.tryParse(_pointsController.text) ?? 0,
            dueDate: _dueDate,
            assignedTo: _assignedTo,
            metadata: {
              'category': _category.name,
              'difficulty': _difficulty.name,
              'tags': _selectedTags,
            },
          );
          await ref.read(taskNotifierProvider.notifier).updateTask(params);
        } else {
          await ref.read(taskNotifierProvider.notifier).createNewTask(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            points: int.tryParse(_pointsController.text) ?? 10,
            assignedTo: _assignedTo!,
            createdBy: user.id,
            dueDate: _dueDate,
            frequency: _frequency,
            familyId: user.familyId!,
            metadata: {
              'category': _category.name,
              'difficulty': _difficulty.name,
              'tags': _selectedTags,
            },
          );
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }
}
