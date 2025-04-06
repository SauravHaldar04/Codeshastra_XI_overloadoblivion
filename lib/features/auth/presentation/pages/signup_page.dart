import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';
import 'package:codeshastraxi_overload_oblivion/core/utils/loader.dart';
import 'package:codeshastraxi_overload_oblivion/core/utils/snackbar.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/widgets/auth_button.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/widgets/auth_textfield.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cpasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Define slide transition animation
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    cpasswordController.dispose();
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
              Text(
                "Create Account!",
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
              Center(
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
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
                            BlocConsumer<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state is AuthFailure) {
                                  showSnackbar(context, state.message);
                                }
                                if (state is AuthSuccess) {
                                  showSnackbar(
                                      context, "Account created successfully");
                                }
                              },
                              builder: (context, state) {
                                if (state is AuthLoading) {
                                  return const Loader();
                                }
                                return Column(
                                  children: [
                                    AuthTextfield(
                                      controller: firstNameController,
                                      text: 'First Name',
                                    ),
                                    const SizedBox(height: 20),
                                    AuthTextfield(
                                      controller: middleNameController,
                                      text: 'Middle Name',
                                    ),
                                    const SizedBox(height: 20),
                                    AuthTextfield(
                                      controller: lastNameController,
                                      text: 'Last Name',
                                    ),
                                    const SizedBox(height: 20),
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
                                    const SizedBox(height: 20),
                                    AuthTextfield(
                                      controller: cpasswordController,
                                      text: 'Confirm Password',
                                      isPassword: true,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              height: 50,
                              child: AuthButton(
                                text: 'Sign Up',
                                onPressed: () {
                                  context.read<AuthBloc>().add(AuthSignUp(
                                        emailController.text.trim(),
                                        passwordController.text.trim(),
                                        firstNameController.text.trim(),
                                        lastNameController.text.trim(),
                                        middleNameController.text.trim(),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    "Sign In",
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
