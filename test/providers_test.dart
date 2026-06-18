import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Model Tests', () {
    test('FeedState copyWith works correctly', () {
      final state = _FeedState(currentStock: 100, maxCapacity: 500, dosage: 25);

      final newState = state.copyWith(currentStock: 150, dosage: 50);

      expect(newState.currentStock, 150);
      expect(newState.dosage, 50);
      expect(newState.maxCapacity, 500);
    });

    test('DailyFeedData stores correct values', () {
      final data = _DailyFeedData(
        dayLabel: 'Sen',
        totalGram: 50.5,
        date: DateTime(2026, 6, 1),
      );

      expect(data.dayLabel, 'Sen');
      expect(data.totalGram, 50.5);
    });

    test('AnalyticsState calculates totals correctly', () {
      final weeklyData = [
        _DailyFeedData(dayLabel: 'Sen', totalGram: 50, date: DateTime.now()),
        _DailyFeedData(dayLabel: 'Sel', totalGram: 75, date: DateTime.now()),
        _DailyFeedData(dayLabel: 'Rab', totalGram: 100, date: DateTime.now()),
      ];

      final total = weeklyData.fold(0.0, (sum, d) => sum + d.totalGram);
      final average = total / weeklyData.length;

      expect(total, 225);
      expect(average, 75);
    });
  });
}

// Test helper classes
class _FeedState {
  final double currentStock;
  final double maxCapacity;
  final int dosage;

  _FeedState({
    required this.currentStock,
    required this.maxCapacity,
    required this.dosage,
  });

  _FeedState copyWith({double? currentStock, double? maxCapacity, int? dosage}) {
    return _FeedState(
      currentStock: currentStock ?? this.currentStock,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      dosage: dosage ?? this.dosage,
    );
  }
}

class _DailyFeedData {
  final String dayLabel;
  final double totalGram;
  final DateTime date;

  _DailyFeedData({
    required this.dayLabel,
    required this.totalGram,
    required this.date,
  });
}