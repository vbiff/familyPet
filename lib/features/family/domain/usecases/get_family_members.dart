import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/family/data/models/family_member_model.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';

class GetFamilyMembersParams {
  final String familyId;

  const GetFamilyMembersParams({
    required this.familyId,
  });
}

class GetFamilyMembers {
  final FamilyRepository _repository;

  GetFamilyMembers(this._repository);

  Future<Either<Failure, List<FamilyMemberModel>>> call(
    GetFamilyMembersParams params,
  ) async {
    // Validate family ID
    if (params.familyId.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Family ID cannot be empty'));
    }

    return _repository.getFamilyMembers(params.familyId);
  }
}
