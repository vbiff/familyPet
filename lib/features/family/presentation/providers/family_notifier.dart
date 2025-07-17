import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhonny/features/family/domain/usecases/create_family.dart';
import 'package:jhonny/features/family/domain/usecases/join_family.dart';
import 'package:jhonny/features/family/domain/usecases/get_current_family.dart';
import 'package:jhonny/features/family/domain/usecases/get_family_members.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';
import 'package:jhonny/features/family/domain/entities/family.dart'
    as family_entity;
import 'package:jhonny/features/family/presentation/providers/family_state.dart';

class FamilyNotifier extends StateNotifier<FamilyState> {
  final CreateFamily _createFamily;
  final JoinFamily _joinFamily;
  final GetCurrentFamily _getCurrentFamily;
  final GetFamilyMembers _getFamilyMembers;
  final FamilyRepository _familyRepository;

  FamilyNotifier({
    required CreateFamily createFamily,
    required JoinFamily joinFamily,
    required GetCurrentFamily getCurrentFamily,
    required GetFamilyMembers getFamilyMembers,
    required FamilyRepository familyRepository,
  })  : _createFamily = createFamily,
        _joinFamily = joinFamily,
        _getCurrentFamily = getCurrentFamily,
        _getFamilyMembers = getFamilyMembers,
        _familyRepository = familyRepository,
        super(FamilyState.initial());

