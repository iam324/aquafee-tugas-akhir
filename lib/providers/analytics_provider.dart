import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'log_provider.dart';
import 'feed_provider.dart';

class DailyFeedData {
  final String dayLabel;
  final double totalGram;
  final DateTime date;

  DailyFeedData({
    required this.dayLabel,
    required this.totalGram,
    required this.date,
  });
}

class AnalyticsState {
  final List<DailyFeedData> weeklyData;
  final double totalThisWeek;
  final double averagePerDay;
  final double maxConsumption;
  final double currentStock;
  final double maxCapacity;

  AnalyticsState({
    required this.weeklyData,
    required this.totalThisWeek,
    required this.averagePerDay,
    required this.maxConsumption,
    required this.currentStock,
    required this.maxCapacity,
  });
}

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  @override
  AnalyticsState build() {
    final logs = ref.watch(logProvider);
    final feedState = ref.watch(feedProvider);
    return _processData(logs, feedState);
  }

  AnalyticsState _processData(List<ActivityLog> logs, FeedState feedState) {
    final today = DateTime.now();
    final List<DailyFeedData> weeklyData = [];

    // Generate last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayLabel = _getDayLabel(date, today);

      double totalGram = 0;
      for (final log in logs) {
        if (_isSameDay(log.timestamp, date) && log.type == LogType.success) {
          totalGram += log.dosage;
        }
      }

      weeklyData.add(DailyFeedData(
        dayLabel: dayLabel,
        totalGram: totalGram,
        date: date,
      ));
    }

    final totalThisWeek = weeklyData.fold(0.0, (sum, d) => sum + d.totalGram);
    final averagePerDay = totalThisWeek / 7;
    final maxConsumption = weeklyData.isEmpty
        ? 0.0
        : weeklyData.map((d) => d.totalGram).reduce((a, b) => a > b ? a : b);

    return AnalyticsState(
      weeklyData: weeklyData,
      totalThisWeek: totalThisWeek,
      averagePerDay: averagePerDay,
      maxConsumption: maxConsumption,
      currentStock: feedState.currentStock,
      maxCapacity: feedState.maxCapacity,
    );
  }

  String _getDayLabel(DateTime date, DateTime today) {
    final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Hari Ini';
    }
    return dayNames[date.weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(() {
  return AnalyticsNotifier();
});
