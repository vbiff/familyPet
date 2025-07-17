import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/domain/repositories/auth_repository.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _init();
  }

  void _init() {
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }, onError: (error) {
      // Handle auth errors like invalid refresh tokens
      if (error.toString().contains('refresh_token_not_found') ||
          error.toString().contains('Invalid Refresh Token')) {
        // Clear invalid session and redirect to login
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    state = result.fold(
      (failure) => state.copyWith(
        status: AuthStatus.error,
        failure: failure,
      ),
      (user) => state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    print('🔄 AuthNotifier: Starting signup...');
    state = state.copyWith(status: AuthStatus.loading);

    print('🔄 AuthNotifier: Calling repository signup...');
    final result = await _authRepository.signUp(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
    );

    print('🔄 AuthNotifier: Repository result received');
    state = result.fold(
      (failure) {
        print('❌ AuthNotifier: Signup failed - ${failure.message}');
        return state.copyWith(
          status: AuthStatus.error,
          failure: failure,
        );
      },
      (user) {
        print(
            '✅ AuthNotifier: Signup successful - ${user.displayName} (${user.role})');
        return state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );

    print('🔄 AuthNotifier: Final state - ${state.status}');
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.signOut();

    state = result.fold(
      (failure) => state.copyWith(
        status: AuthStatus.error,
        failure: failure,
      ),
      (_) => const AuthState(status: AuthStatus.unauthenticated),
    );
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (state.user == null) return;

    final result = await _authRepository.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    state = result.fold(
      (failure) => state.copyWith(failure: failure),
      (_) {
        final currentUser = state.user;
        if (currentUser == null) return state;

        return state.copyWith(
          user: currentUser.copyWith(
            displayName: displayName ?? currentUser.displayName,
            avatarUrl: avatarUrl ?? currentUser.avatarUrl,
          ),
        );
      },
    );
  }

  Future<void> refreshUser() async {
    if (state.user == null) return;

    final result = await _authRepository.getCurrentUser();

    result.fold(
      (failure) => state = state.copyWith(failure: failure),
      (user) => state = state.copyWith(user: user, failure: null),
    );
  }

  Future<void> resetPassword({required String email}) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.resetPassword(email: email);

    state = result.fold(
      (failure) => state.copyWith(
        status: AuthStatus.error,
        failure: failure,
      ),
      (_) => state.copyWith(
        status: AuthStatus.unauthenticated,
        failure: null,
      ),
    );
  }
}
