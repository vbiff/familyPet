import 'package:equatable/equatable.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed,
  expired;

  bool get isPending => this == TaskStatus.pending;
  bool get isInProgress => this == TaskStatus.inProgress;
  bool get isCompleted => this == TaskStatus.completed;
  bool get isExpired => this == TaskStatus.expired;
}

enum TaskFrequency {
  once,
  daily,
  weekly,
  monthly;

  bool get isRecurring => this != TaskFrequency.once;
}

enum TaskCategory {
  study,
  work,
  sport,
  family,
  friends,
  other;

  String get displayName {
    switch (this) {
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.sport:
        return 'Sport';
      case TaskCategory.family:
        return 'Family';
      case TaskCategory.friends:
        return 'Friends';
      case TaskCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case TaskCategory.study:
        return '📚';
      case TaskCategory.work:
        return '💼';
      case TaskCategory.sport:
        return '🏃‍♂️';
      case TaskCategory.family:
        return '👨‍👩‍👧‍👦';
      case TaskCategory.friends:
        return '👥';
      case TaskCategory.other:
        return '📝';
    }
  }
}

enum TaskDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case TaskDifficulty.easy:
        return 'Easy';
      case TaskDifficulty.medium:
        return 'Medium';
      case TaskDifficulty.hard:
        return 'Hard';
    }
  }

  int get basePointMultiplier {
    switch (this) {
      case TaskDifficulty.easy:
        return 1;
      case TaskDifficulty.medium:
        return 2;
      case TaskDifficulty.hard:
        return 3;
    }
  }
}

enum TaskRewardType {
  points,
  badge,
  privilege,
  custom;

  String get displayName {
    switch (this) {
      case TaskRewardType.points:
        return 'Points';
      case TaskRewardType.badge:
        return 'Badge';
      case TaskRewardType.privilege:
        return 'Privilege';
      case TaskRewardType.custom:
        return 'Custom';
    }
  }
}

class TaskReward extends Equatable {
  final TaskRewardType type;
  final String title;
  final String description;
  final int value; // Points value or duration in minutes for privileges
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  const TaskReward({
    required this.type,
    required this.title,
    required this.description,
    required this.value,
    this.imageUrl,
    this.metadata,
  });

  @override
  List<Object?> get props =>
      [type, title, description, value, imageUrl, metadata];
}

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final int points;
  final TaskStatus status;
  final String assignedTo;
  final String createdBy;
  final DateTime dueDate;
  final TaskFrequency frequency;
  final String? verifiedById;
  final String familyId;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? verifiedAt;
  final Map<String, dynamic>? metadata;
  final bool isArchived;

  // Phase 2 enhancements
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final List<String> tags;
  final List<TaskReward> rewards;
  final DateTime? nextDueDate; // For recurring tasks
  final int streakCount; // How many times completed in a row
  final bool isTemplate; // Template for recurring tasks
  final String? parentTaskId; // Reference to template task

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.status,
    required this.assignedTo,
    required this.createdBy,
    required this.dueDate,
    required this.frequency,
    this.verifiedById,
    required this.familyId,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.verifiedAt,
    this.metadata,
    this.isArchived = false,
    // Phase 2 properties with defaults
    this.category = TaskCategory.other,
    this.difficulty = TaskDifficulty.medium,
    this.tags = const [],
    this.rewards = const [],
    this.nextDueDate,
    this.streakCount = 0,
    this.isTemplate = false,
    this.parentTaskId,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate) && !status.isCompleted;
  bool get hasImages => imageUrls.isNotEmpty;
  bool get isVerifiedByParent => verifiedById != null;
  bool get needsVerification =>
      status == TaskStatus.completed && verifiedById == null;
  bool get hasCustomRewards => rewards.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get isRecurringInstance => parentTaskId != null;
  bool get hasStreak => streakCount > 0;

  // Calculate total reward points including difficulty bonus
  int get totalRewardPoints {
    final basePoints = points * difficulty.basePointMultiplier;
    final bonusPoints = rewards
        .where((reward) => reward.type == TaskRewardType.points)
        .fold(0, (sum, reward) => sum + reward.value);
    return basePoints + bonusPoints;
  }

  // Get all non-point rewards
  List<TaskReward> get nonPointRewards =>
      rewards.where((reward) => reward.type != TaskRewardType.points).toList();

  // Calculate time until due
  Duration get timeUntilDue => dueDate.difference(DateTime.now());

  // Check if task is due soon (within 24 hours)
  bool get isDueSoon =>
      !status.isCompleted &&
      timeUntilDue.isNegative == false &&
      timeUntilDue.inHours <= 24;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    TaskStatus? status,
    String? assignedTo,
    String? createdBy,
    DateTime? dueDate,
    TaskFrequency? frequency,
    String? verifiedById,
    String? familyId,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? verifiedAt,
    Map<String, dynamic>? metadata,
    bool? isArchived,
    TaskCategory? category,
    TaskDifficulty? difficulty,
    List<String>? tags,
    List<TaskReward>? rewards,
    DateTime? nextDueDate,
    int? streakCount,
    bool? isTemplate,
    String? parentTaskId,
    bool clearVerification = false,
    bool clearNextDueDate = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      verifiedById:
          clearVerification ? null : (verifiedById ?? this.verifiedById),
      familyId: familyId ?? this.familyId,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      verifiedAt: clearVerification ? null : (verifiedAt ?? this.verifiedAt),
      metadata: metadata ?? this.metadata,
      isArchived: isArchived ?? this.isArchived,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      rewards: rewards ?? this.rewards,
      nextDueDate: clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      streakCount: streakCount ?? this.streakCount,
      isTemplate: isTemplate ?? this.isTemplate,
      parentTaskId: parentTaskId ?? this.parentTaskId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        points,
        status,
        assignedTo,
        createdBy,
        dueDate,
        frequency,
        verifiedById,
        familyId,
        imageUrls,
        createdAt,
        updatedAt,
        completedAt,
        verifiedAt,
        metadata,
        isArchived,
        category,
        difficulty,
        tags,
        rewards,
        nextDueDate,
        streakCount,
        isTemplate,
        parentTaskId,
      ];
}
