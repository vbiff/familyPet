import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/domain/usecases/add_experience.dart';
import 'package:jhonny/features/pet/domain/usecases/feed_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/get_family_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/give_medical_care.dart';
import 'package:jhonny/features/pet/domain/usecases/play_with_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/create_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/auto_evolve_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/update_pet_time_decay.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_state.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_provider.dart';
import 'package:logger/logger.dart';

class PetNotifier extends StateNotifier<PetState> {
  final GetFamilyPet _getFamilyPet;
  final FeedPet _feedPet;
  final PlayWithPet _playWithPet;
  final GiveMedicalCare _giveMedicalCare;
  final AddExperience _addExperience;
  final CreatePet _createPet;
  final AutoEvolvePet _autoEvolvePet;
  final UpdatePetTimeDecay _updatePetTimeDecay;
  final Logger _logger;
  final Ref _ref;

  PetNotifier(
    this._getFamilyPet,
    this._feedPet,
    this._playWithPet,
    this._giveMedicalCare,
    this._addExperience,
    this._createPet,
    this._autoEvolvePet,
    this._updatePetTimeDecay,
    this._logger,
    this._ref,
  ) : super(const PetState());

  /// Load family pet
  Future<void> loadFamilyPet(String familyId) async {
    if (state.isLoading) return;

    // Guard: Don't load if family ID is empty
    if (familyId.isEmpty) {
      _logger.w('Attempted to load pet with empty family ID');
      state = state.copyWith(
        status: PetStateStatus.success,
        pet: null,
      );
      return;
    }

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
      (pet) async {
        _logger.i('Family pet loaded successfully: ${pet?.name ?? 'No pet'}');

        if (pet != null) {
          // Apply time decay first
          final timeDecayResult = await _updatePetTimeDecay(
              UpdatePetTimeDecayParams(petId: pet.id));

          Pet? petWithDecay = pet;
          timeDecayResult.fold(
            (failure) {
              _logger.w('Time decay update failed: ${failure.message}');
              // Continue with original pet if decay fails - this is not critical
              // and shouldn't affect the user experience
            },
            (decayedPet) {
              petWithDecay = decayedPet;
              _logger.i('Time decay applied to pet: ${decayedPet.name}');
            },
          );

          // Check if pet needs auto-evolution based on age
          final evolveResult = await _autoEvolvePet(petWithDecay!);
          evolveResult.fold(
            (failure) {
              _logger.w('Auto-evolution check failed: ${failure.message}');
              // Still set the pet even if evolution fails
              state = state.copyWith(
                status: PetStateStatus.success,
                pet: petWithDecay,
              );
            },
            (evolvedPet) {
              if (evolvedPet != null &&
                  evolvedPet.stage != petWithDecay!.stage) {
                // Pet evolved! Show evolution message
                _logger.i(
                    'Pet evolved from ${petWithDecay!.stage.name} to ${evolvedPet.stage.name}!');
                state = state.copyWith(
                  status: PetStateStatus.success,
                  pet: evolvedPet,
                  lastAction:
                      '🎉 ${petWithDecay!.name} evolved into ${evolvedPet.stage.name.toUpperCase()}! 🎉',
                  hasEvolved: true,
                );
              } else {
                // No evolution needed
                state = state.copyWith(
                  status: PetStateStatus.success,
                  pet: evolvedPet ?? petWithDecay,
                );
              }
            },
          );
        } else {
          // No pet found for family - this is normal and not an error
          _logger.i('No pet found for family $familyId - this is normal');
          state = state.copyWith(
            status: PetStateStatus.success,
            pet: null,
          );
        }
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

      // Get the current user ID from auth provider
      final currentUser = _ref.read(currentUserProvider);
      final petOwnerId = ownerId ?? currentUser?.id;

      if (petOwnerId == null) {
        _logger.e('Cannot create pet: no current user ID available');
        state = state.copyWith(
          isUpdating: false,
          status: PetStateStatus.error,
          errorMessage: 'User not authenticated',
        );
        return;
      }

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

  /// Reset pet stats to 100% (temporary fix for happiness issue)
  Future<void> resetPetStats() async {
    final currentPet = state.pet;
    if (currentPet == null) return;

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      // Create updated pet with all stats at 100%
      final updatedPet = currentPet.copyWith(
        stats: {
          'health': 100,
          'happiness': 100,
          'energy': 100,
          'hunger': 100,
          'emotion': 100,
        },
        mood: PetMood.veryVeryHappy, // Set to highest mood
        lastCareAt: DateTime.now(),
        lastFedAt: DateTime.now(),
        lastPlayedAt: DateTime.now(),
      );

      _logger.i('Resetting pet stats to 100%: ${updatedPet.name}');

      // Simply update the state directly for immediate UI feedback
      state = state.copyWith(
        isUpdating: false,
        pet: updatedPet,
        lastAction: '✨ ${updatedPet.name}\'s stats have been reset to 100%!',
      );

      _logger.i('Pet stats reset successfully to maximum values');
    } catch (e) {
      _logger.e('Failed to reset pet stats: $e');
      state = state.copyWith(
        isUpdating: false,
        errorMessage: 'Failed to reset pet stats: $e',
      );
    }
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
      (experienceResult) async {
        final updatedPet = experienceResult.pet;
        final evolved = experienceResult.evolved;

        _logger.i(
            'Experience added successfully. XP: ${updatedPet.experience}, Level: ${updatedPet.level}, Evolved: $evolved');

        // Feed the pet with task points (1 point = 1% hunger)
        final feedResult = await _feedPet(FeedPetParams(
          petId: currentPet.id,
          bonusPoints: experiencePoints, // Use experience points as food
        ));

        feedResult.fold(
          (failure) {
            _logger.w(
                'Failed to feed pet after task completion: ${failure.message}');
            // Still show success for experience gain
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
          (fedPet) {
            String actionMessage =
                'Earned $experiencePoints XP and fed ${fedPet.name} from completing "$taskTitle"!';
            if (evolved) {
              actionMessage +=
                  '\n🎉 ${fedPet.name} evolved to ${fedPet.stage.name}!';
            }

            state = state.copyWith(
              isUpdating: false,
              pet: fedPet,
              hasEvolved: evolved,
              lastAction: actionMessage,
            );
          },
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
