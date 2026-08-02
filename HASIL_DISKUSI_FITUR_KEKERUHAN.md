# 📋 Hasil Akhir Diskusi: Fitur Deteksi Kekeruhan Air

> Dokumen ini adalah rangkuman lengkap dari seluruh diskusi mengenai fitur baru yang akan ditambahkan ke proyek **AquaFeed** — Sistem Deteksi Kekeruhan Air berbasis Image Processing.

---

## 1. Apa Fitur Ini?

Fitur ini memungkinkan aplikasi AquaFeed **mendeteksi tingkat kekeruhan air akuarium secara otomatis** menggunakan kamera ESP32-CAM yang sudah ada, **tanpa sensor tambahan**.

Jika air terdeteksi keruh, aplikasi akan menampilkan **notifikasi peringatan** agar pengguna tahu bahwa air akuarium perlu dibersihkan atau diganti.

### Ringkasan Singkat

| Aspek | Detail |
|---|---|
| **Nama Fitur** | Deteksi Kekeruhan Air (Water Turbidity Detection) |
| **Metode** | Image Processing — Analisis Distribusi Warna & Luminansi |
| **Bukan AI/ML** | Tidak perlu dataset, tidak perlu training model |
| **Hardware tambahan** | Tidak ada — menggunakan ESP32-CAM & flash LED yang sudah ada |
| **Perubahan firmware** | Minimal — hanya menambah kontrol flash LED via Firebase |
| **Kamera** | Dari atas akuarium, melihat ke bawah ke permukaan air |
| **Target** | Akuarium ikan hias |

---

## 2. Mengapa Fitur Ini Bisa Bekerja?

### Prinsip Ilmiah

Air akuarium yang **jernih** dan **keruh** terlihat berbeda secara visual di kamera:

| Kondisi Air | Tampilan di Kamera | Karakteristik Piksel |
|---|---|---|
| **Jernih** | Terang, warna tajam, ikan & dekorasi terlihat jelas | Kecerahan tinggi, warna bervariasi |
| **Keruh (hijau)** | Dominan hijau, seperti air berlumut | Banyak piksel hijau (alga bloom) |
| **Keruh (coklat)** | Dominan coklat/kuning, buram | Banyak piksel coklat (sedimen, sisa pakan) |
| **Keruh (putih/susu)** | Pudar merata, tidak transparan | Kecerahan rendah & merata (bakteri bloom) |

Karena perbedaan ini bisa diukur secara matematis, kita bisa menentukan tingkat kekeruhan **tanpa sensor fisik** — cukup dari gambar kamera.

---

## 3. Cara Kerja Teknis (Image Processing)

### Apa yang Dihitung dari Setiap Foto?

Setiap foto dari kamera terdiri dari ribuan piksel. Setiap piksel punya 3 nilai: **Merah (R)**, **Hijau (G)**, **Biru (B)** (masing-masing 0-255).

Dari piksel-piksel ini, dihitung **3 komponen**:

```
Foto dari kamera (160 x 120 piksel = 19.200 piksel)
    │
    ├── 1. KECERAHAN RATA-RATA
    │   Rumus: (0.299×R + 0.587×G + 0.114×B) per piksel
    │   Lalu dirata-ratakan dari seluruh 19.200 piksel
    │   → Hasil: angka 0-255
    │   → Semakin rendah = semakin gelap = semakin keruh
    │
    ├── 2. RASIO PIKSEL HIJAU (Indikator Alga)
    │   Hitung berapa piksel yang warna hijaunya dominan
    │   (G > R+15 DAN G > B+15)
    │   → Hasil: persentase 0-100%
    │   → Semakin tinggi = semakin banyak alga
    │
    └── 3. RASIO PIKSEL COKLAT (Indikator Sedimen/Lumpur)
        Hitung berapa piksel yang berwarna coklat
        (R > 60, G > 40, B < G, R mendekati G)
        → Hasil: persentase 0-100%
        → Semakin tinggi = semakin banyak sedimen
```

### Bagaimana Menjadi Skor Kekeruhan?

Ketiga komponen digabung dengan **rumus berbobot**:

```
Skor Kekeruhan = (Skor Kecerahan × 50%) + (Skor Hijau × 25%) + (Skor Coklat × 25%)
```

> [!NOTE]
> **Skor Kecerahan dibalik**: Kecerahan tinggi → skor rendah (jernih), kecerahan rendah → skor tinggi (keruh).

### Klasifikasi Level

| Skor | Level | Warna di UI | Arti |
|---|---|---|---|
| 0 – 20 | **Jernih** | 🔵 Biru | Air dalam kondisi sangat baik |
| 20 – 40 | **Normal** | 🟢 Hijau | Air baik, tidak perlu tindakan |
| 40 – 60 | **Agak Keruh** | 🟡 Kuning | Mulai perlu perhatian |
| 60 – 80 | **Keruh** | 🟠 Oranye | Disarankan ganti air / bersihkan filter |
| 80 – 100 | **Sangat Keruh** | 🔴 Merah | Segera ganti air! |

