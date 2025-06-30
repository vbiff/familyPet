import 'package:equatable/equatable.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/family/data/models/family_member_model.dart';

enum FamilyStatus {
  initial,
  loading,
  loaded,
  creating,
  joining,
  error,
}

class FamilyState extends Equatable {
  final FamilyStatus status;
  final Family? family;
  final List<FamilyMemberModel> members;
  final String? errorMessage;
  final bool isCreating;
  final bool isJoining;
  final bool isLoadingMembers;

  const FamilyState({
    this.status = FamilyStatus.initial,
    this.family,
    this.members = const [],
    this.errorMessage,
    this.isCreating = false,
    this.isJoining = false,
    this.isLoadingMembers = false,
  });

  factory FamilyState.initial() {
    return const FamilyState();
  }

  factory FamilyState.loading() {
    return const FamilyState(status: FamilyStatus.loading);
  }

  factory FamilyState.creating() {
    return const FamilyState(
      status: FamilyStatus.creating,
      isCreating: true,
    );
  }

  factory FamilyState.joining() {
    return const FamilyState(
      status: FamilyStatus.joining,
      isJoining: true,
    );
  }

  factory FamilyState.loaded({
    required Family family,
    List<FamilyMemberModel> members = const [],
  }) {
    return FamilyState(
      status: FamilyStatus.loaded,
      family: family,
      members: members,
    );
  }

  factory FamilyState.error(String message) {
    return FamilyState(
      status: FamilyStatus.error,
      errorMessage: message,
    );
  }

  FamilyState copyWith({
    FamilyStatus? status,
    Family? family,
    List<FamilyMemberModel>? members,
    String? errorMessage,
    bool? isCreating,
    bool? isJoining,
    bool? isLoadingMembers,
  }) {
    return FamilyState(
      status: status ?? this.status,
      family: family ?? this.family,
      members: members ?? this.members,
      errorMessage: errorMessage ?? this.errorMessage,
      isCreating: isCreating ?? this.isCreating,
      isJoining: isJoining ?? this.isJoining,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
    );
  }

  bool get hasFamily => family != null;
  bool get isLoading => status == FamilyStatus.loading;
  bool get hasError => status == FamilyStatus.error;
  bool get isOperating => isCreating || isJoining;

  @override
  List<Object?> get props => [
        status,
        family,
        members,
        errorMessage,
        isCreating,
        isJoining,
        isLoadingMembers,
      ];
}
