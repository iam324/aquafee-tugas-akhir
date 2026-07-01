import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

class LiveCameraCard extends StatefulWidget {
  const LiveCameraCard({super.key});

  @override
  State<LiveCameraCard> createState() => _LiveCameraCardState();
}

class _LiveCameraCardState extends State<LiveCameraCard> {
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

  Future<void> _takeSnapshot() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.background, // Use darkest color for the camera feed background
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
                  isLive: _isLive,
                  error: (context, error, stack) => _buildErrorState(),
                  loading: (context) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
                  ),
                  stream: _streamUrl,
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
                boxShadow: [ // Subtle glow for live status
                  if (_isLive)
                    BoxShadow(color: AppTheme.live.withAlpha((255 * 0.5).round()), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isLive ? 'LIVE' : 'PAUSED',
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
            icon: Icons.camera_alt_outlined,
            onTap: _takeSnapshot,
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
              foregroundColor: Colors.black, // Dark text on light accent
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
