import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../screens/analytics_screen.dart';
import '../theme.dart';

class AnalyticsSummaryCard extends ConsumerWidget {
  const AnalyticsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINGKASAN MINGGU INI',
            style: AppTheme.titleSmall.copyWith(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBg, width: 1),
            ),
            child: Column(
              children: [
                // Top Row - 2 metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.weekend,
                        label: 'Total Minggu',
                        value: '${analytics.totalThisWeek.toInt()}g',
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.show_chart,
                        label: 'Rata-rata',
                        value: '${analytics.averagePerDay.toStringAsFixed(1)}g',
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom Row - Max consumption
                _buildMetricItem(
                  icon: Icons.trending_up,
                  label: 'Puncak Konsumsi',
                  value: '${analytics.maxConsumption.toInt()}g',
                  color: AppTheme.warning,
                  isFullWidth: true,
                ),
                const SizedBox(height: 12),
                // Button View Details
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: Text(
                      'Lihat Analytics Lengkap',
                      style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent.withOpacity(0.2),
                      foregroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.captionSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.titleLarge.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
