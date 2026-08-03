import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeColors>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeColors> {
  ThemeNotifier() : super(AppTheme.availableThemes.first) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString('app_theme') ?? 'Teal Dark';
      final loadedTheme = AppTheme.getThemeByName(themeName);
      AppTheme.colors = loadedTheme;
      state = loadedTheme;
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeColors theme) async {
    try {
      AppTheme.colors = theme;
      state = theme;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', theme.name);
    } catch (_) {}
  }
}
