import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jhonny/features/pet/data/models/pet_model.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:logger/logger.dart';

abstract class PetRemoteDataSource {
  Future<PetModel?> getPetById(String petId);
  Future<PetModel?> getPetByOwnerId(String ownerId);
  Future<PetModel?> getFamilyPet(String familyId);
  Future<PetModel> createPet(PetModel pet);
  Future<PetModel> updatePet(PetModel pet);
  Future<PetModel> feedPet({required String petId, required int bonusPoints});
  Future<PetModel> playWithPet(
      {required String petId, required int bonusPoints});
  Future<PetModel> giveMedicalCare(
      {required String petId, required int bonusPoints});
  Future<PetModel> addExperience(
      {required String petId, required int experiencePoints});
  Future<PetModel> evolvePet(String petId);
  Future<void> deletePet(String petId);
  Stream<PetModel?> watchPet(String petId);
  Stream<PetModel?> watchFamilyPet(String familyId);
}

class SupabasePetRemoteDataSource implements PetRemoteDataSource {
  final SupabaseClient _client;
  static const String _tableName = 'pets';
  static final _logger = Logger();

  SupabasePetRemoteDataSource(this._client);

  @override
  Future<PetModel?> getPetById(String petId) async {
    try {
      final data =
          await _client.from(_tableName).select().eq('id', petId).maybeSingle();

      if (data == null) return null;
      return PetModel.fromJson(data);
    } catch (e) {
      _logger.e('Failed to get pet by ID: $e');
      throw Exception('Failed to get pet: $e');
    }
  }

