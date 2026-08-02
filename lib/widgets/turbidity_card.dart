import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/detection_provider.dart';
import '../services/image_analysis_service.dart';
import '../theme.dart';

/// Widget card untuk menampilkan status kekeruhan air secara real-time.
///
/// Menampilkan:
/// - Skor kekeruhan (0-100) dengan progress bar berwarna
/// - Level kekeruhan (Jernih / Normal / Agak Keruh / Keruh / Sangat Keruh)
/// - Detail analisis (kecerahan, rasio hijau, rasio coklat)
/// - Toggle untuk mengaktifkan/menonaktifkan deteksi otomatis
/// - Tombol analisis manual
/// - Banner peringatan jika air keruh
class TurbidityStatusCard extends ConsumerWidget {
  const TurbidityStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turbidity = ref.watch(turbidityProvider);
    final result = turbidity.lastResult;

    return Column(
      children: [
        // Banner peringatan (muncul di atas card jika air keruh)
        if (turbidity.isWarning) _buildWarningBanner(ref),

        // Card utama kekeruhan
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: turbidity.isWarning
                  ? AppTheme.warning.withAlpha((255 * 0.3).round())
                  : Colors.white.withAlpha((255 * 0.05).round()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(ref, turbidity),
              const SizedBox(height: 20),
              _buildMainScore(result, turbidity),
              const SizedBox(height: 16),
              _buildTurbidityBar(result),
              const SizedBox(height: 16),
              if (result.level != TurbidityLevel.unknown)
                _buildAnalysisDetails(result),
              if (result.level != TurbidityLevel.unknown)
                const SizedBox(height: 16),
              _buildActions(ref, turbidity),
            ],
          ),
        ),
      ],
    );
  }

  /// Banner peringatan air keruh
  Widget _buildWarningBanner(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withAlpha((255 * 0.12).round()),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: AppTheme.warning.withAlpha((255 * 0.3).round()),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Air Akuarium Terdeteksi Keruh!',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pertimbangkan ganti air atau bersihkan filter.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.warning.withAlpha((255 * 0.8).round()),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header: Judul + toggle deteksi otomatis
  Widget _buildHeader(WidgetRef ref, TurbidityState turbidity) {
    return Row(
      children: [
        const Icon(Icons.water_drop_rounded, color: AppTheme.accent, size: 18),
        const SizedBox(width: 10),
        Text('KEKERUHAN AIR', style: AppTheme.titleSmall),
        const Spacer(),
        GestureDetector(
          onTap: () => ref.read(turbidityProvider.notifier).toggleDetection(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: turbidity.isEnabled
                  ? AppTheme.accent.withAlpha((255 * 0.15).round())
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(
                color: turbidity.isEnabled
                    ? AppTheme.accent.withAlpha((255 * 0.3).round())
                    : Colors.white.withAlpha((255 * 0.08).round()),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: turbidity.isEnabled
                        ? AppTheme.accent
                        : AppTheme.secondaryText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  turbidity.isEnabled ? 'AKTIF' : 'NONAKTIF',
                  style: AppTheme.labelMedium.copyWith(
                    color: turbidity.isEnabled
                        ? AppTheme.accent
                        : AppTheme.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Skor utama dengan icon level dan label
  Widget _buildMainScore(TurbidityResult result, TurbidityState turbidity) {
    final levelColor = _getLevelColor(result.level);
    final levelIcon = _getLevelIcon(result.level);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Icon berdasarkan level
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: levelColor.withAlpha((255 * 0.12).round()),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
          child: Icon(levelIcon, color: levelColor, size: 24),
        ),
        const SizedBox(width: 16),
        // Skor & label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: result.level == TurbidityLevel.unknown
                          ? '--'
                          : result.turbidityScore.toStringAsFixed(1),
                      style: AppTheme.displaySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: levelColor,
                      ),
                    ),
                    if (result.level != TurbidityLevel.unknown)
                      TextSpan(
                        text: '%',
                        style: AppTheme.bodyMedium.copyWith(
                          color: levelColor.withAlpha((255 * 0.7).round()),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                turbidity.isAnalyzing
                    ? turbidity.statusMessage
                    : turbidity.errorMessage ?? result.statusLabel,
                style: AppTheme.bodySmall.copyWith(
                  color: turbidity.errorMessage != null
                      ? AppTheme.error
                      : AppTheme.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Loading indicator
        if (turbidity.isAnalyzing)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accent,
            ),
          ),
      ],
    );
  }

  /// Progress bar visual kekeruhan (gradient biru → merah)
  Widget _buildTurbidityBar(TurbidityResult result) {
    final score = result.level == TurbidityLevel.unknown
        ? 0.0
        : result.turbidityScore / 100.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Jernih', style: AppTheme.bodySmall.copyWith(fontSize: 10)),
            Text('Sangat Keruh',
                style: AppTheme.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            color: AppTheme.background,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Stack(
              children: [
                // Background gradient (samar)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4FC3F7)
                            .withAlpha((255 * 0.15).round()),
                        const Color(0xFF66BB6A)
                            .withAlpha((255 * 0.15).round()),
                        const Color(0xFFFFA726)
                            .withAlpha((255 * 0.15).round()),
                        const Color(0xFFEF5350)
                            .withAlpha((255 * 0.15).round()),
                      ],
                    ),
                  ),
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: score.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4FC3F7),
                          _getLevelColor(result.level),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusPill),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Detail analisis: brightness, green ratio, brown ratio
  Widget _buildAnalysisDetails(TurbidityResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          _DetailItem(
            icon: Icons.brightness_6_outlined,
            label: 'Kecerahan',
            value: result.avgBrightness.toStringAsFixed(0),
          ),
          _detailDivider(),
          _DetailItem(
            icon: Icons.grass_outlined,
            label: 'Alga',
            value: '${result.greenRatio.toStringAsFixed(1)}%',
            valueColor:
                result.greenRatio > 15 ? AppTheme.warning : null,
          ),
          _detailDivider(),
          _DetailItem(
            icon: Icons.landscape_outlined,
            label: 'Sedimen',
            value: '${result.brownRatio.toStringAsFixed(1)}%',
            valueColor:
                result.brownRatio > 15 ? AppTheme.warning : null,
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withAlpha((255 * 0.06).round()),
    );
  }

  /// Tombol aksi: Analisis Sekarang
  Widget _buildActions(WidgetRef ref, TurbidityState turbidity) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: turbidity.isAnalyzing
            ? null
            : () => ref.read(turbidityProvider.notifier).analyzeNow(),
        icon: Icon(
          turbidity.isAnalyzing
              ? Icons.hourglass_top_rounded
              : Icons.analytics_outlined,
          size: 18,
        ),
        label: Text(
          turbidity.isAnalyzing ? 'MENGANALISIS...' : 'ANALISIS SEKARANG',
          style: AppTheme.labelMedium.copyWith(
            color:
                turbidity.isAnalyzing ? AppTheme.secondaryText : Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              turbidity.isAnalyzing ? AppTheme.surfaceLight : AppTheme.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.surfaceLight,
          disabledForegroundColor: AppTheme.secondaryText,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPER: Warna & Icon berdasarkan level kekeruhan
  // ============================================================

  Color _getLevelColor(TurbidityLevel level) {
    switch (level) {
      case TurbidityLevel.clear:
        return const Color(0xFF4FC3F7); // Biru muda
      case TurbidityLevel.normal:
        return AppTheme.accent;         // Hijau teal
      case TurbidityLevel.slightlyTurbid:
        return const Color(0xFFFFA726); // Oranye
      case TurbidityLevel.turbid:
        return const Color(0xFFFF7043); // Oranye tua
      case TurbidityLevel.veryTurbid:
        return AppTheme.error;          // Merah
      case TurbidityLevel.unknown:
        return AppTheme.secondaryText;
    }
  }

  IconData _getLevelIcon(TurbidityLevel level) {
    switch (level) {
      case TurbidityLevel.clear:
        return Icons.water_drop_outlined;
      case TurbidityLevel.normal:
        return Icons.check_circle_outline_rounded;
      case TurbidityLevel.slightlyTurbid:
        return Icons.info_outline_rounded;
      case TurbidityLevel.turbid:
        return Icons.warning_amber_rounded;
      case TurbidityLevel.veryTurbid:
        return Icons.dangerous_outlined;
      case TurbidityLevel.unknown:
        return Icons.help_outline_rounded;
    }
  }
}

/// Item detail kecil (kecerahan / alga / sedimen)
class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon,
              size: 14,
              color: AppTheme.secondaryText.withAlpha((255 * 0.6).round())),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.labelMedium.copyWith(
              color: valueColor ?? AppTheme.primaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
