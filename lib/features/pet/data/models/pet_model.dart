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
  final DateTime lastFedAt;
  final DateTime lastPlayedAt;
  final DateTime lastCareAt;
  final DateTime createdAt;
  final Map<String, int> stats;

  const PetModel({
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
      lastFedAt: DateTime.parse(json['last_fed_at'] as String),
      lastPlayedAt: DateTime.parse(json['last_played_at'] as String),
      lastCareAt: json['last_care_at'] != null
          ? DateTime.parse(json['last_care_at'] as String)
          : DateTime.parse(
              json['created_at'] as String), // Fallback to created_at
      createdAt: DateTime.parse(json['created_at'] as String),
      stats: _parseStats(json),
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
      'last_fed_at': lastFedAt.toIso8601String(),
      'last_played_at': lastPlayedAt.toIso8601String(),
      'last_care_at': lastCareAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'happiness': stats['happiness'] ?? 100,
      'health': stats['health'] ?? 100,
      'hunger': stats['hunger'] ?? 100,
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
      lastFedAt: lastFedAt,
      lastPlayedAt: lastPlayedAt,
      lastCareAt: lastCareAt,
      createdAt: createdAt,
      stats: stats,
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
      lastFedAt: pet.lastFedAt,
      lastPlayedAt: pet.lastPlayedAt,
      lastCareAt: pet.lastCareAt,
      createdAt: pet.createdAt,
      stats: pet.stats,
    );
  }

  // Helper methods
  static Map<String, int> _parseStats(Map<String, dynamic> json) {
    return {
      'health': json['health'] as int? ?? 100,
      'happiness': json['happiness'] as int? ?? 100,
      'hunger': json['hunger'] as int? ?? 100,
    };
  }

  static PetStage _parseStage(String stage) {
    return PetStage.values.firstWhere(
      (s) => s.name == stage,
      orElse: () => PetStage.egg,
    );
  }

  static PetMood _parseMood(String mood) {
    try {
      return PetMood.values.firstWhere(
        (m) => m.name == mood,
      );
    } catch (e) {
      // Handle legacy mood values by mapping them to new values
      switch (mood.toLowerCase()) {
        case 'happy':
          return PetMood.happy;
        case 'content':
          return PetMood.content;
        case 'neutral':
          return PetMood.neutral;
        case 'sad':
          return PetMood.sad;
        case 'upset':
          return PetMood.upset;
        default:
          return PetMood.neutral; // Safe fallback
      }
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
    DateTime? lastFedAt,
    DateTime? lastPlayedAt,
    DateTime? lastCareAt,
    DateTime? createdAt,
    Map<String, int>? stats,
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
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      lastCareAt: lastCareAt ?? this.lastCareAt,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }
}
