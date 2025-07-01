import 'package:jhonny/features/pet/domain/entities/pet.dart';

class PetModel {
  final String id;
  final String name;
  final String familyId;
  final String ownerId;
  final String stage;
  final String mood;
  final int experience;
  final int level;
  final String currentImageUrl;
  final List<String> unlockedImageUrls;
  final DateTime lastFedAt;
  final DateTime lastPlayedAt;
  final DateTime createdAt;
  final Map<String, int> stats;
  final Map<String, dynamic>? metadata;

  const PetModel({
    required this.id,
    required this.name,
    required this.familyId,
    required this.ownerId,
    required this.stage,
    required this.mood,
    required this.experience,
    required this.level,
    required this.currentImageUrl,
    required this.unlockedImageUrls,
    required this.lastFedAt,
    required this.lastPlayedAt,
    required this.createdAt,
    required this.stats,
    this.metadata,
  });

  // Convert from JSON (database)
  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      familyId: json['family_id'] as String,
      ownerId: json['owner_id'] as String,
      stage: json['stage'] as String,
      mood: json['mood'] as String,
      experience: json['experience'] as int,
      level: json['level'] as int,
      currentImageUrl: json['current_image_url'] as String? ?? '',
      unlockedImageUrls: json['unlocked_image_urls'] != null
          ? List<String>.from(json['unlocked_image_urls'] as List)
          : [],
      lastFedAt: DateTime.parse(json['last_fed'] as String),
      lastPlayedAt: DateTime.parse(json['last_interaction'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      stats: _parseStats(json),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to JSON (database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'family_id': familyId,
      'owner_id': ownerId,
      'stage': stage,
      'mood': mood,
      'experience': experience,
      'level': level,
      'current_image_url': currentImageUrl,
      'unlocked_image_urls': unlockedImageUrls,
      'last_fed': lastFedAt.toIso8601String(),
      'last_interaction': lastPlayedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'happiness': stats['happiness'] ?? 50,
      'energy': stats['energy'] ?? 100,
      'health': stats['health'] ?? 100,
      'metadata': metadata,
    };
  }

  // Convert to JSON for creating new records
  Map<String, dynamic> toCreateJson() {
    final json = toJson();
    json.remove('id'); // Let database generate ID
    return json;
  }

  // Convert to domain entity
  Pet toEntity() {
    return Pet(
      id: id,
      name: name,
      familyId: familyId,
      ownerId: ownerId,
      stage: _parseStage(stage),
      mood: _parseMood(mood),
      experience: experience,
      level: level,
      currentImageUrl:
          currentImageUrl.isEmpty ? _getDefaultImage(stage) : currentImageUrl,
      unlockedImageUrls: unlockedImageUrls,
      lastFedAt: lastFedAt,
      lastPlayedAt: lastPlayedAt,
      createdAt: createdAt,
      stats: stats,
      metadata: metadata,
    );
  }

  // Convert from domain entity
  factory PetModel.fromEntity(Pet pet) {
    return PetModel(
      id: pet.id,
      name: pet.name,
      familyId: pet.familyId,
      ownerId: pet.ownerId,
      stage: pet.stage.name,
      mood: pet.mood.name,
      experience: pet.experience,
      level: pet.level,
      currentImageUrl: pet.currentImageUrl,
      unlockedImageUrls: pet.unlockedImageUrls,
      lastFedAt: pet.lastFedAt,
      lastPlayedAt: pet.lastPlayedAt,
      createdAt: pet.createdAt,
      stats: pet.stats,
      metadata: pet.metadata,
    );
  }

  // Helper methods
  static Map<String, int> _parseStats(Map<String, dynamic> json) {
    return {
      'health': json['health'] as int? ?? 100,
      'happiness': json['happiness'] as int? ?? 50,
      'energy': json['energy'] as int? ?? 100,
    };
  }

  static PetStage _parseStage(String stage) {
    return PetStage.values.firstWhere(
      (s) => s.name == stage,
      orElse: () => PetStage.egg,
    );
  }

  static PetMood _parseMood(String mood) {
    return PetMood.values.firstWhere(
      (m) => m.name == mood,
      orElse: () => PetMood.neutral,
    );
  }

  static String _getDefaultImage(String stage) {
    switch (stage) {
      case 'egg':
        return 'assets/images/pet_egg.png';
      case 'baby':
        return 'assets/images/pet_baby.png';
      case 'child':
        return 'assets/images/pet_child.png';
      case 'teen':
        return 'assets/images/pet_teen.png';
      case 'adult':
        return 'assets/images/pet_adult.png';
      default:
        return 'assets/images/pet_default.png';
    }
  }

  PetModel copyWith({
    String? id,
    String? name,
    String? familyId,
    String? ownerId,
    String? stage,
    String? mood,
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
    return PetModel(
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
}
