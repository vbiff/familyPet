import 'package:equatable/equatable.dart';

class ChildInvitationToken extends Equatable {
  final String id;
  final String familyId;
  final String createdById;
  final String token;
  final DateTime expiresAt;
  final bool isUsed;
  final String? usedById;
  final DateTime? usedAt;
  final String? childDisplayName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ChildInvitationToken({
    required this.id,
    required this.familyId,
    required this.createdById,
    required this.token,
    required this.expiresAt,
    this.isUsed = false,
    this.usedById,
    this.usedAt,
    this.childDisplayName,
    this.metadata,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  ChildInvitationToken copyWith({
    String? id,
    String? familyId,
    String? createdById,
    String? token,
    DateTime? expiresAt,
    bool? isUsed,
    String? usedById,
    DateTime? usedAt,
    String? childDisplayName,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ChildInvitationToken(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      createdById: createdById ?? this.createdById,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      usedById: usedById ?? this.usedById,
      usedAt: usedAt ?? this.usedAt,
      childDisplayName: childDisplayName ?? this.childDisplayName,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        createdById,
        token,
        expiresAt,
        isUsed,
        usedById,
        usedAt,
        childDisplayName,
        metadata,
        createdAt,
      ];
}

class TokenValidationResult extends Equatable {
  final String familyId;
  final String familyName;
  final String? childDisplayName;
  final String inviteCode;

  const TokenValidationResult({
    required this.familyId,
    required this.familyName,
    this.childDisplayName,
    required this.inviteCode,
  });

  @override
  List<Object?> get props => [
        familyId,
        familyName,
        childDisplayName,
        inviteCode,
      ];
}
