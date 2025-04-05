import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/layout_page.dart';
//import 'package:codeshastraxi_overload_oblivion/layout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';
import 'package:codeshastraxi_overload_oblivion/core/utils/snackbar.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:codeshastraxi_overload_oblivion/layout_page.dart';
// import 'package:codeshastraxi_overload_oblivion/map.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
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
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Positioned.fill(
                  child: Image.asset(
                    'assets/images/landing.gif',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Content Container
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo or Header Image

                        const SizedBox(height: 20),
                        // Title Section
                        const Text(
                          "Verify Your Email",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Pallete.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "A verification link will be sent to your email address. Please verify your email to continue.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Pallete.greyColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        // Verify Email Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    context
                                        .read<AuthBloc>()
                                        .add(AuthEmailVerification());
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Pallete.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: state is AuthLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Verify Email",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Resend Email Button
                        TextButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthEmailVerification());
                                },
                          child: const Text(
                            "Resend Verification Email",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Pallete.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Footer Section
                      ],
                    ),
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
