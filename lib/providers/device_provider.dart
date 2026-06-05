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
            print('Error parsing device_status: $e');
          }
        },
        onError: (error) {
          print('Error listening to device_status: $error');
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
            print('Error parsing valve_status: $e');
          }
        },
        onError: (error) {
          print('Error listening to valve_status: $error');
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
            print('Error parsing servo_status: $e');
          }
        },
        onError: (error) {
          print('Error listening to servo_status: $error');
          state = state.copyWith(isFirebaseConnected: false);
        },
      );
    } catch (e) {
      print('Error initializing device provider: $e');
    }

    return DeviceState(
      isFirebaseConnected: true,
      status: 'Standby',
      valveStatus: 'Tertutup',
      servoStatus: 'Ready',
    );
  }

  void toggleConnection() {
    try {
      state = state.copyWith(isFirebaseConnected: !state.isFirebaseConnected);
    } catch (e) {
      print('Error toggling connection: $e');
    }
  }
}

final deviceProvider = NotifierProvider<DeviceNotifier, DeviceState>(() {
  return DeviceNotifier();
});
