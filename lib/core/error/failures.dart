import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, code, stackTrace];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}
