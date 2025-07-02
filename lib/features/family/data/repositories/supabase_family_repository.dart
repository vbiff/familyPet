import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/family/data/datasources/family_remote_datasource.dart';
import 'package:jhonny/features/family/data/models/family_model.dart';
import 'package:jhonny/features/family/data/models/family_member_model.dart';
import 'package:jhonny/features/family/domain/entities/family.dart';
import 'package:jhonny/features/family/domain/repositories/family_repository.dart';

class SupabaseFamilyRepository implements FamilyRepository {
  final FamilyRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  SupabaseFamilyRepository(this._remoteDataSource, this._uuid);

  @override
  Future<Either<Failure, Family>> createFamily({
    required String name,
    required String createdById,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final familyId = _uuid.v4();
      final inviteCode = _generateInviteCode();
      final now = DateTime.now();

      final familyModel = FamilyModel(
        id: familyId,
        name: name,
        inviteCode: inviteCode,
        createdById: createdById,
        parentIds: [createdById], // Creator is automatically a parent
        childIds: const [],
        createdAt: now,
        lastActivityAt: now,
        settings: settings ?? {},
        metadata: const {},
      );

      final createdFamily = await _remoteDataSource.createFamily(familyModel);
      return right(createdFamily.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Family>> joinFamily({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Double-check if user already has a family at repository level
      final existingFamilyResult = await getCurrentUserFamily(userId);

      final hasExistingFamily = existingFamilyResult.fold(
        (failure) => false, // If we can't check, proceed cautiously
        (family) => family != null,
      );

      if (hasExistingFamily) {
        return left(const ValidationFailure(
            message: 'You are already a member of a family'));
      }

      // First, find the family with this invite code
      final family = await _remoteDataSource.getFamilyByInviteCode(inviteCode);

      // Add the user to the family
      await _remoteDataSource.addMemberToFamily(family.id, userId);

      // Return the updated family
      final updatedFamily = await _remoteDataSource.getFamilyById(family.id);
      return right(updatedFamily.toEntity());
    } catch (e) {
      final errorMessage = e.toString();

      if (errorMessage.contains('Family not found') ||
          errorMessage.contains('invite code')) {
        return left(const ValidationFailure(
            message:
                'Invalid invite code. Please check the code and try again.'));
      }

      if (errorMessage.contains('already') || errorMessage.contains('member')) {
        return left(const ValidationFailure(
            message: 'You are already a member of a family'));
      }

      return left(
          ServerFailure(message: 'Failed to join family: $errorMessage'));
    }
  }

  @override
  Future<Either<Failure, Family>> getFamilyById(String familyId) async {
    try {
      final familyModel = await _remoteDataSource.getFamilyById(familyId);
      return right(familyModel.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Family>> getFamilyByInviteCode(
      String inviteCode) async {
    try {
      final familyModel =
          await _remoteDataSource.getFamilyByInviteCode(inviteCode);
      return right(familyModel.toEntity());
    } catch (e) {
      return left(const ValidationFailure(message: 'Invalid invite code'));
    }
  }

  @override
  Future<Either<Failure, Family?>> getCurrentUserFamily(String userId) async {
    try {
      final familyModel = await _remoteDataSource.getCurrentUserFamily(userId);
      if (familyModel == null) {
        return right(null);
      }
      return right(familyModel.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Family>> updateFamily(Family family) async {
    try {
      final familyModel = FamilyModel.fromEntity(family);
      final updatedFamily = await _remoteDataSource.updateFamily(familyModel);
      return right(updatedFamily.toEntity());
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addMemberToFamily({
    required String familyId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.addMemberToFamily(familyId, userId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeMemberFromFamily({
    required String familyId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.removeMemberFromFamily(familyId, userId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FamilyMemberModel>>> getFamilyMembers(
    String familyId,
  ) async {
    try {
      final members = await _remoteDataSource.getFamilyMembers(familyId);
      return right(members);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMemberRole({
    required String familyId,
    required String userId,
    required String role,
  }) async {
    try {
      await _remoteDataSource.updateMemberRole(familyId, userId, role);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateNewInviteCode(String familyId) async {
    try {
      final newInviteCode =
          await _remoteDataSource.generateNewInviteCode(familyId);
      return right(newInviteCode);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveFamily({
    required String familyId,
    required String userId,
  }) async {
    try {
      await _remoteDataSource.leaveFamily(familyId, userId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFamily(String familyId) async {
    try {
      await _remoteDataSource.deleteFamily(familyId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Family> watchFamily(String familyId) {
    return _remoteDataSource
        .watchFamily(familyId)
        .map((familyModel) => familyModel.toEntity());
  }

  @override
  Stream<List<FamilyMemberModel>> watchFamilyMembers(String familyId) {
    return _remoteDataSource.watchFamilyMembers(familyId);
  }

  String _generateInviteCode() {
    const chars = '9A4B8C2D6E0F3G7H1I5J9K2L4M8N6P0Q3R7S5T1U9V4W2X6Y0Z3'
        '8F2E4A9C1B7D3G5H6J8K9L2M4N5P7Q8R9S1T3U4V6W7X8Y9Z'
        '2468ACEGIKMOQSUWY13579BDFHJLNPRTVXZ'
        'QWERTYUIOPASDFGHJKLZXCVBNM'
        '9876543210ZYXWVUTSRQPONMLKJIHGFEDCBA'
        'MNBVCXZLKJHGFDSAPOIUYTREWQ'
        '0369CFILOR258BEHKNQTWY147ADGJMPSUXZ'
        'ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210'
        'RSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQ'
        'P2Q4R6S8T9U1V3W5X7Y8Z9A2B4C5D7E8F9G';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }

  @override
  Future<Either<Failure, void>> updatePetImageUrl({
    required String familyId,
    required String petImageUrl,
  }) async {
    try {
      await _remoteDataSource.updatePetImageUrl(
        familyId: familyId,
        petImageUrl: petImageUrl,
      );
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePetStageImages({
    required String familyId,
    required Map<String, String> petStageImages,
  }) async {
    try {
      await _remoteDataSource.updatePetStageImages(
        familyId: familyId,
        petStageImages: petStageImages,
      );
      return right(null);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getFamilyPetImageUrl(String familyId) async {
    try {
      final petImageUrl =
          await _remoteDataSource.getFamilyPetImageUrl(familyId);
      return right(petImageUrl);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
