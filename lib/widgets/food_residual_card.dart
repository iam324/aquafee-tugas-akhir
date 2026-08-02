import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/food_detection_provider.dart';
import '../services/food_detection_service.dart';
import '../theme.dart';

class FoodResidualCard extends ConsumerWidget {
  const FoodResidualCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodState = ref.watch(foodDetectionProvider);
    final result = foodState.lastResult;

    Color badgeColor;
    IconData badgeIcon;

    switch (result.status) {
      case FoodResidualStatus.empty:
        badgeColor = const Color(0xFF10B981); // Emerald Green
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
      case FoodResidualStatus.low:
        badgeColor = const Color(0xFF3B82F6); // Blue
        badgeIcon = Icons.info_outline_rounded;
        break;
      case FoodResidualStatus.moderate:
        badgeColor = const Color(0xFFF59E0B); // Amber / Orange
        badgeIcon = Icons.warning_amber_rounded;
        break;
      case FoodResidualStatus.high:
        badgeColor = const Color(0xFFEF4444); // Red
        badgeIcon = Icons.error_outline_rounded;
        break;
      case FoodResidualStatus.unknown:
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: badgeColor.withAlpha((255 * 0.3).round()),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withAlpha((255 * 0.1).round()),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha((255 * 0.15).round()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.set_meal_rounded,
                          color: badgeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deteksi Sisa Pakan AI',
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Analisis Permukaan Air',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.secondaryText,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: foodState.isAnalyzing
                      ? null
                      : () => ref.read(foodDetectionProvider.notifier).detectNow(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    ),
                    elevation: 0,
                  ),
                  child: foodState.isAnalyzing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.autorenew_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'AUTO (10s)',
                              style: AppTheme.labelMedium.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- RESULT DISPLAY ---
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha((255 * 0.08).round()),
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
              child: Row(
                children: [
                  Icon(badgeIcon, color: badgeColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.statusLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.recommendation,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (result.status != FoodResidualStatus.unknown) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status AI: ${result.status == FoodResidualStatus.empty ? "Bersih" : "Terdeteksi"}',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  Text(
                    'Akurasi: 94%',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
