// main.dart
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/layout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/core/cubits/auth_user/auth_user_cubit.dart'
    as auth_user;
import 'package:codeshastraxi_overload_oblivion/core/theme/theme.dart';
import 'package:codeshastraxi_overload_oblivion/core/utils/loader.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/pages/landing_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/pages/verification_page.dart';
import 'package:codeshastraxi_overload_oblivion/init_dependencies.dart';
//import 'package:codeshastraxi_overload_oblivion/layout_page.dart';
// import 'package:codeshastraxi_overload_oblivion/map.dart';
// import 'package:codeshastraxi_overload_oblivion/services/notification_service.dart';
// import 'package:codeshastraxi_overload_oblivion/testpage.dart';

/// The main entry point of the Aparna Education application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<auth_user.AuthUserCubit>(
          lazy: false, // Initialize immediately
          create: (context) => serviceLocator<auth_user.AuthUserCubit>(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => serviceLocator<AuthBloc>(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class ProfileBloc {}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a separate widget to initialize the AuthBloc
    return MaterialApp(
      title: 'Trakshak',
      theme: AppTheme.appTheme,
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
    );
  }
}

/// A StatefulWidget responsible for initializing authentication status.
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Dispatch AuthIsUserLoggedIn event once when the app initializes
    context.read<AuthBloc>().add(AuthIsUserLoggedIn());
    // NotificationService.showNotification(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            // Display error message using a SnackBar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<auth_user.AuthUserCubit, auth_user.AuthUserState>(
          builder: (context, authUserState) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthLoading) {
                  return const Loader();
                }

                if (authUserState is auth_user.AuthUserLoggedIn) {
                  if (authUserState.user.emailVerified) {
                    return const LayoutPage();
                  } else {
                    return const VerificationPage();
                  }
                }

                return const LandingPage();
              },
            );
          },
        ),
      ),
    );
  }
}
