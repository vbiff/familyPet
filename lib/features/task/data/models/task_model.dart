import 'package:jhonny/features/task/domain/entities/task.dart';

class TaskModel extends Task {
  // Helper methods for status conversion between Dart enum and database values
  static String _statusToDb(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'inProgress'; // Use camelCase for existing database
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.expired:
        return 'expired';
    }
  }

  static TaskStatus _statusFromDb(String dbStatus) {
    switch (dbStatus) {
      case 'pending':
        return TaskStatus.pending;
      case 'inProgress': // Handle existing camelCase
      case 'in_progress': // Handle snake_case if it exists
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'expired':
        return TaskStatus.expired;
      default:
        return TaskStatus.pending; // fallback
    }
  }

  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.points,
    required super.status,
    required super.assignedTo,
    required super.createdBy,
    required super.dueDate,
    required super.frequency,
    super.verifiedById,
    required super.familyId,
    super.imageUrls = const [],
    required super.createdAt,
    super.updatedAt,
    super.completedAt,
    super.verifiedAt,
    super.metadata,
    super.isArchived = false,
    // Phase 2 properties
    super.category = TaskCategory.other,
    super.difficulty = TaskDifficulty.medium,
    super.tags = const [],
    super.rewards = const [],
    super.nextDueDate,
    super.streakCount = 0,
    super.isTemplate = false,
    super.parentTaskId,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      status: _statusFromDb(json['status'] as String),
      assignedTo: json['assigned_to_id'] as String,
      createdBy: json['created_by_id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      frequency: TaskFrequency.values.firstWhere(
        (frequency) => frequency.name == json['frequency'],
        orElse: () => TaskFrequency.once,
      ),
      verifiedById: json['verified_by_id'] as String?,
      familyId: json['family_id'] as String,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isArchived: json['is_archived'] as bool? ?? false,
      // Phase 2 properties
      category: json['category'] != null
          ? TaskCategory.values.firstWhere(
              (c) => c.name == json['category'],
              orElse: () => TaskCategory.other,
            )
          : TaskCategory.other,
      difficulty: json['difficulty'] != null
          ? TaskDifficulty.values.firstWhere(
              (d) => d.name == json['difficulty'],
              orElse: () => TaskDifficulty.medium,
            )
          : TaskDifficulty.medium,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      rewards: json['rewards'] != null
          ? [] // TODO: Implement TaskReward deserialization
          : const [],
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      streakCount: json['streak_count'] as int? ?? 0,
      isTemplate: json['is_template'] as bool? ?? false,
      parentTaskId: json['parent_task_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'status': _statusToDb(status),
      'assigned_to_id': assignedTo,
      'created_by_id': createdBy,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency.name,
      'verified_by_id': verifiedById,
      'family_id': familyId,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'metadata': metadata,
      'is_archived': isArchived,
      // Phase 2 properties
      'category': category.name,
      'difficulty': difficulty.name,
      'tags': tags,
      'rewards': [], // TODO: Implement TaskReward serialization
      'next_due_date': nextDueDate?.toIso8601String(),
      'streak_count': streakCount,
      'is_template': isTemplate,
      'parent_task_id': parentTaskId,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'points': points,
      'status': _statusToDb(status),
      'assigned_to_id': assignedTo,
      'created_by_id': createdBy,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency.name,
      'family_id': familyId,
      'image_urls': imageUrls,
      'metadata': metadata,
      // Phase 2 properties
      'category': category.name,
      'difficulty': difficulty.name,
      'tags': tags,
      'rewards': [], // TODO: Implement TaskReward serialization
      'next_due_date': nextDueDate?.toIso8601String(),
      'streak_count': streakCount,
      'is_template': isTemplate,
      'parent_task_id': parentTaskId,
    };
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      points: task.points,
      status: task.status,
      assignedTo: task.assignedTo,
      createdBy: task.createdBy,
      dueDate: task.dueDate,
      frequency: task.frequency,
      verifiedById: task.verifiedById,
      familyId: task.familyId,
      imageUrls: task.imageUrls,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      completedAt: task.completedAt,
      verifiedAt: task.verifiedAt,
      metadata: task.metadata,
      isArchived: task.isArchived,
      // Phase 2 properties
      category: task.category,
      difficulty: task.difficulty,
      tags: task.tags,
      rewards: task.rewards,
      nextDueDate: task.nextDueDate,
      streakCount: task.streakCount,
      isTemplate: task.isTemplate,
      parentTaskId: task.parentTaskId,
    );
  }

  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      points: points,
      status: status,
      assignedTo: assignedTo,
      createdBy: createdBy,
      dueDate: dueDate,
      frequency: frequency,
      verifiedById: verifiedById,
      familyId: familyId,
      imageUrls: imageUrls,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      verifiedAt: verifiedAt,
      metadata: metadata,
      isArchived: isArchived,
      // Phase 2 properties
      category: category,
      difficulty: difficulty,
      tags: tags,
      rewards: rewards,
      nextDueDate: nextDueDate,
      streakCount: streakCount,
      isTemplate: isTemplate,
      parentTaskId: parentTaskId,
    );
  }
}
