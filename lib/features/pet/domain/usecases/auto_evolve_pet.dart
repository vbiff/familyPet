import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class AutoEvolvePet {
  final PetRepository _repository;

  const AutoEvolvePet(this._repository);

  /// Automatically evolve pet based on its age
  /// Evolution happens every 2 days: egg -> baby -> child -> teen -> adult
  Future<Either<Failure, Pet?>> call(Pet pet) async {
    try {
      // Calculate pet's age in days
      final now = DateTime.now();
      final ageInDays = now.difference(pet.createdAt).inDays;

      // Determine what stage the pet should be based on age
      final expectedStage = _calculateStageByAge(ageInDays);

      // If pet is already at the correct stage, no evolution needed
      if (pet.stage == expectedStage) {
        return Right(pet);
      }

      // Check if the expected stage is more advanced than current stage
      final currentStageIndex = PetStage.values.indexOf(pet.stage);
      final expectedStageIndex = PetStage.values.indexOf(expectedStage);

      // Only evolve forward, never backward
      if (expectedStageIndex <= currentStageIndex) {
        return Right(pet);
      }

      // Evolve the pet to the expected stage
      final evolvedPet = pet.copyWith(
        stage: expectedStage,
        mood: PetMood.happy, // Pet is happy after evolution
        stats: _calculateEvolvedStats(pet.stats, expectedStage),
      );

      // Update the pet in the database
      final updateResult = await _repository.updatePet(evolvedPet);

      return updateResult.fold(
        (failure) => Left(failure),
        (updatedPet) => Right(updatedPet),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to auto-evolve pet: $e'));
    }
  }

  /// Calculate the expected stage based on pet's age in days
  PetStage _calculateStageByAge(int ageInDays) {
    if (ageInDays < 2) return PetStage.egg; // 0-1 days
    if (ageInDays < 4) return PetStage.baby; // 2-3 days
    if (ageInDays < 6) return PetStage.child; // 4-5 days
    if (ageInDays < 8) return PetStage.teen; // 6-7 days
    return PetStage.adult; // 8+ days
  }

  /// Calculate evolved stats - pets get stronger as they grow
  Map<String, int> _calculateEvolvedStats(
      Map<String, int> currentStats, PetStage newStage) {
    final stats = Map<String, int>.from(currentStats);

    // Base stat boosts for evolution
    final healthBoost = _getStatBoost(newStage, 'health');
    final happinessBoost = _getStatBoost(newStage, 'happiness');
    final energyBoost = _getStatBoost(newStage, 'energy');

    stats['health'] = (stats['health']! + healthBoost).clamp(0, 100);
    stats['happiness'] = (stats['happiness']! + happinessBoost).clamp(0, 100);
    stats['energy'] = (stats['energy']! + energyBoost).clamp(0, 100);

    return stats;
  }

  /// Get stat boost amount based on the new stage
  int _getStatBoost(PetStage stage, String statType) {
    switch (stage) {
      case PetStage.baby:
        return statType == 'health'
            ? 5
            : statType == 'happiness'
                ? 10
                : 5;
      case PetStage.child:
        return statType == 'health'
            ? 8
            : statType == 'happiness'
                ? 5
                : 8;
      case PetStage.teen:
        return statType == 'health'
            ? 10
            : statType == 'happiness'
                ? 8
                : 12;
      case PetStage.adult:
        return statType == 'health'
            ? 15
            : statType == 'happiness'
                ? 10
                : 15;
      default:
        return 0;
    }
  }
}
