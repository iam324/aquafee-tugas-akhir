import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

// ============================================================
// ENUM & MODEL
// ============================================================

/// Level kekeruhan air berdasarkan analisis gambar
enum TurbidityLevel {
  clear,           // Jernih — air bersih
  normal,          // Normal — sedikit partikel
  slightlyTurbid,  // Agak keruh
  turbid,          // Keruh — perlu perhatian
  veryTurbid,      // Sangat keruh — bahaya!
  unknown,         // Belum dianalisis
}

/// Hasil analisis kekeruhan dari satu frame kamera
class TurbidityResult {
  final double turbidityScore;     // 0.0 (jernih) - 100.0 (sangat keruh)
  final double avgBrightness;      // Rata-rata kecerahan (0-255)
  final double greenRatio;         // Rasio warna hijau / alga (%)
  final double brownRatio;         // Rasio warna coklat / sedimen (%)
  final TurbidityLevel level;      // Level kekeruhan
  final DateTime analyzedAt;       // Waktu analisis
  final String statusLabel;        // Label untuk UI

  TurbidityResult({
    required this.turbidityScore,
    required this.avgBrightness,
    required this.greenRatio,
    required this.brownRatio,
    required this.level,
    required this.analyzedAt,
    required this.statusLabel,
  });

  /// Factory untuk status awal "belum dianalisis"
  factory TurbidityResult.initial() => TurbidityResult(
    turbidityScore: 0,
    avgBrightness: 0,
    greenRatio: 0,
    brownRatio: 0,
    level: TurbidityLevel.unknown,
    analyzedAt: DateTime.now(),
    statusLabel: 'Menunggu analisis...',
  );
}

// ============================================================
// SERVICE UTAMA
// ============================================================

/// Service untuk menganalisis kekeruhan air dari frame kamera ESP32-CAM.
///
/// Cara kerja:
/// 1. Ambil frame JPEG dari ESP32-CAM via HTTP
/// 2. Decode dan resize gambar untuk efisiensi
/// 3. Analisis distribusi warna & kecerahan
/// 4. Hitung skor kekeruhan (turbidity score)
/// 5. Klasifikasikan ke dalam level kekeruhan
///
/// Prinsip ilmiah:
/// - Air jernih memiliki kecerahan tinggi dan dominan biru
/// - Air keruh memiliki kecerahan rendah, dominan coklat/hijau
/// - Semakin banyak partikel tersuspensi = semakin gelap & keruh gambar
class ImageAnalysisService {

  // ---- Threshold Konfigurasi ----

  /// Batas atas untuk level "Jernih" (skor 0-20)
  static const double _clearThreshold = 20.0;

  /// Batas atas untuk level "Normal" (skor 20-40)
  static const double _normalThreshold = 40.0;

  /// Batas atas untuk level "Agak Keruh" (skor 40-60)
  static const double _slightlyTurbidThreshold = 60.0;

  /// Batas atas untuk level "Keruh" (skor 60-80)
  static const double _turbidThreshold = 80.0;

  // Di atas 80 = "Sangat Keruh"

  /// Resolusi analisis (resize untuk efisiensi)
  static const int _analysisWidth = 160;
  static const int _analysisHeight = 120;

  // ---- Bobot untuk skor komposit ----

  /// Bobot kecerahan dalam skor akhir
  static const double _brightnessWeight = 0.50;

  /// Bobot warna hijau (alga)
  static const double _greenWeight = 0.25;

  /// Bobot warna coklat (sedimen)
  static const double _brownWeight = 0.25;

  // ============================================================
  // CAPTURE FRAME
  // ============================================================

