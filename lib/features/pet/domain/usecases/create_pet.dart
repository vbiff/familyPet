import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class CreatePet {
  final PetRepository _repository;

  const CreatePet(this._repository);

  Future<Either<Failure, Pet>> call(CreatePetParams params) async {
    // Validation
    if (params.name.trim().isEmpty) {
      return left(const ValidationFailure(message: 'Pet name cannot be empty'));
    }

    if (params.familyId.trim().isEmpty) {
      return left(
          const ValidationFailure(message: 'Family ID cannot be empty'));
    }

    if (params.ownerId.trim().isEmpty) {
      return left(const ValidationFailure(message: 'Owner ID cannot be empty'));
    }

    // Create pet
    return await _repository.createPet(
      name: params.name.trim(),
      ownerId: params.ownerId,
      familyId: params.familyId,
    );
  }
}

class CreatePetParams {
  final String name;
  final String ownerId;
  final String familyId;

  const CreatePetParams({
    required this.name,
    required this.ownerId,
    required this.familyId,
  });
}
