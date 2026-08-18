import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppThemeColors {
  final String name;
  final bool isDark;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color primaryText;
  final Color secondaryText;
  final Color statusOnline;
  final Color warning;
  final Color error;
  final Color live;

  const AppThemeColors({
    required this.name,
    required this.isDark,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.primaryText,
    required this.secondaryText,
    required this.statusOnline,
    required this.warning,
    required this.error,
    required this.live,
  });

  // Ultra-Premium Border Radius System (Extra Bouncy & Modern)
  final double radiusCard = 28.0; // Very round cards like iOS 17
  final double radiusButton = 20.0;
  final double radiusPill = 32.0;
  final double radiusInput = 18.0;
  final double radiusSmall = 12.0;

  // Ultra-Premium Typography (Outfit with refined tracking & weights)
  TextStyle get displayLarge => GoogleFonts.outfit(fontSize: 38, fontWeight: FontWeight.w900, color: primaryText, letterSpacing: -1.5);
  TextStyle get displayMedium => GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w800, color: primaryText, letterSpacing: -1.0);
  TextStyle get displaySmall => GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: primaryText, letterSpacing: -0.5);
  TextStyle get headlineLarge => GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: primaryText);
  TextStyle get headlineMedium => GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: primaryText);
  TextStyle get titleLarge => GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: primaryText);
  TextStyle get titleMedium => GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText);
  TextStyle get titleSmall => GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: secondaryText, letterSpacing: 1.2);
  TextStyle get bodyLarge => GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: primaryText);
  TextStyle get bodyMedium => GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: secondaryText);
  TextStyle get bodySmall => GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w400, color: secondaryText);
  TextStyle get labelLarge => GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: primaryText);
  TextStyle get labelMedium => GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText);

  ThemeData get themeData {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      fontFamily: GoogleFonts.outfit().fontFamily,
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 12,
        shadowColor: isDark ? Colors.transparent : accent.withAlpha(25), // Elegant glowing shadow
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(
            color: isDark ? Colors.white.withAlpha(10) : accent.withAlpha(20), 
            width: 1.5
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        hourMinuteTextColor: primaryText,
        dialHandColor: accent,
        dialBackgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      colorScheme: isDark 
        ? ColorScheme.dark(primary: accent, secondary: accent, surface: surface, onSurface: primaryText, background: background)
        : ColorScheme.light(primary: accent, secondary: accent, surface: surface, onSurface: primaryText, background: background),
      useMaterial3: true,
    );
  }
}

// THEME 1: Cyber Neon (100x Better Dark Mode)
class TealDarkTheme extends AppThemeColors {
  const TealDarkTheme() : super(
    name: 'Cyber Neon',
    isDark: true,
    accent: const Color(0xFF00BFA5), // Neon Teal (Better contrast for white text)
    background: const Color(0xFF05070A), // Abyss Black
    surface: const Color(0xFF0D1219), // Midnight Blue-Grey
    surfaceLight: const Color(0xFF161E29), // Lighter floating element
    primaryText: const Color(0xFFFFFFFF), // Pure White
    secondaryText: const Color(0xFF8B9CB6), // Metallic Slate
    statusOnline: const Color(0xFF00FF7F), // Neon Spring Green
    warning: const Color(0xFFFFB300), // Glowing Amber
    error: const Color(0xFFFF2A55), // Cyber Red
    live: const Color(0xFFFF0055), // Pulsing Magenta-Red
  );
}

// THEME 2: Sakura Glass (100x Better Pink Light Mode)
class PinkLightTheme extends AppThemeColors {
  const PinkLightTheme() : super(
    name: 'Sakura Glass',
    isDark: false,
    accent: const Color(0xFFFF2A7A), // Punchy Sakura Magenta
    background: const Color(0xFFFCF8FA), // Ultra soft pinkish-pearl
    surface: const Color(0xFFFFFFFF), // Pure White for high contrast
    surfaceLight: const Color(0xFFFFF0F5), // Lavender Blush
    primaryText: const Color(0xFF381D35), // Dark Aubergine (Very readable)
    secondaryText: const Color(0xFF8F748D), // Mauve Grey
    statusOnline: const Color(0xFF00C853), // Vivid Green
    warning: const Color(0xFFFF9100), // Vivid Orange
    error: const Color(0xFFFF1744), // Crimson
    live: const Color(0xFFFF1744), // Crimson
  );
}

// THEME 3: Ocean Glide (100x Better Blue Light Mode)
class OceanLightTheme extends AppThemeColors {
  const OceanLightTheme() : super(
    name: 'Ocean Glide',
    isDark: false,
    accent: const Color(0xFF0066FF), // Hyper Blue (Apple/Stripe style)
    background: const Color(0xFFF2F6FF), // Cool Ice Blue
    surface: const Color(0xFFFFFFFF), // Pure White
    surfaceLight: const Color(0xFFE5EDFF), // Soft Blue Wash
    primaryText: const Color(0xFF0F172A), // Very Dark Slate
    secondaryText: const Color(0xFF64748B), // Slate Grey
    statusOnline: const Color(0xFF06B6D4), // Cyan
    warning: const Color(0xFFF59E0B),
    error: const Color(0xFFEF4444),
    live: const Color(0xFFEF4444),
  );
}

class AppTheme {
  // Current active theme colors. Defaults to Cyber Neon.
  static AppThemeColors colors = const TealDarkTheme();

  static final List<AppThemeColors> availableThemes = [
    const TealDarkTheme(),
    const PinkLightTheme(),
    const OceanLightTheme(),
  ];

  static AppThemeColors getThemeByName(String name) {
    return availableThemes.firstWhere((t) => t.name == name, orElse: () => const TealDarkTheme());
  }
}