---

## 4. Alur Proses Lengkap

### A. Siklus Analisis Otomatis (Setiap 2 Jam)

Fitur berjalan **sepenuhnya otomatis** setelah user mengaktifkannya. User tidak perlu menyentuh apa pun setelah menekan tombol "Aktifkan".

```
User tekan "Aktifkan Deteksi" (sekali saja)
    │
    └──► Timer otomatis dimulai (setiap 2 jam):
         │
         │  STEP 1: Cek apakah 30 menit terakhir ada pemberian pakan?
         │  │
         │  ├── YA → Skip analisis. Tampilkan "Menunggu air stabil..."
         │  │        (Alasan: pakan yang baru masuk bikin air keruh
         │  │         sementara, bisa bikin hasil salah)
         │  │
         │  └── TIDAK → Lanjut ke analisis:
         │
         │      STEP 2: Nyalakan Flash ESP32
         │      │  App kirim perintah "flash_on" ke Firebase
         │      │  ESP32 baca perintah → nyalakan flash LED (Pin 4)
         │      │  Tunggu 1 detik (biar kamera menyesuaikan cahaya)
         │      │
         │      STEP 3: Ambil Foto
         │      │  App request HTTP ke ESP32: /capture
         │      │  ESP32 kirim 1 frame JPEG ke App
         │      │
         │      STEP 4: Matikan Flash
         │      │  App kirim "flash_off" ke Firebase
         │      │  ESP32 matikan flash LED
         │      │
         │      STEP 5: Analisis Foto
         │      │  Resize gambar ke 160×120 piksel
         │      │  Hitung kecerahan rata-rata
         │      │  Hitung rasio hijau (alga)
         │      │  Hitung rasio coklat (sedimen)
         │      │  Hitung skor kekeruhan komposit (0-100)
         │      │
         │      STEP 6: Tampilkan Hasil di UI
         │      │  Update card kekeruhan dengan skor & level baru
         │      │
         │      STEP 7: Cek apakah air keruh?
         │         │
         │         ├── Skor < 60 → Tampilkan status normal di UI
         │         │
         │         └── Skor ≥ 60 → Tampilkan NOTIFIKASI PERINGATAN:
         │                         "⚠️ Air akuarium terdeteksi keruh!
         │                          Pertimbangkan ganti air atau
         │                          bersihkan filter."
         │
         └──► Tunggu 2 jam... ulangi lagi ↺
```

### B. Analisis Manual

Selain otomatis, user juga bisa menekan tombol **"Analisis Sekarang"** kapan saja untuk langsung menjalankan analisis (melewati jeda 2 jam dan jeda post-pakan).

### C. Post-Feeding Delay (Jeda Setelah Pakan)

```
12:00  🍽️ User memberikan pakan via tombol "BERI PAKAN"
12:00  ⏸️ Sistem catat waktu pemberian pakan
  ...
12:15  ⏰ Timer 2 jam berbunyi → Cek: Pakan terakhir jam 12:00
       → Baru 15 menit lalu → SKIP (belum 30 menit)
       → Tampilkan: "Menunggu air stabil... (15 menit lagi)"
  ...
12:30  ✅ Sudah 30 menit sejak pakan → Boleh analisis lagi
```

> [!IMPORTANT]
> **Mengapa perlu jeda 30 menit?**
> Pemberian pakan ikan menyebabkan partikel pakan tersuspensi di air, membuat air tampak keruh sementara. Setelah 15-30 menit, partikel ini larut atau dimakan ikan, dan air kembali normal. Jika analisis dilakukan saat partikel masih melayang, hasilnya akan **salah** (false positive — terdeteksi keruh padahal sebenarnya normal).

---

## 5. Kontrol Flash LED ESP32

### Mengapa Perlu Flash?

Kamera ESP32-CAM membutuhkan pencahayaan yang **konsisten** untuk hasil analisis yang akurat. Jika hanya mengandalkan cahaya kamar/matahari, hasil bisa berbeda antara siang dan malam.

### Cara Kerja Flash

Flash LED hanya dinyalakan **selama 2-3 detik saat analisis**, bukan menyala terus-menerus.

| Aspek | Detail |
|---|---|
| **Pin GPIO** | Pin 4 (sudah ada di ESP32-CAM) |
| **Durasi nyala** | ± 2-3 detik per siklus analisis |
| **Frekuensi** | Setiap 2 jam (mengikuti siklus analisis) |
| **Total per hari** | ± 12 kali × 3 detik = 36 detik per hari |
| **Dampak ke ikan** | Minimal — sangat singkat |
| **Kontrol** | Via Firebase: `/aquafeed/command/flash` → `"on"` / `"off"` |

### Perubahan Firmware ESP32

Hanya perlu menambahkan beberapa baris di fungsi `loop()`:

