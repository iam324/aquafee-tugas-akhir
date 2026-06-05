import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';
import '../theme.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logState = ref.watch(logProvider);
    final logs = logState.logs;
    final isLoading = logState.isLoading;
    final error = logState.error;

    // Group logs by date
    final groupedLogs = _groupLogsByDate(logs);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Semua History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error != null)
              _buildErrorState(error)
            else if (isLoading && logs.isEmpty)
              _buildLoadingState()
            else if (logs.isEmpty)
              _buildEmptyState()
            else
              _buildGroupedLogs(groupedLogs, context, ref),
          ],
        ),
      ),
    );
  }

  Map<String, List<ActivityLog>> _groupLogsByDate(List<ActivityLog> logs) {
    final grouped = <String, List<ActivityLog>>{};
    final today = DateTime.now();

    for (final log in logs) {
      final logDate = log.timestamp;
      String dateKey;

      if (_isSameDay(logDate, today)) {
        dateKey = 'Hari Ini';
      } else if (_isSameDay(logDate, today.subtract(const Duration(days: 1)))) {
        dateKey = 'Kemarin';
      } else {
        // Format: "Jum, 5 Juni 2026"
        dateKey = _formatDateLabel(logDate);
      }

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(log);
    }

    return grouped;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateLabel(DateTime date) {
    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${dayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Terjadi Kesalahan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.history, size: 64, color: AppTheme.secondaryText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mulai beri makan untuk lihat riwayat aktivitas',
            style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedLogs(
    Map<String, List<ActivityLog>> groupedLogs,
    BuildContext context,
    WidgetRef ref,
  ) {
    final sortedKeys = _sortDateKeys(groupedLogs.keys.toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedKeys.map((dateKey) {
        final logsForDate = groupedLogs[dateKey]!;
        return _buildDateSection(dateKey, logsForDate, context, ref);
      }).toList(),
    );
  }

  List<String> _sortDateKeys(List<String> keys) {
    // Priority order: Hari Ini, Kemarin, then by date
    final priority = {'Hari Ini': 0, 'Kemarin': 1};
    keys.sort((a, b) {
      final aPriority = priority[a] ?? 2;
      final bPriority = priority[b] ?? 2;
      return aPriority.compareTo(bPriority);
    });
    return keys;
  }

  Widget _buildDateSection(
    String dateKey,
    List<ActivityLog> logs,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${logs.length} item',
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.accent),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            final isSuccess = log.type == LogType.success;

            return Dismissible(
              key: Key(log.id ?? '$dateKey$index'),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBg, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: isSuccess ? AppTheme.success : AppTheme.warning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.title,
                            style: AppTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            log.time,
                            style: AppTheme.captionSmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            isSuccess ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.status,
                        style: AppTheme.labelSmall.copyWith(
                          color: isSuccess ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
