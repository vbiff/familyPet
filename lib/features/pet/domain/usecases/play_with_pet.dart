import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class PlayWithPet {
  final PetRepository _repository;

  const PlayWithPet(this._repository);

  Future<Either<Failure, Pet>> call(PlayWithPetParams params) async {
    // Validation
    if (params.petId.isEmpty) {
      return left(const ValidationFailure(message: 'Pet ID cannot be empty'));
    }

    if (params.bonusPoints < 0) {
      return left(
          const ValidationFailure(message: 'Bonus points cannot be negative'));
    }

    // Get current pet state to check if we need to fetch by ID
    final petResult = await _repository.getPetByOwnerId(params.petId);
    return petResult.fold(
      (failure) => left(failure),
      (pet) async {
        if (pet == null) {
          return left(const ValidationFailure(message: 'Pet not found'));
        }

        // Check if pet needs play (business rule)
        if (!pet.needsPlay && params.bonusPoints == 0) {
          return left(const ValidationFailure(
            message:
                'Pet is not in the mood to play right now. Try again later!',
          ));
        }

        // Check pet energy level
        final currentEnergy = pet.stats['energy'] ?? 0;
        if (currentEnergy < 20) {
          return left(const ValidationFailure(
            message: 'Pet is too tired to play. Feed your pet first!',
          ));
        }

        // Play with the pet
        return await _repository.playWithPet(
          petId: params.petId,
          bonusPoints: params.bonusPoints,
        );
      },
    );
  }
}

class PlayWithPetParams {
  final String petId;
  final int bonusPoints; // Bonus points from task completion

  const PlayWithPetParams({
    required this.petId,
    this.bonusPoints = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayWithPetParams &&
        other.petId == petId &&
        other.bonusPoints == bonusPoints;
  }

  @override
  int get hashCode => petId.hashCode ^ bonusPoints.hashCode;
}
