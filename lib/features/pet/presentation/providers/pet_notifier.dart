import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/core/services/pet_mood_service.dart';
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
        // Record feeding interaction with mood service for analytics
        final moodService = PetMoodService();
        moodService.recordFeedInteraction(currentPet.id);

        _logger.i(
            'Pet fed successfully. Health: ${updatedPet.stats['health']}, Happiness: ${updatedPet.stats['happiness']}, Hunger: ${updatedPet.stats['hunger']}');
        state = state.copyWith(
          isUpdating: false,
          pet: updatedPet,
          lastAction:
              '🍖 Fed ${updatedPet.name}! Hunger restored to ${updatedPet.stats['hunger']}%.',
        );
      },
    );
  }

  /// Play with the pet (with enhanced mood service constraints)
  Future<void> playWithPet({int bonusPoints = 0}) async {
    final currentPet = state.pet;
    if (currentPet == null) return;

    // Check if pet can play using the mood service (once per hour limit)
    final moodService = PetMoodService();
    if (!moodService.canPlayWithPet(currentPet.id)) {
      final timeUntilNext = moodService.getTimeUntilNextPlay(currentPet.id);
      final minutesLeft = timeUntilNext?.inMinutes ?? 0;

      _logger.i('Pet play blocked: can play again in $minutesLeft minutes');
      state = state.copyWith(
        errorMessage:
            'You can play with ${currentPet.name} again in $minutesLeft minutes! 🎮',
      );
      return;
    }

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      // Apply mood service happiness increase (5% of max happiness = 5 points)
      final currentStats = Map<String, int>.from(currentPet.stats);
      final enhancedStats =
          moodService.applyPlayHappinessIncrease(currentStats);

      // Record the play interaction in mood service
      moodService.recordPlayInteraction(currentPet.id);

      // Now use the original play functionality for happiness/other effects
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
          // Ensure the mood service happiness boost is preserved
          final finalPet = updatedPet.copyWith(
            stats: {
              ...updatedPet.stats,
              'happiness':
                  enhancedStats['happiness']!, // Keep mood service boost
            },
          );

          _logger.i(
              'Played with pet successfully. Happiness: ${finalPet.stats['happiness']}, Hunger: ${finalPet.stats['hunger']}');
          state = state.copyWith(
            isUpdating: false,
            pet: finalPet,
            lastAction:
                '🎮 Played with ${finalPet.name}! Happiness increased by 5%.',
          );
        },
      );
    } catch (e) {
      _logger.e('Error during enhanced play interaction: $e');
      state = state.copyWith(
        isUpdating: false,
        errorMessage: 'Failed to play with pet: $e',
      );
    }
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
        // Record medical care interaction with mood service for analytics
        final moodService = PetMoodService();
        moodService.recordHealInteraction(currentPet.id);

        _logger.i(
            'Medical care given successfully. Health: ${updatedPet.stats['health']} (restored to 100%)');
        state = state.copyWith(
          isUpdating: false,
          pet: updatedPet,
          lastAction:
              '💊 Gave medical care to ${updatedPet.name}! Health restored to 100%.',
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
          'hunger': 100,
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
    if (currentPet == null) {
      _logger.w(
          'No pet found in state when trying to add experience for task: $taskTitle');
      return;
    }

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

        // If pet not found, clear the pet from state to prevent future errors
        if (failure.message.contains('Pet not found')) {
          _logger.w('Pet not found in database, clearing pet from state');
          state = state.copyWith(
            isUpdating: false,
            pet: null,
            errorMessage: 'Pet not found. Please create a new pet.',
          );
        } else {
          state = state.copyWith(
            isUpdating: false,
            errorMessage: failure.message,
          );
        }
      },
      (experienceResult) async {
        final updatedPet = experienceResult.pet;
        final evolved = experienceResult.evolved;

        _logger.i(
            'Experience added successfully. XP: ${updatedPet.experience}, Level: ${updatedPet.level}, Evolved: $evolved');

        // Task completion restores happiness to 100% and feeds the pet
        final petWithMaxHappiness = updatedPet.copyWith(
          stats: {
            ...updatedPet.stats,
            'happiness':
                100, // Task completion always restores happiness to 100%
          },
        );

        // Feed the pet with task points (1 point = 1% hunger)
        final feedResult = await _feedPet(FeedPetParams(
          petId: currentPet.id,
          bonusPoints: experiencePoints, // Use experience points as food
        ));

        feedResult.fold(
          (failure) {
            _logger.w(
                'Failed to feed pet after task completion: ${failure.message}');
            // Still show success for experience gain and happiness boost
            String actionMessage =
                '🎉 Task completed! Earned $experiencePoints XP and happiness restored to 100%!';
            if (evolved) {
              actionMessage +=
                  '\n🌟 ${petWithMaxHappiness.name} evolved to ${petWithMaxHappiness.stage.name}!';
            }

            state = state.copyWith(
              isUpdating: false,
              pet: petWithMaxHappiness,
              hasEvolved: evolved,
              lastAction: actionMessage,
            );
          },
          (fedPet) {
            // Ensure happiness is still 100% after feeding
            final finalPet = fedPet.copyWith(
              stats: {
                ...fedPet.stats,
                'happiness': 100, // Always 100% happiness on task completion
              },
            );

            String actionMessage =
                '🎉 Task completed! Earned $experiencePoints XP, happiness restored to 100%, and fed ${finalPet.name}!';
            if (evolved) {
              actionMessage +=
                  '\n🌟 ${finalPet.name} evolved to ${finalPet.stage.name}!';
            }

            state = state.copyWith(
              isUpdating: false,
              pet: finalPet,
              hasEvolved: evolved,
              lastAction: actionMessage,
            );
          },
        );
      },
    );
  }

  /// Apply hourly happiness decay to current pet (called by mood service)
  void applyHourlyHappinessDecay() {
    final currentPet = state.pet;
    if (currentPet == null) return;

    _logger.d('🔄 Applying hourly happiness decay to ${currentPet.name}');

    try {
      // Use mood service to calculate and apply happiness decay
      final moodService = PetMoodService();
      final currentStats = Map<String, int>.from(currentPet.stats);
      final newStats = moodService.applyHappinessDecay(currentStats);

      // Update pet with new stats
      final updatedPet = currentPet.copyWith(
        stats: newStats,
        lastCareAt: DateTime.now(),
      );

      // Update state
      state = state.copyWith(
        pet: updatedPet,
        lastAction:
            '⏰ Time passed - ${updatedPet.name}\'s happiness decreased naturally.',
      );

      _logger.i(
          '⏰ Applied happiness decay: ${currentStats['happiness']} → ${newStats['happiness']}');
    } catch (e) {
      _logger.e('Failed to apply happiness decay: $e');
    }
  }

  /// Apply weekly health decay to current pet (called by mood service)
  void applyWeeklyHealthDecay() {
    final currentPet = state.pet;
    if (currentPet == null) return;

    _logger.d('🏥 Applying weekly health decay to ${currentPet.name}');

    try {
      // Use mood service to calculate and apply health decay
      final moodService = PetMoodService();
      final currentStats = Map<String, int>.from(currentPet.stats);
      final newStats =
          moodService.applyHealthDecay(currentStats, currentPet.id);

      // Only update if health actually decayed
      if (newStats['health'] != currentStats['health']) {
        // Update pet with new stats
        final updatedPet = currentPet.copyWith(
          stats: newStats,
          lastCareAt: DateTime.now(),
        );

        // Update state
        state = state.copyWith(
          pet: updatedPet,
          lastAction:
              '🏥 A week has passed - ${updatedPet.name}\'s health decreased naturally. Give medical care!',
        );

        _logger.i(
            '🏥 Applied health decay: ${currentStats['health']} → ${newStats['health']}');
      } else {
        _logger.d('🏥 Health decay skipped (not yet time)');
      }
    } catch (e) {
      _logger.e('Failed to apply health decay: $e');
    }
  }

  /// Restore health to 100% for testing purposes
  void restoreHealth() {
    final currentPet = state.pet;
    if (currentPet == null) return;

    _logger.i('🏥 Restoring health to 100% for testing');

    try {
      // Use mood service to apply medical care (health to 100%)
      final moodService = PetMoodService();
      final currentStats = Map<String, int>.from(currentPet.stats);
      final newStats = moodService.applyMedicalCare(currentStats);

      // Update pet with new stats
      final updatedPet = currentPet.copyWith(
        stats: newStats,
        lastCareAt: DateTime.now(),
      );

      // Update state
      state = state.copyWith(
        pet: updatedPet,
        lastAction: '🏥 Debug: ${updatedPet.name}\'s health restored to 100%!',
      );

      _logger.i('🏥 Debug health restoration completed');
    } catch (e) {
      _logger.e('Failed to restore health: $e');
    }
  }

  /// Debug method to change pet mood by setting specific hunger and happiness values
  void debugChangeMood(PetMood targetMood) {
    final currentPet = state.pet;
    if (currentPet == null) return;

    _logger.i(
        '🎭 Debug: Changing ${currentPet.name}\'s mood to ${targetMood.name}');

    try {
      // Calculate stats needed for the target mood
      Map<String, int> newStats = Map<String, int>.from(currentPet.stats);

      // Set hunger and happiness values based on target mood
      switch (targetMood) {
        case PetMood.veryVeryHappy:
          newStats['happiness'] = 95;
          newStats['hunger'] = 80;
          break;
        case PetMood.veryHappy:
          newStats['happiness'] = 85;
          newStats['hunger'] = 80;
          break;
        case PetMood.happy:
          newStats['happiness'] = 75;
          newStats['hunger'] = 80;
          break;
        case PetMood.content:
          newStats['happiness'] = 65;
          newStats['hunger'] = 80;
          break;
        case PetMood.neutral:
          newStats['happiness'] = 50;
          newStats['hunger'] = 80;
          break;
        case PetMood.sad:
          newStats['happiness'] = 30;
          newStats['hunger'] = 80;
          break;
        case PetMood.upset:
          newStats['happiness'] = 10;
          newStats['hunger'] = 80;
          break;
        case PetMood.hungry:
          newStats['happiness'] = 80;
          newStats['hunger'] = 25;
          break;
        case PetMood.veryHungry:
          newStats['happiness'] = 80;
          newStats['hunger'] = 15;
          break;
        case PetMood.veryVeryHungry:
          newStats['happiness'] = 80;
          newStats['hunger'] = 5;
          break;
      }

      // Update pet with new stats
      final updatedPet = currentPet.copyWith(
        stats: newStats,
        lastCareAt: DateTime.now(),
      );

      // Update state
      state = state.copyWith(
        pet: updatedPet,
        lastAction:
            '🎭 Debug: ${updatedPet.name}\'s mood changed to ${targetMood.name}!',
      );

      _logger.i(
          '🎭 Debug mood change completed: ${targetMood.name} (H:${newStats['happiness']}, F:${newStats['hunger']})');
    } catch (e) {
      _logger.e('Failed to change mood: $e');
    }
  }

  /// Debug method to change pet stage for testing growth scenario
  void debugChangeStage(PetStage targetStage) {
    final currentPet = state.pet;
    if (currentPet == null) return;

    _logger.i(
        '🔄 Debug: Changing ${currentPet.name}\'s stage to ${targetStage.name}');

    try {
      // Update pet with new stage
      final updatedPet = currentPet.copyWith(
        stage: targetStage,
        lastCareAt: DateTime.now(),
      );

      // Update state
      state = state.copyWith(
        pet: updatedPet,
        lastAction:
            '🔄 Debug: ${updatedPet.name}\'s stage changed to ${targetStage.name}!',
      );

      _logger.i('🔄 Debug stage change completed: ${targetStage.name}');
    } catch (e) {
      _logger.e('Failed to change stage: $e');
    }
  }

  /// Get pet interaction analytics
  Map<String, dynamic> getPetAnalytics() {
    final currentPet = state.pet;
    if (currentPet == null) return {};

    final moodService = PetMoodService();
    return moodService.getInteractionAnalytics(currentPet.id);
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
