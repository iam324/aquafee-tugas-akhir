import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_detection_provider.dart';
import '../services/food_detection_service.dart';
import '../theme.dart';
import 'glass_card.dart';

class FoodDetectionPanel extends ConsumerWidget {
  const FoodDetectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionState = ref.watch(foodDetectionProvider);

    IconData icon;
    Color color;
    String statusText;

    // Map status sisa pakan ke warna dan icon
    switch (detectionState.lastResult.status) {
      case FoodResidualStatus.empty:
        icon = Icons.check_circle_outline;
        color = const Color(0xFF10B981); // Green
        statusText = detectionState.lastResult.statusLabel;
        break;
      case FoodResidualStatus.low:
        icon = Icons.info_outline_rounded;
        color = const Color(0xFF3B82F6); // Blue
        statusText = detectionState.lastResult.statusLabel;
        break;
      case FoodResidualStatus.moderate:
        icon = Icons.warning_amber_rounded;
        color = const Color(0xFFF59E0B); // Orange
        statusText = detectionState.lastResult.statusLabel;
        break;
      case FoodResidualStatus.high:
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFEF4444); // Red
        statusText = detectionState.lastResult.statusLabel;
        break;
      case FoodResidualStatus.unknown:
        icon = Icons.help_outline_rounded;
        color = AppTheme.colors.secondaryText;
        statusText = 'Belum Dipindai';
    }

    // Jika sedang analyzing, ganti icon dan warna
    if (detectionState.isAnalyzing) {
      color = const Color(0xFF3B82F6); // Blue
      icon = Icons.analytics_outlined;
    }

    // Jika error
    if (detectionState.errorMessage != null) {
      color = const Color(0xFFEF4444); // Red
      icon = Icons.error_outline;
    }

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: detectionState.isAnalyzing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Deteksi Sisa Pakan',
                    style: AppTheme.colors.labelMedium.copyWith(
                      color: AppTheme.colors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: AppTheme.colors.titleMedium.copyWith(
                      color: detectionState.errorMessage != null
                          ? Colors.red
                          : AppTheme.colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Teks hitung mundur (countdown)
                  Text(
                    detectionState.statusMessage,
                    style: AppTheme.colors.bodySmall.copyWith(
                      color: AppTheme.colors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Tombol manual trigger
            IconButton(
              onPressed: detectionState.isAnalyzing
                  ? null
                  : () => ref.read(foodDetectionProvider.notifier).detectNow(),
              icon: Icon(
                Icons.refresh_rounded,
                color: detectionState.isAnalyzing
                    ? AppTheme.colors.secondaryText.withAlpha((255 * 0.3).round())
                    : AppTheme.colors.accent,
              ),
              tooltip: 'Deteksi sekarang',
            ),
          ],
        ),
      ),
    );
  }
}
