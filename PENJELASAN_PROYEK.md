# 📘 Penjelasan Proyek AquaFeed untuk Tugas Akhir (Updated)

Dokumen ini berisi penjelasan mendalam mengenai arsitektur, fitur, hardware, dan struktur kode proyek **AquaFeed**. Gunakan dokumen ini sebagai referensi utama untuk memahami ekosistem sistem IoT dan AI ini secara keseluruhan.

---

## 1. Konsep Utama Proyek (Architectural Overview)

Proyek ini adalah sistem **Smart Fish Feeder & Water Quality Monitor** berbasis IoT dan Computer Vision/AI yang menghubungkan perangkat keras (Hardware) dengan aplikasi mobile secara *real-time*.

*   **Framework Aplikasi**: Flutter (Dart) dengan arsitektur **Clean UI & Responsive Layout**.
*   **State Management**: **Riverpod (versi 2.6.x)**. Memastikan aliran data yang *type-safe* dan reaktif di seluruh aplikasi.
*   **Backend & Jembatan Komunikasi**: **Firebase Realtime Database (RTDB)**. Digunakan untuk sinkronisasi perintah (*command*) dan status antara aplikasi dan alat.
*   **Hardware Core**: **ESP32-CAM (AI-Thinker Model)**. Menangani penyiaran video streaming MJPEG, penangkapan citra sensor, dan kontrol langsung motor DC.
*   **Aktuator Pakan (Direct Motor Drive)**: **Motor DC 5V** yang dikontrol secara langsung melalui **4 Pin GPIO Paralel (GPIO 12, 13, 14, 15)** dengan mode **Active-LOW (Sinking Current)** tanpa memerlukan Module Relay.
*   **Wireless Firmware Update (ArduinoOTA)**: Memungkinkan pembaruan program firmware secara *nirkabel (wireless via Wi-Fi)* tanpa colok kabel FTDI lagi.
*   **AI Engine**: **Computer Vision (Color-Space Thresholding & Blob Detection)** untuk Deteksi Sisa Pakan Ikan dan Analisis Kekeruhan Air secara *real-time*.
*   **Theme & UI**: Desain **Dark Mode** modern (*Midnight Aquatic Theme*) dengan skema warna *Emerald Green*, *Cyan*, *Magenta*, dan *Teal*.

---

## 2. Fitur Utama & Penjelasan Teknis

### A. Real-Time Camera Stream & YouTube-Style Floating Mini Player (PiP)
*   **Fungsi**: Memantau kondisi fisik kolam secara *live video streaming* tanpa terputus.
*   **Teknis**: 
    *   **Video Engine**: Menggunakan `flutter_mjpeg` untuk menangkap stream dari ESP32-CAM (`http://<IP_ESP32>:81/stream`).
    *   **Frame Buffer Optimizing**: Pada firmware ESP32-CAM, nilai `config.fb_count` diatur ke **2** (Double Buffering di PSRAM) untuk menghilangkan *dropped frames* dan membuat stream sangat halus.
    *   **YouTube-Style Floating Mini Player (Picture-in-Picture)**: Saat pengguna melakukan *scroll* ke bawah melewati batas 240px, jendela video mini otomatis muncul di pojok kanan bawah layar.
    *   **Single-Stream Seamless Transfer**: ESP32-CAM hanya mampu menangani 1 koneksi streaming HTTP. Dibuat logika switching cerdas pada `home_screen.dart` dan `live_camera_card.dart` sehingga stream ditransfer secara aman tanpa menyebabkan koneksi terputus saat di-scroll naik-turun.

