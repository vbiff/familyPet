import 'package:jhonny/features/family/domain/entities/family.dart';

class FamilyModel extends Family {
  const FamilyModel({
    required super.id,
    required super.name,
    required super.inviteCode,
    required super.createdById,
    super.parentIds = const [],
    super.childIds = const [],
    required super.createdAt,
    super.lastActivityAt,
    super.settings,
    super.metadata,
  });

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
      settings: json['settings'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
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
    );
  }
}
