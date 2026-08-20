# 📘 Dokumentasi Teknis & Penjelasan Sistem "AquaFeed" (Untuk Sidang Tugas Akhir)

Dokumen ini merupakan referensi akademis dan teknis yang sangat mendalam mengenai arsitektur, algoritma, serta keputusan rekayasa perangkat lunak (*software engineering*) dan perangkat keras (*hardware*) dari proyek **AquaFeed - Smart Fish Feeder & AI-Based Live Monitor**.

---

## 1. Arsitektur Sistem (System Architecture)

Proyek ini menggunakan pendekatan arsitektur **Terdistribusi (Distributed Architecture)** di mana beban komputasi dibagi secara presisi antara mikrokontroler (Edge) dan perangkat *mobile* (Client).

*   **Microcontroller (Edge Device)**: **ESP32-CAM (AI-Thinker Model)**. Dioptimalkan menggunakan arsitektur **FreeRTOS (Real-Time Operating System)** untuk manajemen *Dual-Core*.
*   **Backend & Jembatan Komunikasi**: **Firebase Realtime Database (RTDB)**. Berfungsi sebagai *Message Broker* untuk perintah (*command*), penjadwalan (*scheduling*), status perangkat, dan *Auto-IP Discovery*.
*   **Aplikasi Mobile (Client)**: Dibangun menggunakan **Flutter (Dart)** dengan state management **Riverpod**. Aplikasi tidak hanya bertindak sebagai *remote control*, tetapi juga memikul beban berat komputasi Kecerdasan Buatan (AI) untuk pengolahan citra (*Image Processing*).
*   **Aktuator Elektromekanis**: **Motor DC 5V (Dinamo Gearbox Mini)** yang dikendalikan melalui **Motor Driver L298N Mini (H-Bridge)** untuk menahan beban arus dan memungkinkan putaran dua arah yang lebih aman.

---

## 2. Spesifikasi & Persyaratan Sistem

### A. Persyaratan Perangkat Android
Aplikasi Flutter dapat dijalankan pada perangkat Android dengan versi minimal **5.0 (Lollipop) atau API Level 21** ke atas. Namun, perlu diperhatikan ketentuan berikut:

*   **Fitur Live Monitoring**: Perangkat **wajib terhubung ke jaringan Wi-Fi yang sama** dengan ESP32-CAM. Hal ini dikarenakan *video stream* dikirim langsung dari ESP32-CAM ke aplikasi melalui jaringan lokal (HTTP MJPEG) **tanpa melalui server *cloud***. Sehingga latensi video sangat rendah dan tidak memakan kuota internet.
*   **Fitur Lainnya (Jadwal, Kontrol Manual, Deteksi Pakan)**: Dapat digunakan selama perangkat terhubung ke internet (WiFi maupun data seluler), terlepas dari jaringan yang digunakan, karena fitur-fitur ini berkomunikasi melalui Firebase.

### B. Spesifikasi Minimal Hardware
*   Android **5.0 (Lollipop)** / API Level 21
*   Kamera (untuk fitur deteksi pakan via live stream)
*   Koneksi Wi-Fi (untuk live monitoring)
*   Koneksi Internet (untuk semua fitur Firebase)

---

## 3. Inovasi Utama & Penyelesaian Masalah (Engineering Solutions)

Sistem ini telah melewati berbagai tahap optimalisasi kelas industri untuk mengatasi kelemahan bawaan (keterbatasan memori dan *bandwidth*) pada ESP32-CAM. Berikut adalah rincian mendalam fitur inovatifnya:

### A. AI Color-Based Food Detection & Coverage Analysis (Kecerdasan Buatan di Sisi Klien)
Mendeteksi sisa pakan di dalam air bukanlah hal mudah karena air kolam seringkali keruh atau gelap. AI pada proyek ini menggunakan metode **Computer Vision** yang dirancang khusus (Custom Algorithm):
1.  **Region of Interest (ROI) Cropping**: AI secara otomatis membuang 15% area pinggiran gambar (atas, bawah, kiri, kanan). Hal ini mengeleminasi *noise* berupa tembok wadah, bayangan sudut, atau mesin filter yang sering disalahartikan sebagai pakan. AI murni hanya memindai area tengah air.
2.  **Color-Pigment Thresholding**: Berbeda dengan algoritma kuno yang mencari noda gelap (*grayscale*), AI ini membedah setiap piksel gambar ke dalam struktur RGB (Red, Green, Blue). AI diprogram secara spesifik untuk mencari pelet dengan pigmen dominan **Merah/Pink/Coklat** dan mengabaikan spektrum warna air.
3.  **Blob Counting vs Coverage Percentage**: Jika sisa pakan sedikit (misal 5 butir), AI akan menghitung gumpalan (*Blob Counting*). Namun, jika pakan **menumpuk sangat banyak (menyerupai karpet)**, algoritma blob akan gagal karena menganggapnya sebagai 1 objek raksasa. Untuk mengatasinya, AI mengkalkulasi **Coverage Percentage (Persentase Luas Area)**. Jika area yang tertutup warna pelet > 15%, sistem langsung membunyikan alarm "Menumpuk Sangat Banyak".
4.  **Isolate Processing**: Agar aplikasi tidak macet (*freeze*) saat melakukan perulangan matematika pada jutaan piksel, seluruh perhitungan AI dipindahkan ke **Isolate (Thread terpisah dari UI utama)** pada perangkat HP.

