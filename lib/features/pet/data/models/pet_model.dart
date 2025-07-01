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
      'created_at': createdAt.toIso8601String(),
      'happiness': stats['happiness'] ?? 50,
      'energy': stats['energy'] ?? 100,
      'health': stats['health'] ?? 100,
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
      createdAt: pet.createdAt,
      stats: pet.stats,
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
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }
}