### B. Real-time Fish Food Residual Detection (AI Deteksi Sisa Pakan)
*   **Fungsi**: Mendeteksi secara otomatis apakah pelet pakan ikan di permukaan air **masih ada** atau **sudah habis**.
*   **Prinsip Kerja & Algoritma**:
    1. **Direct Sensor Capture**: `FoodDetectionNotifier` mengambil citra segar dari sensor hardware ESP32-CAM via endpoint `/capture`.
    2. **Color-Space Segmentation**: Mengisolasi warna pelet pakan (cokelat keemasan / *tan*) yang mengapung di permukaan air berdasarkan rumus ambang batas RGB/HSV.
    3. **Blob Detection (Connected Component Labeling)**: Menghitung kelompok piksel pelet pakan yang terisolasi.
    4. **AI Bounding Box Overlay**: Menggambar kotak hijau neon (*Bounding Box*) dan label magenta tag (`Pakan Terdeteksi | 94%` atau `Pakan Habis`) secara *real-time* langsung di atas video live stream menggunakan `CustomPainter` (`AIBoundingBoxPainter`).
    5. **Auto-Scan 10 Detik**: Pemindaian otomatis berjalan di *background* setiap 10 detik sekali oleh `FoodDetectionNotifier`.
*   **Manfaat Utama (Nilai Tambah TA)**: Berfungsi sebagai *Decision Support System* untuk **mencegah Overfeeding** (pemberian pakan berlebih) yang menyebabkan pemborosan pakan dan pembusukan air kolam.

### C. Low-Light Water Turbidity Analysis (Analisis Kekeruhan Air)
*   **Fungsi**: Memantau tingkat kekeruhan air kolam secara visual berdasarkan distribusi warna dan kecerahan.
*   **Algoritma**:
    *   Mengklasifikasikan air menjadi 5 level (*Clear, Normal, Slightly Turbid, Turbid, Very Turbid*).
    *   Memperhitungkan kecerahan rata-rata (*brightness*) dan rasio pigmen hijau (alga) serta cokelat (sedimen/lumpur).
    *   Menggunakan bobot komposit: `(brightnessScore * 0.40) + (colorScore * 0.60)` dengan pembobotan warna 3.0x agar tetap sensitif dalam kondisi pencahayaan rendah (*low-light*).
    *   Dukungan otomatis decoding format JPEG maupun PNG.

### D. Direct Motor Drive via 4-GPIO Active-LOW (Tanpa Relay)
*   **Fungsi**: Membuka katup pakan mekanis menggunakan motor DC 5V tanpa komponen saklar relay.
*   **Prinsip Kerja Listrik**:
    *   4 Pin GPIO (GPIO 12, 13, 14, 15) disolder gabung secara paralel untuk melipatgandakan arus hingga **160 mA - 240 mA**.
    *   Menggunakan metode **Current Sinking (Active-LOW)**: Motor (+) dihubungkan ke 5V murni, Motor (-) dihubungkan ke gabungan 4 Pin GPIO.
    *   Saat perintah `"dispense"` diterima dari Firebase, ESP32 menyetel ke-4 pin ke `LOW` (0 Volt) secara serentak selama durasi `dispenseDuration` (7 detik), kemudian mengembalikannya ke `HIGH` (3.3 Volt) untuk menghentikan motor.

### E. Wireless Firmware Update (ArduinoOTA)
*   **Fungsi**: Memungkinkan pengunggahan kodingan baru ke ESP32-CAM secara nirkabel (wireless via Wi-Fi) dari Arduino IDE tanpa perlu mencolokkan kabel FTDI setelah upload pertama.

---

## 3. Spesifikasi Perangkat Keras & Rangkaian (Hardware Setup)

### A. Komponen Hardware Utama
1. **ESP32-CAM (AI-Thinker Model)**: Otak utama mikrokontroler & pemroses kamera.
2. **Motor DC 5V (Gearbox)**: Penggerak mekanis pemutar pakan.
3. **Papan ESP32-CAM MB / Charger HP (5V / 2A)**: Sumber listrik utama dan port USB.

### B. Skema Rangkaian Pin (Wiring Diagram Direct 4-Pin)

```text
 ┌────────────────────────────────────────────────────────┐
 │                   ESP32-CAM BOARD                      │
 ├────────────────────────────────────────────────────────┤
 │  Pin 5V ───────────────────────────────────────────────┼─────────► Kabel MERAH Motor (+)
 │                                                        │
 │  Pin 12 (IO12) ──┐                                     │
 │  Pin 13 (IO13)  ──┼── (DISOLDER GABUNG JADI 1) ──────────┼─────────► Kabel PUTIH Motor (-)
 │  Pin 15 (IO15)  ──┼──  UNTUK CURRENT SINKING)          │
 │  Pin 14 (IO14) ──┘                                     │
 └────────────────────────────────────────────────────────┘
```

