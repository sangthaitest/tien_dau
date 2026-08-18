sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

final class PersistenceFailure extends AppFailure {
  const PersistenceFailure(super.message, {this.cause});
  final Object? cause;
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}
