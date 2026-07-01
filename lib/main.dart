import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'theme.dart';
import 'providers/demo_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
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
    
    return MaterialApp(
      title: 'AquaFeed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
