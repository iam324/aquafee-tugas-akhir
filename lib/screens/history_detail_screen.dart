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

    final groupedLogs = _groupLogsByDate(logs);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _BackBtn(onTap: () => Navigator.of(context).pop()),
        title: Text('Activity History', style: AppTheme.headlineMedium),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withAlpha((255 * 0.05).round()),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.error.withAlpha((255 * 0.1).round())),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 32),
          const SizedBox(height: 16),
          Text('Terjadi Kesalahan', style: AppTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: AppTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(Icons.history_toggle_off_outlined, size: 64, color: AppTheme.secondaryText.withAlpha((255 * 0.2).round())),
          const SizedBox(height: 24),
          Text('No History Found', style: AppTheme.headlineMedium.copyWith(color: AppTheme.secondaryText)),
          const SizedBox(height: 8),
          Text(
            'Activities will appear here once you start feeding.',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(5, (index) => _SkeletonItem()),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Row(
            children: [
              Text(
                dateKey.toUpperCase(),
                style: AppTheme.titleSmall,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withAlpha((255 * 0.05).round()),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = logs[index];
            final isSuccess = log.type == LogType.success;
            final timeFormatted = "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}";

            return Dismissible(
              key: Key(log.id ?? '$dateKey$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha((255 * 0.2).round()),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              ),
              onDismissed: (_) {
                if (log.id != null) ref.read(logProvider.notifier).deleteLog(log.id!);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isSuccess ? AppTheme.statusOnline : AppTheme.warning).withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_circle_outline_rounded : Icons.priority_high_rounded,
                        color: isSuccess ? AppTheme.statusOnline : AppTheme.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.title, style: AppTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(timeFormatted, style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        log.status,
                        style: AppTheme.labelMedium.copyWith(
                          color: isSuccess ? AppTheme.statusOnline : AppTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryText, size: 18),
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
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
      ),
    );
  }
}
