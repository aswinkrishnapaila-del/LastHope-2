import '../errors/failures.dart';

sealed class Result<S, E extends Failure> {
  const Result();
}

class Success<S, E extends Failure> extends Result<S, E> {
  final S value;
  const Success(this.value);
}

class Error<S, E extends Failure> extends Result<S, E> {
  final E failure;
  const Error(this.failure);
}
