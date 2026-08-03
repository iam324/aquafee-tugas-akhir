import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';
import '../screens/history_detail_screen.dart';
import '../theme.dart';
import 'glass_card.dart';

class ActivityLogSection extends ConsumerWidget {
  const ActivityLogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logProvider);
    final logs = logState.logs;
    final isLoading = logState.isLoading;
    final error = logState.error;

    final todayLogs = _getTodayLogs(logs).take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppTheme.colors.accent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'AKTIVITAS HARI INI',
                    style: AppTheme.colors.titleSmall,
                  ),
                ],
              ),
              if (logs.isNotEmpty && !isLoading)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const HistoryDetailScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.colors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.colors.radiusPill),
                      border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
                    ),
                    child: Text(
                      'Semua',
                      style: AppTheme.colors.labelMedium.copyWith(color: AppTheme.colors.primaryText, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (error != null)
            _buildErrorState(error)
          else if (isLoading && logs.isEmpty)
            _buildLoadingState()
          else if (logs.isEmpty)
            _buildEmptyState()
          else if (todayLogs.isEmpty)
            _buildNoTodayLogsState()
          else
            _buildLogsList(todayLogs, context, ref),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<ActivityLog> _getTodayLogs(List<ActivityLog> logs) {
    final today = DateTime.now();
    return logs.where((log) {
      return log.timestamp.year == today.year &&
          log.timestamp.month == today.month &&
          log.timestamp.day == today.day;
    }).toList();
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.colors.error.withAlpha((255 * 0.05).round()),
        borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
        border: Border.all(color: AppTheme.colors.error.withAlpha((255 * 0.1).round())),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.colors.error, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              error,
              style: AppTheme.colors.bodySmall.copyWith(color: AppTheme.colors.error.withAlpha((255 * 0.8).round())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _InfoPlaceholder(
      icon: Icons.history_toggle_off_outlined,
      title: 'Belum Ada History',
      subtitle: 'Aktivitas Anda akan muncul di sini',
    );
  }

  Widget _buildNoTodayLogsState() {
    return _InfoPlaceholder(
      icon: Icons.calendar_today_outlined,
      title: 'Belum Ada Aktivitas',
      subtitle: 'Belum ada pemberian pakan hari ini',
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) => _SkeletonItem()),
    );
  }

  Widget _buildLogsList(List<ActivityLog> logs, BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];
        final isSuccess = log.type == LogType.success;
        final timeFormatted = "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}";

        return Dismissible(
          key: Key(log.id ?? index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: AppTheme.colors.error.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline_rounded, color: AppTheme.colors.error),
          ),
          onDismissed: (_) {
            if (log.id != null) ref.read(logProvider.notifier).deleteLog(log.id!);
          },
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isSuccess ? AppTheme.colors.statusOnline : AppTheme.colors.warning).withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(AppTheme.colors.radiusButton),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_outline_rounded : Icons.priority_high_rounded,
                    color: isSuccess ? AppTheme.colors.statusOnline : AppTheme.colors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.title,
                        style: AppTheme.colors.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeFormatted,
                        style: AppTheme.colors.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.colors.radiusPill),
                  ),
                  child: Text(
                    log.status,
                    style: AppTheme.colors.labelMedium.copyWith(
                      color: isSuccess ? AppTheme.colors.statusOnline : AppTheme.colors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoPlaceholder({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.colors.secondaryText.withAlpha((255 * 0.3).round())),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.colors.titleMedium.copyWith(color: AppTheme.colors.secondaryText)),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTheme.colors.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
        ),
      ),
    );
  }
}