### B. FreeRTOS Dual-Core Load Balancing
ESP32 memiliki dua otak (Core 0 dan Core 1), namun pengaturan bawaan sering menumpuk semua tugas di satu Core. Proyek ini membelah tugas secara paksa:
*   **Core 0**: Didedikasikan 100% secara eksklusif untuk menjalankan Server HTTP guna menangani *streaming video (MJPEG)*.
*   **Core 1 (Loop Bawaan)**: Menjalankan eksekusi utama (Sinkronisasi Firebase, penjadwalan, dan kontrol motor L298N). Awalnya digunakan Custom Task, namun dipindahkan kembali ke `loopTask` bawaan Core 1 untuk **menghemat 8KB SRAM** yang sangat dibutuhkan oleh modul SSL Firebase.

### C. Solusi Kelistrikan & Kendali Motor
Motor DC menghasilkan lonjakan arus listrik saat menyala yang dapat merusak mikrokontroler jika dihubungkan langsung. Solusi fisik yang diterapkan:
1.  **Modul L298N Mini**: Menggantikan skema Transistor tunggal yang rawan bocor arus. L298N memberikan isolasi yang jauh lebih baik terhadap rangkaian logika mikrokontroler, sekaligus memungkinkan pengendalian arah putaran motor (H-Bridge).
2.  **Logika High-Z (GPIO sebagai INPUT saat OFF)**: Saat motor tidak aktif, pin GPIO diset ke mode `INPUT` (high-impedance) bukan `LOW`, sehingga tidak ada arus yang bocor ke motor secara tidak sengaja.

### D. Anti-Spam Memory Lock (Pencegah Crash DMA)
Kamera ESP32-CAM mengirimkan gambar utuh (*Full JPEG*). Jika *user* menekan tombol deteksi pakan berkali-kali secara brutal, ESP32 akan kehabisan RAM (*DMA Memory Exhaustion*).
*   **Solusi**: Diimplementasikan *State Lock* pada aplikasi Flutter. Saat tombol deteksi ditekan, tombol langsung dikunci dan muncul animasi pemindaian, mencegah pemboman *request*.

### E. Independent Smart Schedule System (NTP & Firebase)
Pemberian pakan otomatis tidak bergantung pada HP. Saat ESP32 menyala, ia mengambil jam atom dari server `pool.ntp.org` (WIB GMT+7). Ia mengunduh array jadwal dari Firebase dan mengeksekusinya secara absolut.

### F. Safety Lock pada Perintah Manual
Saat perintah manual (`action: dispense`) diterima oleh ESP32, nilai perintah **langsung direset ke `idle`** sebelum motor dijalankan. Hal ini mencegah motor berputar berulang kali secara tidak sengaja jika koneksi Firebase lambat atau terjadi duplikasi perintah.

### G. Auto-IP Discovery (Menemukan ESP32 Otomatis)
Setiap kali ESP32 menyala dan mendapat IP dari router, ESP32 langsung mengunggah URL stream-nya (`http://[IP]:81/stream`) ke Firebase. Aplikasi Flutter mendengarkan (*listen*) perubahan node ini secara *real-time*, sehingga pengguna tidak perlu mengatur ulang IP secara manual setiap kali ESP32 berpindah jaringan.

---

## 4. Skema Perangkat Keras & Kelistrikan (Hardware Wiring)

