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

  @override
  FeedState build() {
    // Inisialisasi _db di sini untuk memastikan Firebase sudah siap
    _db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
    ).ref('aquafeed');

    // Mendengarkan perubahan stok dari Firebase secara real-time
    _db.child('current_stock').onValue.listen((event) {
      final value = event.snapshot.value;
      if (value != null) {
        state = state.copyWith(currentStock: (value as num).toDouble());
      }
    });

    return FeedState(currentStock: 0, maxCapacity: 500, dosage: 25);
  }

  void incrementDosage() {
    state = state.copyWith(dosage: state.dosage + 1);
  }

  void decrementDosage() {
    if (state.dosage > 0) {
      state = state.copyWith(dosage: state.dosage - 1);
    }
  }

  void setDosage(int value) {
    state = state.copyWith(dosage: value);
  }

  Future<void> dispenseFeed() async {
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
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});
