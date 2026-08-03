import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme.dart';
import 'glass_card.dart';

final GlobalKey<LiveCameraCardState> liveCameraKey = GlobalKey<LiveCameraCardState>();

/// Provider untuk stream URL (shared antara main card dan floating player)
final streamUrlProvider = StateProvider<String>((ref) => 'http://10.184.111.136:81/stream');

class LiveCameraCard extends ConsumerStatefulWidget {
  final bool isStreamPaused;
  LiveCameraCard({Key? key, this.isStreamPaused = false}) : super(key: key ?? liveCameraKey);

  @override
  ConsumerState<LiveCameraCard> createState() => LiveCameraCardState();
}

class LiveCameraCardState extends ConsumerState<LiveCameraCard> {
  bool _isLive = true;
  String _streamUrl = 'http://10.184.111.136:81/stream';
  StreamSubscription? _firebaseUrlSub;

  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
    _listenFirebaseUrl();
  }

  Future<void> _loadSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('esp32_stream_url');
      if (saved != null && saved.isNotEmpty) {
        setState(() => _streamUrl = saved);
        ref.read(streamUrlProvider.notifier).state = saved;
      }
    } catch (_) {}
  }

  /// Dengarkan perubahan stream_url dari Firebase (Auto-IP)
  void _listenFirebaseUrl() {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
      ).ref('aquafeed/stream_url');

      _firebaseUrlSub = db.onValue.listen((event) async {
        final value = event.snapshot.value;
        if (value != null && value.toString().isNotEmpty) {
          final newUrl = value.toString();
          if (newUrl != _streamUrl) {
            // Simpan ke SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('esp32_stream_url', newUrl);

            if (mounted) {
              setState(() {
                _streamUrl = newUrl;
                // Restart stream dengan URL baru
                _isLive = false;
              });
              ref.read(streamUrlProvider.notifier).state = newUrl;
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) setState(() => _isLive = true);
              });
            }
          }
        }
      });
    } catch (_) {}
  }

  Future<Uint8List?> getSnapshotBytes() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void refreshStream() {
    setState(() => _isLive = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isLive = true);
    });
  }

  @override
  void dispose() {
    _firebaseUrlSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 240,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // MJPEG Stream Viewer
            Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: widget.isStreamPaused
                    ? Container(
                        color: AppTheme.colors.surface,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_in_picture_alt_rounded,
                                  color: AppTheme.colors.accent.withAlpha((255 * 0.5).round()), size: 32),
                              const SizedBox(height: 8),
                              Text('Sedang tampil di mini player',
                                  style: AppTheme.colors.bodySmall.copyWith(color: AppTheme.colors.secondaryText)),
                            ],
                          ),
                        ),
                      )
                    : Mjpeg(
                        isLive: _isLive,
                        error: (context, error, stack) => _buildErrorState(),
                        loading: (context) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppTheme.colors.accent, strokeWidth: 3),
                              const SizedBox(height: 12),
                              Text('Menghubungkan ke kamera...',
                                  style: AppTheme.colors.bodySmall.copyWith(color: AppTheme.colors.secondaryText)),
                            ],
                          ),
                        ),
                        stream: _streamUrl,
                        timeout: const Duration(seconds: 5),
                      ),
              ),
            ),

            // Overlays
            if (!widget.isStreamPaused) ...[
              _buildStatusBadge(),
              _buildControls(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((255 * 0.55).round()),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _isLive ? AppTheme.colors.live : AppTheme.colors.secondaryText,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isLive)
                    BoxShadow(color: AppTheme.colors.live.withAlpha((255 * 0.5).round()), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _isLive ? 'LIVE' : 'PAUSED',
              style: AppTheme.colors.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Row(
        children: [
          _ControlButton(
            icon: _isLive ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: () => setState(() => _isLive = !_isLive),
          ),
          const SizedBox(width: 8),
          _ControlButton(
            icon: Icons.refresh_rounded,
            onTap: refreshStream,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: AppTheme.colors.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, color: AppTheme.colors.secondaryText.withAlpha((255 * 0.3).round()), size: 36),
          const SizedBox(height: 12),
          Text('Kamera Terputus', style: AppTheme.colors.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Pastikan ESP32 terhubung ke Wi-Fi yang sama',
            style: AppTheme.colors.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionTextButton(
                label: 'Refresh',
                onTap: refreshStream,
              ),
              const SizedBox(width: 12),
              _ActionTextButton(
                label: 'Config',
                onTap: _showChangeUrlDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangeUrlDialog() {
    final controller = TextEditingController(text: _streamUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Stream Configuration', style: AppTheme.colors.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ESP32 Stream URL', style: AppTheme.colors.bodySmall),
            const SizedBox(height: 4),
            Text('IP akan otomatis update dari ESP32',
                style: AppTheme.colors.bodySmall.copyWith(color: AppTheme.colors.accent, fontSize: 11)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: AppTheme.colors.bodyMedium,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.colors.radiusInput),
                  borderSide: BorderSide.none,
                ),
                hintText: 'http://192.168.1.x:81/stream',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTheme.colors.labelLarge.copyWith(color: AppTheme.colors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.colors.radiusButton)),
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('esp32_stream_url', newUrl);
              if (!context.mounted) return;
              setState(() {
                _streamUrl = newUrl;
                _isLive = false;
              });
              ref.read(streamUrlProvider.notifier).state = newUrl;
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 300), () => setState(() => _isLive = true));
            },
            child: const Text('Save & Retry'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((255 * 0.5).round()),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ActionTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionTextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: AppTheme.colors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.colors.radiusPill)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: AppTheme.colors.labelMedium.copyWith(color: AppTheme.colors.primaryText),
      ),
    );
  }
}
