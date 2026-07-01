import 'package:flutter/material.dart';
import 'widgets/custom_header.dart';
import 'widgets/live_camera_card.dart';
import 'widgets/status_cards.dart';
import 'widgets/feeding_control.dart';
import 'widgets/activity_log.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              CustomHeader(),
              SizedBox(height: 8),
              LiveCameraCard(),
              SizedBox(height: 12),
              StatusCardsSection(),
              SizedBox(height: 16),
              FeedingControlPanel(),
              SizedBox(height: 20),
              ActivityLogSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

