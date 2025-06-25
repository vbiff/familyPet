import 'package:equatable/equatable.dart';

enum PetMood {
  happy,
  content,
  neutral,
  sad,
  upset;

  bool get isPositive => this == PetMood.happy || this == PetMood.content;
  bool get isNegative => this == PetMood.sad || this == PetMood.upset;
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
  final String currentImageUrl;
  final List<String> unlockedImageUrls;
  final DateTime lastFedAt;
  final DateTime lastPlayedAt;
  final DateTime createdAt;
  final Map<String, int> stats;
  final Map<String, dynamic>? metadata;

  const Pet({
    required this.id,
    required this.name,
    required this.familyId,
    required this.ownerId,
    required this.stage,
    required this.mood,
    required this.experience,
    required this.level,
    required this.currentImageUrl,
    this.unlockedImageUrls = const [],
    required this.lastFedAt,
    required this.lastPlayedAt,
    required this.createdAt,
    required this.stats,
    this.metadata,
  });

  bool get canEvolve =>
      stage.canEvolve &&
      experience >= _experienceThresholds[PetStage.values.indexOf(stage) + 1]!;

  bool get needsFeeding => DateTime.now().difference(lastFedAt).inHours >= 4;

  bool get needsPlay => DateTime.now().difference(lastPlayedAt).inHours >= 6;

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
    String? currentImageUrl,
    List<String>? unlockedImageUrls,
    DateTime? lastFedAt,
    DateTime? lastPlayedAt,
    DateTime? createdAt,
    Map<String, int>? stats,
    Map<String, dynamic>? metadata,
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
      currentImageUrl: currentImageUrl ?? this.currentImageUrl,
      unlockedImageUrls: unlockedImageUrls ?? this.unlockedImageUrls,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
      metadata: metadata ?? this.metadata,
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
        currentImageUrl,
        unlockedImageUrls,
        lastFedAt,
        lastPlayedAt,
        createdAt,
        stats,
        metadata,
      ];
}
