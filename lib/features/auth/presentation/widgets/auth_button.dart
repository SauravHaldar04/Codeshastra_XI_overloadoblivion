import 'package:flutter/material.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isInverted;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 3,
        backgroundColor:
            isInverted ? Pallete.whiteColor : Pallete.secondaryColor,
        foregroundColor:
            isInverted ? Pallete.secondaryColor : Pallete.whiteColor,
        minimumSize: const Size(200, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          // side: const BorderSide(
          //   color: Pallete.primaryColor,
          //   width: 3,
          // ),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
            ),
    );
  }
}
