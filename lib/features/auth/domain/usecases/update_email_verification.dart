
import 'package:fpdart/fpdart.dart';
import 'package:codeshastraxi_overload_oblivion/core/error/failure.dart';
import 'package:codeshastraxi_overload_oblivion/core/usecase/usecase.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/repository/auth_repository.dart';


class UpdateEmailVerification implements Usecase<void, NoParams> {
  final AuthRepository repository;
  UpdateEmailVerification(this.repository);
  @override
  Future<Either<Failure,void>> call(NoParams params) {
    return repository.updateEmailVerification();
  }
}


