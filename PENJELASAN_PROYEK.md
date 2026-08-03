# 📘 Penjelasan Proyek AquaFeed untuk Tugas Akhir (Updated)

Dokumen ini berisi penjelasan mendalam mengenai arsitektur, fitur, hardware, dan struktur kode proyek **AquaFeed**. Gunakan dokumen ini sebagai referensi utama untuk memahami ekosistem sistem IoT dan AI ini secara keseluruhan.

---

## 1. Konsep Utama Proyek (Architectural Overview)

Proyek ini adalah sistem **Smart Fish Feeder & Water Quality Monitor** berbasis IoT dan Computer Vision/AI yang menghubungkan perangkat keras (Hardware) dengan aplikasi mobile secara *real-time*.

*   **Framework Aplikasi**: Flutter (Dart) dengan arsitektur **Clean UI & Responsive Layout**.
*   **State Management**: **Riverpod (versi 2.6.x)**. Memastikan aliran data yang *type-safe* dan reaktif di seluruh aplikasi.
*   **Backend & Jembatan Komunikasi**: **Firebase Realtime Database (RTDB)**. Digunakan untuk sinkronisasi perintah (*command*) dan status antara aplikasi dan alat secara *real-time*.
*   **Hardware Core**: **ESP32-CAM (AI-Thinker Model)**. Menangani penyiaran video streaming MJPEG, penangkapan citra sensor, dan kontrol langsung motor DC.
*   **Aktuator Pakan (Transistor Driver Circuit)**: **Motor DC 5V** yang dikontrol secara presisi via **Single Pin GPIO 15** menggunakan **Rangkaian Transistor Driver + Dioda Proteksi (Flyback Diode 1N4007)** dengan **Teknik High-Impedance (`INPUT` vs `OUTPUT`)** untuk eliminasi arus bocor 100%.
*   **Wireless Firmware Update (ArduinoOTA)**: Memungkinkan pembaruan program firmware secara *nirkabel (wireless via Wi-Fi)* tanpa perlu colok kabel FTDI lagi setelah upload awal.
*   **AI Engine**: **Computer Vision (Color-Space Thresholding & Blob Detection)** untuk Deteksi Sisa Pakan Ikan dan Analisis Kekeruhan Air secara *real-time*.
*   **Theme & UI**: Desain **Dark Mode** modern (*Midnight Aquatic Theme*) dengan skema warna *Emerald Green*, *Cyan*, *Magenta*, dan *Teal*.

---

## 2. Fitur Utama & Penjelasan Teknis

### A. Real-Time Camera Stream & YouTube-Style Floating Mini Player (PiP)
*   **Fungsi**: Memantau kondisi fisik kolam secara *live video streaming* tanpa terputus.
*   **Teknis**: 
    *   **Video Engine**: Menggunakan `flutter_mjpeg` untuk menangkap stream dari ESP32-CAM (`http://<IP_ESP32>:81/stream`).
    *   **Dynamic PSRAM/DRAM Memory Protection**: Firmware ESP32-CAM secara otomatis mengecek ketersediaan PSRAM via `psramFound()`. Jika terdeteksi, kualitas diatur ke VGA (Double Buffering di PSRAM). Jika tidak, sistem otomatis *fallback* ke DRAM internal (QVGA) secara aman tanpa menyebabkan *malloc error* atau crash.
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

### D. Single-Pin Transistor Motor Driver & High-Impedance Zero-Leakage Control
*   **Fungsi**: Menggerakkan Motor DC 5V pemutar pakan secara langsung menggunakan Rangkaian Driver Transistor Tunggal pada **GPIO 15**.
*   **Prinsip Kerja Listrik & Saklar High-Z**:
    *   **Standby / Mode Mati (0 RPM)**: ESP32-CAM menyetel GPIO 15 ke `pinMode(motorPin, INPUT)`. Mode High-Impedance ini menaikkan resistansi pin hingga >10 MΩ sehingga memutus arus murni (0.000 mA), **menghilangkan total arus bocor (slow creep)** saat tidak memberi makan.
    *   **Mode Beri Pakan (Dispense)**: Saat tombol `"Beri Pakan"` ditekan di HP, GPIO 15 disetel ke `pinMode(motorPin, OUTPUT)` dan ditarik ke `digitalWrite(motorPin, LOW)` selama 7 detik (`dispenseDuration`), memicu Transistor untuk memutar motor secara sangat kencang.

