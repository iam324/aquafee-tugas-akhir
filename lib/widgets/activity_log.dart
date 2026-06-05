import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';
import '../screens/history_detail_screen.dart';
import '../theme.dart';

class ActivityLogSection extends ConsumerWidget {
  const ActivityLogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logProvider);
    final logs = logState.logs;
    final isLoading = logState.isLoading;
    final error = logState.error;

    // Filter hanya hari ini (today's logs)
    final todayLogs = _getTodayLogs(logs).take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HISTORY (Hari Ini)',
                style: AppTheme.titleSmall.copyWith(color: AppTheme.secondaryText),
              ),
              if (logs.isNotEmpty && !isLoading)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HistoryDetailScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Lihat Semua',
                    style: AppTheme.labelSmall.copyWith(color: AppTheme.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: AppTheme.secondaryText.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai beri makan untuk lihat riwayat aktivitas',
            style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoTodayLogsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.today, size: 48, color: AppTheme.secondaryText.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Aktivitas Hari Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai beri makan ikan Anda',
            style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildSkeletonLoader(),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<ActivityLog> logs, BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = logs[index];
        final isSuccess = log.type == LogType.success;

        return Dismissible(
          key: Key(log.id ?? index.toString()),
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            if (log.id != null) {
              ref.read(logProvider.notifier).deleteLog(log.id!);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSuccess ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check : Icons.warning_amber_rounded,
                    color: isSuccess ? AppTheme.success : AppTheme.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.time,
                        style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (isSuccess)
                      const Icon(Icons.check, color: AppTheme.success, size: 14)
                    else
                      const Text('!', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text(
                      log.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSuccess ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
