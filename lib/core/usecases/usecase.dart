import '../utils/result.dart';
import '../errors/failures.dart';

abstract class UseCase<TypeOut, Params> {
  Future<Result<TypeOut, Failure>> call(Params params);
}

class NoParams {}
