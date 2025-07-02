import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jhonny/features/pet/data/models/pet_model.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:logger/logger.dart';

abstract class PetRemoteDataSource {
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
          .single();

      return PetModel.fromJson(data);
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
      final currentPet = await _getPetById(petId);

      // Apply time decay first
      final petWithDecay = currentPet.toEntity().applyTimeDecay();

      // Calculate new stats based on new mechanics
      final currentHunger = petWithDecay.hunger;
      final currentEnergy = petWithDecay.energy;
      final currentEmotion = petWithDecay.emotion;

      // 1 point = 1% hunger increase, energy goes to 100%
      final hungerIncrease = bonusPoints; // Direct 1:1 mapping
      final newHunger = (currentHunger + hungerIncrease).clamp(0, 100);
      const newEnergy = 100; // Energy always goes to 100% when fed

      // Improve emotion based on how much hunger was restored
      final emotionIncrease =
          (hungerIncrease * 0.5).round(); // Half of hunger increase
      final newEmotion = (currentEmotion + emotionIncrease).clamp(0, 100);

      // Keep other stats
      final newHealth = petWithDecay.health;
      final newHappiness = petWithDecay.happiness;

      final updatedStats = <String, int>{
        'health': newHealth,
        'happiness': newHappiness,
        'energy': newEnergy,
        'hunger': newHunger,
        'emotion': newEmotion,
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
      final currentPet = await _getPetById(petId);

      // Calculate new stats
      final currentEnergy = currentPet.stats['energy'] ?? 100;
      final currentHappiness = currentPet.stats['happiness'] ?? 100;

      final energyDecrease =
          15 - bonusPoints; // Playing uses energy, bonuses reduce energy cost
      final happinessIncrease = 20 + bonusPoints; // 20 base + bonus

      final newEnergy = (currentEnergy - energyDecrease).clamp(0, 100);
      final newHappiness = (currentHappiness + happinessIncrease).clamp(0, 100);

      // Determine mood change
      final newMood = _calculateMoodFromStats(
          currentPet.stats['health'] ?? 100, newHappiness, newEnergy);

      final updatedStats = Map<String, int>.from(currentPet.stats);
      updatedStats['energy'] = newEnergy;
      updatedStats['happiness'] = newHappiness;

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
      final currentPet = await _getPetById(petId);

      // Calculate new stats
      final currentHealth = currentPet.stats['health'] ?? 100;
      final currentHappiness = currentPet.stats['happiness'] ?? 100;
      final currentEnergy = currentPet.stats['energy'] ?? 100;

      final healthIncrease = 25 + (bonusPoints * 3); // Strong health boost
      final happinessIncrease = 10 + bonusPoints; // Small happiness boost
      final energyIncrease = 5 + bonusPoints; // Small energy boost

      final newHealth = (currentHealth + healthIncrease).clamp(0, 100);
      final newHappiness = (currentHappiness + happinessIncrease).clamp(0, 100);
      final newEnergy = (currentEnergy + energyIncrease).clamp(0, 100);

      // Medical care always improves mood significantly if pet was sick
      final newMood = newHealth >= 80 ? PetMood.content : PetMood.neutral;

      final updatedStats = Map<String, int>.from(currentPet.stats);
      updatedStats['health'] = newHealth;
      updatedStats['happiness'] = newHappiness;
      updatedStats['energy'] = newEnergy;

      final updatedPet = currentPet.copyWith(
        mood: newMood.name,
        stats: updatedStats,
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
      final currentPet = await _getPetById(petId);

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
      final currentPet = await _getPetById(petId);

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
      updatedStats['energy'] = 100; // Full energy on evolution

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
  Future<PetModel> _getPetById(String petId) async {
    final data =
        await _client.from(_tableName).select().eq('id', petId).maybeSingle();
    if (data == null) {
      throw Exception('Pet not found with id: $petId');
    }
    return PetModel.fromJson(data);
  }

  PetMood _calculateMoodFromStats(int health, int happiness, int energy) {
    final average = (health + happiness + energy) / 3;
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
