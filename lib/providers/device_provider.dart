import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceState {
  final bool isFirebaseConnected;
  final String status;
  final String valveStatus;
  final String servoStatus;

  DeviceState({
    required this.isFirebaseConnected,
    required this.status,
    required this.valveStatus,
    required this.servoStatus,
  });

  DeviceState copyWith({
    bool? isFirebaseConnected,
    String? status,
    String? valveStatus,
    String? servoStatus,
  }) {
    return DeviceState(
      isFirebaseConnected: isFirebaseConnected ?? this.isFirebaseConnected,
      status: status ?? this.status,
      valveStatus: valveStatus ?? this.valveStatus,
      servoStatus: servoStatus ?? this.servoStatus,
    );
  }
}

class DeviceNotifier extends Notifier<DeviceState> {
  late final DatabaseReference _db;

  @override
  DeviceState build() {
    // Inisialisasi _db di sini untuk memastikan Firebase sudah siap
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
    ).ref('aquafeed');

    // Mendengarkan status alat dari Firebase secara real-time
    _db.child('device_status').onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        state = state.copyWith(status: value.toString());
      }
    });

    _db.child('valve_status').onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        state = state.copyWith(valveStatus: value.toString());
      }
    });

    _db.child('servo_status').onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        state = state.copyWith(servoStatus: value.toString());
      }
    });

    return DeviceState(
      isFirebaseConnected: true,
      status: 'Standby',
      valveStatus: 'Tertutup',
      servoStatus: 'Ready',
    );
  }

  void toggleConnection() {
    state = state.copyWith(isFirebaseConnected: !state.isFirebaseConnected);
  }
}

final deviceProvider = NotifierProvider<DeviceNotifier, DeviceState>(() {
  return DeviceNotifier();
});
