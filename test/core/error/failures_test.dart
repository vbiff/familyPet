import 'package:test/test.dart';
import 'package:jhonny/core/error/failures.dart';

void main() {
  group('Failure Classes Tests', () {
    const testMessage = 'Test error message';
    const testCode = 'TEST_CODE';
    final testStackTrace = StackTrace.current;

    group('ServerFailure', () {
      test('should create failure with message only', () {
        const failure = ServerFailure(message: testMessage);

        expect(failure.message, testMessage);
        expect(failure.code, isNull);
        expect(failure.stackTrace, isNull);
      });

      test('should create failure with all properties', () {
        final failure = ServerFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.message, testMessage);
        expect(failure.code, testCode);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should be equal when properties are same', () {
        const failure1 = ServerFailure(message: testMessage, code: testCode);
        const failure2 = ServerFailure(message: testMessage, code: testCode);

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });

      test('should not be equal when properties differ', () {
        const failure1 = ServerFailure(message: testMessage);
        const failure2 = ServerFailure(message: 'Different message');

        expect(failure1, isNot(equals(failure2)));
      });

      test('should include all properties in props', () {
        final failure = ServerFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.props, [testMessage, testCode, testStackTrace]);
      });
    });

    group('CacheFailure', () {
      test('should create failure with message only', () {
        const failure = CacheFailure(message: testMessage);

        expect(failure.message, testMessage);
        expect(failure.code, isNull);
        expect(failure.stackTrace, isNull);
      });

      test('should create failure with all properties', () {
        final failure = CacheFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.message, testMessage);
        expect(failure.code, testCode);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should be equal when properties are same', () {
        const failure1 = CacheFailure(message: testMessage, code: testCode);
        const failure2 = CacheFailure(message: testMessage, code: testCode);

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('NetworkFailure', () {
      test('should create failure with message only', () {
        const failure = NetworkFailure(message: testMessage);

        expect(failure.message, testMessage);
        expect(failure.code, isNull);
        expect(failure.stackTrace, isNull);
      });

      test('should create failure with all properties', () {
        final failure = NetworkFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.message, testMessage);
        expect(failure.code, testCode);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should be equal when properties are same', () {
        const failure1 = NetworkFailure(message: testMessage, code: testCode);
        const failure2 = NetworkFailure(message: testMessage, code: testCode);

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('ValidationFailure', () {
      test('should create failure with message only', () {
        const failure = ValidationFailure(message: testMessage);

        expect(failure.message, testMessage);
        expect(failure.code, isNull);
        expect(failure.stackTrace, isNull);
      });

      test('should create failure with all properties', () {
        final failure = ValidationFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.message, testMessage);
        expect(failure.code, testCode);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should be equal when properties are same', () {
        const failure1 =
            ValidationFailure(message: testMessage, code: testCode);
        const failure2 =
            ValidationFailure(message: testMessage, code: testCode);

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('AuthenticationFailure', () {
      test('should create failure with message only', () {
        const failure = AuthenticationFailure(message: testMessage);

        expect(failure.message, testMessage);
        expect(failure.code, isNull);
        expect(failure.stackTrace, isNull);
      });

      test('should create failure with all properties', () {
        final failure = AuthenticationFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.message, testMessage);
        expect(failure.code, testCode);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should be equal when properties are same', () {
        const failure1 =
            AuthenticationFailure(message: testMessage, code: testCode);
        const failure2 =
            AuthenticationFailure(message: testMessage, code: testCode);

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('PermissionFailure', () {
      test('should create failure with message only', () {
        const failure = PermissionFailure(message: testMessage);

        expect(failure.message, testMessage);
        expect(failure.code, isNull);
        expect(failure.stackTrace, isNull);
      });

      test('should create failure with all properties', () {
        final failure = PermissionFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.message, testMessage);
        expect(failure.code, testCode);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should be equal when properties are same', () {
        const failure1 =
            PermissionFailure(message: testMessage, code: testCode);
        const failure2 =
            PermissionFailure(message: testMessage, code: testCode);

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('UnexpectedFailure', () {
      test('should create failure with message only', () {
        const failure = UnexpectedFailure(message: testMessage);

        expect(failure.message, testMessage);
        expect(failure.code, isNull);
        expect(failure.stackTrace, isNull);
      });

      test('should create failure with all properties', () {
        final failure = UnexpectedFailure(
          message: testMessage,
          code: testCode,
          stackTrace: testStackTrace,
        );

        expect(failure.message, testMessage);
        expect(failure.code, testCode);
        expect(failure.stackTrace, testStackTrace);
      });

      test('should be equal when properties are same', () {
        const failure1 =
            UnexpectedFailure(message: testMessage, code: testCode);
        const failure2 =
            UnexpectedFailure(message: testMessage, code: testCode);

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });
    });

    group('Different failure types', () {
      test('should not be equal when types are different', () {
        const serverFailure = ServerFailure(message: testMessage);
        const networkFailure = NetworkFailure(message: testMessage);

        expect(serverFailure, isNot(equals(networkFailure)));
        expect(serverFailure.hashCode, isNot(equals(networkFailure.hashCode)));
      });

      test('should all extend Failure base class', () {
        const serverFailure = ServerFailure(message: testMessage);
        const cacheFailure = CacheFailure(message: testMessage);
        const networkFailure = NetworkFailure(message: testMessage);
        const validationFailure = ValidationFailure(message: testMessage);
        const authFailure = AuthenticationFailure(message: testMessage);
        const permissionFailure = PermissionFailure(message: testMessage);
        const unexpectedFailure = UnexpectedFailure(message: testMessage);

        expect(serverFailure, isA<Failure>());
        expect(cacheFailure, isA<Failure>());
        expect(networkFailure, isA<Failure>());
        expect(validationFailure, isA<Failure>());
        expect(authFailure, isA<Failure>());
        expect(permissionFailure, isA<Failure>());
        expect(unexpectedFailure, isA<Failure>());
      });
    });
  });
}
