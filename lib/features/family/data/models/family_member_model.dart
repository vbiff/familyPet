import 'package:equatable/equatable.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';

class FamilyMemberModel extends Equatable {
  final String id;
  final String displayName;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String familyId;
  final DateTime joinedAt;
  final DateTime? lastSeenAt;
  final bool isOnline;
  final Map<String, dynamic>? metadata;

  // Family-specific stats
  final int tasksCompleted;
  final int totalPoints;
  final int currentStreak;
  final DateTime? lastTaskCompletedAt;

  const FamilyMemberModel({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.familyId,
    required this.joinedAt,
    this.lastSeenAt,
    this.isOnline = false,
    this.metadata,
    this.tasksCompleted = 0,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.lastTaskCompletedAt,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.child,
      ),
      avatarUrl: json['avatar_url'] as String?,
      familyId: json['family_id'] as String,
      joinedAt: DateTime.parse(json['created_at'] as String),
      lastSeenAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      isOnline: _calculateOnlineStatus(json['last_login_at']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      lastTaskCompletedAt: json['last_task_completed_at'] != null
          ? DateTime.parse(json['last_task_completed_at'] as String)
          : null,
    );
  }

  factory FamilyMemberModel.fromUser(User user) {
    return FamilyMemberModel(
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      role: user.role,
      avatarUrl: user.avatarUrl,
      familyId: user.familyId ?? '',
      joinedAt: user.createdAt,
      lastSeenAt: user.lastLoginAt,
      isOnline: _calculateOnlineStatus(user.lastLoginAt.toIso8601String()),
      metadata: user.metadata,
    );
  }

  static bool _calculateOnlineStatus(String? lastLoginAt) {
    if (lastLoginAt == null) return false;
    final lastLogin = DateTime.parse(lastLoginAt);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    return difference.inMinutes <
        15; // Consider online if active within 15 minutes
  }

  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeenAt == null) return 'Never seen';

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt!);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.child:
        return 'Child';
    }
  }

  bool get hasCompletedTasks => tasksCompleted > 0;
  bool get hasActiveStreak => currentStreak > 0;

  FamilyMemberModel copyWith({
    String? id,
    String? displayName,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? familyId,
    DateTime? joinedAt,
    DateTime? lastSeenAt,
    bool? isOnline,
    Map<String, dynamic>? metadata,
    int? tasksCompleted,
    int? totalPoints,
    int? currentStreak,
    DateTime? lastTaskCompletedAt,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      familyId: familyId ?? this.familyId,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
      metadata: metadata ?? this.metadata,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      lastTaskCompletedAt: lastTaskCompletedAt ?? this.lastTaskCompletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        email,
        role,
        avatarUrl,
        familyId,
        joinedAt,
        lastSeenAt,
        isOnline,
        metadata,
        tasksCompleted,
        totalPoints,
        currentStreak,
        lastTaskCompletedAt,
      ];
}
