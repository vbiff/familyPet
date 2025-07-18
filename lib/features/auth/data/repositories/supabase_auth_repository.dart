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
      print('🚀 Starting signup process...');
      print('📧 Email: $email');
      print('👤 Display Name: $displayName');
      print('🎭 Role: $role');

      // First create the user account with display name in metadata
      print('🔐 Creating auth user...');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'role': role.name,
        },
      );

      print('🔐 Auth signup response received');
      print('🔐 User: ${response.user?.id}');
      print(
          '🔐 Session: ${response.session?.accessToken != null ? 'exists' : 'null'}');
      print(
          '🔐 Auth error: ${response.user == null ? 'USER IS NULL' : 'user exists'}');

      final user = response.user;
      if (user == null) {
        print('❌ Auth user creation failed - user is null');
        return left(const AuthenticationFailure(
          message: 'Failed to create user account - auth returned null user',
        ));
      }

      print('✅ Auth user created successfully: ${user.id}');
      print('📧 Auth user email: ${user.email}');

      final userId = user.id;
      final now = DateTime.now();

      // Create profile directly - should work with new RLS policies
      final profileData = {
        'id': userId,
        'email': email,
        'display_name': displayName,
        'role': role.name,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'last_login_at': now.toIso8601String(),
      };

      print('📝 Creating profile with data: $profileData');
      print(
          '🔐 Current auth session exists: ${_client.auth.currentSession != null}');
      print('🔐 Current auth user: ${_client.auth.currentUser?.id}');

      try {
        final profileResult =
            await _client.from('profiles').upsert(profileData);
        print('✅ Profile creation successful: $profileResult');
      } catch (profileError) {
        print('❌ Profile creation failed: $profileError');
        print('❌ Profile error type: ${profileError.runtimeType}');
        print('❌ Profile error details: ${profileError.toString()}');
        rethrow;
      }

      final createdUser = User(
        id: userId,
        email: email,
        displayName: displayName,
        role: role,
        authMethod: AuthMethod.email,
        createdAt: now,
        lastLoginAt: now,
      );

      print('🎉 Signup completed successfully!');
      print(
          '👤 Created user: ${createdUser.displayName} (${createdUser.role})');

      return right(createdUser);
    } on supabase.AuthException catch (e) {
      print('❌ AuthException caught: ${e.message}');
      print('❌ AuthException code: ${e.statusCode}');
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
      print('❌ Generic exception caught: $e');
      print('❌ Exception type: ${e.runtimeType}');
      return left(UnexpectedFailure(
        message: 'Failed to create user profile: ${e.toString()}',
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

      final user = response.user;
      if (user == null) {
        return left(const AuthenticationFailure(
          message: 'Invalid email or password',
        ));
      }

      final userId = user.id;
      final now = DateTime.now();

      // Try to get existing profile
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle to avoid exception if not found

      Map<String, dynamic> profile;

      if (profileResponse == null) {
        // Profile doesn't exist (e.g., after app reinstall), create it
        final displayName = user.userMetadata?['display_name'] as String? ??
            email.split('@').first;
        final role = user.userMetadata?['role'] as String? ?? 'parent';

        profile = {
          'id': userId,
          'email': email,
          'display_name': displayName,
          'role': role,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'last_login_at': now.toIso8601String(),
        };

        // Create the missing profile
        await _client.from('profiles').upsert(profile);
      } else {
        profile = profileResponse;

        // Update last login time for existing profile
        await _client.from('profiles').update({
          'last_login_at': now.toIso8601String(),
        }).eq('id', userId);
      }

      return right(User(
        id: userId,
        email: email,
        displayName: profile['display_name'] ?? email.split('@').first,
        avatarUrl: profile['avatar_url'],
        role: UserRole.values.firstWhere(
          (role) => role.name == profile['role'],
          orElse: () => UserRole.parent, // Default to parent role
        ),
        authMethod: AuthMethod.values.firstWhere(
          (method) => method.name == (profile['auth_method'] ?? 'email'),
          orElse: () => AuthMethod.email,
        ),
        familyId: profile['family_id'],
        createdAt:
            DateTime.parse(profile['created_at'] ?? now.toIso8601String()),
        lastLoginAt: now,
        metadata: profile['metadata'],
      ));
    } on supabase.AuthException catch (e) {
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to sign in: ${e.toString()}',
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
      print('🔄 Auth state change event: ${event.event}');

      if (event.event == supabase.AuthChangeEvent.signedOut) {
        print('🔄 User signed out');
        return null;
      }

      final user = event.session?.user;
      if (user == null) {
        print('🔄 No user in session');
        return null;
      }

      print('🔄 Auth user found: ${user.id}, fetching profile...');

      try {
        final profile =
            await _client.from('profiles').select().eq('id', user.id).single();

        print(
            '✅ Profile found: ${profile['display_name']} (${profile['role']})');

        return User(
          id: user.id,
          email: user.email!,
          displayName: profile['display_name'],
          avatarUrl: profile['avatar_url'],
          role: UserRole.values.firstWhere(
            (role) => role.name == profile['role'],
            orElse: () => UserRole.child,
          ),
          authMethod: AuthMethod.values.firstWhere(
            (method) => method.name == (profile['auth_method'] ?? 'email'),
            orElse: () => AuthMethod.email,
          ),
          familyId: profile['family_id'],
          createdAt: DateTime.parse(profile['created_at']),
          lastLoginAt: DateTime.parse(profile['last_login_at']),
          metadata: profile['metadata'],
        );
      } catch (e) {
        print('❌ Failed to fetch profile for user ${user.id}: $e');
        print('❌ Error type: ${e.runtimeType}');
        return null;
      }
    });
  }
}
