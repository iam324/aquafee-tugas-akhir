# 📘 Penjelasan Proyek AquaFeed untuk Tugas Akhir (Final Update)

Dokumen ini berisi penjelasan mendalam mengenai arsitektur, fitur, hardware, dan struktur kode proyek **AquaFeed**. Gunakan dokumen ini sebagai referensi utama untuk memahami ekosistem sistem IoT ini secara keseluruhan. Pembaruan terakhir ini mencakup penghapusan fitur AI untuk stabilitas, penambahan sistem jadwal mandiri, dan perbaikan performa streaming.

---

## 1. Konsep Utama Proyek (Architectural Overview)

Proyek ini adalah sistem **Smart Fish Feeder & Live Monitor** berbasis IoT yang menghubungkan perangkat keras (Hardware) dengan aplikasi mobile secara *real-time*, dengan fokus pada keandalan operasional (*reliability*) dan efisiensi memori.

*   **Framework Aplikasi**: Flutter (Dart) dengan arsitektur **Clean UI & Responsive Layout**.
*   **State Management**: **Riverpod (versi 2.6.x)**. Memastikan aliran data yang *type-safe* dan reaktif di seluruh aplikasi.
*   **Backend & Jembatan Komunikasi**: **Firebase Realtime Database (RTDB)**. Digunakan untuk sinkronisasi perintah (*command*), jadwal otomatis, dan pelaporan IP perangkat secara *real-time*.
*   **Hardware Core**: **ESP32-CAM (AI-Thinker Model)**. Menangani penyiaran video streaming MJPEG, penjadwalan mandiri via NTP, dan kontrol motor DC.
*   **Aktuator Pakan**: **Motor DC 5V** yang dikontrol secara presisi via **Single Pin GPIO 15** menggunakan **Rangkaian Transistor Driver + Dioda Proteksi** dengan **Teknik High-Impedance**.
*   **Theme & UI**: Sistem **Dynamic Theme** (Teal Dark, Pink Light, Ocean Light) yang bisa diubah *on-the-fly* lewat menu Appearance.

---

## 2. Fitur Utama & Penjelasan Teknis

### A. Real-Time Camera Stream & True-Live Floating Mini Player (PiP)
*   **Fungsi**: Memantau kondisi fisik kolam secara *live video streaming* tanpa terputus.
*   **Teknis**: 
    *   **Auto-IP Publish**: Setiap kali menyala, ESP32-CAM secara otomatis mengirimkan IP Address lokalnya (contoh: `http://192.168.x.x:81/stream`) ke Firebase RTDB. Aplikasi Flutter secara dinamis mendengarkan (*listen*) perubahan URL ini, sehingga pengguna tidak perlu lagi mengetik IP manual saat router berubah.
    *   **True-Live Floating Mini Player**: Saat pengguna melakukan *scroll* ke bawah, jendela video mini otomatis muncul di pojok kanan bawah. Karena ESP32-CAM hanya mampu melayani **1 koneksi stream**, aplikasi dirancang dengan logika *Single-Stream Takeover*: Kamera utama di-*pause* dan koneksinya dipindahkan secara mulus ke Mini Player, memastikan video tetap **LIVE** tanpa membuat sistem ESP32 *crash* atau terbebani.

### B. Independent Smart Schedule System (Jadwal Mandiri ESP32)
*   **Fungsi**: Memberi makan ikan secara otomatis sesuai jam yang ditentukan, terlepas dari apakah aplikasi HP sedang dibuka, ditutup, atau bahkan di-*uninstall*.
*   **Teknis**:
    *   **NTP Time Sync**: Saat *boot*, ESP32-CAM terhubung ke server `pool.ntp.org` untuk mensinkronisasi jam internalnya ke zona waktu GMT+7.
    *   **Firebase JSON Polling**: ESP32 secara rutin membaca daftar jadwal (array JSON) dari `/aquafeed/schedule` di Firebase RTDB.
    *   **Autonomous Execution**: Ketika waktu internal ESP32 cocok dengan waktu jadwal, alat akan langsung memutar motor dan mengirim *Activity Log* kembali ke Firebase secara mandiri tanpa campur tangan HP.

### C. Non-Blocking Motor Driver & High-Impedance Zero-Leakage
*   **Fungsi**: Menggerakkan Motor DC 5V pemutar pakan dengan aman tanpa memutus koneksi Wi-Fi.
*   **Teknis (Non-Blocking Loop)**: Putaran motor tidak lagi menggunakan fungsi `delay()` yang membekukan mikrokontroler. Digunakan loop `while(millis())` sambil memanggil `ArduinoOTA.handle()` dan `delay(10)`. Ini memastikan **sistem anti-hang**; Wi-Fi, OTA, dan Streaming Kamera tetap hidup meskipun motor sedang menyala.
*   **Standby High-Z**: Saat tidak aktif, pin motor (GPIO 15) dialihkan ke mode `INPUT` (High-Impedance) untuk memutus arus bocor hingga 0.000 mA. Saat aktif, pin diubah ke `OUTPUT` dan ditarik `LOW`.

