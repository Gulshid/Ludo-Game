import 'package:flutter/material.dart';

/// Central place for every color used in the game.
/// Keeping these as named constants (instead of scattering Color(0x...)
/// everywhere) makes it trivial to re-theme the board later.
class AppColors {
  AppColors._();

  // Player colors
  static const Color red = Color(0xFFE53935);
  static const Color green = Color(0xFF43A047);
  static const Color yellow = Color(0xFFFDD835);
  static const Color blue = Color(0xFF1E88E5);

  // Board neutrals
  static const Color boardBackground = Color(0xFFFFFFFF);
  static const Color pathCell = Color(0xFFFFFFFF);
  static const Color cellBorder = Color(0xFFBDBDBD);
  static const Color boardOuterBorder = Color(0xFF212121);

  // UI
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color appBarText = Color(0xFF212121);
  static const Color disabled = Color(0xFF9E9E9E);

  /// Helper to get a player's color from an enum-like string key.
  static Color fromKey(String key) {
    switch (key) {
      case 'red':
        return red;
      case 'green':
        return green;
      case 'yellow':
        return yellow;
      case 'blue':
        return blue;
      default:
        return disabled;
    }
  }
}
