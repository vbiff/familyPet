import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';

class JoinFamilyParams {
  final String inviteCode;
  final String userId;

  const JoinFamilyParams({
    required this.inviteCode,
    required this.userId,
  });
}

class JoinFamily {
  final FamilyRepository _repository;

  JoinFamily(this._repository);

  Future<Either<Failure, Family>> call(JoinFamilyParams params) async {
    // Validate invite code
    if (params.inviteCode.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Invite code cannot be empty'));
    }

    if (params.inviteCode.trim().length != 6) {
      return left(const ValidationFailure(
          message: 'Invite code must be 6 characters long'));
    }

    // Validate user ID
    if (params.userId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'User ID cannot be empty'));
    }

    // Join the family - let repository handle duplicate membership validation
    return _repository.joinFamily(
      inviteCode: params.inviteCode.trim().toUpperCase(),
      userId: params.userId,
    );
  }
}
