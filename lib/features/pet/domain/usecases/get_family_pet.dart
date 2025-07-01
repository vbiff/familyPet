import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class GetFamilyPet {
  final PetRepository _repository;

  const GetFamilyPet(this._repository);

  Future<Either<Failure, Pet?>> call(String familyId) async {
    // Validation
    if (familyId.isEmpty) {
      return left(
          const ValidationFailure(message: 'Family ID cannot be empty'));
    }

    // Get family pet
    return await _repository.getFamilyPet(familyId);
  }

  /// Watch family pet changes in real-time
  Stream<Pet?> watch(String familyId) {
    if (familyId.isEmpty) {
      return Stream.error(
          const ValidationFailure(message: 'Family ID cannot be empty'));
    }

    return _repository.watchFamilyPet(familyId);
  }
}
