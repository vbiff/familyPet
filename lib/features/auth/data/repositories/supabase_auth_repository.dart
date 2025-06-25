import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      // First create the user account
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return left(const AuthenticationFailure(
          message: 'Failed to create user account',
        ));
      }

      final userId = response.user!.id;
      final now = DateTime.now();

      // Create profile with only essential fields first
      final profileData = {
        'id': userId,
        'email': email,
        'display_name': displayName,
        'role': role.name,
      };

      await _client.from('profiles').insert(profileData);

      return right(User(
        id: userId,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: now,
        lastLoginAt: now,
      ));
    } on supabase.AuthException catch (e) {
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Database error: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return left(const AuthenticationFailure(
          message: 'Invalid email or password',
        ));
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      await _client.from('profiles').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', response.user!.id);

      return right(User(
        id: response.user!.id,
        email: email,
        displayName: profile['display_name'],
        avatarUrl: profile['avatar_url'],
        role: UserRole.values.firstWhere(
          (role) => role.name == profile['role'],
          orElse: () => UserRole.child,
        ),
        familyId: profile['family_id'],
        createdAt: DateTime.parse(profile['created_at']),
        lastLoginAt: DateTime.now(),
        metadata: profile['metadata'],
      ));
    } on supabase.AuthException catch (e) {
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _client.auth.signOut();
      return right(null);
    } on supabase.AuthException catch (e) {
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final currentUser = _client.auth.currentUser;

      if (currentUser == null) {
        return left(const AuthenticationFailure(
          message: 'No user is currently signed in',
        ));
      }

      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .single();

      return right(User(
        id: currentUser.id,
        email: currentUser.email!,
        displayName: profile['display_name'],
        avatarUrl: profile['avatar_url'],
        role: UserRole.values.firstWhere(
          (role) => role.name == profile['role'],
          orElse: () => UserRole.child,
        ),
        familyId: profile['family_id'],
        createdAt: DateTime.parse(profile['created_at']),
        lastLoginAt: DateTime.parse(profile['last_login_at']),
        metadata: profile['metadata'],
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;

      if (currentUser == null) {
        return left(const AuthenticationFailure(
          message: 'No user is currently signed in',
        ));
      }

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _client.from('profiles').update(updates).eq('id', currentUser.id);

      return right(null);
    } catch (e) {
      return left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return right(null);
    } on supabase.AuthException catch (e) {
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.auth.updateUser(
        supabase.UserAttributes(
          password: newPassword,
        ),
      );
      return right(null);
    } on supabase.AuthException catch (e) {
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: e.toString(),
      ));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.event == supabase.AuthChangeEvent.signedOut) {
        return null;
      }

      final user = event.session?.user;
      if (user == null) return null;

      try {
        final profile =
            await _client.from('profiles').select().eq('id', user.id).single();

        return User(
          id: user.id,
          email: user.email!,
          displayName: profile['display_name'],
          avatarUrl: profile['avatar_url'],
          role: UserRole.values.firstWhere(
            (role) => role.name == profile['role'],
            orElse: () => UserRole.child,
          ),
          familyId: profile['family_id'],
          createdAt: DateTime.parse(profile['created_at']),
          lastLoginAt: DateTime.parse(profile['last_login_at']),
          metadata: profile['metadata'],
        );
      } catch (_) {
        return null;
      }
    });
  }
}
