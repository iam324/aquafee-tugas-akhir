import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'widgets/custom_header.dart';
import 'widgets/live_camera_card.dart';
import 'widgets/feeding_control.dart';
import 'widgets/schedule_card.dart';
import 'widgets/food_detection_panel.dart';
import 'widgets/activity_log.dart';
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

  double _pipX = 16.0;
  double _pipY = 24.0;
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _onScroll() {
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
            backgroundColor: AppTheme.colors.statusOnline,
            textColor: Colors.black,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    });

    final streamUrl = ref.watch(streamUrlProvider);
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
                  // Pause kamera utama saat floating player aktif
                  LiveCameraCard(isStreamPaused: isMiniActive),
                  const SizedBox(height: 12),
                  const FoodDetectionPanel(),
                  const SizedBox(height: 12),
                  const FeedingControlPanel(),
                  const SizedBox(height: 12),
                  const ScheduleView(),
                  const SizedBox(height: 16),
                  const ActivityLogSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // --- YOUTUBE-STYLE FLOATING MINI PLAYER (TRULY LIVE) ---
            if (isMiniActive)
              Positioned(
                bottom: _pipY,
                right: _pipX,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _pipX -= details.delta.dx;
                      _pipY -= details.delta.dy;
                      // Batasi agar tidak keluar layar
                      final size = MediaQuery.of(context).size;
                      _pipX = _pipX.clamp(0.0, size.width - 180);
                      _pipY = _pipY.clamp(0.0, size.height - 140);
                    });
                  },
                  onTap: _scrollToTop,
                  child: Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.colors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.colors.accent.withAlpha((255 * 0.6).round()),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.6).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppTheme.colors.accent.withAlpha((255 * 0.1).round()),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.5),
                      child: Stack(
                        children: [
                          // Stream Video LIVE (mengambil alih koneksi dari kamera utama)
                          Center(
                            child: Mjpeg(
                              isLive: true,
                              stream: streamUrl,
                              error: (context, error, stack) => Container(
                                color: AppTheme.colors.surface,
                                child: const Center(
                                  child: Icon(Icons.videocam_off, color: Colors.grey, size: 20),
                                ),
                              ),
                              loading: (context) => Container(
                                color: AppTheme.colors.surface,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.colors.accent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Gradient Overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha((255 * 0.5).round()),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withAlpha((255 * 0.7).round()),
                                  ],
                                  stops: const [0.0, 0.3, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Top: LIVE Badge
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.colors.live,
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
                                    'LIVE',
                                    style: AppTheme.colors.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Top: Close Button
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _isMiniPlayerClosed = true),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha((255 * 0.5).round()),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                              ),
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
