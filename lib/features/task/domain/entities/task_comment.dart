import 'package:equatable/equatable.dart';

class TaskComment extends Equatable {
  final String id;
  final String taskId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  TaskComment copyWith({
    String? id,
    String? taskId,
    String? authorId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskComment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        authorId,
        content,
        createdAt,
        updatedAt,
      ];
}
