
import 'package:fpdart/fpdart.dart';
import 'package:codeshastraxi_overload_oblivion/core/error/failure.dart';
import 'package:codeshastraxi_overload_oblivion/core/usecase/usecase.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/repository/auth_repository.dart';


class VerifyUserEmail implements Usecase<void,NoParams> {
  final AuthRepository authRepository;
  const VerifyUserEmail(this.authRepository);
  @override
  Future<Either<Failure,bool>> call(NoParams params) async{
    return authRepository.verifyEmail();
  }
}