### E. Wireless Firmware Update (ArduinoOTA)
*   **Fungsi**: Memungkinkan pengunggahan kodingan baru ke ESP32-CAM secara nirkabel (wireless via Wi-Fi) dari Arduino IDE tanpa perlu mencolokkan kabel FTDI setelah upload pertama.

---

## 3. Spesifikasi Perangkat Keras & Rangkaian (Hardware Setup)

### A. Komponen Hardware Utama
1. **ESP32-CAM (AI-Thinker Model)**: Otak utama mikrokontroler & pemroses kamera.
2. **Motor DC 5V (Gearbox)**: Penggerak mekanis pemutar pakan.
3. **Transistor (NPN / MOSFET)**: Saklar elektronik penguat arus motor.
4. **Dioda Proteksi (Flyback Diode 1N4007)**: Pelindung ESP32-CAM dari lonjakan tegangan induksi balik motor.
5. **Sumber Daya 5V / 2A (USB / Adaptor HP)**: Sumber listrik utama perangkat.

### B. Skema Rangkaian Pin (Wiring Diagram Transistor Driver)

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 |                            ESP32-CAM BOARD                             |
 ├────────────────────────────────────────────────────────────────────────┤
 |  Pin 5V ───────────────────────────────────┬─────► Kabel MERAH Motor (+)
 |                                            |                           |
 |                                          [DIODA 1N4007]                |
 |                                            | (Dipasang Anoda-Katoda    |
 |  Pin 15 (GPIO 15) ──► Kaki Base Transistor │  Paralel Motor)           |
 |                             │              |                           |
 |                             ▼              ├─────► Kabel PUTIH Motor (-)
 |                    [TRANSISTOR DRIVER] ────┘                           |
 |                             │                                          |
 |  Pin GND ───────────────────┴────────────────────► Ke GND Catu Daya    |
 └────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Struktur Database & Backend (Firebase RTDB)

*   `/aquafeed/command/action`: Menerima instruksi perintah (`"dispense"` atau `"idle"`).
*   `/aquafeed/command/flash`: Mengontrol lampu flash LED onboard (`"on"` / `"off"`).
*   `/aquafeed/device_status`: Menyimpan status konektivitas perangkat (`"Online"` / `"Offline"`).
*   `/aquafeed/last_ping`: Stempel waktu (*timestamp/millis*) ping aktif perangkat.
*   `/aquafeed/logs/`: Menyimpan data histori pemberian pakan.

---

## 5. Struktur Folder Kode (Clean Code Standard)

```text
f:\TA\aquafeed\
├── esp32_firmware/
│   └── feeder_esp32/
│       ├── feeder_esp32.ino        # Firmware utama ESP32 (Firebase, High-Z Motor Driver, OTA, Dynamic PSRAM)
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

1. **Penggunaan Transistor Driver & Teknik High-Impedance (GPIO 15)**:
   * Menggantikan skema relay dan solder paralel multi-pin dengan 1 Transistor Driver + Dioda Proteksi 1N4007 pada GPIO 15. Untuk mengatasi masalah arus bocor (*slow creep*), digunakan saklar software berbasis *High-Impedance*: menyetel GPIO 15 ke `pinMode(INPUT)` saat standby untuk memutus murni arus 0.000 mA, dan beralih ke `pinMode(OUTPUT)` + `LOW` saat memberi pakan.
2. **Dynamic PSRAM/DRAM Memory Protection (`psramFound()`)**:
   * Mencegah *Memory Allocation Error* atau crash `cam_dma_config failed` pada ESP32-CAM dengan mendeteksi ketersediaan PSRAM secara dinamis saat boot dan memilih alokasi memori DRAM secara aman jika PSRAM tidak terdeteksi.
3. **Pemanfaatan ArduinoOTA (Wireless Firmware Update)**:
   * Mengeliminasi kebutuhan bongkar-pasang kabel FTDI dengan fitur upload firmware nirkabel via Wi-Fi dari Arduino IDE.
4. **Direct Sensor Capture vs UI Snapshot**:
   * Menghindari *false negative* ("Pakan Habis") saat layar dipause dengan selalu memprioritaskan penangkapan frame langsung dari sensor kamera ESP32-CAM (`/capture`).

---

*Dokumen ini diperbarui secara otomatis untuk mencerminkan status pengembangan dan pencapaian terbaru proyek Tugas Akhir AquaFeed.*