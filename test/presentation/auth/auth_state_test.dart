import 'package:test/test.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/core/error/failures.dart';

void main() {
  group('AuthState Tests', () {
    group('AuthStatus enum', () {
      test('should have all expected values', () {
        expect(AuthStatus.values, [
          AuthStatus.initial,
          AuthStatus.loading,
          AuthStatus.authenticated,
          AuthStatus.unauthenticated,
          AuthStatus.error,
        ]);
      });
    });

    group('AuthState class', () {
      late User testUser;
      late DateTime testDate;

      setUp(() {
        testDate = DateTime(2024, 1, 1, 12, 0, 0);
        testUser = User(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.parent,
          createdAt: testDate,
          lastLoginAt: testDate,
        );
      });

      test('should create initial state', () {
        final state = AuthState.initial();

        expect(state.status, AuthStatus.initial);
        expect(state.user, isNull);
        expect(state.failure, isNull);
      });

      test('should create state with all properties', () {
        const failure = AuthenticationFailure(message: 'Test error');
        final state = AuthState(
          status: AuthStatus.error,
          user: testUser,
          failure: failure,
        );

        expect(state.status, AuthStatus.error);
        expect(state.user, testUser);
        expect(state.failure, failure);
      });

      test('should create state with required status only', () {
        const state = AuthState(status: AuthStatus.loading);

        expect(state.status, AuthStatus.loading);
        expect(state.user, isNull);
        expect(state.failure, isNull);
      });

      group('copyWith method', () {
        test('should create copy with updated status', () {
          final originalState = AuthState(
            status: AuthStatus.initial,
            user: testUser,
          );

          final updatedState = originalState.copyWith(
            status: AuthStatus.loading,
          );

          expect(updatedState.status, AuthStatus.loading);
          expect(updatedState.user, testUser);
          expect(updatedState.failure, isNull);
        });

        test('should create copy with updated user', () {
          const originalState = AuthState(status: AuthStatus.unauthenticated);

          final updatedState = originalState.copyWith(
            status: AuthStatus.authenticated,
            user: testUser,
          );

          expect(updatedState.status, AuthStatus.authenticated);
          expect(updatedState.user, testUser);
          expect(updatedState.failure, isNull);
        });

        test('should create copy with updated failure', () {
          final originalState = AuthState(
            status: AuthStatus.authenticated,
            user: testUser,
          );

          const failure = AuthenticationFailure(message: 'Error occurred');
          final updatedState = originalState.copyWith(
            status: AuthStatus.error,
            failure: failure,
          );

          expect(updatedState.status, AuthStatus.error);
          expect(updatedState.user, testUser);
          expect(updatedState.failure, failure);
        });

        test('should preserve original values when not specified', () {
          const failure = AuthenticationFailure(message: 'Original error');
          final originalState = AuthState(
            status: AuthStatus.error,
            user: testUser,
            failure: failure,
          );

          final updatedState = originalState.copyWith(
            status: AuthStatus.loading,
          );

          expect(updatedState.status, AuthStatus.loading);
          expect(updatedState.user, testUser);
          expect(updatedState.failure, failure);
        });

        test(
            'should preserve existing values when copyWith called without changes',
            () {
          final originalState = AuthState(
            status: AuthStatus.authenticated,
            user: testUser,
          );

          final updatedState = originalState.copyWith();

          expect(updatedState.status, AuthStatus.authenticated);
          expect(updatedState.user, testUser);
          expect(updatedState.failure, isNull);
        });
      });

      group('State transitions', () {
        test('should handle initial to loading transition', () {
          final initialState = AuthState.initial();
          final loadingState = initialState.copyWith(
            status: AuthStatus.loading,
          );

          expect(initialState.status, AuthStatus.initial);
          expect(loadingState.status, AuthStatus.loading);
          expect(loadingState.user, isNull);
          expect(loadingState.failure, isNull);
        });

        test('should handle loading to authenticated transition', () {
          const loadingState = AuthState(status: AuthStatus.loading);
          final authenticatedState = loadingState.copyWith(
            status: AuthStatus.authenticated,
            user: testUser,
          );

          expect(authenticatedState.status, AuthStatus.authenticated);
          expect(authenticatedState.user, testUser);
          expect(authenticatedState.failure, isNull);
        });

        test('should handle loading to error transition', () {
          const loadingState = AuthState(status: AuthStatus.loading);
          const failure = AuthenticationFailure(message: 'Login failed');
          final errorState = loadingState.copyWith(
            status: AuthStatus.error,
            failure: failure,
          );

          expect(errorState.status, AuthStatus.error);
          expect(errorState.user, isNull);
          expect(errorState.failure, failure);
        });

        test('should handle authenticated to unauthenticated transition', () {
          final authenticatedState = AuthState(
            status: AuthStatus.authenticated,
            user: testUser,
          );
          final unauthenticatedState = authenticatedState.copyWith(
            status: AuthStatus.unauthenticated,
          );

          expect(unauthenticatedState.status, AuthStatus.unauthenticated);
          // Note: copyWith might preserve user, this tests the status change
          expect(unauthenticatedState.failure, isNull);
        });
      });

      group('Common state scenarios', () {
        test('should create typical initial state', () {
          final state = AuthState.initial();

          expect(state.status, AuthStatus.initial);
          expect(state.user, isNull);
          expect(state.failure, isNull);
        });

        test('should create typical loading state', () {
          const state = AuthState(status: AuthStatus.loading);

          expect(state.status, AuthStatus.loading);
          expect(state.user, isNull);
          expect(state.failure, isNull);
        });

        test('should create typical authenticated state', () {
          final state = AuthState(
            status: AuthStatus.authenticated,
            user: testUser,
          );

          expect(state.status, AuthStatus.authenticated);
          expect(state.user, testUser);
          expect(state.failure, isNull);
        });

        test('should create typical unauthenticated state', () {
          const state = AuthState(status: AuthStatus.unauthenticated);

          expect(state.status, AuthStatus.unauthenticated);
          expect(state.user, isNull);
          expect(state.failure, isNull);
        });

        test('should create typical error state', () {
          const failure =
              AuthenticationFailure(message: 'Authentication failed');
          const state = AuthState(
            status: AuthStatus.error,
            failure: failure,
          );

          expect(state.status, AuthStatus.error);
          expect(state.user, isNull);
          expect(state.failure, failure);
        });
      });
    });
  });
}
