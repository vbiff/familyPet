import 'package:jhonny/features/auth/domain/entities/child_invitation_token.dart';

class ChildInvitationTokenModel extends ChildInvitationToken {
  @override
  final String id;
  @override
  final String familyId;
  @override
  final String createdById;
  @override
  final String token;
  @override
  final DateTime? expiresAt; // Made nullable
  @override
  final bool isUsed;
  @override
  final String? usedById;
  @override
  final DateTime? usedAt;
  @override
  final String? childDisplayName;
  @override
  final Map<String, dynamic>? metadata;
  @override
  final DateTime createdAt;

  const ChildInvitationTokenModel({
    required this.id,
    required this.familyId,
    required this.createdById,
    required this.token,
    this.expiresAt, // Now nullable
    this.isUsed = false,
    this.usedById,
    this.usedAt,
    this.childDisplayName,
    this.metadata,
    required this.createdAt,
  }) : super(
          id: id,
          familyId: familyId,
          createdById: createdById,
          token: token,
          expiresAt: expiresAt,
          isUsed: isUsed,
          usedById: usedById,
          usedAt: usedAt,
          childDisplayName: childDisplayName,
          metadata: metadata,
          createdAt: createdAt,
        );

  factory ChildInvitationTokenModel.fromJson(Map<String, dynamic> json) {
    return ChildInvitationTokenModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      createdById: json['created_by_id'] as String,
      token: json['token'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null, // Handle null expires_at
      isUsed: json['is_used'] as bool? ?? false,
      usedById: json['used_by_id'] as String?,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      childDisplayName: json['child_display_name'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'created_by_id': createdById,
      'token': token,
      'expires_at': expiresAt?.toIso8601String(), // Handle null expires_at
      'is_used': isUsed,
      'used_by_id': usedById,
      'used_at': usedAt?.toIso8601String(),
      'child_display_name': childDisplayName,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'family_id': familyId,
      'created_by_id': createdById,
      'child_display_name': childDisplayName,
      'metadata': metadata,
    };
  }

  ChildInvitationToken toEntity() {
    return ChildInvitationToken(
      id: id,
      familyId: familyId,
      createdById: createdById,
      token: token,
      expiresAt: expiresAt,
      isUsed: isUsed,
      usedById: usedById,
      usedAt: usedAt,
      childDisplayName: childDisplayName,
      metadata: metadata,
      createdAt: createdAt,
    );
  }
}

class TokenValidationResultModel extends TokenValidationResult {
  @override
  final String familyId;
  @override
  final String familyName;
  @override
  final String? childDisplayName;
  @override
  final String inviteCode;

  const TokenValidationResultModel({
    required this.familyId,
    required this.familyName,
    this.childDisplayName,
    required this.inviteCode,
  }) : super(
          familyId: familyId,
          familyName: familyName,
          childDisplayName: childDisplayName,
          inviteCode: inviteCode,
        );

  factory TokenValidationResultModel.fromJson(Map<String, dynamic> json) {
    return TokenValidationResultModel(
      familyId: json['family_id'] as String,
      familyName: json['family_name'] as String,
      childDisplayName: json['child_display_name'] as String?,
      inviteCode: json['invite_code'] as String,
    );
  }

  TokenValidationResult toEntity() {
    return TokenValidationResult(
      familyId: familyId,
      familyName: familyName,
      childDisplayName: childDisplayName,
      inviteCode: inviteCode,
    );
  }
}
