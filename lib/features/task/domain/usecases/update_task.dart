import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/entities/task.dart';
import 'package:jhonny/features/task/domain/repositories/task_repository.dart';

class UpdateTask {
  final TaskRepository repository;

  UpdateTask(this.repository);

  Future<Either<Failure, Task>> call(UpdateTaskParams params) async {
    return await repository.updateTask(params.taskId, params.toMap());
  }
}

class UpdateTaskParams {
  final String taskId;
  final String? title;
  final String? description;
  final int? points;
  final DateTime? dueDate;
  final String? assignedTo;
  final List<String>? imageUrls;
  final Map<String, dynamic>? metadata;
  final bool? isArchived;
  // Phase 2 fields
  final TaskCategory? category;
  final TaskDifficulty? difficulty;
  final List<String>? tags;

  UpdateTaskParams({
    required this.taskId,
    this.title,
    this.description,
    this.points,
    this.dueDate,
    this.assignedTo,
    this.imageUrls,
    this.metadata,
    this.isArchived,
    // Phase 2 fields
    this.category,
    this.difficulty,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (points != null) map['points'] = points;
    if (dueDate != null) map['due_date'] = dueDate!.toIso8601String();
    if (assignedTo != null) map['assigned_to_id'] = assignedTo;
    if (imageUrls != null) map['image_urls'] = imageUrls;
    if (metadata != null) map['metadata'] = metadata;
    if (isArchived != null) map['is_archived'] = isArchived;
    // Phase 2 fields
    if (category != null) map['category'] = category!.name;
    if (difficulty != null) map['difficulty'] = difficulty!.name;
    if (tags != null) map['tags'] = tags;
    map['updated_at'] = DateTime.now().toIso8601String();
    return map;
  }
}
