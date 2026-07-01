import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedState {
  final double currentStock;
  final double currentWeight;
  final double maxCapacity;
  final int dosage;

  FeedState({
    required this.currentStock,
    this.currentWeight = 0.0,
    required this.maxCapacity,
    required this.dosage,
  });

  FeedState copyWith({
    double? currentStock,
    double? currentWeight,
    double? maxCapacity,
    int? dosage,
  }) {
    return FeedState(
      currentStock: currentStock ?? this.currentStock,
      currentWeight: currentWeight ?? this.currentWeight,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      dosage: dosage ?? this.dosage,
    );
  }
}

class FeedNotifier extends Notifier<FeedState> {
  late final DatabaseReference _db;
  String? _lastError;

  @override
  FeedState build() {
    try {
      // Inisialisasi _db di sini untuk memastikan Firebase sudah siap
      _db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
      ).ref('aquafeed');

      // Mendengarkan perubahan stok dari Firebase secara real-time
      _db.child('current_stock').onValue.listen(
        (event) {
          try {
            final value = event.snapshot.value;
            if (value != null) {
              state = state.copyWith(currentStock: (value as num).toDouble());
              _lastError = null;
            }
          } catch (e) {
            _lastError = 'Error parsing stock data';
          }
        },
        onError: (error) {
          _lastError = 'Koneksi Firebase gagal: $error';
        },
      );

      // Mendengarkan perubahan berat aktual dari Loadcell HX711
      _db.child('current_weight').onValue.listen(
        (event) {
          try {
            final value = event.snapshot.value;
            if (value != null) {
              state = state.copyWith(currentWeight: (value as num).toDouble());
            }
          } catch (e) {
            // Error parsing weight data
          }
        },
      );
    } catch (e) {
      _lastError = 'Error inisialisasi: ${e.toString()}';
    }

    return FeedState(currentStock: 0, currentWeight: 0, maxCapacity: 500, dosage: 25);
  }

  void incrementDosage() {
    try {
      if (state.dosage < 100) {
        state = state.copyWith(dosage: state.dosage + 25);
      }
    } catch (e) {
      // Error incrementing dosage
    }
  }

  void decrementDosage() {
    try {
      if (state.dosage > 0) {
        state = state.copyWith(dosage: state.dosage - 25);
      }
    } catch (e) {
      // Error decrementing dosage
    }
  }

  void setDosage(int value) {
    try {
      if (value >= 0 && value <= 100) {
        state = state.copyWith(dosage: value);
      }
    } catch (e) {
      // Error setting dosage
    }
  }

  Future<void> dispenseFeed() async {
    try {
      if (state.dosage <= 0) {
        throw Exception('Dosis harus lebih dari 0');
      }

      final newStock = state.currentStock - state.dosage;
      final finalStock = newStock < 0 ? 0.0 : newStock;
      
      // Update ke Firebase
      await _db.update({
        'current_stock': finalStock,
        'command': {
          'action': 'dispense',
          'dosage': state.dosage,
          'timestamp': ServerValue.timestamp,
        }
      });
      
      // Update state lokal juga
      state = state.copyWith(currentStock: finalStock);
      _lastError = null;
    } catch (e) {
      _lastError = 'Gagal memberi pakan: ${e.toString()}';
      rethrow;
    }
  }

  /// Memberi pakan secara lokal (demo mode) tanpa Firebase
  /// Cocok untuk testing saat ESP32 offline
  void dispenseFeedLocal() {
    if (state.dosage <= 0) {
      throw Exception('Dosis harus lebih dari 0');
    }

    final newStock = state.currentStock - state.dosage;
    final finalStock = newStock < 0 ? 0.0 : newStock;
    
    // Update state lokal saja
    state = state.copyWith(currentStock: finalStock);
    _lastError = null;
  }

  String? getLastError() => _lastError;

  Future<void> resetStock() async {
    try {
      final maxCap = state.maxCapacity;
      await _db.update({'current_stock': maxCap});
      _lastError = null;
    } catch (e) {
      _lastError = 'Gagal reset stok: ${e.toString()}';
      rethrow;
    }
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});
