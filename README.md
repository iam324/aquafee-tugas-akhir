# 🐟 AquaFeed — Sistem Pemberi Pakan Ikan Otomatis Berbasis IoT

**AquaFeed** adalah aplikasi **Flutter** (mobile) yang dikembangkan sebagai proyek **Tugas Akhir** untuk memonitor dan mengontrol alat pemberi pakan ikan otomatis berbasis **Internet of Things (IoT)** secara *real-time*.

---

## 📱 Fitur Utama

### 1. 🎥 Live Camera Monitoring
- Menampilkan visualisasi area kolam secara *live streaming* melalui kamera ESP32-CAM.
- Fitur **Snapshot** untuk mengambil gambar area kolam.
- Fitur **Pause/Play** untuk mengontrol *stream* kamera.
- Dukungan penggantian URL *stream* secara dinamis.

### 2. 📊 Monitoring Status Perangkat
- Menampilkan **Stok Pakan** (sisa pakan dalam gram) dengan **Progress Bar** visual.
- Menampilkan **Status Alat** (Standby/Offline/Error).
- Menampilkan status **Katup** (Tertutup/Terbuka).
- Menampilkan status **Servo** (Ready/Bergerak).
- Indikator **koneksi Firebase** secara *real-time*.

### 3. 🎛️ Kontrol Pakan Cerdas (*Smart Feeding Control*)
- Input **dosis pakan** dalam satuan gram (gram).
- Tombol **+/-** untuk menambah/mengurangi dosis.
- Tombol **"Beri Makan"** untuk mengeksekusi pemberian pakan langsung ke perangkat IoT.
- Notifikasi *snackbar* setelah pakan diberikan.

### 4. 📋 Log Aktivitas (*Activity Log*)
- Mencatat riwayat pemberian pakan secara otomatis.
- Setiap log menampilkan **judul aktivitas**, **waktu**, dan **status** (sukses/peringatan).

---

## 🏗️ Arsitektur & Teknologi

| Komponen | Teknologi |
|----------|-----------|
| **Framework** | Flutter (Dart) — *Single Codebase* untuk Android & iOS |
| **State Management** | Riverpod 2.6.x — Aman tipe (*type-safe*), performa tinggi, *reactive* |
| **Backend/Database** | Firebase Realtime Database — Sinkronisasi data *real-time* |
| **Theme** | Dark Mode (Midnight Blue & Cyan) — Desain *High-Tech* |
| **Streaming Kamera** | MJPEG via ESP32-CAM |
| **Font** | Google Fonts (Inter) |

## 📂 Struktur Folder

```
lib/
├── main.dart                      # Entry point aplikasi
├── home_screen.dart               # Halaman utama (dashboard)
├── theme.dart                     # Tema dark mode (warna, tipografi)
├── providers/
│   ├── device_provider.dart       # Status perangkat (Firebase)
│   ├── feed_provider.dart         # Stok & dosis pakan (Firebase)
│   └── log_provider.dart          # Log aktivitas (Firebase)
└── widgets/
    ├── custom_header.dart         # Header dengan indikator koneksi
    ├── live_camera_card.dart      # Live streaming kamera ESP32
    ├── status_cards.dart          # Kartu stok pakan & status alat
    ├── feeding_control.dart       # Panel kontrol dosis pakan
    └── activity_log.dart          # Riwayat log aktivitas
```

## ⚙️ Cara Kerja

1. **Aplikasi** (Flutter) terhubung ke **Firebase Realtime Database**.
2. **Perangkat IoT** (ESP32) juga terhubung ke Firebase yang sama.
3. Saat pengguna menekan **"Beri Makan"**:
   - Aplikasi mengirim perintah `dispense` + dosis ke Firebase.
   - ESP32 mendeteksi perubahan tersebut dan menggerakkan **servo/katup**.
   - **Load Cell** membaca berat pakan yang jatuh.
   - Setelah dosis tercapai, servo menutup katup secara otomatis.
   - Data **stok terbaru** dikirim kembali ke Firebase → aplikasi diperbarui secara *real-time*.
4. **Kamera** ESP32-CAM mengirimkan *stream* video MJPEG langsung ke aplikasi.

## 🚀 Cara Menjalankan

```bash
# Clone repositori
git clone https://github.com/iam324/aquafee-tugas-akhir.git

# Masuk ke folder project
cd aquafeed

# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

> **Catatan**: Pastikan sudah mengatur file `google-services.json` dari Firebase Console untuk koneksi database.

## 📚 Dokumentasi Lainnya

- **[PENJELASAN_PROYEK.md](./PENJELASAN_PROYEK.md)** — Penjelasan detail arsitektur, fitur, dan analisis pemecahan masalah.
- **[TAHAP_SELANJUTNYA.md](./TAHAP_SELANJUTNYA.md)** — Panduan integrasi hardware ESP32, Firebase, dan skema elektronika.

---

## 👨‍💻 Developer

Dikembangkan untuk **Tugas Akhir** — Program Studi [Sistem Informasi/Teknik Informatika]

---
*"Smart Feeding, Smarter Aquaculture"* 🐟

# aquafeed

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
