import 'package:equatable/equatable.dart';
import 'package:jhonny/features/pet/domain/entities/pet.dart';

enum PetStateStatus {
  initial,
  loading,
  success,
  error,
}

class PetState extends Equatable {
  final PetStateStatus status;
  final Pet? pet;
  final String? errorMessage;
  final bool isUpdating;
  final bool hasEvolved;
  final String? lastAction;

  const PetState({
    this.status = PetStateStatus.initial,
    this.pet,
    this.errorMessage,
    this.isUpdating = false,
    this.hasEvolved = false,
    this.lastAction,
  });

  bool get hasError => status == PetStateStatus.error;
  bool get isLoading => status == PetStateStatus.loading;
  bool get isSuccess => status == PetStateStatus.success;
  bool get hasPet => pet != null;

  // Pet convenience getters
  String get petName => pet?.name ?? '';
  PetStage get petStage => pet?.stage ?? PetStage.egg;
  PetMood get petMood => pet?.mood ?? PetMood.neutral;
  int get petLevel => pet?.level ?? 1;
  int get petExperience => pet?.experience ?? 0;
  Map<String, int> get petStats => pet?.stats ?? {};

  // Care status getters
  bool get needsFeeding => pet?.needsFeeding ?? false;
  bool get needsPlay => pet?.needsPlay ?? false;
  bool get canEvolve => pet?.canEvolve ?? false;

  // Stat convenience getters
  int get health => petStats['health'] ?? 100;
  int get happiness => petStats['happiness'] ?? 100;
  int get hunger => petStats['hunger'] ?? 100;

  // Current mood based on stats
  PetMood get currentMood => pet?.currentMood ?? PetMood.neutral;

  PetState copyWith({
    PetStateStatus? status,
    Pet? pet,
    String? errorMessage,
    bool? isUpdating,
    bool? hasEvolved,
    String? lastAction,
    bool clearError = false,
    bool clearEvolution = false,
  }) {
    return PetState(
      status: status ?? this.status,
      pet: pet ?? this.pet,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isUpdating: isUpdating ?? this.isUpdating,
      hasEvolved: clearEvolution ? false : hasEvolved ?? this.hasEvolved,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pet,
        errorMessage,
        isUpdating,
        hasEvolved,
        lastAction,
      ];
}
