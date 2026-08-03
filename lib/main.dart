import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'providers/demo_mode_provider.dart';
import 'providers/theme_provider.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable persistence for Realtime Database so data is available offline
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    // Optional: set cache size (default is 1 MB, you can increase)
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10 MB
  } catch (e) {
    // Firebase already initialized, continue
  }

  runApp(
    const ProviderScope(
      child: AquaFeedApp(),
    ),
  );
}

class AquaFeedApp extends ConsumerWidget {
  const AquaFeedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Muat status demo mode dari penyimpanan lokal
    ref.read(demoModeProvider.notifier).loadDemoMode();

    final activeTheme = ref.watch(themeProvider);

    return MaterialApp(
      key: ValueKey(activeTheme.name), // Force full app rebuild when theme changes
      title: 'AquaFeed',
      debugShowCheckedModeBanner: false,
      theme: activeTheme.themeData,
      home: const HomeScreen(),
    );
  }
}