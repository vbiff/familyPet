import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/providers/supabase_provider.dart';
import 'package:jhonny/core/services/pet_mood_service.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';
import 'package:jhonny/features/pet/data/datasources/pet_remote_datasource.dart';
import 'package:jhonny/features/pet/data/repositories/supabase_pet_repository.dart';
import 'package:jhonny/features/pet/domain/repositories/pet_repository.dart';
import 'package:jhonny/features/pet/domain/usecases/add_experience.dart';
import 'package:jhonny/features/pet/domain/usecases/feed_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/get_family_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/give_medical_care.dart';
import 'package:jhonny/features/pet/domain/usecases/play_with_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/create_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/auto_evolve_pet.dart';
import 'package:jhonny/features/pet/domain/usecases/update_pet_time_decay.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_notifier.dart';
import 'package:jhonny/features/pet/presentation/providers/pet_state.dart';

// Data Source Provider
final petRemoteDataSourceProvider = Provider<PetRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabasePetRemoteDataSource(supabaseClient);
});

// UUID Provider (if not already provided globally)
final petUuidProvider = Provider<Uuid>((ref) => const Uuid());

// Repository Provider
final petRepositoryProvider = Provider<PetRepository>((ref) {
  final remoteDataSource = ref.watch(petRemoteDataSourceProvider);
  final uuid = ref.watch(petUuidProvider);
  return SupabasePetRepository(remoteDataSource, uuid);
});

// Use Case Providers
final getFamilyPetUseCaseProvider = Provider<GetFamilyPet>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return GetFamilyPet(repository);
});

final feedPetUseCaseProvider = Provider<FeedPet>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return FeedPet(repository);
});

final playWithPetUseCaseProvider = Provider<PlayWithPet>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return PlayWithPet(repository);
});

final giveMedicalCareUseCaseProvider = Provider<GiveMedicalCare>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return GiveMedicalCare(repository);
});

final addExperienceUseCaseProvider = Provider<AddExperience>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return AddExperience(repository);
});

final createPetUseCaseProvider = Provider<CreatePet>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return CreatePet(repository);
});

final autoEvolvePetUseCaseProvider = Provider<AutoEvolvePet>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return AutoEvolvePet(repository);
});

final updatePetTimeDecayUseCaseProvider = Provider<UpdatePetTimeDecay>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return UpdatePetTimeDecay(repository);
});

// Logger Provider
final petLoggerProvider = Provider<Logger>((ref) => Logger());

// Pet Notifier Provider
final petNotifierProvider = StateNotifierProvider<PetNotifier, PetState>((ref) {
  final getFamilyPet = ref.watch(getFamilyPetUseCaseProvider);
  final feedPet = ref.watch(feedPetUseCaseProvider);
  final playWithPet = ref.watch(playWithPetUseCaseProvider);
  final giveMedicalCare = ref.watch(giveMedicalCareUseCaseProvider);
  final addExperience = ref.watch(addExperienceUseCaseProvider);
  final createPet = ref.watch(createPetUseCaseProvider);
  final autoEvolvePet = ref.watch(autoEvolvePetUseCaseProvider);
  final updatePetTimeDecay = ref.watch(updatePetTimeDecayUseCaseProvider);
  final logger = ref.watch(petLoggerProvider);

  final notifier = PetNotifier(
    getFamilyPet,
    feedPet,
    playWithPet,
    giveMedicalCare,
    addExperience,
    createPet,
    autoEvolvePet,
    updatePetTimeDecay,
    logger,
    ref,
  );

  // Set up the mood service callback for hourly happiness decay
  PetMoodService.setHappinessDecayCallback(() {
    notifier.applyHourlyHappinessDecay();
  });

  // Set up the mood service callback for weekly health decay
  PetMoodService.setHealthDecayCallback(() {
    notifier.applyWeeklyHealthDecay();
  });

  logger
      .d('🎮 Pet Mood Service callbacks set up for happiness and health decay');

  return notifier;
});

