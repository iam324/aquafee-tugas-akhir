# 💡 Ide Pengembangan Aplikasi AquaFeed

> Dokumen ini berisi kumpulan ide pengembangan untuk project Tugas Akhir **AquaFeed** — Sistem Pemberi Pakan Ikan Otomatis Berbasis IoT.
>
> Dibuat untuk: **Mahasiswa D3 Teknik Informatika POLINES**

---

## 📋 Daftar Isi

1. [Dashboard Analytics dengan Grafik 📈](#-a-dashboard-analytics-dengan-grafik)
2. [Penjadwalan Pakan Otomatis ⏰](#-b-penjadwalan-pakan-otomatis)
3. [Monitoring Kualitas Air 🌡️](#-c-monitoring-kualitas-air)
4. [Multi Kolam / Multiple Tank 🏊](#-d-multi-kolam--multiple-tank)
5. [Notifikasi & Alert 🔔](#-e-notifikasi--alert)
6. [Autentikasi Pengguna 🔐](#-f-autentikasi-pengguna)
7. [Dark/Light Mode Toggle 🌓](#-g-darklight-mode-toggle)
8. [Integrasi Load Cell & Feedback Control ⚖️](#-h-integrasi-load-cell--feedback-control)

---

## 🥇 A. Dashboard Analytics dengan Grafik 📈

### Deskripsi
Menambahkan halaman **analitik/statistik** yang menampilkan data historis dalam bentuk grafik visual. Cocok untuk melihat tren konsumsi pakan dan stok dari waktu ke waktu.

### Library yang Dibutuhkan
| Paket | Kegunaan |
|-------|----------|
| `fl_chart` ⭐ | Library grafik paling populer untuk Flutter |
| `intl` | Format tanggal/waktu |

### Fitur yang Bisa Ditambahkan

#### 📈 Grafik Konsumsi Pakan Harian
- **Sumbu X**: Tanggal (Senin, Selasa, ...)
- **Sumbu Y**: Jumlah pakan (gram)
- **Bar chart** untuk melihat pola konsumsi

#### 📉 Grafik Sisa Stok
- **Line chart** menunjukkan penurunan stok
- Bisa lihat kapan stok harus diisi ulang

#### 📊 Ringkasan Statistik
- Total pakan minggu ini
- Rata-rata per hari
- Pemberian pakan terbanyak

### Tampilan yang Disarankan
```
┌─────────────────────────────┐
│  📊 ANALYTICS               │
│  Total: 340g  Rata2: 48g/h  │
│  ╭──╮  ╭──╮  ╭──╮         │
│  │  │  │  │  │  │  ╭──╮    │
│  │  │  │  │  │  │  │  │    │
│  Sen Sel Rab Kam Jum Sab Min│
│  Stok: ████████████░░░░ 342g│
└─────────────────────────────┘
```

### Tingkat Kesulitan
🟢 **Mudah** — Bisa dikerjakan 1-2 hari

## 🥇 B. Penjadwalan Pakan Otomatis ⏰

### Deskripsi
Fitur untuk mengatur jadwal pemberian pakan **otomatis** tanpa harus menekan tombol manual. ESP32 akan membaca jadwal dari Firebase dan mengeksekusi pemberian pakan sesuai waktu yang ditentukan.

### Arsitektur Data Firebase
```json
{
  "aquafeed": {
    "schedule": {
      "feed1": { "time": "08:00", "dosage": 25, "active": true },
      "feed2": { "time": "14:00", "dosage": 20, "active": true },
      "feed3": { "time": "18:00", "dosage": 15, "active": false }
    }
  }
}
```

### Fitur di Aplikasi Flutter
- Tambah jadwal baru (pilih jam + dosis)
- Edit jadwal
- Hapus jadwal
- Aktif/nonaktifkan jadwal (toggle switch)

### Tampilan yang Disarankan
```
┌─────────────────────────────┐
│  ⏰ JADWAL PAKAN            │
│  ┌─────────────────────┐   │
│  │ 🌅 08:00  |  25g   ●│   │
│  │ Setiap hari  Aktif  │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ ☀️ 14:00  |  20g   ●│   │
│  │ Setiap hari  Aktif  │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 🌙 18:00  |  15g   ○│   │
│  │ Setiap hari  Mati   │   │
│  └─────────────────────┘   │
│       [ + Tambah Jadwal ]   │
└─────────────────────────────┘
```

### Kode Provider Flutter (Konsep)
```dart
class ScheduleNotifier extends Notifier<List<FeedingSchedule>> {
  @override
  List<FeedingSchedule> build() { return []; }
  Future<void> addSchedule(String time, int dosage) async { /* push Firebase */ }
  Future<void> toggleSchedule(String id, bool active) async { /* update */ }
  Future<void> deleteSchedule(String id) async { /* hapus */ }
}
```

### Tips ESP32
1. Sinkronisasi waktu via NTP: `configTime(0, 0, "pool.ntp.org")`
2. Loop cek jadwal tiap 30 detik
3. Simpan timestamp eksekusi terakhir untuk cegah duplikasi

### Tingkat Kesulitan
🟡 **Sedang** — Butuh 3-4 hari (Flutter + Firebase + ESP32)


## 🥈 C. Monitoring Kualitas Air 🌡️

### Deskripsi
Menambahkan sensor **suhu air** dan **pH** ke dalam sistem. Data dari sensor dikirim ke Firebase dan ditampilkan di aplikasi secara real-time.

### Komponen Hardware Tambahan
| Komponen | Estimasi Harga | Fungsi |
|----------|---------------|--------|
| DS18B20 (suhu) | Rp15.000 - Rp25.000 | Mengukur suhu air |
| Sensor pH | Rp50.000 - Rp150.000 | Mengukur pH air |

### Struktur Data Firebase
```json
{
  "aquafeed": {
    "water_quality": {
      "temperature": 28.5,
      "ph": 7.2,
      "last_updated": "2026-05-22 10:30:00"
    }
  }
}
```

### Kode ESP32 (Suhu DS18B20)
```cpp
#include <OneWire.h>
#include <DallasTemperature.h>
#define ONE_WIRE_BUS 14
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
sensors.requestTemperatures();
float tempC = sensors.getTempCByIndex(0);
```

### Tingkat Kesulitan
🔴 **Agak Sulit** — Butuh hardware tambahan dan pengkabelan


## 🥈 D. Multi Kolam / Multiple Tank 🏊

### Deskripsi
Mendukung pemantauan **lebih dari satu kolam** dalam satu aplikasi.

### Struktur Data Firebase
```json
{
  "aquafeed": {
    "ponds": {
      "kolam_a": { "current_stock": 340, "temperature": 28.5 },
      "kolam_b": { "current_stock": 500, "temperature": 27.8 }
    }
  }
}
```

### Tampilan di Flutter
- **Dropdown** atau **Tab Bar** untuk pilih kolam
- Atau **ListView** ringkasan semua kolam

### Tingkat Kesulitan
🟡 **Sedang** — Butuh perubahan struktur data + UI


## 🥉 E. Notifikasi & Alert 🔔

### Deskripsi
Memberikan notifikasi ke HP pengguna untuk kondisi-kondisi penting.

### Jenis Notifikasi
| Jenis | Kondisi | Warna |
|-------|---------|-------|
| ⚠️ Peringatan | Stok pakan < 100g | Kuning |
| 🔴 Darurat | ESP32 offline > 5 menit | Merah |
| ✅ Sukses | Pakan berhasil diberikan | Hijau |
| 📅 Pengingat | Jadwal pakan akan tiba | Biru |

### Library
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  firebase_messaging: ^15.0.0
```

### Tingkat Kesulitan
🟢 **Mudah - Sedang** — 2-3 hari


## 🥉 F. Autentikasi Pengguna 🔐

### Deskripsi
Menambahkan sistem **login/register** agar aplikasi tidak bisa dipakai sembarangan.

### Fitur
- Register dengan email & password
- Login & Logout
- Lupa password
- Setiap user punya data Firebase sendiri

### Library
```yaml
dependencies:
  firebase_auth: ^5.0.0
```

### Alur
```
Register → Login → Dashboard (data diproteksi by User UID)
```

### Tingkat Kesulitan
🟡 **Sedang** — 2-3 hari


## 🎁 G. Dark/Light Mode Toggle 🌓

### Deskripsi
Tambahkan tombol untuk mengganti tema antara **Dark Mode** (sekarang) dan **Light Mode**.

### Cara Implementasi
```dart
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);
  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
```

### Tingkat Kesulitan
🟢 **Mudah** — 1 hari


## ⚠️ H. Integrasi Load Cell & Feedback Control ⚖️

### Deskripsi
> **Catatan**: Ini adalah **INTI dari judul TA Anda!** Saat ini sistem hanya pakai `delay(2000)`. Dengan Load Cell, feedback control benar-benar berjalan.

### Logika Feedback Control
```
User set 25g → Servo BUKA → Load Cell baca ↓ berat
→ Berat < target? → Ya: Lanjut | Tidak: Tutup katup
→ Update stok ke Firebase
```

### Kode ESP32 (Konsep)
```cpp
#include "HX711.h"
#define DT_PIN 4
#define SCK_PIN 5
HX711 scale;

void dispenseWithFeedback(int targetGram) {
  float initialWeight = scale.get_units(10);
  float targetWeight = initialWeight - targetGram;
  ledcWrite(servoPin, dutyOpen);
  float currentWeight = initialWeight;
  while (currentWeight > targetWeight) {
    currentWeight = scale.get_units(5);
    Firebase.RTDB.setFloat(&fbdo, "/aquafeed/current_stock", currentWeight);
    delay(200);
  }
  ledcWrite(servoPin, dutyClose);
}
```

### Tingkat Kesulitan
🟡 **Sedang** — Butuh wiring + kalibrasi Load Cell



---

## 🎯 PRIORITAS SARAN PENGERJAAN

| Prioritas | Fitur | Dampak ke Nilai | Estimasi Waktu |
|-----------|-------|-----------------|----------------|
| 🥇 | **Dashboard Grafik (fl_chart)** | 🔥🔥🔥🔥 | 1-2 hari |
| 🥇 | **Penjadwalan Otomatis** | 🔥🔥🔥🔥 | 3-4 hari |
| 🥈 | **Notifikasi & Alert** | 🔥🔥🔥 | 2-3 hari |
| 🥈 | **Dark/Light Mode** | 🔥🔥🔥 | 1 hari |
| 🥉 | **Autentikasi Pengguna** | 🔥🔥 | 2-3 hari |
| 🥉 | **Multi Kolam** | 🔥🔥 | 3-4 hari |
| 🎁 | **Monitoring Kualitas Air** | 🔥🔥🔥🔥🔥 | 5-7 hari + HW |
| ⚠️ | **Load Cell Feedback Control** | 🔥🔥🔥🔥🔥 | 3-5 hari + HW |

## 📚 Library Tambahan

```yaml
dependencies:
  fl_chart: ^0.70.0                 # Grafik
  intl: ^0.19.0                     # Format tanggal
  flutter_local_notifications: ^17.0.0  # Notif lokal
  firebase_auth: ^5.0.0             # Autentikasi
  firebase_messaging: ^15.0.0       # Push notif
  go_router: ^14.0.0                # Navigasi
```

---

## 💬 Penutup

Project **AquaFeed** sudah memiliki fondasi yang kuat. Dengan menambahkan fitur-fitur di atas (terutama **Grafik** dan **Penjadwalan**), project Anda akan semakin matang untuk dinilai.

> **Tips:** Jangan ubah semuanya sekaligus. Pilih 2-3 fitur prioritas, kerjakan satu per satu, pastikan semuanya berfungsi dengan baik.

Selamat mengerjakan Tugas Akhir! 🐟💪
