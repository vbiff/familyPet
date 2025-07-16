import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/domain/entities/child_invitation_token.dart';
import 'package:jhonny/features/auth/data/models/child_invitation_token_model.dart';
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
      // First create the user account with display name in metadata
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'role': role.name,
        },
      );

      if (response.user == null) {
        return left(const AuthenticationFailure(
          message: 'Failed to create user account',
        ));
      }

      final userId = response.user!.id;
      final now = DateTime.now();

      // Create profile with comprehensive data
      // Since we removed the auth trigger, we need to handle this client-side
      final profileData = {
        'id': userId,
        'email': email,
        'display_name': displayName,
        'role': role.name,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'last_login_at': now.toIso8601String(),
      };

      // Use upsert to handle any potential conflicts gracefully
      await _client.from('profiles').upsert(profileData);

      return right(User(
        id: userId,
        email: email,
        displayName: displayName,
        role: role,
        authMethod: AuthMethod.email,
        createdAt: now,
        lastLoginAt: now,
        isPinSetup: false,
      ));
    } on supabase.AuthException catch (e) {
      return left(AuthenticationFailure(
        message: e.message,
        code: e.statusCode,
      ));
    } catch (e) {
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

      if (response.user == null) {
        return left(const AuthenticationFailure(
          message: 'Invalid email or password',
        ));
      }

      final userId = response.user!.id;
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
        final displayName =
            response.user!.userMetadata?['display_name'] as String? ??
                email.split('@').first;
        final role =
            response.user!.userMetadata?['role'] as String? ?? 'parent';

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
        isPinSetup: profile['is_pin_setup'] as bool? ?? false,
        lastPinUpdate: profile['last_pin_update'] != null
            ? DateTime.parse(profile['last_pin_update'])
            : null,
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
          authMethod: AuthMethod.values.firstWhere(
            (method) => method.name == (profile['auth_method'] ?? 'email'),
            orElse: () => AuthMethod.email,
          ),
          familyId: profile['family_id'],
          createdAt: DateTime.parse(profile['created_at']),
          lastLoginAt: DateTime.parse(profile['last_login_at']),
          isPinSetup: profile['is_pin_setup'] as bool? ?? false,
          lastPinUpdate: profile['last_pin_update'] != null
              ? DateTime.parse(profile['last_pin_update'])
              : null,
          metadata: profile['metadata'],
        );
      } catch (_) {
        return null;
      }
    });
  }

  // PIN Authentication Methods
  @override
  Future<Either<Failure, User>> signInWithPin({
    required String displayName,
    required String pin,
  }) async {
    try {
      // Find user by display name and role (child with PIN setup)
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('display_name', displayName)
          .eq('role', 'child')
          .eq('auth_method', 'pin')
          .eq('is_pin_setup', true)
          .maybeSingle();

      if (profileResponse == null) {
        return left(const AuthenticationFailure(
          message: 'User not found or PIN not set up',
        ));
      }

      final userId = profileResponse['id'] as String;

      // Verify PIN using database function
      final pinVerifyResponse = await _client.rpc('verify_pin', params: {
        'user_id': userId,
        'pin_text': pin,
      });

      if (pinVerifyResponse != true) {
        return left(const AuthenticationFailure(
          message: 'Invalid PIN',
        ));
      }

      // Update last login
      await _client.from('profiles').update(
          {'last_login_at': DateTime.now().toIso8601String()}).eq('id', userId);

      // Create User entity
      return right(User(
        id: userId,
        email: profileResponse['email'] ?? '',
        displayName: profileResponse['display_name'],
        avatarUrl: profileResponse['avatar_url'],
        role: UserRole.child,
        authMethod: AuthMethod.pin,
        familyId: profileResponse['family_id'],
        createdAt: DateTime.parse(profileResponse['created_at']),
        lastLoginAt: DateTime.now(),
        isPinSetup: true,
        lastPinUpdate: profileResponse['last_pin_update'] != null
            ? DateTime.parse(profileResponse['last_pin_update'])
            : null,
        metadata: profileResponse['metadata'],
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to sign in with PIN: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, User>> signUpChildWithPin({
    required String token,
    required String displayName,
    required String pin,
  }) async {
    try {
      // Validate the invitation token first
      final tokenValidation = await validateChildInvitationToken(token: token);
      if (tokenValidation.isLeft()) {
        return tokenValidation.fold(
          (failure) => left(failure),
          (result) => right(User(
            id: '',
            email: '',
            displayName: displayName,
            role: UserRole.child,
            authMethod: AuthMethod.pin,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          )),
        );
      }

      final tokenResult = tokenValidation.fold(
        (failure) => throw failure,
        (result) => result,
      );

      // Create a temporary email for the child (will not be used for auth)
      final tempEmail =
          '${displayName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}@child.jhonny.app';

      // Create auth user with dummy password (PIN will be primary auth)
      final authResponse = await _client.auth.signUp(
        email: tempEmail,
        password: 'temp_password_${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'display_name': displayName,
          'role': 'child',
          'auth_method': 'pin',
        },
      );

      if (authResponse.user == null) {
        return left(const AuthenticationFailure(
          message: 'Failed to create child account',
        ));
      }

      final userId = authResponse.user!.id;
      final now = DateTime.now();

      // Setup PIN using database function
      final pinSetupResponse = await _client.rpc('setup_child_pin', params: {
        'user_id': userId,
        'pin_text': pin,
        'display_name_param': displayName,
      });

      if (pinSetupResponse != true) {
        return left(const AuthenticationFailure(
          message: 'Failed to setup PIN',
        ));
      }

      // Consume the invitation token and add to family
      final consumeResult = await consumeChildInvitationToken(
        token: token,
        childUserId: userId,
      );

      if (consumeResult.isLeft()) {
        return consumeResult.fold(
          (failure) => left(failure),
          (_) => left(const UnexpectedFailure(message: 'Unexpected error')),
        );
      }

      // Sign out the temporary auth session
      await _client.auth.signOut();

      return right(User(
        id: userId,
        email: tempEmail,
        displayName: displayName,
        role: UserRole.child,
        authMethod: AuthMethod.pin,
        familyId: tokenResult.familyId,
        createdAt: now,
        lastLoginAt: now,
        isPinSetup: true,
        lastPinUpdate: now,
      ));
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to create child account with PIN: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> setupPin({
    required String pin,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthenticationFailure(
          message: 'No user is currently signed in',
        ));
      }

      final response = await _client.rpc('setup_child_pin', params: {
        'user_id': currentUser.id,
        'pin_text': pin,
        'display_name_param':
            currentUser.userMetadata?['display_name'] ?? 'Child',
      });

      if (response != true) {
        return left(const AuthenticationFailure(
          message: 'Failed to setup PIN',
        ));
      }

      return right(null);
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to setup PIN: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updatePin({
    required String currentPin,
    required String newPin,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthenticationFailure(
          message: 'No user is currently signed in',
        ));
      }

      // Verify current PIN first
      final verifyResult = await verifyPin(pin: currentPin);
      if (verifyResult.isLeft()) {
        return left(const AuthenticationFailure(
          message: 'Current PIN is incorrect',
        ));
      }

      final isValid = verifyResult.fold(
        (failure) => false,
        (result) => result,
      );
      if (!isValid) {
        return left(const AuthenticationFailure(
          message: 'Current PIN is incorrect',
        ));
      }

      // Setup new PIN
      final setupResult = await setupPin(pin: newPin);
      return setupResult;
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to update PIN: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin({
    required String pin,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthenticationFailure(
          message: 'No user is currently signed in',
        ));
      }

      final response = await _client.rpc('verify_pin', params: {
        'user_id': currentUser.id,
        'pin_text': pin,
      });

      return right(response == true);
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to verify PIN: ${e.toString()}',
      ));
    }
  }

  // Child Invitation Token Methods
  @override
  Future<Either<Failure, String>> createChildInvitationToken({
    required String familyId,
    String? childDisplayName,
    int? expiresInHours, // Changed to nullable - null means never expire
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return left(const AuthenticationFailure(
          message: 'No user is currently signed in',
        ));
      }

      final token = await _client.rpc('create_child_invitation_token', params: {
        'family_id_param': familyId,
        'created_by_id_param': currentUser.id,
        'child_display_name_param': childDisplayName,
        'expires_in_hours': expiresInHours, // Pass null if never expire
      });

      return right(token as String);
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to create invitation token: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, TokenValidationResult>> validateChildInvitationToken({
    required String token,
  }) async {
    try {
      final response = await _client.rpc('validate_child_invitation_token',
          params: {'token_param': token});

      if (response == null || (response as List).isEmpty) {
        return left(const ValidationFailure(
          message: 'Invalid, expired, or already used invitation token',
        ));
      }

      final result = (response).first;
      return right(TokenValidationResultModel.fromJson(result).toEntity());
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to validate invitation token: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> consumeChildInvitationToken({
    required String token,
    required String childUserId,
  }) async {
    try {
      final response =
          await _client.rpc('consume_child_invitation_token', params: {
        'token_param': token,
        'child_user_id': childUserId,
      });

      if (response != true) {
        return left(const ValidationFailure(
          message: 'Failed to consume invitation token',
        ));
      }

      return right(null);
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to consume invitation token: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, List<ChildInvitationToken>>>
      getFamilyInvitationTokens({
    required String familyId,
  }) async {
    try {
      final response = await _client
          .from('child_invitation_tokens')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      final tokens = (response as List)
          .map((json) => ChildInvitationTokenModel.fromJson(json).toEntity())
          .toList();

      return right(tokens);
    } catch (e) {
      return left(UnexpectedFailure(
        message: 'Failed to get family invitation tokens: ${e.toString()}',
      ));
    }
  }
}
