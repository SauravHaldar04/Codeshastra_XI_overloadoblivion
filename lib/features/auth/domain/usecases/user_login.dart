
import 'package:fpdart/fpdart.dart';
import 'package:codeshastraxi_overload_oblivion/core/entities/user_entity.dart';
import 'package:codeshastraxi_overload_oblivion/core/error/failure.dart';
import 'package:codeshastraxi_overload_oblivion/core/usecase/usecase.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/repository/auth_repository.dart';


class UserLogin implements Usecase<User, UserLoginParams> {
  final AuthRepository repository;

  UserLogin(this.repository);

  @override
  Future<Either<Failure, User>> call(UserLoginParams params) async {
    return await repository.loginWithEmailAndPassword(
        email: params.email, password: params.password);
  }
}

class UserLoginParams {
  final String email;
  final String password;

  UserLoginParams({required this.email, required this.password});
}