### D. Wireless Firmware Update (ArduinoOTA)
*   **Fungsi**: Memungkinkan pengunggahan program baru ke ESP32-CAM secara nirkabel (wireless via Wi-Fi) dari Arduino IDE tanpa perlu kabel FTDI.

---

## 3. Spesifikasi Perangkat Keras & Rangkaian (Hardware Setup)

### A. Komponen Hardware Utama
1. **ESP32-CAM (AI-Thinker Model)**: Otak utama mikrokontroler & pemroses kamera.
2. **Motor DC 5V (Gearbox)**: Penggerak mekanis pemutar pakan (Drum feeder mechanism).
3. **Transistor (NPN / MOSFET)**: Saklar elektronik penguat arus motor.
4. **Dioda Proteksi (Flyback Diode 1N4007)**: Pelindung ESP32-CAM dari lonjakan tegangan balik motor.
5. **Sumber Daya 5V / 2A+**: Adaptor eksternal berdaya tinggi (sangat diwajibkan agar koneksi Wi-Fi tidak drop saat motor berputar).

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

*   `/aquafeed/stream_url`: URL dinamis (Auto-IP) yang dikirim oleh ESP32.
*   `/aquafeed/command/action`: Menerima instruksi manual (`"dispense"` atau `"idle"`).
*   `/aquafeed/device_status`: Menyimpan status konektivitas perangkat (`"Online"` / `"Offline"`).
*   `/aquafeed/last_ping`: Stempel waktu (*timestamp/millis*) ping aktif perangkat.
*   `/aquafeed/schedule`: Array JSON berisi daftar jadwal otomatis (time, dosage, active).
*   `/aquafeed/logs/`: Menyimpan histori/riwayat pemberian pakan otomatis maupun manual.

---

## 5. Struktur Folder Kode (Clean Code Standard)

```text
f:\TA\aquafeed\
├── esp32_firmware/
│   └── feeder_esp32/
│       ├── feeder_esp32.ino        # Firmware ESP32 (Firebase Auto-IP, Non-blocking Motor, OTA, NTP Schedule)
│       └── app_httpd.cpp           # Server HTTP streaming MJPEG
├── lib/
│   ├── main.dart                   # Entry point aplikasi & Theme Provider Scope
│   ├── home_screen.dart            # Halaman utama (Stack Scroll & True-Live Mini Player)
│   ├── theme.dart                  # Sistem Warna Dinamis (Teal Dark, Pink Light, Ocean Light)
│   ├── providers/                  # Business Logic Layer
│   │   ├── theme_provider.dart     # Pengelola perubahan tema UI
│   │   ├── feed_provider.dart      # Pengelola perintah pakan manual
│   │   ├── device_provider.dart    # Pengelola status online/offline
│   │   └── log_provider.dart       # Pengelola riwayat log
│   ├── screens/                    
│   │   └── settings_screen.dart    # Menu Appearance (Pemilihan Tema Aplikasi)
│   └── widgets/                    # UI Component Layer
│       ├── live_camera_card.dart   # Live Stream MJPEG Card
│       ├── feeding_control.dart    # Panel Kontrol & Tombol Beri Pakan
│       ├── custom_header.dart      # Header Status Sistem & Notifikasi
│       ├── schedule_card.dart      # Editor Daftar Jadwal Pakan
│       └── activity_log.dart       # Daftar Riwayat Log Pakan
└── PENJELASAN_PROYEK.md            # Dokumentasi utama proyek
```

---

## 6. Keputusan Rekayasa Utama (Engineering Decisions)

1. **Penghapusan AI untuk Skalabilitas Memori & Performa Jaringan**: 
   Awalnya terdapat Computer Vision. Dihapus secara total demi memfokuskan ESP32-CAM murni pada stabilitas MJPEG Stream dan sistem *scheduling*, mengatasi masalah memori (*hang*) karena *overload HTTP request* beruntun.
2. **Sistem Motor Non-Blocking (Anti-Hang)**: 
   Fungsi `delay()` yang sebelumnya membekukan *chip* selama motor berputar telah diganti dengan *Yielding While-Loop* `delay(10)`. Hasilnya, koneksi Wi-Fi Firebase dan video stream tidak terputus (*disconnect*) saat pemberian pakan berlangsung.
3. **Single-Stream Takeover pada UI**: 
   Karena keterbatasan koneksi ESP32 (1 klien), UI Flutter dirancang untuk melepas koneksi kamera utama saat fitur *Floating Player* aktif, lalu meresume-nya secara otomatis. Ini menghilangkan kebutuhan request ganda (*dual-stream*) yang selalu membuat ESP32 lumpuh.
4. **Auto-IP Firebase Mechanism**: 
   Menggunakan Firebase RTDB sebagai jembatan *service discovery*. Setiap terkoneksi Wi-Fi baru, ESP32 meletakkan IP-nya di database sehingga Flutter *app* tidak pernah kehilangan jejak lokasi stream kamera.