Berikut adalah skema koneksi antara charger HP tipe‑C, modul FTDI, ESP32‑CAM, modul driver L298N, dan motor DC 5V (tanpa kapasitor).

 ```text
 ┌────────────────────────────────────────────────────────┐
 │            Charger HP Type-C (5V, Min. 2A)             │
 └──────────────────────────┬─────────────────────────────┘
                            │ (Kabel USB Type-C)
                            ▼
 ┌────────────────────────────────────────────────────────┐
 │            Modul FTDI (USB-to-UART Adapter)            │
 │             [Mode Jumper: 5V Power Supply]             │
 └──────┬────────────┬─────────────┬─────────────┬────────┘
        │ +5V        │ GND         │ TX          │ RX
        │            │             │             │
        │            │             │             │
        │      ┌─────┼─────────────┼─────────────┼─────┐
        │      │     ▼             ▼             ▼     │
        ├────► │  [Pin 5V]      [Pin RX]      [Pin TX] │
        │      │                                       │
        │  ┌─► │  [Pin GND]                            │
        │  │   │               ESP32-CAM               │
        │  │   │                                       │
        │  │   │  [GPIO 15]                   [GPIO 14]│
        │  │   └──────┬───────────────────────────┬────┘
        │  │          │ (Sinyal Maju)             │ (Sinyal Mundur)
        ▼  ▼          ▼                           ▼
 ┌──────┴──┴──────────┴───────────────────────────┴───────┐
 │ [Pin VCC] [Pin GND]      [Pin IN1]          [Pin IN2]  │
 │                                                        │
 │                Modul Motor Driver L298N Mini           │
 │                                                        │
 │               [MOTOR-A +]         [MOTOR-A -]          │
 └────────────────────┬───────────────────┬───────────────┘
                      │ (Kabel Motor)     │ (Kabel Motor)
                      ▼                   ▼
                 [ Terminal Motor DC 5V Gearbox ]
 ```

---

## 5. Alur Kerja (Workflow) Sistem AI Deteksi Pakan

1.  **Pemicu**: Fitur AI dipicu secara otomatis dari dalam aplikasi *background* dengan interval dinamis **1 menit sekali** (beserta *Live Countdown* UI) atau secara **Manual** lewat tombol.
2.  **Frame Extraction**: Aplikasi mengambil *snapshot* langsung dari endpoint `/capture` pada ESP32-CAM (bukan dari *live stream* yang sedang berjalan), sehingga tidak mengganggu tampilan video.
3.  **Color Filtering & Masking**: Gambar diproses di dalam *Isolate*. Tepi gambar dibuang (ROI Cropping 15%). Setiap piksel dievaluasi warnanya.
4.  **Status Determination**:
    *   Jika Butir Pelet <= 2 **DAN** *Coverage Area* < 1.5% ➔ **Kosong / Makanan Habis**
    *   Jika *Coverage Area* < 5.0% ➔ **Sisa Sedikit**
    *   Jika *Coverage Area* 5.0% - 15.0% ➔ **Sisa Sedang (Tunda Makan)**
    *   Jika *Coverage Area* > 15.0% ➔ **Pakan Menumpuk Sangat Banyak**
5.  **Visualisasi**: Hasil analisis dikembalikan ke UI melalui `Riverpod` State Management dan ditampilkan langsung di layar **tanpa dikirim ke Firebase**.

---

## 6. Pengujian Sistem

### A. Pengujian Data Jadwal dan Aktivitas Firebase
Pengujian dilakukan untuk memastikan bahwa sistem dapat menyimpan dan membaca data jadwal serta riwayat aktivitas dengan benar.

| No. | Skenario | Data di Aplikasi | Data di Firebase | Data di ESP32-CAM | Hasil |
|-----|----------|-----------------|-----------------|-------------------|-------|
| 1 | Tambah jadwal 08.00 | Tersimpan | Tersimpan | Terbaca | Berhasil |
| 2 | Tambah jadwal 12.00 | Tersimpan | Tersimpan | Terbaca | Berhasil |
| 3 | Tambah jadwal 18.00 | Tersimpan | Tersimpan | Terbaca | Berhasil |
| 4 | Pemberian pakan otomatis | - | Riwayat tersimpan | Jadwal Dieksekusi | Berhasil |
| 5 | Pemberian pakan manual | Perintah Terkirim | Riwayat tersimpan | - | Berhasil |

### B. Persyaratan Koneksi per Fitur

| Fitur | Koneksi WiFi Lokal (sama dengan ESP32) | Koneksi Internet |
|-------|----------------------------------------|-----------------|
| Live Monitoring (Video Stream) | ✅ Wajib | ❌ Tidak perlu |
| Deteksi Pakan AI | ✅ Wajib (butuh snapshot kamera) | ❌ Tidak perlu |
| Kontrol Manual (Beri Pakan) | ❌ Tidak perlu | ✅ Wajib (via Firebase) |
| Pengaturan Jadwal | ❌ Tidak perlu | ✅ Wajib (via Firebase) |
| Lihat Riwayat Aktivitas | ❌ Tidak perlu | ✅ Wajib (via Firebase) |