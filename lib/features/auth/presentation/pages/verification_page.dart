import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/layout_page.dart';
//import 'package:codeshastraxi_overload_oblivion/layout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';
import 'package:codeshastraxi_overload_oblivion/core/utils/snackbar.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/widgets/auth_button.dart';
// import 'package:codeshastraxi_overload_oblivion/layout_page.dart';
// import 'package:codeshastraxi_overload_oblivion/map.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Define the slide transition animation
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start off-screen (from the bottom)
      end: Offset.zero, // Final position (center)
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Define the fade animation
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthEmailVerified) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LayoutPage()),
          );
        } else if (state is AuthFailure) {
          showSnackbar(context, state.message);
        } else if (state is AuthEmailVerificationInProgress) {
          showSnackbar(
              context, 'Verification in progress. Please check your email.');
        }
      },
      builder: (context, state) {
        return Scaffold(
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
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        "Email Verification",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Pallete.whiteColor,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.9),
                              blurRadius: 5,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtitle with animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          "Please verify your email to continue",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Pallete.whiteColor,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.9),
                                blurRadius: 5,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Card Container with animation
                    SlideTransition(
                      position: _offsetAnimation,
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
                        child: Column(
                          children: [
                            // Icon
                            Icon(
                              Icons.mark_email_unread_rounded,
                              size: 80,
                              color: Pallete.primaryColor,
                            ),
                            const SizedBox(height: 20),
                            // Message
                            Text(
                              "We've sent a verification link to your email address.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Pallete.greyColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Click the link in your email to verify your account. If you can't find the email, check your spam folder.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Pallete.greyColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            // Verify Button
                            SizedBox(
                              height: 50,
                              child: AuthButton(
                                text: 'Verify Email',
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                        context
                                            .read<AuthBloc>()
                                            .add(AuthEmailVerification());
                                      },
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Resend Email Text Button
                            TextButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      context
                                          .read<AuthBloc>()
                                          .add(AuthEmailVerification());
                                    },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh,
                                      size: 16, color: Pallete.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Resend Verification Email",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Pallete.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Loading indicator
              if (state is AuthLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Pallete.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
