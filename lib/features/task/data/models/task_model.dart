import 'package:jhonny/features/task/domain/entities/task.dart';

class TaskModel extends Task {
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
    super.completedAt,
    super.verifiedAt,
    super.metadata,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      status: TaskStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
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
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'status': status.name,
      'assigned_to_id': assignedTo,
      'created_by_id': createdBy,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency.name,
      'verified_by_id': verifiedById,
      'family_id': familyId,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'points': points,
      'status': status.name,
      'assigned_to_id': assignedTo,
      'created_by_id': createdBy,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency.name,
      'family_id': familyId,
      'image_urls': imageUrls,
      'metadata': metadata,
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
      completedAt: task.completedAt,
      verifiedAt: task.verifiedAt,
      metadata: task.metadata,
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
      completedAt: completedAt,
      verifiedAt: verifiedAt,
      metadata: metadata,
    );
  }
}
