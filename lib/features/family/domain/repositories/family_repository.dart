import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/family/data/models/family_member_model.dart';

abstract class FamilyRepository {
  /// Create a new family
  Future<Either<Failure, Family>> createFamily({
    required String name,
    required String createdById,
    Map<String, dynamic>? settings,
  });

  /// Join an existing family using invite code
  Future<Either<Failure, Family>> joinFamily({
    required String inviteCode,
    required String userId,
  });

  /// Get family by ID
  Future<Either<Failure, Family>> getFamilyById(String familyId);

  /// Get family by invite code
  Future<Either<Failure, Family>> getFamilyByInviteCode(String inviteCode);

  /// Get current user's family
  Future<Either<Failure, Family?>> getCurrentUserFamily(String userId);

  /// Update family details
  Future<Either<Failure, Family>> updateFamily(Family family);

  /// Add member to family
  Future<Either<Failure, void>> addMemberToFamily({
    required String familyId,
    required String userId,
  });

  /// Remove member from family
  Future<Either<Failure, void>> removeMemberFromFamily({
    required String familyId,
    required String userId,
  });

  /// Get all family members with their statistics
  Future<Either<Failure, List<FamilyMemberModel>>> getFamilyMembers(
    String familyId,
  );

  /// Update family member role
  Future<Either<Failure, void>> updateMemberRole({
    required String familyId,
    required String userId,
    required String role,
  });

  /// Generate new invite code for family
  Future<Either<Failure, String>> generateNewInviteCode(String familyId);

  /// Leave family (for non-creator members)
  Future<Either<Failure, void>> leaveFamily({
    required String familyId,
    required String userId,
  });

  /// Delete family (creator only)
  Future<Either<Failure, void>> deleteFamily(String familyId);

  /// Watch family changes for real-time updates
  Stream<Family> watchFamily(String familyId);

  /// Watch family members for real-time updates
  Stream<List<FamilyMemberModel>> watchFamilyMembers(String familyId);
}
