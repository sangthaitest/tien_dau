import 'app_failure.dart';

sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T unwrapOrThrow() {
    return switch (this) {
      Ok(:final value) => value,
      Err(:final failure) => throw StateError(failure.message),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
