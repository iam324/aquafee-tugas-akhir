# 🐟 AquaFeed — Sistem Pemberi Pakan Ikan Otomatis Berbasis IoT & AI

**AquaFeed** adalah aplikasi **Flutter** (mobile) yang dikembangkan sebagai proyek **Tugas Akhir** untuk memonitor, menjadwalkan, dan mengontrol alat pemberi pakan ikan otomatis berbasis **Internet of Things (IoT)** secara *real-time*. Proyek ini dilengkapi dengan teknologi **Kecerdasan Buatan (AI)** di sisi klien untuk mendeteksi sisa pakan.

---

## 📱 Fitur Utama

### 1. 🎥 Live Camera Monitoring & AI Food Detection
- Menampilkan visualisasi area kolam secara *live streaming* melalui kamera ESP32-CAM.
- **Kecerdasan Buatan (AI) Client-Side**: Aplikasi memproses video stream menggunakan metode *Computer Vision* (Color-Pigment Thresholding & Coverage Area Analysis) untuk mendeteksi apakah sisa pakan di kolam telah habis, sisa sedikit, atau menumpuk.
- AI dijalankan menggunakan sistem **Isolate (Multithreading)** pada *smartphone* agar UI aplikasi tetap mulus dan ESP32 terhindar dari *overheat*.

### 2. 🎛️ Kontrol Pakan Cerdas & Penjadwalan (*Smart Feeding & Scheduling*)
- Pemberian pakan dapat dilakukan secara **Manual** (Beri Pakan Sekarang) langsung dari aplikasi.
- Sistem **Penjadwalan Waktu (Scheduler)** otomatis yang tersinkronisasi via Internet Time (NTP) dan Firebase. 
- Durasi putaran motor dikunci secara presisi menggunakan *hardware timer* untuk memastikan konsistensi keluaran pakan.

### 3. 📊 Monitoring Status Perangkat
- Menampilkan **Status Alat** (Online/Offline/Error).
- Menampilkan notifikasi visual secara *real-time* mengenai aktivitas kamera dan status deteksi sisa pakan.
- Indikator **koneksi Firebase** dan *Ping* secara *real-time*.

### 4. 📋 Log Aktivitas (*Activity Log*)
- Mencatat riwayat pemberian pakan secara otomatis, baik yang dilakukan secara manual maupun jadwal otomatis.
- Setiap log menampilkan **judul aktivitas**, **waktu**, dan **status** keberhasilan.

---

## 🏗️ Arsitektur & Teknologi

Sistem ini menerapkan konsep **Distributed Architecture (Arsitektur Terdistribusi)** di mana beban komputasi dibagi antara perangkat *Edge* dan *Client*:

| Komponen | Teknologi | Keterangan |
|----------|-----------|------------|
| **Client / Mobile App** | Flutter (Dart) & Riverpod | Menjalankan *State Management* dan komputasi berat algoritma **AI Image Processing**. |
| **Backend / Broker** | Firebase Realtime Database (RTDB) | Jembatan komunikasi *real-time* untuk perintah, status, dan *Auto-IP Discovery*. |
| **Edge / Microcontroller** | ESP32-CAM (AI-Thinker) | Berfungsi murni sebagai pengirim *video stream* dan penggerak *actuator*. |
| **Sistem Operasi Edge** | FreeRTOS (Dual-Core) | **Core 0** menangani *Video Streaming*. **Core 1** (*feederTask*) menangani Firebase & Motor. |
| **Actuator Driver** | L298N Mini (H-Bridge) | Mengendalikan Motor DC dengan aman, mencegah *brownout* / restart akibat *Noise Kelistrikan (EMI)*. |

## ⚙️ Cara Kerja Sistem (Alur Singkat)

1. **Aplikasi Flutter** dan **ESP32-CAM** terhubung ke **Firebase Realtime Database**.
2. Kamera ESP32-CAM (Core 0) secara konstan mengirimkan *stream* video MJPEG ke IP lokal jaringan.
3. Aplikasi menangkap *stream* tersebut, dan pengguna dapat mengaktifkan fitur **AI Deteksi Sisa Pakan** yang akan membedah warna piksel RGB dari video tersebut di HP pengguna.
4. Saat waktu **Jadwal** tiba atau tombol **Beri Makan** ditekan, ESP32 (Core 1) membaca perintah tersebut dari Firebase.
5. ESP32 mengaktifkan modul **L298N** untuk memutar Motor DC maju selama sekian detik.
6. Catatan riwayat pakan otomatis dikirim kembali ke Firebase dan masuk ke menu **Log Aktivitas** di aplikasi.

---

## 🚀 Cara Menjalankan Project (Developer)

```bash
# Clone repositori
git clone https://github.com/iam324/aquafee-tugas-akhir.git

# Masuk ke folder project
cd aquafeed

# Install dependencies Flutter
flutter pub get

# Jalankan aplikasi (Disarankan menggunakan perangkat fisik Android/iOS untuk performa AI)
flutter run --release
```

> **Catatan**: Pastikan Anda sudah mengatur file `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) dari Firebase Console Anda sendiri.

## 📚 Dokumentasi Analisis Lengkap

Untuk melihat dokumentasi teknis mendalam mengenai arsitektur, metode algoritma AI, dan keputusan teknik kelistrikan, silakan baca:
- **[PENJELASAN_PROYEK.md](./PENJELASAN_PROYEK.md)** — Wajib dibaca untuk memahami arsitektur AI, FreeRTOS, dan pemecahan masalah *hardware*.
- **[panduan_pemasangan_L9110S.md](./panduan_pemasangan_L9110S.md)** — Skema kelistrikan motor driver H-Bridge ke ESP32.

---

## 👨‍💻 Developer

Dikembangkan untuk **Tugas Akhir**
*"Smart Feeding, Smarter Aquaculture"* 🐟