// Convenience Providers for UI
final petProvider = Provider<PetState>((ref) {
  return ref.watch(petNotifierProvider);
});

final hasPetProvider = Provider<bool>((ref) {
  final petState = ref.watch(petNotifierProvider);
  return petState.hasPet;
});

final petNeedsCareProvider = Provider<bool>((ref) {
  final petState = ref.watch(petNotifierProvider);
  return petState.needsFeeding || petState.needsPlay;
});

final petHealthStatusProvider = Provider<String>((ref) {
  final petState = ref.watch(petNotifierProvider);
  if (!petState.hasPet) return 'No pet';

  final health = petState.health;
  if (health >= 80) return 'Excellent';
  if (health >= 60) return 'Good';
  if (health >= 40) return 'Fair';
  if (health >= 20) return 'Poor';
  return 'Critical';
});

final petMoodDisplayProvider = Provider<String>((ref) {
  final petState = ref.watch(petNotifierProvider);
  if (!petState.hasPet) return 'Unknown';

  switch (petState.currentMood) {
    case PetMood.veryVeryHappy:
      return 'Very Very Happy 🤩';
    case PetMood.veryHappy:
      return 'Very Happy 😄';
    case PetMood.happy:
      return 'Happy 😊';
    case PetMood.content:
      return 'Content 😌';
    case PetMood.neutral:
      return 'Neutral 😐';
    case PetMood.sad:
      return 'Sad 😢';
    case PetMood.upset:
      return 'Upset 😡';
    case PetMood.hungry:
      return 'Hungry 😋';
    case PetMood.veryHungry:
      return 'Very Hungry 🤤';
    case PetMood.veryVeryHungry:
      return 'Starving 😵';
  }
});

final petStageDisplayProvider = Provider<String>((ref) {
  final petState = ref.watch(petNotifierProvider);
  if (!petState.hasPet) return 'No pet';

  final stage = petState.petStage;
  switch (stage) {
    case PetStage.egg:
      return 'Egg 🥚';
    case PetStage.baby:
      return 'Baby 🐣';
    case PetStage.child:
      return 'Child 🐤';
    case PetStage.teen:
      return 'Teen 🐦';
    case PetStage.adult:
      return 'Adult 🦅';
  }
});

final petAgeProvider = Provider<String>((ref) {
  final petState = ref.watch(petNotifierProvider);
  if (!petState.hasPet || petState.pet == null) return 'Unknown';

  final ageInDays = DateTime.now().difference(petState.pet!.createdAt).inDays;
  return '$ageInDays day${ageInDays == 1 ? '' : 's'} old';
});

final petEvolutionStatusProvider = Provider<String>((ref) {
  final petState = ref.watch(petNotifierProvider);
  if (!petState.hasPet || petState.pet == null) return 'No pet';

  final ageInDays = DateTime.now().difference(petState.pet!.createdAt).inDays;
  final currentStage = petState.petStage;

  switch (currentStage) {
    case PetStage.egg:
      final daysUntilBaby = 2 - ageInDays;
      return daysUntilBaby > 0
          ? 'Evolves in $daysUntilBaby day${daysUntilBaby == 1 ? '' : 's'}'
          : 'Ready to evolve!';
    case PetStage.baby:
      final daysUntilChild = 4 - ageInDays;
      return daysUntilChild > 0
          ? 'Evolves in $daysUntilChild day${daysUntilChild == 1 ? '' : 's'}'
          : 'Ready to evolve!';
    case PetStage.child:
      final daysUntilTeen = 6 - ageInDays;
      return daysUntilTeen > 0
          ? 'Evolves in $daysUntilTeen day${daysUntilTeen == 1 ? '' : 's'}'
          : 'Ready to evolve!';
    case PetStage.teen:
      final daysUntilAdult = 8 - ageInDays;
      return daysUntilAdult > 0
          ? 'Evolves in $daysUntilAdult day${daysUntilAdult == 1 ? '' : 's'}'
          : 'Ready to evolve!';
    case PetStage.adult:
      return 'Fully grown';
  }
});
