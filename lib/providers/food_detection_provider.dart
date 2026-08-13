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
    this.statusMessage = 'Otomatis dalam 60s',
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

  int _countdown = 60;

  /// Mulai hitung mundur scan otomatis
  void _startAutoScan() {
    _autoScanTimer?.cancel();
    _countdown = 60;

    // Jalankan scan pertama setelah 2 detik (saat UI siap)
    Future.delayed(const Duration(seconds: 2), () {
      detectNow();
      
      // Mulai timer mundur 1 detik
      _autoScanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.isAnalyzing) return; // Pause saat sedang memindai

        _countdown--;

        if (_countdown <= 0) {
          detectNow();
          _countdown = 60; // Reset kembali ke 60
        } else {
          // Update tulisan di layar setiap detik
          state = state.copyWith(
            statusMessage: 'Otomatis dalam ${_countdown}s',
          );
        }
      });
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
        statusMessage: 'Otomatis dalam ${_countdown}s',
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
