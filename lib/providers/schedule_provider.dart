import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedingSchedule {
  final String id;
  final String time; // Format: HH:mm (24-hour format)
  final int dosage; // in grams
  final bool active;
  final String? label; // Optional label like "Morning", "Evening"
  final List<bool> days; // [Sun, Mon, Tue, Wed, Thu, Fri, Sat]

  FeedingSchedule({
    required this.id,
    required this.time,
    required this.dosage,
    this.active = true,
    this.label,
    List<bool>? days,
  })  : days = days ?? List.filled(7, true); // Default: all days active

  factory FeedingSchedule.fromMap(String id, Map<dynamic, dynamic> map) {
    List<bool> parsedDays = List.filled(7, true);
    if (map['days'] != null) {
      if (map['days'] is List) {
        final rawList = map['days'] as List;
        parsedDays = List.generate(7, (index) {
          if (index < rawList.length) {
            return rawList[index] == true;
          }
          return true;
        });
      }
    }

    return FeedingSchedule(
      id: id,
      time: map['time']?.toString() ?? '08:00',
      dosage: int.tryParse(map['dosage']?.toString() ?? '25') ?? 25,
      active: map['active'] == true || map['active'] == null,
      label: map['label']?.toString(),
      days: parsedDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'dosage': dosage,
      'active': active,
      'label': label ?? '',
      'days': days,
    };
  }

  FeedingSchedule copyWith({
    String? time,
    int? dosage,
    bool? active,
    String? label,
    List<bool>? days,
  }) {
    return FeedingSchedule(
      id: id,
      time: time ?? this.time,
      dosage: dosage ?? this.dosage,
      active: active ?? this.active,
      label: label ?? this.label,
      days: days ?? this.days,
    );
  }
}

class ScheduleState {
  final List<FeedingSchedule> schedules;
  final String? lastError;

  const ScheduleState({
    required this.schedules,
    this.lastError,
  });

  ScheduleState copyWith({
    List<FeedingSchedule>? schedules,
    String? lastError,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      lastError: lastError ?? this.lastError,
    );
  }
}

class ScheduleNotifier extends Notifier<ScheduleState> {
  late final DatabaseReference _db;
  String? _lastError;

  @override
  ScheduleState build() {
    try {
      _db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
      ).ref('aquafeed/schedule');

      // Listen for schedule changes from Firebase
      _db.onValue.listen((event) {
        try {
          final Map<dynamic, dynamic>? values = event.snapshot.value as Map<dynamic, dynamic>?;
          if (values != null) {
            final List<FeedingSchedule> loadedSchedules = [];
            values.forEach((key, value) {
              if (value != null && value is Map) {
                final schedule = FeedingSchedule.fromMap(key.toString(), value);
                loadedSchedules.add(schedule);
              }
            });
            // Sort by time
            loadedSchedules.sort((a, b) => a.time.compareTo(b.time));
            state = ScheduleState(schedules: loadedSchedules, lastError: null);
            _lastError = null;
          } else {
            state = const ScheduleState(schedules: [], lastError: null);
            _lastError = null;
          }
        } catch (e) {
          _lastError = 'Error parsing schedule data: $e';
          state = ScheduleState(schedules: state.schedules, lastError: _lastError);
        }
      }, onError: (error) {
        _lastError = 'Firebase connection error: $error';
        state = ScheduleState(schedules: state.schedules, lastError: _lastError);
      });
    } catch (e) {
      _lastError = 'Error initializing schedule provider: $e';
    }

    return const ScheduleState(schedules: [], lastError: null);
  }

  String? getLastError() => _lastError;

  Future<void> addSchedule(String time, int dosage, {String? label, List<bool>? days}) async {
    try {
      if (time.isEmpty) throw Exception('Time cannot be empty');
      if (dosage <= 0) throw Exception('Dosage must be greater than 0');

      final newSchedule = FeedingSchedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        time: time,
        dosage: dosage,
        label: label,
        days: days,
      );

      await _db.child(newSchedule.id).set(newSchedule.toMap());
      _lastError = null;
    } catch (e) {
      _lastError = 'Failed to add schedule: $e';
      rethrow;
    }
  }

  Future<void> updateSchedule(String id, FeedingSchedule updatedSchedule) async {
    try {
      await _db.child(id).set(updatedSchedule.toMap());
      _lastError = null;
    } catch (e) {
      _lastError = 'Failed to update schedule: $e';
      rethrow;
    }
  }

  Future<void> toggleSchedule(String id, bool active) async {
    try {
      final scheduleIndex = state.schedules.indexWhere((s) => s.id == id);
      if (scheduleIndex == -1) throw Exception('Schedule not found');

      final updatedSchedule = state.schedules[scheduleIndex].copyWith(active: active);
      await updateSchedule(id, updatedSchedule);
    } catch (e) {
      _lastError = 'Failed to toggle schedule: $e';
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _db.child(id).remove();
      _lastError = null;
    } catch (e) {
      _lastError = 'Failed to delete schedule: $e';
      rethrow;
    }
  }

  // Get next upcoming scheduled feeding
  FeedingSchedule? getNextScheduledFeeding() {
    if (state.schedules.isEmpty) return null;

    final activeSchedules = state.schedules.where((s) => s.active).toList();
    if (activeSchedules.isEmpty) return null;

    final now = DateTime.now();
    final currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentDayIdx = now.weekday % 7; // 0 = Sun, 1 = Mon, ..., 6 = Sat

    // 1. Check for upcoming schedules today
    final upcomingToday = activeSchedules.where((s) {
      return s.days[currentDayIdx] && s.time.compareTo(currentTimeStr) > 0;
    }).toList();

    if (upcomingToday.isNotEmpty) {
      upcomingToday.sort((a, b) => a.time.compareTo(b.time));
      return upcomingToday.first;
    }

    // 2. Check for upcoming schedules on next days
    for (int offset = 1; offset <= 7; offset++) {
      final targetDayIdx = (currentDayIdx + offset) % 7;
      final upcomingDay = activeSchedules.where((s) => s.days[targetDayIdx]).toList();
      if (upcomingDay.isNotEmpty) {
        upcomingDay.sort((a, b) => a.time.compareTo(b.time));
        return upcomingDay.first;
      }
    }

    return activeSchedules.first;
  }
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(() {
  return ScheduleNotifier();
});