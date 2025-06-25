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
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _authRepository.signUp(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
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
      (_) => state.copyWith(
        user: state.user!.copyWith(
          displayName: displayName ?? state.user!.displayName,
          avatarUrl: avatarUrl ?? state.user!.avatarUrl,
        ),
      ),
    );
  }
}
