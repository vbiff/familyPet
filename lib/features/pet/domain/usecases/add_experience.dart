import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class AddExperience {
  final PetRepository _repository;

  const AddExperience(this._repository);

  Future<Either<Failure, PetExperienceResult>> call(
      AddExperienceParams params) async {
    // Validation
    if (params.petId.isEmpty) {
      return left(const ValidationFailure(message: 'Pet ID cannot be empty'));
    }

    if (params.experiencePoints <= 0) {
      return left(const ValidationFailure(
          message: 'Experience points must be positive'));
    }

    // Add experience to pet
    final experienceResult = await _repository.addExperience(
      petId: params.petId,
      experiencePoints: params.experiencePoints,
    );

    return experienceResult.fold(
      (failure) => left(failure),
      (updatedPet) async {
        // Check if pet can evolve after gaining experience
        if (updatedPet.canEvolve) {
          final evolutionResult = await _repository.evolvePet(params.petId);
          return evolutionResult.fold(
            (failure) => right(PetExperienceResult(
              pet: updatedPet,
              experienceGained: params.experiencePoints,
              evolved: false,
              evolutionError: failure.message,
            )),
            (evolvedPet) => right(PetExperienceResult(
              pet: evolvedPet,
              experienceGained: params.experiencePoints,
              evolved: true,
            )),
          );
        } else {
          return right(PetExperienceResult(
            pet: updatedPet,
            experienceGained: params.experiencePoints,
            evolved: false,
          ));
        }
      },
    );
  }
}

class AddExperienceParams {
  final String petId;
  final int experiencePoints;
  final String reason; // e.g., "Task completed: Clean Room"

  const AddExperienceParams({
    required this.petId,
    required this.experiencePoints,
    this.reason = 'Task completed',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddExperienceParams &&
        other.petId == petId &&
        other.experiencePoints == experiencePoints &&
        other.reason == reason;
  }

  @override
  int get hashCode =>
      petId.hashCode ^ experiencePoints.hashCode ^ reason.hashCode;
}

class PetExperienceResult {
  final Pet pet;
  final int experienceGained;
  final bool evolved;
  final String? evolutionError;

  const PetExperienceResult({
    required this.pet,
    required this.experienceGained,
    required this.evolved,
    this.evolutionError,
  });

  bool get hasEvolutionError => evolutionError != null;
}