```c
// Baca perintah flash dari Firebase
if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/flash")) {
  if (fbdo.dataType() == "string") {
    String flashCmd = fbdo.stringData();
    if (flashCmd == "on") {
      digitalWrite(flashLedPin, HIGH);
    } else if (flashCmd == "off") {
      digitalWrite(flashLedPin, LOW);
    }
  }
}
```

---

## 6. Perubahan pada Proyek AquaFeed

### File Baru

| File | Fungsi |
|---|---|
| `lib/services/image_analysis_service.dart` | Ambil frame dari kamera + hitung skor kekeruhan |
| `lib/providers/detection_provider.dart` | State management: timer, siklus analisis, status |
| `lib/widgets/turbidity_card.dart` | Widget UI card kekeruhan air |

### File yang Dimodifikasi

| File | Perubahan |
|---|---|
| `pubspec.yaml` | Tambah dependency `image` (untuk analisis piksel) |
| `lib/home_screen.dart` | Tambahkan `TurbidityStatusCard` di layout |
| `esp32_firmware/feeder_esp32.ino` | Tambah kontrol flash via Firebase (±5 baris) |

### File yang TIDAK Berubah

- `lib/providers/feed_provider.dart` — tetap sama
- `lib/providers/device_provider.dart` — tetap sama
- `lib/providers/log_provider.dart` — tetap sama
- `lib/widgets/feeding_control.dart` — tetap sama
- `lib/widgets/live_camera_card.dart` — tetap sama
- `lib/widgets/status_cards.dart` — tetap sama
- `lib/theme.dart` — tetap sama

### Struktur Database Firebase (Tambahan)

```
/aquafeed/
├── command/
│   ├── action: "idle"          ← (sudah ada)
│   └── flash: "off"           ← 🆕 kontrol flash LED
├── status/                     ← (sudah ada, tidak berubah)
├── logs/                       ← (sudah ada, tidak berubah)
└── last_ping                   ← (sudah ada, tidak berubah)
```

---

## 7. Tampilan UI di Aplikasi

### Card Kekeruhan Air (Kondisi Normal)

```
┌──────────────────────────────────────┐
│ 💧 KEKERUHAN AIR             [AKTIF] │
│                                       │
│  [💧]  35.2%                          │
│         Normal — Skor 35.2%           │
│                                       │
│  Jernih ▓▓▓▓▓▓▓▓░░░░░░░ Sangat Keruh │
│                                       │
│  ┌──────────────────────────────────┐ │
│  │ ☀ Kecerahan  │ 🌿 Alga  │ 🏔 Sed │ │
│  │     158      │  5.2%    │  3.1% │ │
│  └──────────────────────────────────┘ │
│                                       │
│  [      🔍 ANALISIS SEKARANG       ]  │
└──────────────────────────────────────┘
```

### Banner Peringatan (Jika Air Keruh)

```
┌──────────────────────────────────────┐
│ ⚠️ Air akuarium terdeteksi KERUH!    │
│ Pertimbangkan ganti air atau         │
│ bersihkan filter.      [Tutup] [Cek] │
└──────────────────────────────────────┘
```

### Posisi di Home Screen

```
┌──────────────────────┐
│    Custom Header      │
├──────────────────────┤
│    Live Camera Card   │
├──────────────────────┤
│    Status Cards       │
├──────────────────────┤
│  🆕 Turbidity Card    │  ← Card kekeruhan air (BARU)
├──────────────────────┤
│    Feeding Control    │
├──────────────────────┤
│    Activity Log       │
└──────────────────────┘
```

---

## 8. Istilah untuk Tugas Akhir

### Judul yang Bisa Dipakai

> *"Rancang Bangun Sistem Smart Fish Feeder Berbasis IoT dengan Fitur Monitoring Kekeruhan Air Menggunakan Image Processing"*

### Kata Kunci Teknis

- **Image Processing** (Pengolahan Citra Digital)
- **Analisis Distribusi Warna** (Color Distribution Analysis)
- **Luminansi** (Luminance / Brightness Analysis)
- **Computer Vision**
- **Turbidity Estimation**
- **IoT (Internet of Things)**
- **Real-time Monitoring**
- **Post-Feeding Delay Mechanism**

---

## 9. Ringkasan Akhir

| Pertanyaan | Jawaban |
|---|---|
| Apakah ini AI? | **Tidak**, ini Image Processing (perhitungan matematika) |
| Perlu dataset? | **Tidak** |
| Perlu sensor tambahan? | **Tidak**, pakai kamera yang sudah ada |
| Perlu ubah firmware ESP32? | **Ya, sedikit** (±5 baris untuk kontrol flash) |
| User harus manual? | **Tidak**, semuanya otomatis setelah diaktifkan |
| Interval analisis? | **Setiap 2 jam** (otomatis) + tombol manual |
| Ada pengaman? | **Ya**, jeda 30 menit setelah pemberian pakan |
| Notifikasi? | **Ya**, muncul peringatan jika air terdeteksi keruh |
