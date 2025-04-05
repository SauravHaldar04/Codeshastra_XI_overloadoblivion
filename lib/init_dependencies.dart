import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:logger/logger.dart';
import 'package:codeshastraxi_overload_oblivion/core/cubits/auth_user/auth_user_cubit.dart';
import 'package:codeshastraxi_overload_oblivion/core/network/check_internet_connection.dart';
import 'package:codeshastraxi_overload_oblivion/core/network/api_service.dart';
import 'package:codeshastraxi_overload_oblivion/core/usecase/current_user.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/data/datasources/auth_remote_datasources.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/repository/auth_repository.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/usecases/get_firebase_auth.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/usecases/google_login.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/usecases/is_user_email_verified.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/usecases/update_email_verification.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/usecases/user_login.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/usecases/user_signup.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/domain/usecases/verify_user_email.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/cubit/space_optimization_cubit.dart';
//import 'package:codeshastraxi_overload_oblivion/services/notification_service.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase instances
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final Logger logger = Logger();

  serviceLocator.registerSingleton<GoogleSignIn>(googleSignIn);
  serviceLocator.registerSingleton<FirebaseAuth>(firebaseAuth);
  serviceLocator.registerSingleton<FirebaseFirestore>(firebaseFirestore);
  serviceLocator.registerSingleton<Logger>(logger);
  serviceLocator.registerFactory(() => InternetConnection());
  serviceLocator.registerFactory<CheckInternetConnection>(
      () => CheckInternetConnectionImpl(
            serviceLocator(),
          ));
  
  // Register API Service
  serviceLocator.registerLazySingleton<ApiService>(() => ApiService());
  
  // Register SpaceOptimizationCubit
  serviceLocator.registerFactory<SpaceOptimizationCubit>(
    () => SpaceOptimizationCubit()
  );

  // Initialize AuthUserCubit with Firebase Auth
  serviceLocator.registerLazySingleton<AuthUserCubit>(
      () => AuthUserCubit(serviceLocator<FirebaseAuth>()));

  _initAuth();
}

class DefaultFirebaseOptions {
  static var currentPlatform;
}

void _initAuth() {
  serviceLocator
    ..registerFactory<AuthRemoteDataSources>(
      () => AuthRemoteDataSourcesImpl(
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
        serviceLocator(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(
        serviceLocator(),
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserSignup(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UserLogin(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GoogleLogin(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => CurrentUser(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => VerifyUserEmail(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => IsUserEmailVerified(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => UpdateEmailVerification(
        serviceLocator(),
      ),
    )
    ..registerFactory(
      () => GetFirebaseAuth(
        serviceLocator(),
      ),
    )
    ..registerFactory(() => AuthBloc(
          updateEmailVerification: serviceLocator(),
          logger: serviceLocator(),
          userSignup: serviceLocator(),
          userLogin: serviceLocator(),
          currentUser: serviceLocator(),
          authUserCubit: serviceLocator(),
          googleSignIn: serviceLocator(),
          verifyUserEmail: serviceLocator(),
          getFirebaseAuth: serviceLocator(),
          isUserEmailVerified: serviceLocator(),
        ));
}
