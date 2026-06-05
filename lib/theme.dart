import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF09121C);
  static const Color surface = Color(0xFF131F2D);
  static const Color cardBg = Color(0xFF162534);
  static const Color accent = Color(0xFF2CB1FF);
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFF8E9AAF);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color live = Color(0xFFE53935);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      cardColor: surface,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: primaryText),
          bodyMedium: TextStyle(color: secondaryText),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        onSurface: primaryText,
      ),
    );
  }
}
