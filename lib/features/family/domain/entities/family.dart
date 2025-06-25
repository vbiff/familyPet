import 'package:equatable/equatable.dart';

class Family extends Equatable {
  final String id;
  final String name;
  final String inviteCode;
  final String createdById;
  final List<String> parentIds;
  final List<String> childIds;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdById,
    this.parentIds = const [],
    this.childIds = const [],
    required this.createdAt,
    this.lastActivityAt,
    this.settings,
    this.metadata,
  });

  int get totalMembers => parentIds.length + childIds.length;
  bool get hasChildren => childIds.isNotEmpty;
  bool get hasMultipleParents => parentIds.length > 1;
  bool get isActive =>
      lastActivityAt != null &&
      DateTime.now().difference(lastActivityAt!).inDays < 30;

  bool isMember(String userId) =>
      parentIds.contains(userId) || childIds.contains(userId);

  bool isParent(String userId) => parentIds.contains(userId);

  bool isChild(String userId) => childIds.contains(userId);

  Family copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdById,
    List<String>? parentIds,
    List<String>? childIds,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdById: createdById ?? this.createdById,
      parentIds: parentIds ?? this.parentIds,
      childIds: childIds ?? this.childIds,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        inviteCode,
        createdById,
        parentIds,
        childIds,
        createdAt,
        lastActivityAt,
        settings,
        metadata,
      ];
}
