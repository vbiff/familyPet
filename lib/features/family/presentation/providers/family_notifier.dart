import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/family/domain/usecases/create_family.dart';
import 'package:jhonny/features/family/domain/usecases/join_family.dart';
import 'package:jhonny/features/family/domain/usecases/get_current_family.dart';
import 'package:jhonny/features/family/domain/usecases/get_family_members.dart';
import 'package:jhonny/features/family/presentation/providers/family_state.dart';

class FamilyNotifier extends StateNotifier<FamilyState> {
  final CreateFamily _createFamily;
  final JoinFamily _joinFamily;
  final GetCurrentFamily _getCurrentFamily;
  final GetFamilyMembers _getFamilyMembers;

  FamilyNotifier({
    required CreateFamily createFamily,
    required JoinFamily joinFamily,
    required GetCurrentFamily getCurrentFamily,
    required GetFamilyMembers getFamilyMembers,
  })  : _createFamily = createFamily,
        _joinFamily = joinFamily,
        _getCurrentFamily = getCurrentFamily,
        _getFamilyMembers = getFamilyMembers,
        super(FamilyState.initial());

  Future<void> loadCurrentFamily(String userId) async {
    if (state.isLoading) return;

    // Guard: Don't load if userId is empty
    if (userId.isEmpty) {
      state = FamilyState.initial();
      return;
    }

    try {
      state = FamilyState.loading();

      final result =
          await _getCurrentFamily(GetCurrentFamilyParams(userId: userId));

      result.fold(
        (failure) {
          state = FamilyState.error(failure.message);
        },
        (family) {
          if (family != null) {
            state = FamilyState.loaded(family: family);
            // Load family members
            _loadFamilyMembers(family.id);
          } else {
            state = FamilyState.initial();
          }
        },
      );
    } catch (e) {
      state = FamilyState.error('Failed to load family: $e');
    }
  }

  Future<bool> createFamily({
    required String name,
    required String createdById,
    Map<String, dynamic>? settings,
  }) async {
    if (state.isOperating) return false;

    state = state.copyWith(
      status: FamilyStatus.creating,
      isCreating: true,
      errorMessage: null,
    );

    final result = await _createFamily(CreateFamilyParams(
      name: name,
      createdById: createdById,
      settings: settings,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: FamilyStatus.error,
          errorMessage: failure.message,
          isCreating: false,
        );
        return false;
      },
      (family) {
        state = FamilyState.loaded(family: family);
        // Load family members
        _loadFamilyMembers(family.id);
        return true;
      },
    );
  }

  Future<bool> joinFamily({
    required String inviteCode,
    required String userId,
  }) async {
    if (state.isOperating) return false;

    state = state.copyWith(
      status: FamilyStatus.joining,
      isJoining: true,
      errorMessage: null,
    );

    final result = await _joinFamily(JoinFamilyParams(
      inviteCode: inviteCode,
      userId: userId,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: FamilyStatus.error,
          errorMessage: failure.message,
          isJoining: false,
        );
        return false;
      },
      (family) {
        state = FamilyState.loaded(family: family);
        // Load family members
        _loadFamilyMembers(family.id);
        return true;
      },
    );
  }

  Future<void> _loadFamilyMembers(String familyId) async {
    try {
      state = state.copyWith(isLoadingMembers: true);

      final result = await _getFamilyMembers(GetFamilyMembersParams(
        familyId: familyId,
      ));

      result.fold(
        (failure) {
          // If member loading fails, set empty list and show error in logs
          // TODO: Use proper logging instead of print
          // print('Failed to load family members: ${failure.message}');
          state = state.copyWith(
            members: [],
            isLoadingMembers: false,
          );
        },
        (members) {
          state = state.copyWith(
            members: members,
            isLoadingMembers: false,
          );
        },
      );
    } catch (e) {
      // If member loading fails completely, ensure we have an empty list
      // TODO: Use proper logging instead of print
      // print('Exception loading family members: $e');
      state = state.copyWith(
        members: [],
        isLoadingMembers: false,
      );
    }
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        status: FamilyStatus.initial,
        errorMessage: null,
      );
    }
  }

  void reset() {
    state = FamilyState.initial();
  }
}
