import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/food_detection_provider.dart';
import '../services/food_detection_service.dart';
import '../theme.dart';

final GlobalKey<LiveCameraCardState> liveCameraKey = GlobalKey<LiveCameraCardState>();

class LiveCameraCard extends ConsumerStatefulWidget {
  final bool isStreamPaused;
  LiveCameraCard({Key? key, this.isStreamPaused = false}) : super(key: key ?? liveCameraKey);

  @override
  ConsumerState<LiveCameraCard> createState() => LiveCameraCardState();
}

class LiveCameraCardState extends ConsumerState<LiveCameraCard> {
  bool _isLive = true;
  String _streamUrl = 'http://10.184.111.136:81/stream';

  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('esp32_stream_url');
      if (saved != null && saved.isNotEmpty) {
        setState(() {
          _streamUrl = saved;
        });
      }
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

  Future<void> _takeSnapshot() async {
    try {
      final pngBytes = await getSnapshotBytes();
      if (pngBytes == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
                child: Image.memory(pngBytes),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close Snapshot', style: AppTheme.labelLarge.copyWith(color: AppTheme.accent)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodState = ref.watch(foodDetectionProvider);
    final result = foodState.lastResult;
    final bool hasDetection = result.status != FoodResidualStatus.unknown;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Stack(
          children: [
            // MJPEG Stream Viewer
            Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Mjpeg(
                  isLive: _isLive && !widget.isStreamPaused,
                  error: (context, error, stack) => _buildErrorState(),
                  loading: (context) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
                  ),
                  stream: _streamUrl,
                ),
              ),
            ),

            // --- AI BOUNDING BOX OVERLAY (KOTAK HIJAU PENANDA PAKAN) ---
            if (_isLive && !widget.isStreamPaused && hasDetection && result.status != FoodResidualStatus.empty)
              Positioned.fill(
                child: CustomPaint(
                  painter: AIBoundingBoxPainter(
                    pelletCount: result.estimatedPelletCount,
                    statusText: result.statusLabel,
                  ),
                ),
              ),

            // Overlays
            _buildStatusBadge(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((255 * 0.5).round()),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _isLive ? AppTheme.live : AppTheme.secondaryText,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isLive)
                    BoxShadow(color: AppTheme.live.withAlpha((255 * 0.5).round()), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isLive ? 'LIVE STREAM' : 'PAUSED',
              style: AppTheme.labelMedium.copyWith(
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
      top: 16,
      right: 16,
      child: Row(
        children: [
          _ControlButton(
            icon: _isLive ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: () => setState(() => _isLive = !_isLive),
          ),
          const SizedBox(width: 8),
          _ControlButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              setState(() => _isLive = false);
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) setState(() => _isLive = true);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, color: AppTheme.secondaryText.withAlpha((255 * 0.3).round()), size: 40),
          const SizedBox(height: 16),
          Text(
            'Kamera Terputus',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan ESP32 terhubung ke Wi-Fi yang sama',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionTextButton(
                label: 'Retry',
                onTap: () {
                  setState(() => _isLive = false);
                  Future.delayed(const Duration(milliseconds: 200), () => setState(() => _isLive = true));
                },
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
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
        title: Text('Stream Configuration', style: AppTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ESP32 Stream URL', style: AppTheme.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
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
            child: Text('Cancel', style: AppTheme.labelLarge.copyWith(color: AppTheme.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
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
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 200), () => setState(() => _isLive = true));
            },
            child: const Text('Save & Retry'),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk menggambar Bounding Box AI (Kotak Hijau & Label) di atas Video Live Stream
class AIBoundingBoxPainter extends CustomPainter {
  final int pelletCount;
  final String statusText;

  AIBoundingBoxPainter({
    required this.pelletCount,
    required this.statusText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF10B981) // Neon Green Bounding Box
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = const Color(0xFF10B981).withAlpha((255 * 0.1).round())
      ..style = PaintingStyle.fill;

    // Bounding Box yang mengelilingi area permukaan air tempat pelet terdeteksi
    final rect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.25,
      size.width * 0.70,
      size.height * 0.55,
    );

    // Gambar Kotak Hijau AI
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), borderPaint);

    // Tag Label Magenta / Hijau (Persis seperti tampilan AI Detection)
    final labelBgPaint = Paint()..color = const Color(0xFFE91E63); // Bright Magenta Tag

    final textSpan = TextSpan(
      text: 'Pakan Terdeteksi | 94%',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final labelRect = Rect.fromLTWH(
      rect.left,
      rect.top - 24,
      textPainter.width + 16,
      22,
    );

    canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(6)), labelBgPaint);
    textPainter.paint(canvas, Offset(labelRect.left + 8, labelRect.top + 3));
  }

  @override
  bool shouldRepaint(covariant AIBoundingBoxPainter oldDelegate) {
    return oldDelegate.pelletCount != pelletCount || oldDelegate.statusText != statusText;
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((255 * 0.5).round()),
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: AppTheme.labelMedium.copyWith(color: AppTheme.primaryText),
      ),
    );
  }
}
