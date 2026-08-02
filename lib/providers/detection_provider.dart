import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/image_analysis_service.dart';
import '../widgets/live_camera_card.dart';

/// State untuk fitur deteksi kekeruhan air
class TurbidityState {
  final TurbidityResult lastResult;  // Hasil analisis terakhir
  final bool isAnalyzing;           // Sedang dalam proses analisis
  final bool isEnabled;             // Fitur deteksi aktif/tidak
  final bool isWarning;             // Apakah air sedang dalam kondisi keruh
  final int analysisCount;          // Total analisis hari ini
  final String? errorMessage;       // Pesan error (jika ada)
  final String statusMessage;       // Pesan status proses untuk UI

  TurbidityState({
    required this.lastResult,
    this.isAnalyzing = false,
    this.isEnabled = false,
    this.isWarning = false,
    this.analysisCount = 0,
    this.errorMessage,
    this.statusMessage = 'Deteksi nonaktif',
  });

  TurbidityState copyWith({
    TurbidityResult? lastResult,
    bool? isAnalyzing,
    bool? isEnabled,
    bool? isWarning,
    int? analysisCount,
    String? errorMessage,
    String? statusMessage,
  }) {
    return TurbidityState(
      lastResult: lastResult ?? this.lastResult,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isEnabled: isEnabled ?? this.isEnabled,
      isWarning: isWarning ?? this.isWarning,
      analysisCount: analysisCount ?? this.analysisCount,
      errorMessage: errorMessage,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// Provider Riverpod untuk mengelola siklus deteksi kekeruhan air.
///
/// Fitur utama:
/// - Analisis otomatis setiap 2 jam
/// - Post-feeding delay: jeda 30 menit setelah pemberian pakan
/// - Flash LED control: nyalakan flash saat analisis untuk pencahayaan konsisten
/// - Notifikasi peringatan jika air terdeteksi keruh (skor ≥ 60)
class TurbidityNotifier extends Notifier<TurbidityState> {
  final ImageAnalysisService _service = ImageAnalysisService();
  Timer? _analysisTimer;
  String _streamUrl = '';
  late DatabaseReference _db;

  /// Interval analisis: 2 jam (7200 detik)
  static const int _analysisIntervalSeconds = 7200;

  /// Jeda setelah pemberian pakan: 30 menit
  static const int _postFeedingDelayMinutes = 30;

  /// Skor minimum untuk trigger peringatan
  static const double _warningThreshold = 60.0;

  /// Waktu terakhir pemberian pakan (didengarkan dari Firebase)
  DateTime? _lastFeedingTime;

  @override
  TurbidityState build() {
    try {
      _db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://aquafeed-f3451-default-rtdb.firebaseio.com/',
      ).ref('aquafeed');

      // Dengarkan perubahan command/action untuk mendeteksi kapan pakan diberikan
      _db.child('command/action').onValue.listen((event) {
        try {
          final value = event.snapshot.value;
          if (value != null && value.toString() == 'dispense') {
            _lastFeedingTime = DateTime.now();
          }
        } catch (_) {}
      });
    } catch (_) {}

    _loadStreamUrl();

    ref.onDispose(() {
      _analysisTimer?.cancel();
    });

    return TurbidityState(
      lastResult: TurbidityResult.initial(),
    );
  }

  /// Load URL stream dari SharedPreferences
  Future<void> _loadStreamUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _streamUrl = prefs.getString('esp32_stream_url') ??
          'http://10.184.111.136:81/stream';
    } catch (_) {}
  }

  /// Update URL stream (dipanggil dari Settings)
  void updateStreamUrl(String url) {
    _streamUrl = url;
  }

  /// Toggle aktif/nonaktif deteksi kekeruhan
  void toggleDetection() {
    if (state.isEnabled) {
      _stopDetection();
    } else {
      _startDetection();
    }
  }

