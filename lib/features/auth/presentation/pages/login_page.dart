import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/layout_page.dart';
//import 'package:codeshastraxi_overload_oblivion/layout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';
import 'package:codeshastraxi_overload_oblivion/core/utils/loader.dart';
import 'package:codeshastraxi_overload_oblivion/core/utils/snackbar.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/pages/verification_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/widgets/auth_button.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/widgets/auth_textfield.dart';
// import 'package:codeshastraxi_overload_oblivion/layout_page.dart';
// import 'package:codeshastraxi_overload_oblivion/map.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Define the slide transition animation
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start off-screen (from the bottom)
      end: Offset.zero, // Final position (center)
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/landing_page.png',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Central Sliding Container
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Pallete.whiteColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.9),
                        blurRadius: 5,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  "Enter your login details!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Pallete.whiteColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.9),
                        blurRadius: 5,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 237, 237, 237),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 30),
                            BlocConsumer<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state is AuthSuccess) {
                                  showSnackbar(context, "Login Successful");
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        context
                                            .read<AuthBloc>()
                                            .add(AuthIsUserEmailVerified());
                                        return state is AuthEmailVerified
                                            ? const LayoutPage()
                                            : const VerificationPage();
                                      },
                                    ),
                                    (route) => false,
                                  );
                                }
                                if (state is AuthFailure) {
                                  showSnackbar(context, state.message);
                                }
                              },
                              builder: (context, state) {
                                if (state is AuthLoading) {
                                  return const Loader();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AuthTextfield(
                                      controller: emailController,
                                      text: 'Email',
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 20),
                                    AuthTextfield(
                                      controller: passwordController,
                                      text: 'Password',
                                      isPassword: true,
                                    ),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: Pallete.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              height: 50,
                              child: AuthButton(
                                text: 'Log In',
                                onPressed: () {
                                  context.read<AuthBloc>().add(AuthLogIn(
                                        emailController.text.trim(),
                                        passwordController.text.trim(),
                                      ));
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                text: "By continuing you are agreeing to the ",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: "Terms of Service",
                                    style: TextStyle(
                                      color: Pallete.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " and ",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: "Privacy Policy",
                                    style: TextStyle(
                                      color: Pallete.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                SizedBox(
                                  height: 50,
                                  child: AuthButton(
                                    text: '       Continue with Google',
                                    isInverted: true,
                                    onPressed: () {
                                      context
                                          .read<AuthBloc>()
                                          .add(AuthGoogleSignIn());
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 7,
                                  left: 10,
                                  child: Image.asset(
                                    'assets/images/google.png',
                                    height: 35,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    "Sign Up",
                                    style:
                                        TextStyle(color: Pallete.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
