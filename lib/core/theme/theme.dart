import 'package:flutter/material.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';

class AppTheme {
  static final appTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Pallete.primaryColor,
      brightness: Brightness.light,
      primary: Pallete.primaryColor,
      secondary: Pallete.secondaryColor,
      error: Pallete.errorColor,
      background: Pallete.backgroundColor,
    ),
    scaffoldBackgroundColor: Pallete.backgroundColor,
    fontFamily: 'Poppins',
    useMaterial3: true,

    // Card theme with elevation and rounded corners
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Pallete.whiteColor,
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Pallete.whiteColor,
        backgroundColor: Pallete.primaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pallete.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Pallete.primaryColor, width: 1.5),
      ),
    ),

    // Text theme with Poppins
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: Pallete.primaryColor,
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
    ),

    // AppBar with primary color and no elevation
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Pallete.primaryColor,
      foregroundColor: Pallete.whiteColor,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: Pallete.whiteColor,
      ),
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Pallete.whiteColor,
      contentPadding: const EdgeInsets.all(16),
      hintStyle: TextStyle(color: Pallete.greyColor.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Pallete.greyColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Pallete.greyColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Pallete.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Pallete.errorColor),
      ),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: Pallete.primaryColor.withOpacity(0.1),
      labelStyle: const TextStyle(color: Pallete.primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Pallete.whiteColor,
      selectedItemColor: Pallete.primaryColor,
      unselectedItemColor: Pallete.greyColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Legacy input decoration for specific uses
  static final inputDecoration = InputDecoration(
    contentPadding: const EdgeInsets.all(15),
    filled: true,
    fillColor: Pallete.whiteColor,
    hintStyle: TextStyle(color: Pallete.greyColor.withOpacity(0.7)),
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Pallete.inactiveColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Pallete.primaryColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide:
          BorderSide(color: Pallete.greyColor.withOpacity(0.3), width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
