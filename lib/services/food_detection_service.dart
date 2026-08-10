import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Status sisa pakan ikan
enum FoodResidualStatus {
  empty,      // Pakan habis (air bersih dari pakan)
  low,        // Pakan tersisa sedikit (1-4 butir)
  moderate,   // Pakan tersisa sedang (5-10 butir)
  high,       // Pakan masih banyak (>10 butir) — Jangan beri makan dulu!
  unknown,    // Belum dianalisis
}

/// Hasil analisis sisa pakan dari frame kamera
class FoodDetectionResult {
  final int estimatedPelletCount;    // Estimasi jumlah butir pelet pakan
  final double coveragePercentage;   // Persentase luas pakan di air (%)
  final FoodResidualStatus status;   // Status sisa pakan
  final DateTime analyzedAt;         // Waktu analisis
  final String statusLabel;          // Label untuk UI
  final String recommendation;       // Rekomendasi tindakan

  FoodDetectionResult({
    required this.estimatedPelletCount,
    required this.coveragePercentage,
    required this.status,
    required this.analyzedAt,
    required this.statusLabel,
    required this.recommendation,
  });

  factory FoodDetectionResult.initial() => FoodDetectionResult(
        estimatedPelletCount: 0,
        coveragePercentage: 0.0,
        status: FoodResidualStatus.unknown,
        analyzedAt: DateTime.now(),
        statusLabel: 'Menunggu analisis...',
        recommendation: 'Buka kamera untuk mendeteksi sisa pakan.',
      );
}

/// Service AI Computer Vision untuk mendeteksi sisa pelet pakan ikan.
class FoodDetectionService {
  static const int _analysisWidth = 160;
  static const int _analysisHeight = 120;

  /// Ambil frame JPEG dari stream HTTP ESP32-CAM
  Future<Uint8List?> captureFrame(String streamUrl) async {
    try {
      final snapshotUrl = streamUrl
          .replaceAll(':81/stream', '/capture')
          .replaceAll('/stream', '/capture');

      final response = await http
          .get(Uri.parse(snapshotUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  /// Analisis frame JPEG untuk mencari pelet pakan ikan (warna coklat pekat/keemasan)
  FoodDetectionResult analyzeFrame(Uint8List imageBytes) {
    try {
      final original = img.decodeImage(imageBytes);
      if (original == null) return FoodDetectionResult.initial();

      final resized = img.copyResize(
        original,
        width: _analysisWidth,
        height: _analysisHeight,
      );

      int totalPixels = resized.width * resized.height;
      int pelletPixels = 0;

      // Grid untuk blob counting (kelompok piksel pelet)
      final List<List<bool>> mask = List.generate(
        resized.height,
        (_) => List.filled(resized.width, false),
      );

      // --- Tentukan Region of Interest (ROI) ---
      // Abaikan pinggiran gambar (tembok akuarium, mesin, benda di luar air)
      // Kita hanya fokus pada 70% area tengah gambar.
      final int startX = (resized.width * 0.15).toInt();
      final int endX = (resized.width * 0.85).toInt();
      final int startY = (resized.height * 0.15).toInt();
      final int endY = (resized.height * 0.85).toInt();
      final int roiPixels = (endX - startX) * (endY - startY);

      // Hitung rata-rata kecerahan gambar HANYA di area ROI (dihapus karena kita ganti ke deteksi warna)
      // Kita langsung memindai setiap piksel berdasarkan pigmen warna (Merah/Pink & Hijau)

      for (int y = startY; y < endY; y++) {
        for (int x = startX; x < endX; x++) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // DETEKSI WARNA (COLOR-BASED DETECTION)
          // Pelet baru berwarna Merah/Pink dan Hijau cerah.
          // Dasar air yang kosong berwarna kusam/abu-abu/hijau gelap kotor.
          
          // 1. Pelet Merah/Pink: Unsur Merah (R) sangat dominan menonjol
          bool isReddish = r > (g + 20) && r > (b + 20);
          
          // 2. Pelet Hijau Cerah: Unsur Hijau (G) sangat menonjol dibanding Merah dan Biru
          bool isGreenish = g > (r + 15) && g > (b + 15) && g > 80;
          
          // 3. Syarat Kecerahan: Harus cukup terang, bukan cuma bayangan gelap di air
          bool isBrightEnough = (r + g + b) > 120;

          if ((isReddish || isGreenish) && isBrightEnough) {
            pelletPixels++;
            mask[y][x] = true;
          }
        }
      }

      // Hitung kluster / butir pelet (Blob Counting)
      int detectedBlobs = 0;
      int validPellets = 0; // Hanya menghitung gumpalan seukuran pelet
      final visited = List.generate(
        resized.height,
        (_) => List.filled(resized.width, false),
      );

      for (int y = startY; y < endY; y++) {
        for (int x = startX; x < endX; x++) {
          if (mask[y][x] && !visited[y][x]) {
            int blobSize = _exploreBlob(mask, visited, x, y, resized.width, resized.height);
            if (blobSize >= 1) detectedBlobs++;
            
            // Filter ukuran butir
            if (blobSize >= 2 && blobSize <= 40) {
              validPellets++;
            }
          }
        }
      }

      final coveragePercent = (pelletPixels / roiPixels) * 100.0;

      FoodResidualStatus status;
      String statusLabel;
      String recommendation;

      // Status: Dikatakan habis jika bola-bola (validPellets) sangat sedikit (<= 2)
      // DAN area yang tertutup pelet sangat kecil (< 1.5%).
      // (Syarat area < 1.5% penting karena jika pelet menumpuk seperti karpet, 
      // blob size akan raksasa sehingga validPellets = 0, padahal aslinya makanan penuh!)
      
      if (validPellets <= 2 && coveragePercent < 1.5) {
        status = FoodResidualStatus.empty;
        statusLabel = 'Makanan Habis';
        recommendation = 'Air bersih. Silakan beri pakan.';
      } else {
        status = FoodResidualStatus.high;
        statusLabel = 'Pakan Terdeteksi';
        recommendation = 'Sisa pakan masih ada. Tunda pemberian makan.';
      }

      return FoodDetectionResult(
        estimatedPelletCount: detectedBlobs,
        coveragePercentage: coveragePercent,
        status: status,
        analyzedAt: DateTime.now(),
        statusLabel: statusLabel,
        recommendation: recommendation,
      );
    } catch (_) {
      return FoodDetectionResult.initial();
    }
  }

  /// Flood-fill untuk menghitung luasan 1 kluster pelet pakan
  int _exploreBlob(
    List<List<bool>> mask,
    List<List<bool>> visited,
    int startX,
    int startY,
    int width,
    int height,
  ) {
    int size = 0;
    final queue = [<int>[startX, startY]];
    visited[startY][startX] = true;

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      final cx = curr[0];
      final cy = curr[1];
      size++;

      // Tetangga 4 arah
      final dx = [0, 0, 1, -1];
      final dy = [1, -1, 0, 0];

      for (int i = 0; i < 4; i++) {
        final nx = cx + dx[i];
        final ny = cy + dy[i];

        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          if (mask[ny][nx] && !visited[ny][nx]) {
            visited[ny][nx] = true;
            queue.add([nx, ny]);
          }
        }
      }
    }
    return size;
  }
}
