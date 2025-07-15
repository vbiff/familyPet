import 'package:equatable/equatable.dart';

enum PetMood {
  veryVeryHappy,
  veryHappy,
  happy,
  content,
  neutral,
  sad,
  upset,
  hungry,
  veryHungry,
  veryVeryHungry;

  bool get isPositive =>
      [veryVeryHappy, veryHappy, happy, content].contains(this);
  bool get isNegative =>
      [sad, upset, hungry, veryHungry, veryVeryHungry].contains(this);
  bool get isHungryState => [hungry, veryHungry, veryVeryHungry].contains(this);

  String get imageName {
    switch (this) {
      case PetMood.veryVeryHappy:
        return 'very-happy.png';
      case PetMood.veryHappy:
        return 'very-happy.png';
      case PetMood.happy:
        return 'happy.png'; // Use happy.png for happy mood
      case PetMood.content:
        return 'happy.png'; // Use happy.png for content mood
      case PetMood.neutral:
        return 'happy.png'; // Use happy.png for neutral mood
      case PetMood.sad:
        return 'hungry.png'; // Use hungry.png as "not happy" fallback
      case PetMood.upset:
        return 'very-hungry.png'; // Use very-hungry.png as "very unhappy" fallback
      case PetMood.hungry:
        return 'hungry.png';
      case PetMood.veryHungry:
        return 'very-hungry.png';
      case PetMood.veryVeryHungry:
        return 'very-very-hungry.png';
      default:
        return 'happy.png'; // Default fallback
    }
  }
}

enum PetStage {
  egg,
  baby,
  child,
  teen,
  adult;

  bool get canEvolve => this != PetStage.adult;
  PetStage? get nextStage =>
      canEvolve ? PetStage.values[PetStage.values.indexOf(this) + 1] : null;
}

class Pet extends Equatable {
  final String id;
  final String name;
  final String familyId;
  final String ownerId;
  final PetStage stage;
  final PetMood mood;
  final int experience;
  final int level;
  final DateTime lastFedAt;
  final DateTime lastPlayedAt;
  final DateTime lastCareAt; // Last time stats were updated
  final DateTime createdAt;
  final Map<String, int> stats;

  const Pet({
    required this.id,
    required this.name,
    required this.familyId,
    required this.ownerId,
    required this.stage,
    required this.mood,
    required this.experience,
    required this.level,
    required this.lastFedAt,
    required this.lastPlayedAt,
    required this.lastCareAt,
    required this.createdAt,
    required this.stats,
  });

  bool get canEvolve =>
      stage.canEvolve &&
      experience >= _experienceThresholds[PetStage.values.indexOf(stage) + 1]!;

  bool get needsFeeding => hunger < 30;
  bool get needsPlay => happiness < 30;
  bool get needsCare => needsFeeding || needsPlay;

  // New stat getters
  int get health => stats['health'] ?? 100;
  int get happiness => stats['happiness'] ?? 100;
  int get hunger => stats['hunger'] ?? 100;

  // Calculate current mood based on hunger and happiness
  PetMood get currentMood {
    if (hunger <= 30) {
      if (hunger <= 10) return PetMood.veryVeryHungry;
      if (hunger <= 20) return PetMood.veryHungry;
      return PetMood.hungry;
    }

    // If not hungry, base mood on happiness
    if (happiness >= 90) return PetMood.veryVeryHappy;
    if (happiness >= 80) return PetMood.veryHappy;
    if (happiness >= 70) return PetMood.happy;
    if (happiness >= 60) return PetMood.content;
    if (happiness >= 40) return PetMood.neutral;
    if (happiness >= 20) return PetMood.sad;
    return PetMood.upset;
  }

  // Calculate stats decay based on time passed
  Pet applyTimeDecay() {
    final now = DateTime.now();
    final hoursSinceLastCare = now.difference(lastCareAt).inHours;

    if (hoursSinceLastCare < 3) {
      return this; // No decay yet
    }

    final decayPeriods = hoursSinceLastCare ~/ 3; // Every 3 hours

    // Apply decay: 15% hunger per 3-hour period
    final hungerDecay = (decayPeriods * 15).clamp(0, hunger);
    final newHunger = (hunger - hungerDecay).clamp(0, 100);

    // Calculate happiness decay: 20% for every 30% hunger lost
    var happinessDecay = 0;
    if (hunger >= 70 && newHunger < 70)
      happinessDecay += 20; // First 30% hunger lost
    if (hunger >= 40 && newHunger < 40)
      happinessDecay += 20; // Second 30% hunger lost
    if (hunger >= 10 && newHunger < 10)
      happinessDecay += 20; // Third 30% hunger lost

    final newHappiness = (happiness - happinessDecay).clamp(0, 100);

    final newStats = Map<String, int>.from(stats);
    newStats['hunger'] = newHunger;
    newStats['happiness'] = newHappiness;

    return copyWith(
      stats: newStats,
      lastCareAt: now,
      mood: currentMood, // Update mood based on new stats
    );
  }

  static const Map<int, int> _experienceThresholds = {
    0: 0, // Egg
    1: 100, // Baby
    2: 300, // Child
    3: 600, // Teen
    4: 1000, // Adult
  };

  Pet copyWith({
    String? id,
    String? name,
    String? familyId,
    String? ownerId,
    PetStage? stage,
    PetMood? mood,
    int? experience,
    int? level,
    DateTime? lastFedAt,
    DateTime? lastPlayedAt,
    DateTime? lastCareAt,
    DateTime? createdAt,
    Map<String, int>? stats,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      familyId: familyId ?? this.familyId,
      ownerId: ownerId ?? this.ownerId,
      stage: stage ?? this.stage,
      mood: mood ?? this.mood,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      lastCareAt: lastCareAt ?? this.lastCareAt,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        familyId,
        ownerId,
        stage,
        mood,
        experience,
        level,
        lastFedAt,
        lastPlayedAt,
        lastCareAt,
        createdAt,
        stats,
      ];
}
