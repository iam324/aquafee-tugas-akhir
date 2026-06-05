import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedState {
  final double currentStock;
  final double maxCapacity;
  final int dosage;

  FeedState({
    required this.currentStock,
    required this.maxCapacity,
    required this.dosage,
  });

  FeedState copyWith({
    double? currentStock,
    double? maxCapacity,
    int? dosage,
  }) {
    return FeedState(
      currentStock: currentStock ?? this.currentStock,
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
            print('Error parsing current_stock: $e');
            _lastError = 'Error parsing stock data';
          }
        },
        onError: (error) {
          print('Error listening to current_stock: $error');
          _lastError = 'Koneksi Firebase gagal: $error';
        },
      );
    } catch (e) {
      print('Error initializing feed provider: $e');
      _lastError = 'Error inisialisasi: ${e.toString()}';
    }

    return FeedState(currentStock: 0, maxCapacity: 500, dosage: 25);
  }

  void incrementDosage() {
    try {
      if (state.dosage < 100) {
        state = state.copyWith(dosage: state.dosage + 1);
      }
    } catch (e) {
      print('Error incrementing dosage: $e');
    }
  }

  void decrementDosage() {
    try {
      if (state.dosage > 0) {
        state = state.copyWith(dosage: state.dosage - 1);
      }
    } catch (e) {
      print('Error decrementing dosage: $e');
    }
  }

  void setDosage(int value) {
    try {
      if (value >= 0 && value <= 100) {
        state = state.copyWith(dosage: value);
      }
    } catch (e) {
      print('Error setting dosage: $e');
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
      
      _lastError = null;
    } catch (e) {
      print('Error dispensing feed: $e');
      _lastError = 'Gagal memberi pakan: ${e.toString()}';
      rethrow;
    }
  }

  String? getLastError() => _lastError;
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});
