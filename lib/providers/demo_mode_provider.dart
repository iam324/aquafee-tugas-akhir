import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk menyimpan status Demo Mode
/// Demo Mode memungkinkan aplikasi tetap berfungsi
/// (memberi pakan, mencatat log) meskipun ESP32 offline.
class DemoModeNotifier extends StateNotifier<bool> {
  DemoModeNotifier() : super(false);

  /// Muat status demo mode dari penyimpanan lokal
  Future<void> loadDemoMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool('demo_mode_enabled') ?? false;
    } catch (e) {
      state = false;
    }
  }

  /// Aktifkan / Nonaktifkan demo mode
  Future<void> toggleDemoMode() async {
    try {
      state = !state;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('demo_mode_enabled', state);
    } catch (e) {
      // Gagal menyimpan pengaturan demo mode
    }
  }

  /// Set demo mode ke nilai tertentu
  Future<void> setDemoMode(bool value) async {
    try {
      state = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('demo_mode_enabled', value);
    } catch (e) {
      // Gagal menyimpan pengaturan demo mode
    }
  }
}

final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  return DemoModeNotifier();
});