  Future<void> loadCurrentFamily(String userId) async {
    if (state.isLoading) return;

    // Guard: Don't load if userId is empty
    if (userId.isEmpty) {
      debugPrint('🚨 Cannot load family: userId is empty');
      state = FamilyState.initial();
      return;
    }

    try {
      debugPrint('🔍 Loading current family for user: $userId');
      state = FamilyState.loading();

      final result =
          await _getCurrentFamily(GetCurrentFamilyParams(userId: userId));

      result.fold(
        (failure) {
          debugPrint('🚨 Failed to load current family: ${failure.message}');
          state = FamilyState.error(failure.message);
        },
        (family) {
          if (family != null) {
            debugPrint(
                '✅ Successfully loaded family: ${family.name} (ID: ${family.id})');
            debugPrint('✅ Family has ${family.totalMembers} members');
            state = FamilyState.loaded(family: family);
            // Load family members
            loadFamilyMembers(family.id);
          } else {
            debugPrint('ℹ️ User has no family');
            // User has no family - set to loaded state with null family
            state = const FamilyState(
              status: FamilyStatus.loaded,
              family: null,
              members: [],
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🚨 Exception loading current family: $e');
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
        loadFamilyMembers(family.id);
        return true;
      },
    );
  }

  Future<bool> joinFamily({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      debugPrint('🔄 Attempting to join family with invite code: $inviteCode');
      debugPrint('🔄 User ID: $userId');

      state = FamilyState.loading();

      final result = await _joinFamily(JoinFamilyParams(
        inviteCode: inviteCode,
        userId: userId,
      ));

      final success = result.fold(
        (failure) {
          debugPrint('🚨 Failed to join family: ${failure.message}');
          state = FamilyState.error(failure.message);
          return false;
        },
        (family) {
          debugPrint('✅ Successfully joined family: ${family.name}');
          debugPrint('✅ Family ID: ${family.id}');
          debugPrint('✅ Total members: ${family.totalMembers}');

          state = FamilyState.loaded(family: family);

          // Load family members after joining
          loadFamilyMembers(family.id);

          // For child users, ensure they can see family data immediately
          Future.delayed(const Duration(milliseconds: 500), () {
            debugPrint('🔄 Refreshing family data after join...');
            loadCurrentFamily(userId);
          });

          return true;
        },
      );

      return success;
    } catch (e) {
      debugPrint('🚨 Exception joining family: $e');
      state = FamilyState.error('Failed to join family: $e');
      return false;
    }
  }

  Future<void> loadFamilyMembers(String familyId) async {
    try {
      state = state.copyWith(isLoadingMembers: true);

      final result = await _getFamilyMembers(GetFamilyMembersParams(
        familyId: familyId,
      ));

      result.fold(
        (failure) {
          // Log the error for debugging
          debugPrint('🚨 Failed to load family members: ${failure.message}');
          debugPrint('🚨 Family ID: $familyId');
          debugPrint('🚨 Failure type: ${failure.runtimeType}');

          state = state.copyWith(
            members: [],
            isLoadingMembers: false,
            errorMessage: 'Failed to load family members: ${failure.message}',
          );
        },
        (members) {
          debugPrint('✅ Successfully loaded ${members.length} family members');
          debugPrint(
              '✅ Members: ${members.map((m) => '${m.displayName} (${m.role.name})').join(', ')}');

          state = state.copyWith(
            members: members,
            isLoadingMembers: false,
          );
        },
      );
    } catch (e) {
      // If member loading fails completely, ensure we have an empty list
      debugPrint('🚨 Exception loading family members: $e');
      debugPrint('🚨 Stack trace: ${StackTrace.current}');

      state = state.copyWith(
        members: [],
        isLoadingMembers: false,
        errorMessage: 'Exception loading family members: $e',
      );
    }
  }

  // New Phase 2 methods

  Future<bool> updateFamily(family_entity.Family family) async {
    try {
      final result = await _familyRepository.updateFamily(family);

      return result.fold(
        (failure) {
          state = state.copyWith(
            status: FamilyStatus.error,
            errorMessage: failure.message,
          );
          return false;
        },
        (updatedFamily) {
          state = state.copyWith(
            family: updatedFamily,
            status: FamilyStatus.loaded,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: FamilyStatus.error,
        errorMessage: 'Failed to update family: $e',
      );
      return false;
    }
  }

  Future<bool> leaveFamily({
    required String familyId,
    required String userId,
  }) async {
    try {
      final result = await _familyRepository.leaveFamily(
        familyId: familyId,
        userId: userId,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            status: FamilyStatus.error,
            errorMessage: failure.message,
          );
          return false;
        },
        (_) {
          // Reset state after leaving family
          state = FamilyState.initial();
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: FamilyStatus.error,
        errorMessage: 'Failed to leave family: $e',
      );
      return false;
    }
  }

  Future<bool> deleteFamily(String familyId) async {
    try {
      final result = await _familyRepository.deleteFamily(familyId);

      return result.fold(
        (failure) {
          state = state.copyWith(
            status: FamilyStatus.error,
            errorMessage: failure.message,
          );
          return false;
        },
        (_) {
          // Reset state after deleting family
          state = FamilyState.initial();
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: FamilyStatus.error,
        errorMessage: 'Failed to delete family: $e',
      );
      return false;
    }
  }

  Future<bool> updateMemberRole({
    required String familyId,
    required String userId,
    required String role,
  }) async {
    try {
      final result = await _familyRepository.updateMemberRole(
        familyId: familyId,
        userId: userId,
        role: role,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            status: FamilyStatus.error,
            errorMessage: failure.message,
          );
          return false;
        },
        (_) {
          // Reload family members to show updated roles
          loadFamilyMembers(familyId);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: FamilyStatus.error,
        errorMessage: 'Failed to update member role: $e',
      );
      return false;
    }
  }

  Future<bool> removeMemberFromFamily({
    required String familyId,
    required String userId,
  }) async {
    try {
      final result = await _familyRepository.removeMemberFromFamily(
        familyId: familyId,
        userId: userId,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            status: FamilyStatus.error,
            errorMessage: failure.message,
          );
          return false;
        },
        (_) {
          // Reload family members to show updated list
          loadFamilyMembers(familyId);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: FamilyStatus.error,
        errorMessage: 'Failed to remove member: $e',
      );
      return false;
    }
  }

  Future<bool> generateNewInviteCode(String familyId) async {
    try {
      final result = await _familyRepository.generateNewInviteCode(familyId);

      return result.fold(
        (failure) {
          state = state.copyWith(
            status: FamilyStatus.error,
            errorMessage: failure.message,
          );
          return false;
        },
        (newInviteCode) {
          // Update family with new invite code
          if (state.family != null) {
            final updatedFamily =
                state.family!.copyWith(inviteCode: newInviteCode);
            state = state.copyWith(family: updatedFamily);
          }
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: FamilyStatus.error,
        errorMessage: 'Failed to generate new invite code: $e',
      );
      return false;
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

  // Add method to refresh family member statistics
  Future<void> refreshFamilyMembers() async {
    if (state.family != null) {
      await loadFamilyMembers(state.family!.id);
    }
  }

  // Add method to refresh current family data
  Future<void> refreshCurrentFamily() async {
    final currentUser = state.family?.createdById;
    if (currentUser != null) {
      await loadCurrentFamily(currentUser);
    }
  }
}