---

## 4. Struktur Database & Backend (Firebase RTDB)

*   `/aquafeed/command/action`: Menerima instruksi perintah (contoh: `"dispense"` atau `"idle"`).
*   `/aquafeed/command/flash`: Mengontrol lampu flash LED onboard (`"on"` / `"off"`).
*   `/aquafeed/device/`: Menyimpan status konektivitas perangkat (`online` / `offline`).
*   `/aquafeed/logs/`: Menyimpan data histori pemberian pakan.

---

## 5. Struktur Folder Kode (Clean Code Standard)

```text
f:\TA\aquafeed\
├── esp32_firmware/
│   └── feeder_esp32/
│       ├── feeder_esp32.ino        # Firmware utama ESP32 (Firebase, Direct Motor Drive, OTA, Camera)
│       └── app_httpd.cpp           # Server HTTP streaming MJPEG & /capture
├── lib/
│   ├── main.dart                   # Entry point aplikasi Flutter & ProviderScope
│   ├── home_screen.dart            # Halaman utama (Stack Scroll & Floating Mini Player)
│   ├── theme.dart                  # Sistem desain UI (Dark Aquatic Theme & Typography)
│   ├── providers/                  # Business Logic Layer (Riverpod StateNotifiers)
│   │   ├── feed_provider.dart      # Pengelola dosis & perintah pakan
│   │   ├── food_detection_provider.dart # Pengelola deteksi pakan AI auto 10s
│   │   ├── detection_provider.dart # Pengelola deteksi kekeruhan air
│   │   ├── device_provider.dart    # Pengelola status online/offline alat
│   │   └── log_provider.dart       # Pengelola riwayat aktivasi
│   ├── services/                   # Data Layer & Image Processing
│   │   ├── food_detection_service.dart # Engine AI Computer Vision (Color & Blob Detection)
│   │   └── image_analysis_service.dart # Engine Analisis Kekeruhan Air
│   └── widgets/                    # UI Component Layer (Modular Widgets)
│       ├── live_camera_card.dart   # Live Stream Camera & AIBoundingBoxPainter Overlay
│       ├── food_residual_card.dart # Card Status AI Sisa Pakan (AUTO 10s)
│       ├── turbidity_card.dart     # Card Status Kekeruhan Air
│       ├── feeding_control.dart    # Panel Kontrol Dosis & Tombol Beri Pakan
│       ├── custom_header.dart      # Header Status Sistem & Notifikasi
│       └── activity_log.dart       # Daftar Riwayat Log Pakan
└── PENJELASAN_PROYEK.md            # Dokumentasi utama proyek TA
```

---

## 6. Keputusan Rekayasa & Pemecahan Masalah (Engineering Decisions)

1. **Eliminasi Relay Module (Paralel 4-GPIO Active-LOW)**:
   * Menggabungkan GPIO 12, 13, 14, dan 15 secara paralel dengan mode *Current Sinking (Active-LOW)* sehingga total arus listrik naik menjadi 160-240 mA. Ini cukup untuk menggerakkan Motor DC 5V secara langsung tanpa relay, membuat rangkaian lebih hemat, hening, dan ringkas.
2. **Pemanfaatan ArduinoOTA (Wireless Firmware Update)**:
   * Mengeliminasi kebutuhan bongkar-pasang kabel FTDI dengan fitur upload firmware nirkabel via Wi-Fi dari Arduino IDE.
3. **Direct Sensor Capture vs UI Snapshot**:
   * Menghindari *false negative* ("Pakan Habis") saat layar dipause dengan selalu memprioritaskan penangkapan frame langsung dari sensor kamera ESP32-CAM (`/capture`).

---

*Dokumen ini diperbarui secara otomatis untuk mencerminkan status pengembangan dan pencapaian terbaru proyek Tugas Akhir AquaFeed.*