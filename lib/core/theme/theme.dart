import 'package:flutter/material.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';

class AppTheme {
  static final appTheme = ThemeData(
    colorSchemeSeed: Pallete.primaryColor, // Uses primary color for theme
    scaffoldBackgroundColor: Pallete.backgroundColor, // Dark background color
    fontFamily: 'Poppins', // Updated to use Nunito
    useMaterial3: true, // To align with Material 3 design
    datePickerTheme: DatePickerThemeData(
      headerForegroundColor: Pallete.primaryColor, // Primary color for header
      backgroundColor:
          Pallete.backgroundColor, // Dark background for date picker
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Pallete.primaryColor, // Primary color for app bar
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white), // White icons for contrast
    ),
  );

  static final inputDecoration = InputDecoration(
    contentPadding: const EdgeInsets.all(15),
    filled: true,
    fillColor: Pallete.whiteColor, // Match ProfilePage text fields
    hintStyle: TextStyle(color: Colors.grey), // Grey hint for consistency
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Pallete.inactiveColor, width: 1.5),
      borderRadius: BorderRadius.circular(30), // Rounded to match button style
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
          color: Pallete.primaryColor, width: 1.5), // White border on focus
      borderRadius: BorderRadius.circular(10),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
          color: Pallete.whiteColor, width: 1.5), // Primary color border
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
