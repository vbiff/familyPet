import 'package:jhonny/features/family/domain/entities/family.dart';

class FamilyModel extends Family {
  @override
  final String id;
  @override
  final String name;
  @override
  final String inviteCode;
  @override
  final String createdById;
  @override
  final List<String> parentIds;
  @override
  final List<String> childIds;
  @override
  final DateTime createdAt;
  @override
  final DateTime? lastActivityAt;
  @override
  final Map<String, dynamic>? settings;
  @override
  final Map<String, dynamic>? metadata;
  @override
  final String? petImageUrl;
  @override
  final Map<String, String>? petStageImages;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdById,
    required this.parentIds,
    required this.childIds,
    required this.createdAt,
    this.lastActivityAt,
    this.settings,
    this.metadata,
    this.petImageUrl,
    this.petStageImages,
  }) : super(
          id: id,
          name: name,
          inviteCode: inviteCode,
          createdById: createdById,
          parentIds: parentIds,
          childIds: childIds,
          createdAt: createdAt,
          lastActivityAt: lastActivityAt,
          settings: settings,
          metadata: metadata,
          petImageUrl: petImageUrl,
          petStageImages: petStageImages,
        );

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      createdById: json['created_by_id'] ?? json['parent_id'] as String,
      parentIds: _parseStringList(json['parent_ids']),
      childIds: _parseStringList(json['child_ids']),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      petImageUrl: json['pet_image_url'] as String?,
      petStageImages: json['pet_stage_images'] != null
          ? Map<String, String>.from(json['pet_stage_images'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'created_by_id': createdById,
      'parent_ids': parentIds,
      'child_ids': childIds,
      'created_at': createdAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'settings': settings,
      'metadata': metadata,
      'pet_image_url': petImageUrl,
      'pet_stage_images': petStageImages,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'invite_code': inviteCode,
      'created_by_id': createdById,
      'parent_ids': parentIds,
      'child_ids': childIds,
      'settings': settings ?? {},
      'metadata': metadata ?? {},
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  factory FamilyModel.fromEntity(Family family) {
    return FamilyModel(
      id: family.id,
      name: family.name,
      inviteCode: family.inviteCode,
      createdById: family.createdById,
      parentIds: family.parentIds,
      childIds: family.childIds,
      createdAt: family.createdAt,
      lastActivityAt: family.lastActivityAt,
      settings: family.settings,
      metadata: family.metadata,
      petImageUrl: family.petImageUrl,
      petStageImages: family.petStageImages,
    );
  }

  Family toEntity() {
    return Family(
      id: id,
      name: name,
      inviteCode: inviteCode,
      createdById: createdById,
      parentIds: parentIds,
      childIds: childIds,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
      settings: settings,
      metadata: metadata,
      petImageUrl: petImageUrl,
      petStageImages: petStageImages,
    );
  }
}
