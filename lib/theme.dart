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

  // ===== TYPOGRAPHY SYSTEM =====
  // Display styles (large headers)
  static TextStyle get displayLarge => GoogleFonts.roboto(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: primaryText,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.roboto(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: primaryText,
    height: 1.2,
  );

  // Headline styles (section titles)
  static TextStyle get headlineLarge => GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: primaryText,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.4,
  );

  // Title styles (card titles, labels)
  static TextStyle get titleLarge => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.4,
  );

  static TextStyle get titleSmall => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Body styles (main content)
  static TextStyle get bodyLarge => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: primaryText,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: primaryText,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: primaryText,
    height: 1.5,
  );

  // Label styles (buttons, badges, small text)
  static TextStyle get labelLarge => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryText,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: primaryText,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.roboto(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: primaryText,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // Caption styles (helper text, timestamps)
  static TextStyle get captionLarge => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: secondaryText,
    height: 1.4,
  );

  static TextStyle get captionSmall => GoogleFonts.roboto(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: secondaryText,
    height: 1.4,
  );

  // ===== THEME DATA =====
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      cardColor: surface,
      textTheme: GoogleFonts.robotoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: primaryText),
          bodyMedium: TextStyle(color: secondaryText),
          labelLarge: TextStyle(color: primaryText, fontWeight: FontWeight.w500),
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
