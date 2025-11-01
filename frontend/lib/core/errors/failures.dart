abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required String message,
    this.statusCode,
  }) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error']) : super(message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Authentication failed']) : super(message);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> errors;

  const ValidationFailure(this.errors) : super('Validation failed');
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'An unexpected error occurred']) : super(message);
}
