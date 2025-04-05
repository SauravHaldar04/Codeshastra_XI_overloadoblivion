import 'package:flutter/material.dart';

class Pallete {
  static const Color backgroundColor =
      Color.fromARGB(255, 245, 247, 250); // Light background for clean look
  static const Color primaryColor =
      Color(0xFF3B82F6); // Modern blue as primary color
  static const Color secondaryColor =
      Color(0xFF10B981); // Fresh green as secondary color

  static const Color inactiveColor =
      Color(0xFFE5E7EB); // Light grey for inactive elements
  static const Color whiteColor = Colors.white; // White color for contrast
  static const Color greyColor =
      Color(0xFF64748B); // Blue grey for subtle text/icons
  static const Color errorColor =
      Color(0xFFEF4444); // Bright red for error states
  static const Color transparentColor = Colors.transparent;

  static const Color inactiveSeekColor =
      Colors.white38; // Inactive state for seekbars/sliders

  // Additional brand colors
  static const Color accentColor =
      Color(0xFFF59E0B); // Amber accent for highlights
  static const Color successColor =
      Color(0xFF22C55E); // Green for success states
}
