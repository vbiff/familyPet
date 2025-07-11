import 'package:fpdart/fpdart.dart' hide Task;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';

abstract class PetRepository {
  /// Get pet by ID
  Future<Either<Failure, Pet?>> getPetById(String petId);

  /// Get pet by owner ID
  Future<Either<Failure, Pet?>> getPetByOwnerId(String ownerId);

  /// Get family pet
  Future<Either<Failure, Pet?>> getFamilyPet(String familyId);

  /// Create a new pet for a family member
  Future<Either<Failure, Pet>> createPet({
    required String name,
    required String ownerId,
    required String familyId,
  });

  /// Update pet details
  Future<Either<Failure, Pet>> updatePet(Pet pet);

  /// Feed the pet - increases happiness and health
  Future<Either<Failure, Pet>> feedPet({
    required String petId,
    required int bonusPoints,
  });

  /// Play with the pet - increases happiness
  Future<Either<Failure, Pet>> playWithPet({
    required String petId,
    required int bonusPoints,
  });

  /// Give medical care - increases health and mood
  Future<Either<Failure, Pet>> giveMedicalCare({
    required String petId,
    required int bonusPoints,
  });

  /// Add experience points to pet (from completed tasks)
  Future<Either<Failure, Pet>> addExperience({
    required String petId,
    required int experiencePoints,
  });

  /// Evolve pet to next stage
  Future<Either<Failure, Pet>> evolvePet(String petId);

  /// Update pet mood based on care needs
  Future<Either<Failure, Pet>> updatePetMood(String petId);

  /// Get pet care history
  Future<Either<Failure, List<PetCareEvent>>> getPetCareHistory(String petId);

  /// Watch pet changes in real-time
  Stream<Pet?> watchPet(String petId);

  /// Watch family pet changes
  Stream<Pet?> watchFamilyPet(String familyId);

  /// Delete pet (admin only)
  Future<Either<Failure, void>> deletePet(String petId);
}

/// Pet care event for tracking interactions
class PetCareEvent {
  final String id;
  final String petId;
  final String careType; // 'feed', 'play', 'medical'
  final String performedBy;
  final int pointsAwarded;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PetCareEvent({
    required this.id,
    required this.petId,
    required this.careType,
    required this.performedBy,
    required this.pointsAwarded,
    required this.timestamp,
    this.metadata,
  });
}
