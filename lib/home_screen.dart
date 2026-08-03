import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'widgets/custom_header.dart';
import 'widgets/live_camera_card.dart';
import 'widgets/food_residual_card.dart';
import 'widgets/feeding_control.dart';
import 'widgets/schedule_card.dart';
import 'widgets/activity_log.dart';
import 'providers/food_detection_provider.dart';
import 'providers/log_provider.dart';
import 'theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingCamera = false;
  bool _isMiniPlayerClosed = false;
  String _streamUrl = 'http://10.184.111.136:81/stream';
  
  double _pipX = 16.0;
  double _pipY = 24.0;
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStreamUrl();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadStreamUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('esp32_stream_url');
      if (saved != null && saved.isNotEmpty) {
        setState(() => _streamUrl = saved);
      }
    } catch (_) {}
  }

  void _onScroll() {
    // Tampilkan Floating Mini Player saat scroll melebihi 240px
    if (_scrollController.offset > 240 && !_showFloatingCamera) {
      setState(() {
        _showFloatingCamera = true;
        _isMiniPlayerClosed = false;
      });
    } else if (_scrollController.offset <= 240 && _showFloatingCamera) {
      setState(() => _showFloatingCamera = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LogState>(logProvider, (previous, next) {
      if (previous != null && !previous.isLoading && next.logs.length > previous.logs.length) {
        final newLog = next.logs.first;
        if (newLog.title.toLowerCase().contains('otomatis')) {
          Fluttertoast.showToast(
            msg: 'Berhasil: ${newLog.title}',
            backgroundColor: AppTheme.statusOnline,
            textColor: Colors.black,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    });

    final foodState = ref.watch(foodDetectionProvider);
    final result = foodState.lastResult;
    final bool isMiniActive = _showFloatingCamera && !_isMiniPlayerClosed;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // --- MAIN SCROLL CONTENT ---
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const CustomHeader(),
                  const SizedBox(height: 8),
                  LiveCameraCard(isStreamPaused: isMiniActive),
                  const SizedBox(height: 16),
                  const FoodResidualCard(),
                  const SizedBox(height: 16),
                  const FeedingControlPanel(),
                  const SizedBox(height: 16),
                  const ScheduleView(),
                  const SizedBox(height: 20),
                  const ActivityLogSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // --- YOUTUBE-STYLE FLOATING MINI PLAYER (LIVE VIDEO STREAM) ---
            if (isMiniActive)
              Positioned(
                bottom: _pipY,
                right: _pipX,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _pipX -= details.delta.dx;
                      _pipY -= details.delta.dy;
                    });
                  },
                  onTap: _scrollToTop,
                  child: Container(
                    width: 175,
                    height: 115,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(
                        color: AppTheme.accent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.7).round()),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard - 1.5),
                      child: Stack(
                        children: [
                          // Stream Video Live Asli
                          Center(
                            child: Mjpeg(
                              isLive: true,
                              stream: _streamUrl,
                              error: (context, error, stack) => Container(
                                color: AppTheme.surface,
                                child: const Center(
                                  child: Icon(Icons.videocam_off, color: Colors.grey, size: 24),
                                ),
                              ),
                            ),
                          ),

                          // Gradient Shadow Overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha((255 * 0.6).round()),
                                    Colors.transparent,
                                    Colors.black.withAlpha((255 * 0.75).round()),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Top Badge AI Live
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.live,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI LIVE',
                                    style: AppTheme.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Close Button (Tutup Mini Player)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _isMiniPlayerClosed = true),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha((255 * 0.5).round()),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),

                          // Bottom Title & Tap Guide
                          Positioned(
                            bottom: 6,
                            left: 6,
                            right: 6,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.statusLabel,
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 9),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Tap Perbesar',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: Colors.white.withAlpha((255 * 0.8).round()),
                                        fontSize: 8.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
