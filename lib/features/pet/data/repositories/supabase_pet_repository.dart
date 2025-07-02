import 'package:fpdart/fpdart.dart' hide Task;
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/data/datasources/pet_remote_datasource.dart';
import 'package:jhonny/features/pet/data/models/pet_model.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';

class SupabasePetRepository implements PetRepository {
  final PetRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  SupabasePetRepository(this._remoteDataSource, this._uuid);

  @override
  Future<Either<Failure, Pet?>> getPetByOwnerId(String ownerId) async {
    try {
      final petModel = await _remoteDataSource.getPetByOwnerId(ownerId);
      return right(petModel?.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet?>> getFamilyPet(String familyId) async {
    try {
      final petModel = await _remoteDataSource.getFamilyPet(familyId);
      return right(petModel?.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> createPet({
    required String name,
    required String ownerId,
    required String familyId,
  }) async {
    try {
      final petId = _uuid.v4();
      final now = DateTime.now();

      final petModel = PetModel(
        id: petId,
        name: name,
        familyId: familyId,
        ownerId: ownerId,
        stage: PetStage.egg.name,
        mood: PetMood.neutral.name,
        experience: 0,
        level: 1,
        lastFedAt: now,
        lastPlayedAt: now,
        lastCareAt: now,
        createdAt: now,
        stats: const {
          'health': 100,
          'happiness': 100,
          'energy': 100,
          'hunger': 100,
          'emotion': 100,
        },
      );

      final createdPet = await _remoteDataSource.createPet(petModel);
      return right(createdPet.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> updatePet(Pet pet) async {
    try {
      final petModel = PetModel.fromEntity(pet);
      final updatedPet = await _remoteDataSource.updatePet(petModel);
      return right(updatedPet.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> feedPet({
    required String petId,
    required int bonusPoints,
  }) async {
    try {
      final updatedPet = await _remoteDataSource.feedPet(
        petId: petId,
        bonusPoints: bonusPoints,
      );
      return right(updatedPet.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> playWithPet({
    required String petId,
    required int bonusPoints,
  }) async {
    try {
      final updatedPet = await _remoteDataSource.playWithPet(
        petId: petId,
        bonusPoints: bonusPoints,
      );
      return right(updatedPet.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> giveMedicalCare({
    required String petId,
    required int bonusPoints,
  }) async {
    try {
      final updatedPet = await _remoteDataSource.giveMedicalCare(
        petId: petId,
        bonusPoints: bonusPoints,
      );
      return right(updatedPet.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> addExperience({
    required String petId,
    required int experiencePoints,
  }) async {
    try {
      final updatedPet = await _remoteDataSource.addExperience(
        petId: petId,
        experiencePoints: experiencePoints,
      );
      return right(updatedPet.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> evolvePet(String petId) async {
    try {
      final evolvedPet = await _remoteDataSource.evolvePet(petId);
      return right(evolvedPet.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pet>> updatePetMood(String petId) async {
    try {
      // Get current pet to check stats and calculate new mood
      final petResult = await getPetByOwnerId(petId);
      return petResult.fold(
        (failure) => left(failure),
        (pet) async {
          if (pet == null) {
            return left(const ValidationFailure(message: 'Pet not found'));
          }

          // Calculate mood based on current stats and time since care
          PetMood newMood = pet.mood;

          // Decrease mood over time if not cared for
          if (pet.needsFeeding || pet.needsPlay) {
            final health = pet.stats['health'] ?? 100;
            final happiness = pet.stats['happiness'] ?? 100;
            final energy = pet.stats['energy'] ?? 100;

            // Reduce stats over time for neglected pets
            final newHealth = (health - 5).clamp(0, 100);
            final newHappiness = (happiness - 10).clamp(0, 100);
            final newEnergy = (energy - 5).clamp(0, 100);

            // Calculate new mood from degraded stats
            final average = (newHealth + newHappiness + newEnergy) / 3;
            if (average >= 80)
              newMood = PetMood.happy;
            else if (average >= 60)
              newMood = PetMood.content;
            else if (average >= 40)
              newMood = PetMood.neutral;
            else if (average >= 20)
              newMood = PetMood.sad;
            else
              newMood = PetMood.upset;

            final updatedPet = pet.copyWith(
              mood: newMood,
              stats: {
                'health': newHealth,
                'happiness': newHappiness,
                'energy': newEnergy,
              },
            );

            return updatePet(updatedPet);
          }

          return right(pet);
        },
      );
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PetCareEvent>>> getPetCareHistory(
      String petId) async {
    // For now, return empty list - this could be implemented with a separate care_events table
    try {
      return right(<PetCareEvent>[]);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Pet?> watchPet(String petId) {
    return _remoteDataSource
        .watchPet(petId)
        .map((petModel) => petModel?.toEntity());
  }

  @override
  Stream<Pet?> watchFamilyPet(String familyId) {
    return _remoteDataSource
        .watchFamilyPet(familyId)
        .map((petModel) => petModel?.toEntity());
  }

  @override
  Future<Either<Failure, void>> deletePet(String petId) async {
    try {
      await _remoteDataSource.deletePet(petId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
