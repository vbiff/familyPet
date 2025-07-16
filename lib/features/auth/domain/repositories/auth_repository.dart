import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/domain/entities/child_invitation_token.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  });

  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? avatarUrl,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  // PIN Authentication Methods
  Future<Either<Failure, User>> signInWithPin({
    required String displayName,
    required String pin,
  });

  Future<Either<Failure, User>> signUpChildWithPin({
    required String token,
    required String displayName,
    required String pin,
  });

  Future<Either<Failure, void>> setupPin({
    required String pin,
  });

  Future<Either<Failure, void>> updatePin({
    required String currentPin,
    required String newPin,
  });

  Future<Either<Failure, bool>> verifyPin({
    required String pin,
  });

  // Child Invitation Token Methods
  Future<Either<Failure, String>> createChildInvitationToken({
    required String familyId,
    String? childDisplayName,
    int expiresInHours = 24,
  });

  Future<Either<Failure, TokenValidationResult>> validateChildInvitationToken({
    required String token,
  });

  Future<Either<Failure, void>> consumeChildInvitationToken({
    required String token,
    required String childUserId,
  });

  Future<Either<Failure, List<ChildInvitationToken>>>
      getFamilyInvitationTokens({
    required String familyId,
  });

  Stream<User?> get authStateChanges;
}
