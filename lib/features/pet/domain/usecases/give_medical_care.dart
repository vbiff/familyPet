import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class GiveMedicalCare {
  final PetRepository _repository;

  const GiveMedicalCare(this._repository);

  Future<Either<Failure, Pet>> call(GiveMedicalCareParams params) async {
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

        // Check if pet needs medical care (business rule)
        final currentHealth = pet.stats['health'] ?? 100;
        if (currentHealth >= 90 && params.bonusPoints == 0) {
          return left(const ValidationFailure(
            message: 'Pet is already healthy! Medical care not needed.',
          ));
        }

        // Check if pet is in negative mood and needs care
        if (pet.mood.isNegative || currentHealth < 50) {
          // Medical care is always beneficial for sick pets
        }

        // Give medical care
        return await _repository.giveMedicalCare(
          petId: params.petId,
          bonusPoints: params.bonusPoints,
        );
      },
    );
  }
}

class GiveMedicalCareParams {
  final String petId;
  final int bonusPoints; // Bonus points from task completion

  const GiveMedicalCareParams({
    required this.petId,
    this.bonusPoints = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GiveMedicalCareParams &&
        other.petId == petId &&
        other.bonusPoints == bonusPoints;
  }

  @override
  int get hashCode => petId.hashCode ^ bonusPoints.hashCode;
}
