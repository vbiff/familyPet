import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';

class GetCurrentFamilyParams {
  final String userId;

  const GetCurrentFamilyParams({
    required this.userId,
  });
}

class GetCurrentFamily {
  final FamilyRepository _repository;

  GetCurrentFamily(this._repository);

  Future<Either<Failure, Family?>> call(GetCurrentFamilyParams params) async {
    // Validate user ID
    if (params.userId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'User ID cannot be empty'));
    }

    return _repository.getCurrentUserFamily(params.userId);
  }
}
