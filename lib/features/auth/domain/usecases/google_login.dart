
import 'package:fpdart/fpdart.dart';
import 'package:codeshastraxi_overload_oblivion/core/entities/user_entity.dart';
import 'package:codeshastraxi_overload_oblivion/core/error/failure.dart';
import 'package:codeshastraxi_overload_oblivion/core/usecase/usecase.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/repository/auth_repository.dart';


class GoogleLogin implements Usecase<User,NoParams>{
  final AuthRepository repository;

  GoogleLogin(this.repository);

  @override
  Future<Either<Failure,User>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}