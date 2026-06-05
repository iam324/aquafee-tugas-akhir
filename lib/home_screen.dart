import 'package:flutter/material.dart';
import 'widgets/custom_header.dart';
import 'widgets/live_camera_card.dart';
import 'widgets/status_cards.dart';
import 'widgets/feeding_control.dart';
import 'widgets/analytics_summary_card.dart';
import 'widgets/activity_log.dart';

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
              AnalyticsSummaryCard(),
              ActivityLogSection(),
            ],
          ),
        ),
      ),
    );
  }
}