  /// Mengambil satu frame JPEG dari ESP32-CAM.
  ///
  /// Pertama mencoba endpoint `/capture` (single-shot, lebih ringan).
  /// Jika gagal, fallback ke parsing MJPEG stream.
  Future<Uint8List?> captureFrame(String streamUrl) async {
    try {
      // Coba endpoint snapshot (lebih efisien daripada stream)
      // Ekstrak IP Address dengan aman dari URL stream
      String snapshotUrl;
      try {
        final uri = Uri.parse(streamUrl);
        snapshotUrl = 'http://${uri.host}/capture';
      } catch (_) {
        snapshotUrl = streamUrl.replaceAll(':81/stream', '/capture').replaceAll(':81/', '/capture');
      }

      final response = await http.get(
        Uri.parse(snapshotUrl),
      ).timeout(const Duration(seconds: 8)); // Naikkan timeout karena ESP32 lambat

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      // Fallback: ambil dari MJPEG stream
      return await _captureFromStream(streamUrl);
    }
  }

  /// Fallback: ekstrak satu frame JPEG dari MJPEG stream
  Future<Uint8List?> _captureFromStream(String streamUrl) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await client.send(request).timeout(
        const Duration(seconds: 5),
      );

      final completer = Completer<Uint8List?>();
      final buffer = BytesBuilder();
      bool foundStart = false;

      late StreamSubscription<List<int>> subscription;
      subscription = response.stream.listen(
        (chunk) {
          for (int i = 0; i < chunk.length; i++) {
            // Cari JPEG start marker (0xFF 0xD8)
            if (!foundStart &&
                i < chunk.length - 1 &&
                chunk[i] == 0xFF &&
                chunk[i + 1] == 0xD8) {
              foundStart = true;
              buffer.clear();
            }

            if (foundStart) {
              buffer.addByte(chunk[i]);

              // Cari JPEG end marker (0xFF 0xD9)
              if (buffer.length > 2 &&
                  chunk[i] == 0xD9 &&
                  i > 0 &&
                  chunk[i - 1] == 0xFF) {
                subscription.cancel();
                client.close();
                if (!completer.isCompleted) {
                  completer.complete(buffer.toBytes());
                }
                return;
              }
            }
          }
        },
        onError: (e) {
          subscription.cancel();
          client.close();
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          client.close();
          if (!completer.isCompleted) {
            completer.complete(foundStart ? buffer.toBytes() : null);
          }
        },
      );

      // Timeout safety
      Future.delayed(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          subscription.cancel();
          client.close();
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // ANALISIS KEKERUHAN
  // ============================================================

  /// Menganalisis kekeruhan air dari bytes JPEG.
  ///
  /// Pipeline:
  /// 1. Decode JPEG → img.Image
  /// 2. Resize ke 160x120 (efisiensi)
  /// 3. Hitung rata-rata kecerahan (brightness) — formula BT.601
  /// 4. Hitung rasio warna hijau (indikator alga)
  /// 5. Hitung rasio warna coklat (indikator sedimen)
  /// 6. Gabungkan menjadi skor komposit (0-100)
  /// 7. Klasifikasikan ke level kekeruhan
  TurbidityResult analyzeFrame(Uint8List imageBytes) {
    try {
      // 1. Decode Gambar (otomatis mendeteksi JPEG/PNG)
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        return TurbidityResult.initial();
      }

      // 2. Resize untuk efisiensi perhitungan
      final resized = img.copyResize(
        decoded,
        width: _analysisWidth,
        height: _analysisHeight,
        interpolation: img.Interpolation.nearest,
      );

      // Pass 1: Hitung rata-rata kecerahan (Mean Luminance)
      double totalBrightness = 0;
      int totalPixels = resized.width * resized.height;

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          totalBrightness += (0.299 * r + 0.587 * g + 0.114 * b);
        }
      }
      final double avgBrightness = totalBrightness / totalPixels;

      // --- ADAPTIVE THRESHOLD LOGIC ---
      // Menyesuaikan margin batas warna berdasarkan rata-rata cahaya
      int colorMargin = 10;
      int brownDiff = 15;
      
      if (avgBrightness < 60) {
        // Sangat gelap: sensitivitas dinaikkan (margin diperkecil)
        colorMargin = 3;
        brownDiff = 5;
      } else if (avgBrightness < 120) {
        // Gelap sedang
        colorMargin = 6;
        brownDiff = 10;
      } else if (avgBrightness > 180) {
        // Terlalu terang / silau: sensitivitas diturunkan untuk cegah false positive
        colorMargin = 20;
        brownDiff = 25;
      }

