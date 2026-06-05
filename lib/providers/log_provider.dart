import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogType { success, warning }

class ActivityLog {
  final String? id;
  final String title;
  final String time;
  final LogType type;
  final String status;
  final int dosage;
  final DateTime timestamp;

  ActivityLog({
    this.id,
    required this.title,
    required this.time,
    required this.type,
    required this.status,
    this.dosage = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'time': time,
    'type': type.index,
    'status': status,
    'dosage': dosage,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ActivityLog.fromJson(Map<dynamic, dynamic> json, {String? id}) => ActivityLog(
    id: id,
    title: json['title'],
    time: json['time'],
    type: LogType.values[json['type']],
    status: json['status'],
    dosage: json['dosage'] ?? 0,
    timestamp: json['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
        : DateTime.now(),
  );
}

class LogState {
  final List<ActivityLog> logs;
  final bool isLoading;
  final String? error;

  LogState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  LogState copyWith({
    List<ActivityLog>? logs,
    bool? isLoading,
    String? error,
  }) {
    return LogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LogNotifier extends Notifier<LogState> {
  late final DatabaseReference _db;

  @override
  LogState build() {
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
    ).ref('aquafeed/logs');

    _loadData();
    return LogState(isLoading: true);
  }

  void _loadData() {
    try {
      _db.onValue.listen(
        (event) {
          try {
            final data = event.snapshot.value as Map?;
            if (data != null && data.isNotEmpty) {
              final logs = data.entries
                  .map((e) => ActivityLog.fromJson(e.value as Map, id: e.key))
                  .toList();
              // Sort berdasarkan timestamp dari yang terbaru
              logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              state = state.copyWith(logs: logs, isLoading: false, error: null);
            } else {
              state = state.copyWith(logs: [], isLoading: false, error: null);
            }
          } catch (e) {
            state = state.copyWith(
              isLoading: false,
              error: 'Error parsing data: ${e.toString()}',
            );
            print('Error parsing Firebase data: $e');
          }
        },
        onError: (error) {
          state = state.copyWith(
            isLoading: false,
            error: 'Koneksi Firebase gagal: ${error.toString()}',
          );
          print('Firebase listener error: $error');
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error koneksi Firebase: ${e.toString()}',
      );
      print('Error initializing Firebase listener: $e');
    }
  }

  Future<void> addLog(ActivityLog log) async {
    try {
      await _db.push().set(log.toJson());
    } catch (e) {
      state = state.copyWith(error: 'Gagal menambah log: ${e.toString()}');
      print('Error adding log: $e');
      rethrow;
    }
  }

  Future<void> deleteLog(String logId) async {
    try {
      await _db.child(logId).remove();
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus log: ${e.toString()}');
      print('Error deleting log: $e');
      rethrow;
    }
  }

  Future<void> clearAllLogs() async {
    try {
      await _db.remove();
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus semua log: ${e.toString()}');
      print('Error clearing logs: $e');
      rethrow;
    }
  }

  Future<void> seedDemoData() async {
    try {
      final today = DateTime.now();
      final demoDosages = [25, 30, 20, 35, 0, 15, 10];

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final hour = 8 + (i % 3) * 3;
        final logDate = DateTime(date.year, date.month, date.day, hour, 0, 0);
        final timeStr = '${hour.toString().padLeft(2, '0')}:00';
        final dayStr = '${date.day}/${date.month}/${date.year}';

        final dosage = demoDosages[i];
        if (dosage > 0) {
          await _db.push().set({
            'title': 'Pakan ${dosage}g diberikan',
            'time': '$dayStr $timeStr',
            'type': 0,
            'status': 'Selesai',
            'dosage': dosage,
            'timestamp': logDate.millisecondsSinceEpoch,
          });
        }
      }
      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: 'Gagal seed demo data: ${e.toString()}');
      print('Error seeding demo data: $e');
      rethrow;
    }
  }
}

final logProvider = NotifierProvider<LogNotifier, LogState>(() {
  return LogNotifier();
});

