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
  final DateTime? completedAt;
  final DateTime? verifiedAt;
  final Map<String, dynamic>? metadata;

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
    this.completedAt,
    this.verifiedAt,
    this.metadata,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  bool get hasImages => imageUrls.isNotEmpty;
  bool get isVerifiedByParent => verifiedById != null;
  bool get needsVerification =>
      status == TaskStatus.completed && verifiedById == null;

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
    DateTime? completedAt,
    DateTime? verifiedAt,
    Map<String, dynamic>? metadata,
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
      verifiedById: verifiedById ?? this.verifiedById,
      familyId: familyId ?? this.familyId,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      metadata: metadata ?? this.metadata,
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
        completedAt,
        verifiedAt,
        metadata,
      ];
}
