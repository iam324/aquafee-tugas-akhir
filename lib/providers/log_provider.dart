import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogType { success, warning }

class ActivityLog {
  final String title;
  final String time;
  final LogType type;
  final String status;

  ActivityLog({
    required this.title,
    required this.time,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'time': time,
    'type': type.index,
    'status': status,
  };

  factory ActivityLog.fromJson(Map<dynamic, dynamic> json) => ActivityLog(
    title: json['title'],
    time: json['time'],
    type: LogType.values[json['type']],
    status: json['status'],
  );
}

class LogNotifier extends Notifier<List<ActivityLog>> {
  late final DatabaseReference _db;

  @override
  List<ActivityLog> build() {
    // Inisialisasi _db di sini untuk memastikan Firebase sudah siap
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
    ).ref('aquafeed/logs');

    // Mendengarkan riwayat log dari Firebase
    _db.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final logs = data.values.map((e) => ActivityLog.fromJson(e as Map)).toList();
        // Urutkan berdasarkan waktu (asumsi log terbaru di atas)
        state = logs.reversed.toList();
      }
    });

    return [];
  }

  Future<void> addLog(ActivityLog log) async {
    await _db.push().set(log.toJson());
  }
}

final logProvider = NotifierProvider<LogNotifier, List<ActivityLog>>(() {
  return LogNotifier();
});