  @override
  Future<PetModel?> getPetByOwnerId(String ownerId) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (data == null) return null;
      return PetModel.fromJson(data);
    } catch (e) {
      _logger.e('Failed to get pet by owner ID: $e');
      throw Exception('Failed to get pet: $e');
    }
  }

  @override
  Future<PetModel?> getFamilyPet(String familyId) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .eq('family_id', familyId)
          .maybeSingle();

      if (data == null) return null;
      return PetModel.fromJson(data);
    } catch (e) {
      _logger.e('Failed to get family pet: $e');
      throw Exception('Failed to get family pet: $e');
    }
  }

  @override
  Future<PetModel> createPet(PetModel pet) async {
    try {
      final data = await _client
          .from(_tableName)
          .insert(pet.toCreateJson())
          .select()
          .single();

      _logger.i('Pet created successfully: ${pet.name}');
      return PetModel.fromJson(data);
    } catch (e) {
      _logger.e('Failed to create pet: $e');
      throw Exception('Failed to create pet: $e');
    }
  }

  @override
  Future<PetModel> updatePet(PetModel pet) async {
    try {
      final data = await _client
          .from(_tableName)
          .update(pet.toJson())
          .eq('id', pet.id)
          .select()
          .maybeSingle();

      if (data == null) {
        _logger.w(
            'No pet found for update with id: ${pet.id}. This may be due to RLS policies or the pet may have been deleted.');
        // Return the original pet model instead of throwing an error
        // This prevents cascading failures in the UI
        return pet;
      }

      return PetModel.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116' || e.message.contains('0 rows')) {
        _logger.w(
            'Pet update blocked by RLS policies or pet not found: ${e.message}');
        // Return the original pet model to prevent UI errors
        return pet;
      }
      _logger.e('Failed to update pet with Postgrest error: $e');
      throw Exception('Failed to update pet: $e');
    } catch (e) {
      _logger.e('Failed to update pet: $e');
      throw Exception('Failed to update pet: $e');
    }
  }

  @override
  Future<PetModel> feedPet(
      {required String petId, required int bonusPoints}) async {
    try {
      // Get current pet
      final currentPet = await getPetById(petId);
      if (currentPet == null) {
        throw Exception('Pet not found with id: $petId');
      }

      // Apply time decay first
      final petWithDecay = currentPet.toEntity().applyTimeDecay();

      // Calculate new stats based on new mechanics
      final currentHunger = petWithDecay.hunger;
      final currentHappiness = petWithDecay.happiness;

      // Feeding always restores hunger to 100%, plus bonus points if any
      const newHunger = 100; // Always restore to full hunger

      // Calculate happiness increase based on how much hunger was restored
      final hungerRestored = newHunger - currentHunger;
      final happinessIncrease = (hungerRestored * 0.3).round() +
          bonusPoints; // 30% of hunger restored + bonus
      final newHappiness = (currentHappiness + happinessIncrease).clamp(0, 100);

      // Keep other stats
      final newHealth = petWithDecay.health;

      final updatedStats = <String, int>{
        'health': newHealth,
        'happiness': newHappiness,
        'hunger': newHunger,
      };

      // Create updated pet with new mood calculation
      final updatedPetEntity = petWithDecay.copyWith(
        stats: updatedStats,
        lastFedAt: DateTime.now(),
        lastCareAt: DateTime.now(),
      );

      // Calculate new mood based on updated stats
      final newMood = updatedPetEntity.currentMood;

      final updatedPet = PetModel.fromEntity(updatedPetEntity).copyWith(
        mood: newMood.name,
      );

      return await updatePet(updatedPet);
    } catch (e) {
      _logger.e('Failed to feed pet: $e');
      throw Exception('Failed to feed pet: $e');
    }
  }

  @override
  Future<PetModel> playWithPet(
      {required String petId, required int bonusPoints}) async {
    try {
      // Get current pet
      final currentPet = await getPetById(petId);
      if (currentPet == null) {
        throw Exception('Pet not found with id: $petId');
      }

      // Calculate new stats
      final currentHappiness = currentPet.stats['happiness'] ?? 100;
      final currentHunger = currentPet.stats['hunger'] ?? 100;

      final happinessIncrease = 20 + bonusPoints; // 20 base + bonus
      const hungerDecrease = 5; // Playing makes the pet a bit hungry

      final newHappiness = (currentHappiness + happinessIncrease).clamp(0, 100);
      final newHunger = (currentHunger - hungerDecrease).clamp(0, 100);

      // Determine mood change
      final newMood = _calculateMoodFromStats(
          currentPet.stats['health'] ?? 100, newHappiness, newHunger);

      final updatedStats = Map<String, int>.from(currentPet.stats);
      updatedStats['happiness'] = newHappiness;
      updatedStats['hunger'] = newHunger;

      final updatedPet = currentPet.copyWith(
        lastPlayedAt: DateTime.now(),
        mood: newMood.name,
        stats: updatedStats,
      );

      return await updatePet(updatedPet);
    } catch (e) {
      _logger.e('Failed to play with pet: $e');
      throw Exception('Failed to play with pet: $e');
    }
  }

  @override
  Future<PetModel> giveMedicalCare(
      {required String petId, required int bonusPoints}) async {
    try {
      // Get current pet
      final currentPet = await getPetById(petId);
      if (currentPet == null) {
        throw Exception('Pet not found with id: $petId');
      }

      // Apply time decay first
      final petWithDecay = currentPet.toEntity().applyTimeDecay();

      // Medical care always restores health to 100%, does not affect happiness
      final currentHappiness =
          petWithDecay.stats['happiness'] ?? 100; // Keep unchanged
      final currentHunger =
          petWithDecay.stats['hunger'] ?? 100; // Keep unchanged

      // Always restore health to 100% + any bonus points
      const newHealth = 100; // Always full health
      final newHappiness = currentHappiness; // Don't change happiness
      final newHunger = currentHunger; // Don't change hunger

      final updatedStats = <String, int>{
        'health': newHealth,
        'happiness': newHappiness,
        'hunger': newHunger,
      };

      // Create updated pet with new stats
      final updatedPetEntity = petWithDecay.copyWith(
        stats: updatedStats,
        lastCareAt: DateTime.now(),
      );

      // Calculate new mood based on updated stats (should improve if health was low)
      final newMood = updatedPetEntity.currentMood;

      final updatedPet = PetModel.fromEntity(updatedPetEntity).copyWith(
        mood: newMood.name,
      );

      return await updatePet(updatedPet);
    } catch (e) {
      _logger.e('Failed to give medical care: $e');
      throw Exception('Failed to give medical care: $e');
    }
  }

  @override
  Future<PetModel> addExperience(
      {required String petId, required int experiencePoints}) async {
    try {
      // Get current pet
      final currentPet = await getPetById(petId);
      if (currentPet == null) {
        throw Exception('Pet not found with id: $petId');
      }

      final newExperience = currentPet.experience + experiencePoints;
      final newLevel = _calculateLevel(newExperience);

      final updatedPet = currentPet.copyWith(
        experience: newExperience,
        level: newLevel,
      );

      _logger.i(
          'Added $experiencePoints XP to pet ${currentPet.name}. New total: $newExperience');
      return await updatePet(updatedPet);
    } catch (e) {
      _logger.e('Failed to add experience: $e');
      throw Exception('Failed to add experience: $e');
    }
  }

  @override
  Future<PetModel> evolvePet(String petId) async {
    try {
      // Get current pet
      final currentPet = await getPetById(petId);
      if (currentPet == null) {
        throw Exception('Pet not found with id: $petId');
      }

      // Check if evolution is possible
      final currentStageEnum = PetStage.values.firstWhere(
        (s) => s.name == currentPet.stage,
        orElse: () => PetStage.egg,
      );
      if (!currentStageEnum.canEvolve) {
        throw Exception('Pet cannot evolve further');
      }

      final nextStage = currentStageEnum.nextStage!;

      // Bonus stats for evolution
      final updatedStats = Map<String, int>.from(currentPet.stats);
      updatedStats['health'] = (updatedStats['health']! + 10).clamp(0, 100);
      updatedStats['happiness'] =
          (updatedStats['happiness']! + 15).clamp(0, 100);

      final updatedPet = currentPet.copyWith(
        stage: nextStage.name,
        mood: PetMood.happy.name, // Happy after evolution
        stats: updatedStats,
      );

      _logger.i(
          'Pet ${currentPet.name} evolved from ${currentStageEnum.name} to ${nextStage.name}!');
      return await updatePet(updatedPet);
    } catch (e) {
      _logger.e('Failed to evolve pet: $e');
      throw Exception('Failed to evolve pet: $e');
    }
  }

  @override
  Future<void> deletePet(String petId) async {
    try {
      await _client.from(_tableName).delete().eq('id', petId);
      _logger.i('Pet deleted: $petId');
    } catch (e) {
      _logger.e('Failed to delete pet: $e');
      throw Exception('Failed to delete pet: $e');
    }
  }

  @override
  Stream<PetModel?> watchPet(String petId) {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('id', petId)
        .map((data) => data.isNotEmpty ? PetModel.fromJson(data.first) : null);
  }

  @override
  Stream<PetModel?> watchFamilyPet(String familyId) {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((data) => data.isNotEmpty ? PetModel.fromJson(data.first) : null);
  }

  // Helper methods
  PetMood _calculateMoodFromStats(int health, int happiness, int hunger) {
    // Use inverse of hunger (higher hunger = worse mood)
    final average = (health + happiness + (100 - hunger)) / 3;
    if (average >= 80) return PetMood.happy;
    if (average >= 60) return PetMood.content;
    if (average >= 40) return PetMood.neutral;
    if (average >= 20) return PetMood.sad;
    return PetMood.upset;
  }

  int _calculateLevel(int experience) {
    if (experience < 100) return 1;
    if (experience < 300) return 2;
    if (experience < 600) return 3;
    if (experience < 1000) return 4;
    return min(5 + ((experience - 1000) ~/ 200), 100); // Max level 100
  }
}
