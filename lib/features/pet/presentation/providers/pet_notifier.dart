import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/pet/domain/usecases/add_experience.dart';
import 'package:jhonny/features/pet/domain/usecases/feed_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/get_family_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/give_medical_care.dart';
import 'package:jhonny/features/pet/domain/usecases/play_with_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/create_pet.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_state.dart';
import 'package:logger/logger.dart';

class PetNotifier extends StateNotifier<PetState> {
  final GetFamilyPet _getFamilyPet;
  final FeedPet _feedPet;
  final PlayWithPet _playWithPet;
  final GiveMedicalCare _giveMedicalCare;
  final AddExperience _addExperience;
  final CreatePet _createPet;
  final Logger _logger;

  PetNotifier(
    this._getFamilyPet,
    this._feedPet,
    this._playWithPet,
    this._giveMedicalCare,
    this._addExperience,
    this._createPet,
    this._logger,
  ) : super(const PetState());

  /// Load family pet
  Future<void> loadFamilyPet(String familyId) async {
    if (state.isLoading) return;

    state = state.copyWith(status: PetStateStatus.loading, clearError: true);

    final result = await _getFamilyPet(familyId);
    result.fold(
      (failure) {
        _logger.e('Failed to load family pet: ${failure.message}');
        state = state.copyWith(
          status: PetStateStatus.error,
          errorMessage: failure.message,
        );
      },
      (pet) {
        _logger.i('Family pet loaded successfully: ${pet?.name ?? 'No pet'}');
        state = state.copyWith(
          status: PetStateStatus.success,
          pet: pet,
        );
      },
    );
  }

  /// Create a new pet
  Future<void> createPet({
    required String name,
    required String familyId,
    String? ownerId,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      _logger.i('Creating pet: $name for family: $familyId');

      // Use the current user's ID as the owner ID
      // In a real implementation, this should come from the auth state
      final petOwnerId =
          ownerId ?? 'current-user-id'; // TODO: Get from auth provider

      final result = await _createPet(CreatePetParams(
        name: name,
        ownerId: petOwnerId,
        familyId: familyId,
      ));

      result.fold(
        (failure) {
          _logger.e('Failed to create pet: ${failure.message}');
          state = state.copyWith(
            isUpdating: false,
            status: PetStateStatus.error,
            errorMessage: failure.message,
          );
        },
        (pet) {
          _logger.i('Pet created successfully: ${pet.name}');
          state = state.copyWith(
            isUpdating: false,
            pet: pet,
            status: PetStateStatus.success,
            lastAction: 'Pet "${pet.name}" created successfully! 🎉',
          );
        },
      );
    } catch (e) {
      _logger.e('Failed to create pet: $e');
      state = state.copyWith(
        isUpdating: false,
        status: PetStateStatus.error,
        errorMessage: 'Failed to create pet: $e',
      );
    }
  }

  /// Feed the pet
  Future<void> feedPet({int bonusPoints = 0}) async {
    final currentPet = state.pet;
    if (currentPet == null) return;

    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await _feedPet(FeedPetParams(
      petId: currentPet.id,
      bonusPoints: bonusPoints,
    ));

    result.fold(
      (failure) {
        _logger.e('Failed to feed pet: ${failure.message}');
        state = state.copyWith(
          isUpdating: false,
          errorMessage: failure.message,
        );
      },
      (updatedPet) {
        _logger.i(
            'Pet fed successfully. Health: ${updatedPet.stats['health']}, Happiness: ${updatedPet.stats['happiness']}');
        state = state.copyWith(
          isUpdating: false,
          pet: updatedPet,
          lastAction: 'Fed ${updatedPet.name}! Health and happiness increased.',
        );
      },
    );
  }

  /// Play with the pet
  Future<void> playWithPet({int bonusPoints = 0}) async {
    final currentPet = state.pet;
    if (currentPet == null) return;

    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await _playWithPet(PlayWithPetParams(
      petId: currentPet.id,
      bonusPoints: bonusPoints,
    ));

    result.fold(
      (failure) {
        _logger.e('Failed to play with pet: ${failure.message}');
        state = state.copyWith(
          isUpdating: false,
          errorMessage: failure.message,
        );
      },
      (updatedPet) {
        _logger.i(
            'Played with pet successfully. Happiness: ${updatedPet.stats['happiness']}, Energy: ${updatedPet.stats['energy']}');
        state = state.copyWith(
          isUpdating: false,
          pet: updatedPet,
          lastAction: 'Played with ${updatedPet.name}! Happiness increased.',
        );
      },
    );
  }

  /// Give medical care to the pet
  Future<void> giveMedicalCare({int bonusPoints = 0}) async {
    final currentPet = state.pet;
    if (currentPet == null) return;

    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await _giveMedicalCare(GiveMedicalCareParams(
      petId: currentPet.id,
      bonusPoints: bonusPoints,
    ));

    result.fold(
      (failure) {
        _logger.e('Failed to give medical care: ${failure.message}');
        state = state.copyWith(
          isUpdating: false,
          errorMessage: failure.message,
        );
      },
      (updatedPet) {
        _logger.i(
            'Medical care given successfully. Health: ${updatedPet.stats['health']}');
        state = state.copyWith(
          isUpdating: false,
          pet: updatedPet,
          lastAction:
              'Gave medical care to ${updatedPet.name}! Health restored.',
        );
      },
    );
  }

  /// Add experience to pet (called when tasks are completed)
  Future<void> addExperienceFromTask({
    required int experiencePoints,
    required String taskTitle,
  }) async {
    final currentPet = state.pet;
    if (currentPet == null) return;

    _logger.i(
        'Adding $experiencePoints XP to pet for completing task: $taskTitle');

    state = state.copyWith(isUpdating: true, clearError: true);

    final result = await _addExperience(AddExperienceParams(
      petId: currentPet.id,
      experiencePoints: experiencePoints,
      reason: 'Task completed: $taskTitle',
    ));

    result.fold(
      (failure) {
        _logger.e('Failed to add experience: ${failure.message}');
        state = state.copyWith(
          isUpdating: false,
          errorMessage: failure.message,
        );
      },
      (experienceResult) {
        final updatedPet = experienceResult.pet;
        final evolved = experienceResult.evolved;

        _logger.i(
            'Experience added successfully. XP: ${updatedPet.experience}, Level: ${updatedPet.level}, Evolved: $evolved');

        String actionMessage =
            'Earned $experiencePoints XP from completing "$taskTitle"!';
        if (evolved) {
          actionMessage +=
              '\n🎉 ${updatedPet.name} evolved to ${updatedPet.stage.name}!';
        }

        state = state.copyWith(
          isUpdating: false,
          pet: updatedPet,
          hasEvolved: evolved,
          lastAction: actionMessage,
        );
      },
    );
  }

  /// Clear any temporary state
  void clearLastAction() {
    state = state.copyWith(lastAction: null);
  }

  void clearEvolution() {
    state = state.copyWith(clearEvolution: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh pet data
  Future<void> refresh(String familyId) async {
    await loadFamilyPet(familyId);
  }
}
