import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class FeedPet {
  final PetRepository _repository;

  const FeedPet(this._repository);

  Future<Either<Failure, Pet>> call(FeedPetParams params) async {
    // Validation
    if (params.petId.isEmpty) {
      return left(const ValidationFailure(message: 'Pet ID cannot be empty'));
    }

    if (params.bonusPoints < 0) {
      return left(
          const ValidationFailure(message: 'Bonus points cannot be negative'));
    }

    // Get current pet state
    final petResult = await _repository.getPetByOwnerId(params.petId);
    return petResult.fold(
      (failure) => left(failure),
      (pet) async {
        if (pet == null) {
          return left(const ValidationFailure(message: 'Pet not found'));
        }

        // Check if pet needs feeding (business rule)
        if (!pet.needsFeeding && params.bonusPoints == 0) {
          return left(const ValidationFailure(
            message: 'Pet doesn\'t need feeding right now. Try again later!',
          ));
        }

        // Feed the pet
        return await _repository.feedPet(
          petId: params.petId,
          bonusPoints: params.bonusPoints,
        );
      },
    );
  }
}

class FeedPetParams {
  final String petId;
  final int bonusPoints; // Bonus points from task completion

  const FeedPetParams({
    required this.petId,
    this.bonusPoints = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedPetParams &&
        other.petId == petId &&
        other.bonusPoints == bonusPoints;
  }

  @override
  int get hashCode => petId.hashCode ^ bonusPoints.hashCode;
}
