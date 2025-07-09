import 'package:jhonny/features/task/domain/entities/task_comment.dart';

class TaskCommentModel extends TaskComment {
  const TaskCommentModel({
    required super.id,
    required super.taskId,
    required super.authorId,
    required super.content,
    required super.createdAt,
    super.updatedAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'author_id': authorId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'task_id': taskId,
      'author_id': authorId,
      'content': content,
    };
  }

  factory TaskCommentModel.fromEntity(TaskComment comment) {
    return TaskCommentModel(
      id: comment.id,
      taskId: comment.taskId,
      authorId: comment.authorId,
      content: comment.content,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    );
  }

  TaskComment toEntity() {
    return TaskComment(
      id: id,
      taskId: taskId,
      authorId: authorId,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
