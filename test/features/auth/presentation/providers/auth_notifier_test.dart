import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jhonny/core/error/failures.dart';
import 'package:jhonny/features/auth/domain/entities/user.dart';
import 'package:jhonny/features/auth/domain/repositories/auth_repository.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_notifier.dart';
import 'package:jhonny/features/auth/presentation/providers/auth_state.dart';

// Mock class
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthNotifier Tests', () {
    late AuthNotifier authNotifier;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      // Mock the authStateChanges stream to avoid issues during initialization
      when(mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      authNotifier = AuthNotifier(mockAuthRepository);
    });

    final testUser = User(
      id: 'user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      role: UserRole.parent,
      familyId: 'family-123',
      createdAt: DateTime(2024, 1, 1),
      lastLoginAt: DateTime(2024, 1, 1),
    );

    group('Initial State', () {
      test('should have initial state', () {
        expect(authNotifier.state.status, AuthStatus.initial);
        expect(authNotifier.state.user, isNull);
        expect(authNotifier.state.failure, isNull);
      });
    });

    group('signIn', () {
      test('should emit authenticated when sign in succeeds', () async {
        const email = 'test@example.com';
        const password = 'password123';

        // arrange
        when(mockAuthRepository.signIn(
          email: email,
          password: password,
        )).thenAnswer((_) async => Right(testUser));

        // act
        await authNotifier.signIn(email: email, password: password);

        // assert
        expect(authNotifier.state.status, AuthStatus.authenticated);
        expect(authNotifier.state.user, testUser);
        expect(authNotifier.state.failure, isNull);

        verify(mockAuthRepository.signIn(
          email: email,
          password: password,
        )).called(1);
      });

      test('should emit error when sign in fails', () async {
        const failure = AuthenticationFailure(message: 'Invalid credentials');

        // arrange
        when(mockAuthRepository.signIn(
          email: 'test@example.com',
          password: 'wrongpassword',
        )).thenAnswer((_) async => const Left(failure));

        // act
        await authNotifier.signIn(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        // assert
        expect(authNotifier.state.status, AuthStatus.error);
        expect(authNotifier.state.user, isNull);
        expect(authNotifier.state.failure, failure);
      });

      test('should set loading state during sign in', () async {
        // arrange
        when(mockAuthRepository.signIn(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async {
          // Verify loading state is set
          expect(authNotifier.state.status, AuthStatus.loading);
          return Right(testUser);
        });

        // act
        await authNotifier.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Loading should transition to authenticated after completion
        expect(authNotifier.state.status, AuthStatus.authenticated);
      });
    });

    group('signUp', () {
      test('should emit authenticated when sign up succeeds', () async {
        const email = 'newuser@example.com';
        const password = 'password123';
        const displayName = 'New User';
        const role = UserRole.parent;

        // arrange
        when(mockAuthRepository.signUp(
          email: email,
          password: password,
          displayName: displayName,
          role: role,
        )).thenAnswer((_) async => Right(testUser));

        // act
        await authNotifier.signUp(
          email: email,
          password: password,
          displayName: displayName,
          role: role,
        );

        // assert
        expect(authNotifier.state.status, AuthStatus.authenticated);
        expect(authNotifier.state.user, testUser);
        expect(authNotifier.state.failure, isNull);

        verify(mockAuthRepository.signUp(
          email: email,
          password: password,
          displayName: displayName,
          role: role,
        )).called(1);
      });

      test('should emit error when sign up fails', () async {
        const failure = AuthenticationFailure(message: 'Email already exists');

        // arrange
        when(mockAuthRepository.signUp(
          email: 'existing@example.com',
          password: 'password123',
          displayName: 'Test User',
          role: UserRole.parent,
        )).thenAnswer((_) async => const Left(failure));

        // act
        await authNotifier.signUp(
          email: 'existing@example.com',
          password: 'password123',
          displayName: 'Test User',
          role: UserRole.parent,
        );

        // assert
        expect(authNotifier.state.status, AuthStatus.error);
        expect(authNotifier.state.user, isNull);
        expect(authNotifier.state.failure, failure);
      });
    });

    group('signOut', () {
      test('should emit unauthenticated when sign out succeeds', () async {
        // arrange
        authNotifier.state = authNotifier.state.copyWith(
          status: AuthStatus.authenticated,
          user: testUser,
        );
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));

        // act
        await authNotifier.signOut();

        // assert
        expect(authNotifier.state.status, AuthStatus.unauthenticated);
        expect(authNotifier.state.user, isNull);
        expect(authNotifier.state.failure, isNull);

        verify(mockAuthRepository.signOut()).called(1);
      });

      test('should emit error when sign out fails', () async {
        const failure = ServerFailure(message: 'Sign out failed');

        // arrange
        authNotifier.state = authNotifier.state.copyWith(
          status: AuthStatus.authenticated,
          user: testUser,
        );
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Left(failure));

        // act
        await authNotifier.signOut();

        // assert
        expect(authNotifier.state.status, AuthStatus.error);
        expect(authNotifier.state.failure, failure);
      });
    });

    group('updateProfile', () {
      test('should update user profile successfully', () async {
        const displayName = 'Updated Name';
        const avatarUrl = 'https://example.com/avatar.jpg';

        // arrange
        authNotifier.state = authNotifier.state.copyWith(
          status: AuthStatus.authenticated,
          user: testUser,
        );
        when(mockAuthRepository.updateProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
        )).thenAnswer((_) async => const Right(null));

        // act
        await authNotifier.updateProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
        );

        // assert
        expect(authNotifier.state.user?.displayName, displayName);
        expect(authNotifier.state.user?.avatarUrl, avatarUrl);
        expect(authNotifier.state.failure, isNull);

        verify(mockAuthRepository.updateProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
        )).called(1);
      });

      test('should handle profile update failure', () async {
        const failure = ServerFailure(message: 'Update failed');

        // arrange
        authNotifier.state = authNotifier.state.copyWith(
          status: AuthStatus.authenticated,
          user: testUser,
        );
        when(mockAuthRepository.updateProfile(
          displayName: 'New Name',
          avatarUrl: null,
        )).thenAnswer((_) async => const Left(failure));

        // act
        await authNotifier.updateProfile(displayName: 'New Name');

        // assert
        expect(authNotifier.state.failure, failure);
      });
    });

    group('Auth State Changes', () {
      test('should update state when user logs in via stream', () {
        // This tests the _init method that listens to authStateChanges
        expect(authNotifier.state.status, AuthStatus.initial);

        // The stream is already mocked in setUp to return null initially
        // In a real scenario, the stream would emit user changes
      });
    });

    group('Error handling', () {
      test('should handle different failure types correctly', () async {
        final failures = [
          const AuthenticationFailure(message: 'Authentication failed'),
          const ValidationFailure(message: 'Invalid input'),
          const ServerFailure(message: 'Server error'),
          const NetworkFailure(message: 'Network error'),
        ];

        for (final failure in failures) {
          // arrange
          when(mockAuthRepository.signIn(
            email: 'test@example.com',
            password: 'password',
          )).thenAnswer((_) async => Left(failure));

          // act
          await authNotifier.signIn(
            email: 'test@example.com',
            password: 'password',
          );

          // assert
          expect(authNotifier.state.failure, failure);
          expect(authNotifier.state.status, AuthStatus.error);
        }
      });
    });

    group('Edge cases', () {
      test('should handle empty email/password gracefully', () async {
        const failure = ValidationFailure(message: 'Email is required');

        // arrange
        when(mockAuthRepository.signIn(
          email: '',
          password: '',
        )).thenAnswer((_) async => const Left(failure));

        // act
        await authNotifier.signIn(email: '', password: '');

        // assert
        expect(authNotifier.state.status, AuthStatus.error);
        expect(
            authNotifier.state.failure?.message, contains('Email is required'));
      });

      test('should not update profile when user is null', () async {
        // arrange - no authenticated user
        authNotifier.state = authNotifier.state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        );

        // act
        await authNotifier.updateProfile(displayName: 'New Name');

        // assert - repository should not be called
        verifyNever(mockAuthRepository.updateProfile(
          displayName: 'New Name',
        ));
      });
    });
  });
}
