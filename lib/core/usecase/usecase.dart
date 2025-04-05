
import 'package:fpdart/fpdart.dart';
import 'package:codeshastraxi_overload_oblivion/core/error/failure.dart';

abstract interface class Usecase<SuccessType,Params>{
  Future<Either<Failure,SuccessType>> call(Params params);
}
class NoParams{}