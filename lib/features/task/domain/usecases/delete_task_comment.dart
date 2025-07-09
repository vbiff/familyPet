import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/task/domain/repositories/task_comment_repository.dart';

class DeleteTaskComment {
  final TaskCommentRepository _repository;

  DeleteTaskComment(this._repository);

  Future<Either<Failure, void>> call(String commentId) async {
    if (commentId.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Comment ID cannot be empty'));
    }

    return await _repository.deleteComment(commentId);
  }
}
