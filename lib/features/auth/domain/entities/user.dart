import 'package:equatable/equatable.dart';

enum UserRole {
  parent,
  child;

  String get name => toString().split('.').last;
}

enum AuthMethod {
  email;

  String get name => toString().split('.').last;
}

class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final AuthMethod authMethod;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? avatarUrl;
  final String? familyId;
  final Map<String, dynamic>? metadata;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.authMethod = AuthMethod.email,
    required this.createdAt,
    required this.lastLoginAt,
    this.avatarUrl,
    this.familyId,
    this.metadata,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    AuthMethod? authMethod,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? avatarUrl,
    String? familyId,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      authMethod: authMethod ?? this.authMethod,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      familyId: familyId ?? this.familyId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        role,
        authMethod,
        createdAt,
        lastLoginAt,
        avatarUrl,
        familyId,
        metadata,
      ];
}
