
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:codeshastraxi_overload_oblivion/core/error/failure.dart';
import 'package:codeshastraxi_overload_oblivion/core/usecase/usecase.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/repository/auth_repository.dart';

class GetFirebaseAuth implements Usecase<FirebaseAuth, NoParams> {
  final AuthRepository repository;

  GetFirebaseAuth(this.repository);

  @override
  Future<Either<Failure,FirebaseAuth>> call(NoParams params) async {
    return await repository.getFirebaseAuth();
  }
}