      // Pass 2: Deteksi warna menggunakan ambang batas adaptif
      int greenPixels = 0;
      int brownPixels = 0;

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // Deteksi Warna Hijau Adaptif
          if (g > r + colorMargin && g > b + colorMargin) {
            greenPixels++;
          }

          // Deteksi Warna Coklat Adaptif
          if (r > g && g > b && (r - b) > brownDiff) {
            brownPixels++;
          }
        }
      }

      // 4. Hitung rata-rata dan rasio
      final greenRatio = (greenPixels / totalPixels) * 100.0;
      final brownRatio = (brownPixels / totalPixels) * 100.0;

      // 5. Hitung skor kekeruhan komposit (0-100)
      //
      // Brightness Score: dibalik — terang = skor rendah, gelap = skor tinggi
      // Green Score: semakin banyak hijau = semakin keruh
      // Brown Score: semakin banyak coklat = semakin keruh
      final brightnessScore = _normalizeBrightness(avgBrightness);
      
      // Mengubah rasio pengali agar lebih sensitif (jika 30% pixel coklat, itu sudah sangat keruh)
      final greenScore = (greenRatio * 3.0).clamp(0.0, 100.0);
      final brownScore = (brownRatio * 3.0).clamp(0.0, 100.0);

      // Jika gambar sangat gelap (brightnessScore tinggi) ATAU sangat coklat, 
      // kita ambil nilai tertinggi atau gabungan yang lebih realistis.
      final colorScore = (greenScore > brownScore) ? greenScore : brownScore;
      
      final turbidityScore = (
        (brightnessScore * 0.40) + 
        (colorScore * 0.60)
      ).clamp(0.0, 100.0);

      // 6. Klasifikasikan
      final level = _classifyLevel(turbidityScore);
      final label = _getStatusLabel(level, turbidityScore);

      return TurbidityResult(
        turbidityScore: turbidityScore,
        avgBrightness: avgBrightness,
        greenRatio: greenRatio,
        brownRatio: brownRatio,
        level: level,
        analyzedAt: DateTime.now(),
        statusLabel: label,
      );
    } catch (e) {
      return TurbidityResult.initial();
    }
  }

  /// Normalisasi brightness ke skor kekeruhan (terbalik).
  /// Brightness tinggi (200+) → skor rendah (jernih).
  /// Brightness rendah (50-) → skor tinggi (keruh).
  double _normalizeBrightness(double avgBrightness) {
    const double minBright = 50.0;
    const double maxBright = 200.0;

    final clamped = avgBrightness.clamp(minBright, maxBright);
    final normalized = 1.0 - ((clamped - minBright) / (maxBright - minBright));
    return normalized * 100.0;
  }

  /// Klasifikasi level kekeruhan berdasarkan skor
  TurbidityLevel _classifyLevel(double score) {
    if (score < _clearThreshold) return TurbidityLevel.clear;
    if (score < _normalThreshold) return TurbidityLevel.normal;
    if (score < _slightlyTurbidThreshold) return TurbidityLevel.slightlyTurbid;
    if (score < _turbidThreshold) return TurbidityLevel.turbid;
    return TurbidityLevel.veryTurbid;
  }

  /// Label status untuk ditampilkan di UI
  String _getStatusLabel(TurbidityLevel level, double score) {
    final scoreStr = score.toStringAsFixed(1);
    switch (level) {
      case TurbidityLevel.clear:
        return 'Jernih — Skor $scoreStr%';
      case TurbidityLevel.normal:
        return 'Normal — Skor $scoreStr%';
      case TurbidityLevel.slightlyTurbid:
        return 'Agak Keruh — Skor $scoreStr%';
      case TurbidityLevel.turbid:
        return 'Keruh — Skor $scoreStr%';
      case TurbidityLevel.veryTurbid:
        return 'Sangat Keruh! — Skor $scoreStr%';
      case TurbidityLevel.unknown:
        return 'Menunggu analisis...';
    }
  }
}
