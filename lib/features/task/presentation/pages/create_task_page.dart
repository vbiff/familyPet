import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/usecases/update_task.dart';
import 'package:jhonny/features/task/presentation/providers/task_provider.dart';
import 'package:jhonny/features/family/presentation/providers/family_provider.dart';
import 'package:jhonny/shared/widgets/widgets.dart';
import 'package:jhonny/shared/widgets/delightful_button.dart';
import 'package:jhonny/shared/widgets/animated_interactions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jhonny/core/theme/app_theme.dart';

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

      // Load Phase 2 fields directly from Task entity
      _category = task.category;
      _difficulty = task.difficulty;
      _selectedTags.addAll(task.tags);

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Task' : 'Create New Task',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: AnimatedIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.textPrimary,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildCategorySection()
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 20),
                          _buildTaskInfoSection()
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 20),
                          _buildAssignmentSection()
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 20),
                          _buildSchedulingSection()
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 20),
                          _buildDifficultySection()
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideY(begin: 0.2),
                          const SizedBox(height: 32),
                          _buildActionButtons(isProcessing)
                              .animate()
                              .fadeIn(delay: 600.ms)
                              .slideY(begin: 0.3),
                          const SizedBox(
                              height: 20), // Bottom padding for safe area
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTaskInfoSection() {
    return EnhancedCard(
      type: EnhancedCardType.elevated,
      backgroundColor: AppTheme.surface,
      showShimmer: true,
      titleWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.2),
                  AppTheme.blue.withValues(alpha: 0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.edit_note, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Task Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
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
          const SizedBox(height: 20),
          EnhancedInput.multiline(
            label: 'Description',
            placeholder: 'Describe what needs to be done...',
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

    return EnhancedCard(
      type: EnhancedCardType.elevated,
      backgroundColor: AppTheme.surface,
      showShimmer: true,
      titleWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondary.withValues(alpha: 0.2),
                  AppTheme.lavender.withValues(alpha: 0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add,
                color: AppTheme.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Assignment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!hasFamily)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withValues(alpha: 0.1),
                    AppTheme.error.withValues(alpha: 0.05)
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border:
                    Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppTheme.error,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You need to create or join a family first',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (assignmentOptions.isEmpty)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
            )
          else
            DropdownButtonFormField<String>(
              value:
                  assignmentOptions.any((option) => option['id'] == _assignedTo)
                      ? _assignedTo
                      : null,
              decoration: InputDecoration(
                labelText: 'Assign to family member',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(
                      color: AppTheme.secondary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide:
                      const BorderSide(color: AppTheme.secondary, width: 2),
                ),
              ),
              isExpanded: true,
              items: assignmentOptions.map<DropdownMenuItem<String>>((option) {
                final isCurrentUser = currentUser?.id == option['id'];
                final displayText = isCurrentUser
                    ? '${option['displayName']} (You)'
                    : option['displayName'];

                return DropdownMenuItem<String>(
                  value: option['id'] as String,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isCurrentUser ? Icons.star : Icons.person,
                          size: 16,
                          color: isCurrentUser
                              ? AppTheme.primary
                              : AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
    return EnhancedCard(
      type: EnhancedCardType.elevated,
      backgroundColor: AppTheme.surface,
      showShimmer: true,
      titleWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.green.withValues(alpha: 0.2),
                  AppTheme.blue.withValues(alpha: 0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.schedule, color: AppTheme.green, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Scheduling',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
      child: Column(
        children: [
          SpringButton(
            onPressed: _selectDueDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.05),
                    AppTheme.accent.withValues(alpha: 0.02)
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border:
                    Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return EnhancedCard(
      type: EnhancedCardType.elevated,
      backgroundColor: AppTheme.surface,
      showShimmer: true,
      titleWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.2),
                  AppTheme.secondary.withValues(alpha: 0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.category, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
      child: Column(
        children: [
          DropdownButtonFormField<TaskCategory>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Select category',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
            isExpanded: true,
            items: TaskCategory.values
                .map<DropdownMenuItem<TaskCategory>>((category) {
              return DropdownMenuItem<TaskCategory>(
                value: category,
                child: Row(
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
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
    return EnhancedCard(
      type: EnhancedCardType.elevated,
      backgroundColor: AppTheme.surface,
      showShimmer: true,
      titleWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.orange.withValues(alpha: 0.2),
                  AppTheme.yellow.withValues(alpha: 0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_fire_department,
                color: AppTheme.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Difficulty & Points',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
      child: Column(
        children: [
          DropdownButtonFormField<TaskDifficulty>(
            value: _difficulty,
            decoration: InputDecoration(
              labelText: 'Select difficulty level',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    BorderSide(color: AppTheme.orange.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: AppTheme.orange, width: 2),
              ),
            ),
            isExpanded: true,
            items: TaskDifficulty.values
                .map<DropdownMenuItem<TaskDifficulty>>((difficulty) {
              final difficultyColor = difficulty == TaskDifficulty.easy
                  ? AppTheme.green
                  : difficulty == TaskDifficulty.medium
                      ? AppTheme.yellow
                      : AppTheme.error;

              return DropdownMenuItem<TaskDifficulty>(
                value: difficulty,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          color: difficultyColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              difficulty.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.lavender.withValues(alpha: 0.1),
                  AppTheme.primary.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border:
                  Border.all(color: AppTheme.lavender.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.yellow, AppTheme.orange],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reward Points',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getPointsForDifficulty(_difficulty)} points for completion',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
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
    final user = ref.watch(currentUserProvider);
    final hasFamily = user?.familyId != null;

    return DelightfulButton(
      text: _isEditMode ? 'Save Changes' : 'Create Task',
      icon: _isEditMode ? Icons.save : Icons.add,
      style: DelightfulButtonStyle.primary,
      width: double.infinity,
      onPressed: (isProcessing || !hasFamily) ? null : _submitForm,
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

    // Double-check that user has a family before creating task
    if (user.familyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('You must join or create a family before creating tasks'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if context is mounted before proceeding
    if (!context.mounted) return;

    try {
      // Store notifier reference before async operations
      final taskNotifier = ref.read(taskNotifierProvider.notifier);

      // Check mounted again right before async operations
      if (!context.mounted) return;

      if (_isEditMode) {
        final params = UpdateTaskParams(
          taskId: widget.task!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          points: int.tryParse(_pointsController.text) ?? 0,
          dueDate: _dueDate,
          assignedTo: _assignedTo,
          // Phase 2 fields as proper parameters
          category: _category,
          difficulty: _difficulty,
          tags: _selectedTags,
          metadata: {
            // Keep any other metadata if needed
          },
        );
        await taskNotifier.updateTask(params);
      } else {
        await taskNotifier.createNewTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          points: int.tryParse(_pointsController.text) ?? 10,
          assignedTo: _assignedTo!,
          createdBy: user.id,
          dueDate: _dueDate,
          frequency: _frequency,
          familyId: user.familyId!,
          // Phase 2 fields as proper parameters
          category: _category,
          difficulty: _difficulty,
          tags: _selectedTags,
          metadata: {
            // Keep any other metadata if needed
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
  }
}