  /// Mulai siklus deteksi periodik (setiap 2 jam)
  void _startDetection() {
    state = state.copyWith(
      isEnabled: true,
      errorMessage: null,
      analysisCount: 0,
      statusMessage: 'Menjalankan analisis pertama...',
    );

    // Jalankan analisis pertama langsung
    _runAnalysisCycle();

    // Set timer untuk analisis berikutnya (setiap 2 jam)
    _analysisTimer = Timer.periodic(
      const Duration(seconds: _analysisIntervalSeconds),
      (_) => _runAnalysisCycle(),
    );
  }

  /// Hentikan siklus deteksi
  void _stopDetection() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    state = state.copyWith(
      isEnabled: false,
      isAnalyzing: false,
      isWarning: false,
      lastResult: TurbidityResult.initial(),
      analysisCount: 0,
      statusMessage: 'Deteksi nonaktif',
    );
  }

  /// Satu siklus analisis lengkap:
  /// Cek post-feeding delay → Flash ON → Capture → Analisis → Flash OFF → Update UI
  Future<void> _runAnalysisCycle() async {
    // --- SAFETY CHECK: Post-Feeding Delay ---
    if (_isPostFeedingDelay()) {
      final remaining = _getPostFeedingRemaining();
      state = state.copyWith(
        statusMessage: 'Menunggu air stabil... ($remaining menit lagi)',
      );
      return;
    }

    state = state.copyWith(
      isAnalyzing: true,
      errorMessage: null,
      statusMessage: 'Menyalakan flash...',
    );

    try {
      final stopwatch = Stopwatch()..start();
      
      // STEP 1: Nyalakan flash LED via Firebase
      await _setFlash(true);
      
      // STEP 2: Tunggu 1.5 detik agar kamera menyesuaikan pencahayaan
      state = state.copyWith(statusMessage: 'Menunggu kamera...');
      await Future.delayed(const Duration(milliseconds: 1500));

      // STEP 3: Ambil frame dari layar UI atau fallback ke HTTP
      state = state.copyWith(statusMessage: 'Mengambil gambar...');
      Uint8List? frameBytes = await _service.captureFrame(_streamUrl);
      String source = 'HTTP Sensor';
      if (frameBytes == null && liveCameraKey.currentState != null) {
        frameBytes = await liveCameraKey.currentState!.getSnapshotBytes();
        if (frameBytes != null) source = 'UI Screenshot';
      }

      // STEP 4: Matikan flash
      await _setFlash(false);

      if (frameBytes == null) {
        state = state.copyWith(
          isAnalyzing: false,
          errorMessage: 'Gagal mengambil gambar dari kamera',
          statusMessage: 'Gagal — kamera tidak merespons',
        );
        return;
      }

      // STEP 5: Analisis kekeruhan
      state = state.copyWith(statusMessage: 'Menganalisis gambar...');
      final result = _service.analyzeFrame(frameBytes);

      // STEP 6: Tentukan apakah perlu peringatan
      final isWarning = result.turbidityScore >= _warningThreshold;

      // STEP 7: Update state
      state = state.copyWith(
        lastResult: result,
        isAnalyzing: false,
        isWarning: isWarning,
        analysisCount: state.analysisCount + 1,
        statusMessage: isWarning
            ? '⚠️ Air keruh terdeteksi!'
            : 'Analisis selesai — air dalam kondisi baik',
      );

      stopwatch.stop();
      print('\n=== TELEMETRI ANALISIS KEKERUHAN (OTOMATIS) ===');
      print('- Sumber Gambar  : $source');
      print('- Waktu Eksekusi : ${stopwatch.elapsedMilliseconds} ms');
      print('- Skor Kekeruhan : ${result.turbidityScore.toStringAsFixed(1)}');
      print('- Status         : ${isWarning ? 'KERUH' : 'NORMAL'}');
      print('===============================================\n');
    } catch (e) {
      // Pastikan flash dimatikan jika terjadi error
      await _setFlash(false);
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Error: ${e.toString()}',
        statusMessage: 'Terjadi kesalahan saat analisis',
      );
    }
  }

  /// Analisis manual sekali (tombol "Analisis Sekarang")
  /// Melewati jeda post-feeding dan interval 2 jam
  Future<void> analyzeNow() async {
    if (state.isAnalyzing) return;

    // Sementara aktifkan jika belum
    final wasEnabled = state.isEnabled;
    state = state.copyWith(isEnabled: true);

    // Langsung jalankan tanpa cek post-feeding (user memilih manual)
    state = state.copyWith(
      isAnalyzing: true,
      errorMessage: null,
      statusMessage: 'Menyalakan flash...',
    );

    try {
      final stopwatch = Stopwatch()..start();
      
      await _setFlash(true);
      await Future.delayed(const Duration(milliseconds: 1500));

      state = state.copyWith(statusMessage: 'Mengambil gambar...');
      Uint8List? frameBytes = await _service.captureFrame(_streamUrl);
      String source = 'HTTP Sensor';
      if (frameBytes == null && liveCameraKey.currentState != null) {
        frameBytes = await liveCameraKey.currentState!.getSnapshotBytes();
        if (frameBytes != null) source = 'UI Screenshot';
      }

      await _setFlash(false);

      if (frameBytes == null) {
        state = state.copyWith(
          isAnalyzing: false,
          isEnabled: wasEnabled,
          errorMessage: 'Gagal mengambil gambar',
          statusMessage: 'Gagal — kamera tidak merespons',
        );
        return;
      }

      state = state.copyWith(statusMessage: 'Menganalisis gambar...');
      final result = _service.analyzeFrame(frameBytes);
      final isWarning = result.turbidityScore >= _warningThreshold;

      state = state.copyWith(
        lastResult: result,
        isAnalyzing: false,
        isEnabled: wasEnabled,
        isWarning: isWarning,
        analysisCount: state.analysisCount + 1,
        statusMessage: isWarning
            ? '⚠️ Air keruh terdeteksi!'
            : 'Analisis selesai — air dalam kondisi baik',
      );

      stopwatch.stop();
      print('\n=== TELEMETRI ANALISIS KEKERUHAN (MANUAL) ===');
      print('- Sumber Gambar  : $source');
      print('- Waktu Eksekusi : ${stopwatch.elapsedMilliseconds} ms');
      print('- Skor Kekeruhan : ${result.turbidityScore.toStringAsFixed(1)}');
      print('- Status         : ${isWarning ? 'KERUH' : 'NORMAL'}');
      print('=============================================\n');
    } catch (e) {
      await _setFlash(false);
      state = state.copyWith(
        isAnalyzing: false,
        isEnabled: wasEnabled,
        errorMessage: 'Error: ${e.toString()}',
        statusMessage: 'Terjadi kesalahan',
      );
    }
  }

  // ============================================================
  // HELPER: Flash Control & Post-Feeding
  // ============================================================

  /// Nyalakan/matikan flash LED via Firebase
  Future<void> _setFlash(bool on) async {
    try {
      await _db.child('command/flash').set(on ? 'on' : 'off');
    } catch (_) {
      // Lanjutkan meskipun gagal kontrol flash
    }
  }

  /// Cek apakah masih dalam periode jeda post-feeding (30 menit)
  bool _isPostFeedingDelay() {
    if (_lastFeedingTime == null) return false;
    final elapsed = DateTime.now().difference(_lastFeedingTime!).inMinutes;
    return elapsed < _postFeedingDelayMinutes;
  }

  /// Sisa waktu jeda post-feeding dalam menit
  int _getPostFeedingRemaining() {
    if (_lastFeedingTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastFeedingTime!).inMinutes;
    final remaining = _postFeedingDelayMinutes - elapsed;
    return remaining > 0 ? remaining : 0;
  }
}

final turbidityProvider =
    NotifierProvider<TurbidityNotifier, TurbidityState>(() {
  return TurbidityNotifier();
});
