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
  String _streamUrl = 'http://10.184.111.136:81/stream'; // default


  // snapshot key
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  @override
  void dispose() {
    super.dispose();
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
      final ui.Image image = await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(pngBytes),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close', style: AppTheme.labelMedium),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surface, width: 2),
      ),
      child: Stack(
        children: [
          // MJPEG Stream Viewer wrapped in RepaintBoundary for snapshot
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Mjpeg(
                  isLive: _isLive,
                  error: (context, error, stack) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Kamera Terputus',
                          style: AppTheme.titleSmall.copyWith(color: Colors.white70),
                        ),
                        Text(
                          'Pastikan ESP32 Menyala',
                          style: AppTheme.captionSmall.copyWith(color: Colors.white54),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: AppTheme.captionSmall.copyWith(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                // manual retry
                                setState(() {
                                  _isLive = false;
                                });
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  setState(() {
                                    _isLive = true;
                                  });
                                });
                              },
                              child: Text('Retry', style: AppTheme.labelMedium),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _showChangeUrlDialog(),
                              child: Text('Change URL', style: AppTheme.labelMedium),
                            ),
                          ],
                        ),
                      ],
                    );
                  },

                  loading: (context) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                  stream: _streamUrl,
                ),
              ),
            ),
          ),

          // Controls: Retry/Play and Snapshot
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  tooltip: _isLive ? 'Pause stream' : 'Play stream',
                  icon: Icon(_isLive ? Icons.pause_circle_outline : Icons.play_circle_outline, color: Colors.white, size: 24),
                  onPressed: () {
                    setState(() {
                      _isLive = !_isLive;
                    });
                  },
                ),
                IconButton(
                  tooltip: 'Snapshot',
                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22),
                  onPressed: () async {
                    await _takeSnapshot();
                  },
                ),
              ],
            ),
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
        title: Text('Stream URL', style: AppTheme.titleMedium),
        content: TextField(
          controller: controller,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintStyle: AppTheme.bodySmall,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTheme.labelMedium),
          ),
          TextButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('esp32_stream_url', newUrl);
              } catch (_) {}

              if (!context.mounted) return;

              setState(() {
                _streamUrl = newUrl;
                _isLive = false;
              });
              Navigator.of(context).pop();
              Future.delayed(const Duration(milliseconds: 200), () {
                setState(() {
                  _isLive = true;
                });
              });
            },
            child: Text('Save', style: AppTheme.labelMedium.copyWith(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}
