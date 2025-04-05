import 'package:flutter/material.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/pages/login_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/pages/signup_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/widgets/auth_button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Image.asset(
                'assets/images/landing_page.png',
                fit: BoxFit.cover, // Ensures the image fills the screen
              ),
            ),
          ),
          // Gradient Overlay for better readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3), // Dark gradient at the top
                    Colors.transparent, // Fades to transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Main Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Welcome Text Section
                  Column(
                    children: [
                      Text(
                        "Trakshak",
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Pallete.whiteColor,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your eyes, even without you",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Spacer(flex: 8),
                  // Buttons Section
                  Column(
                    children: [
                      SizedBox(
                        height: 50,
                        child: AuthButton(
                          text: 'Sign Up',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: AuthButton(
                          text: 'Log In',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          isInverted: true, // Adjusts button style
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
