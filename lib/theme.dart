import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. CONSOLIDATED COLOR SYSTEM (Source of Truth)
  // Using Teal as the primary accent for a more aquatic, modern feel.
  static const Color accent = Color(0xFF5DCAA5); 
  static const Color background = Color(0xFF0A1014);   // Darkest layer
  static const Color surface = Color(0xFF121B22);      // Mid-layer for cards
  static const Color surfaceLight = Color(0xFF1A2630); // Lighter layer for interactive elements/pop
  
  static const Color primaryText = Color(0xFFF0F2F5);
  static const Color secondaryText = Color(0xFF8A99A8);
  
  // Semantic colors now use the brand accent for cohesion
  static const Color statusOnline = accent;
  static const Color warning = Color(0xFFFFA940);
  static const Color error = Color(0xFFFF5252);
  static const Color live = Color(0xFFF04438);

  // 2. BORDER RADIUS SYSTEM
  static const double radiusCard = 14.0;
  static const double radiusButton = 12.0;
  static const double radiusPill = 10.0;
  static const double radiusInput = 10.0;
  static const double radiusSmall = 8.0;

  // ===== TYPOGRAPHY SYSTEM =====
  // No major changes, but ensuring it works with the new palette.
  
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: primaryText,
    letterSpacing: -1,
  );

  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: primaryText,
    letterSpacing: -0.5,
  );

  static TextStyle get displaySmall => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: primaryText,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle get titleMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle get titleSmall => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: secondaryText, // Use secondary for section headers
    letterSpacing: 0.8,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: primaryText,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryText,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: secondaryText,
  );

  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryText,
  );

  static TextStyle get labelMedium => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600, // Bolder for labels
    color: primaryText,
  );

  // ===== THEME DATA =====
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: Colors.white.withAlpha((255 * 0.05).round()), width: 1),
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: primaryText),
          bodyMedium: TextStyle(color: secondaryText),
          labelLarge: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent, // No more cyan
        surface: surface,
        onSurface: primaryText,
      ),
      useMaterial3: true,
    );
  }
}
