import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_detection_service.dart';
import '../widgets/live_camera_card.dart';

class FoodDetectionState {
  final FoodDetectionResult lastResult;
  final bool isAnalyzing;
  final String? errorMessage;
  final String statusMessage;

  FoodDetectionState({
    required this.lastResult,
    this.isAnalyzing = false,
    this.errorMessage,
    this.statusMessage = 'Mendeteksi otomatis (setiap 6 jam)',
  });

  FoodDetectionState copyWith({
    FoodDetectionResult? lastResult,
    bool? isAnalyzing,
    String? errorMessage,
    String? statusMessage,
  }) {
    return FoodDetectionState(
      lastResult: lastResult ?? this.lastResult,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: errorMessage,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class FoodDetectionNotifier extends Notifier<FoodDetectionState> {
  Timer? _autoScanTimer;

  @override
  FoodDetectionState build() {
    _startAutoScan();

    ref.onDispose(() {
      _autoScanTimer?.cancel();
    });

    return FoodDetectionState(
      lastResult: FoodDetectionResult.initial(),
    );
  }

  /// Mulai scan otomatis setiap 6 jam
  void _startAutoScan() {
    _autoScanTimer?.cancel();

    // Jalankan scan pertama setelah 2 detik (saat UI siap)
    Future.delayed(const Duration(seconds: 2), () {
      detectNow();
    });

    // Kemudian ulang otomatis setiap 6 jam
    _autoScanTimer = Timer.periodic(const Duration(hours: 6), (_) {
      detectNow();
    });
  }

  /// Picu analisis sisa pakan dari live stream / snapshot
  Future<void> detectNow() async {
    if (state.isAnalyzing) return;

    state = state.copyWith(
      isAnalyzing: true,
      errorMessage: null,
      statusMessage: 'Memindai pakan...',
    );

    try {
      // HINDARI request HTTP /capture ke ESP32 karena membuat ESP32 berat dan panas.
      // Ambil gambar langsung dari layar aplikasi (stream yang sedang berjalan).
      Uint8List? frameBytes;
      if (liveCameraKey.currentState != null) {
        frameBytes = await liveCameraKey.currentState!.getSnapshotBytes();
      }

      if (frameBytes == null) {
        state = state.copyWith(
          isAnalyzing: false,
          errorMessage: 'Kamera offline',
          statusMessage: 'Kamera offline',
        );
        return;
      }

      // Jalankan analisis di isolate terpisah agar UI tidak freeze
      final result = await compute(
        (bytes) => FoodDetectionService().analyzeFrame(bytes),
        frameBytes,
      );

      state = state.copyWith(
        lastResult: result,
        isAnalyzing: false,
        statusMessage: 'Otomatis (setiap 6 jam)',
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: e.toString(),
        statusMessage: 'Error memindai',
      );
    }
  }
}

final foodDetectionProvider =
    NotifierProvider<FoodDetectionNotifier, FoodDetectionState>(() {
  return FoodDetectionNotifier();
});
