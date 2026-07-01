import 'dart:async';
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
  Timer? _pingTimer;
  DateTime? _lastPing;

  @override
  DeviceState build() {
    try {
      // Inisialisasi _db di sini untuk memastikan Firebase sudah siap
      _db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
      ).ref('aquafeed');

      // Mendengarkan status alat dari Firebase secara real-time
      _db.child('device_status').onValue.listen(
        (event) {
          try {
            final value = event.snapshot.value;
            if (value != null) {
              state = state.copyWith(status: value.toString());
            }
          } catch (e) {
            // Error parsing device_status
          }
        },
        onError: (error) {
          state = state.copyWith(isFirebaseConnected: false);
        },
      );

      _db.child('valve_status').onValue.listen(
        (event) {
          try {
            final value = event.snapshot.value;
            if (value != null) {
              state = state.copyWith(valveStatus: value.toString());
            }
          } catch (e) {
            // Error parsing valve_status
          }
        },
        onError: (error) {
          state = state.copyWith(isFirebaseConnected: false);
        },
      );

      _db.child('servo_status').onValue.listen(
        (event) {
          try {
            final value = event.snapshot.value;
            if (value != null) {
              state = state.copyWith(servoStatus: value.toString());
            }
          } catch (e) {
            // Error parsing servo_status
          }
        },
        onError: (error) {
          // Error listening to servo_status
        },
      );

      // Dengarkan denyut (heartbeat) dari ESP32
      _db.child('last_ping').onValue.listen(
        (event) {
          try {
            // Kita tidak peduli isinya apa, yang penting node ini berubah nilainya
            if (event.snapshot.value != null) {
              _lastPing = DateTime.now(); // Catat waktu saat ping diterima di HP
            }
          } catch (e) {
            // Error parsing last_ping
          }
        },
      );

      // Cek setiap 3 detik apakah ESP32 masih berdenyut
      _pingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_lastPing != null) {
          final diff = DateTime.now().difference(_lastPing!).inSeconds;
          // Jika tidak ada update selama lebih dari 12 detik, anggap Offline
          if (diff > 12) {
            if (state.isFirebaseConnected) {
              state = state.copyWith(isFirebaseConnected: false, status: 'Offline');
            }
          } else {
            if (!state.isFirebaseConnected) {
              state = state.copyWith(isFirebaseConnected: true, status: 'Online');
            }
          }
        }
      });

      ref.onDispose(() {
        _pingTimer?.cancel();
      });

    } catch (e) {
      // Error initializing device provider
    }

    return DeviceState(
      isFirebaseConnected: false, // Default ke offline sampai ada ping
      status: 'Mencari Perangkat...',
      valveStatus: 'Tertutup',
      servoStatus: 'Ready',
    );
  }

  void toggleConnection() {
    try {
      state = state.copyWith(isFirebaseConnected: !state.isFirebaseConnected);
    } catch (e) {
      // Error toggling connection
    }
  }
}

final deviceProvider = NotifierProvider<DeviceNotifier, DeviceState>(() {
  return DeviceNotifier();
});
