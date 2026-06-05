import 'package:flutter/material.dart';
import 'widgets/custom_header.dart';
import 'widgets/live_camera_card.dart';
import 'widgets/status_cards.dart';
import 'widgets/feeding_control.dart';
import 'widgets/activity_log.dart';
import 'screens/analytics_screen.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomHeader(),
              LiveCameraCard(),
              StatusCardsSection(),
              FeedingControlPanel(),
              _buildAnalyticsButton(context),
              ActivityLogSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AnalyticsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.bar_chart_rounded, size: 20),
          label: const Text(
            'Lihat Analytics & Grafik',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.accent, width: 1),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
