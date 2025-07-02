import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class UpdatePetTimeDecay {
  final PetRepository _repository;

  const UpdatePetTimeDecay(this._repository);

  Future<Either<Failure, Pet>> call(UpdatePetTimeDecayParams params) async {
    // Validation
    if (params.petId.isEmpty) {
      return left(const ValidationFailure(message: 'Pet ID cannot be empty'));
    }

    try {
      // Get current pet
      final petResult = await _repository.getPetByOwnerId(params.petId);
      return petResult.fold(
        (failure) => left(failure),
        (pet) async {
          if (pet == null) {
            return left(const ValidationFailure(message: 'Pet not found'));
          }

          // Apply time decay to pet stats
          final updatedPet = pet.applyTimeDecay();

          // Only update if stats have changed
          if (updatedPet != pet) {
            return await _repository.updatePet(updatedPet);
          }

          return right(pet);
        },
      );
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}

class UpdatePetTimeDecayParams {
  final String petId;

  const UpdatePetTimeDecayParams({
    required this.petId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdatePetTimeDecayParams && other.petId == petId;
  }

  @override
  int get hashCode => petId.hashCode;
}
