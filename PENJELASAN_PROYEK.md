# 📘 Dokumentasi Teknis & Penjelasan Sistem "AquaFeed" (Untuk Sidang Tugas Akhir)

Dokumen ini merupakan referensi akademis dan teknis yang sangat mendalam mengenai arsitektur, algoritma, serta keputusan rekayasa perangkat lunak (*software engineering*) dan perangkat keras (*hardware*) dari proyek **AquaFeed - Smart Fish Feeder & AI-Based Live Monitor**.

---

## 1. Arsitektur Sistem (System Architecture)

Proyek ini menggunakan pendekatan arsitektur **Terdistribusi (Distributed Architecture)** di mana beban komputasi dibagi secara presisi antara mikrokontroler (Edge) dan perangkat *mobile* (Client).

*   **Microcontroller (Edge Device)**: **ESP32-CAM (AI-Thinker Model)**. Dioptimalkan menggunakan arsitektur **FreeRTOS (Real-Time Operating System)** untuk manajemen *Dual-Core*.
*   **Backend & Jembatan Komunikasi**: **Firebase Realtime Database (RTDB)**. Berfungsi sebagai *Message Broker* untuk perintah (*command*), penjadwalan (*scheduling*), status perangkat, dan *Auto-IP Discovery*.
*   **Aplikasi Mobile (Client)**: Dibangun menggunakan **Flutter (Dart)** dengan state management **Riverpod**. Aplikasi tidak hanya bertindak sebagai *remote control*, tetapi juga memikul beban berat komputasi Kecerdasan Buatan (AI) untuk pengolahan citra (*Image Processing*).
*   **Aktuator Elektromekanis**: **Motor DC 5V** yang dikendalikan melalui **Motor Driver L298N Mini (H-Bridge)** untuk menahan beban arus dan memungkinkan putaran dua arah yang lebih aman.

---

## 2. Inovasi Utama & Penyelesaian Masalah (Engineering Solutions)

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

### C. Solusi Kelistrikan & EMI (Electromagnetic Interference)
Motor DC menghasilkan lonjakan arus listrik kotor (EMI) saat menyala, yang sering membuat ESP32-CAM mengalami *Freeze* (Pingsan/Hang) tanpa henti. Solusi fisik yang diterapkan:
1.  **Kapasitor (Elco) 470uF**: Dipasang secara paralel melintang pada jalur 5V dan GND sebagai "Peredam Kejut" (Shockbreaker) untuk menyerap *noise* radiasi kelistrikan dari motor.
2.  **Modul L298N**: Menggantikan skema Transistor tunggal yang rawan bocor arus. L298N memberikan isolasi yang jauh lebih baik terhadap rangkaian logika mikrokontroler. 

### D. Anti-Spam Memory Lock (Pencegah Crash DMA)
Kamera ESP32-CAM mengirimkan gambar utuh (*Full JPEG*). Jika *user* menekan tombol deteksi pakan berkali-kali secara brutal, ESP32 akan kehabisan RAM (*DMA Memory Exhaustion*).
*   **Solusi**: Diimplementasikan *State Lock* pada aplikasi Flutter. Saat tombol deteksi ditekan, tombol langsung dikunci dan muncul animasi pemindaian, mencegah pemboman *request*.

### E. Independent Smart Schedule System (NTP & Firebase)
Pemberian pakan otomatis tidak bergantung pada HP. Saat ESP32 menyala, ia mengambil jam atom dari server `pool.ntp.org` (WIB GMT+7). Ia mengunduh array jadwal dari Firebase dan mengeksekusinya secara absolut.

---

## 3. Skema Perangkat Keras & Kelistrikan (Hardware Wiring)

Berikut adalah skema final anti-hang dengan mengintegrasikan kapasitor peredam dan modul L298N:

```text
 ┌────────────────────────────────────────────────────────┐
 |                 Adaptor Daya 5V (Min. 2A)              |
 └─┬───────────────────────────────────┬──────────────────┘
   │(+) 5V                             │(-) GND
   │                                   │
   ├────────[ KAPASITOR ELCO 470uF ]───┤  <-- (Peredam Kejut / Noise)
   │                                   │
   ├─► ESP32-CAM Pin 5V                ├─► ESP32-CAM Pin GND
   │                                   │
   └─► L298N Mini Pin VCC (+)          └─► L298N Mini Pin GND (-)

 [Jalur Sinyal Data]
 ESP32-CAM GPIO 15 ──────► L298N Mini (IN1) -> (Putar Maju)
 ESP32-CAM GPIO 14 ──────► L298N Mini (IN2) -> (Tersedia untuk Mundur)

 [Jalur Aktuator]
 L298N Mini MOTOR-A (+) ─► Kabel Motor Kiri
 L298N Mini MOTOR-A (-) ─► Kabel Motor Kanan
```

---

## 4. Alur Kerja (Workflow) Sistem AI Deteksi Pakan

1.  **Pemicu**: Fitur AI dipicu secara otomatis dari dalam aplikasi *background* dengan interval dinamis **1 menit sekali** (beserta *Live Countdown* UI) atau secara **Manual** lewat tombol.
2.  **Frame Extraction**: Aplikasi tidak merepotkan ESP32 untuk mengambil foto baru. Aplikasi mengambil *snapshot* (tangkapan layar digital) langsung dari aliran video (*live stream*) yang sudah berjalan.
3.  **Color Filtering & Masking**: Gambar diproses di matriks *Isolate*. Tepi gambar dibuang (ROI). Setiap piksel dievaluasi warnanya.
4.  **Status Determination**:
    *   Jika Butir Pelet <= 2 dan *Coverage Area* < 1.5% ➔ **Kosong / Makanan Habis**
    *   Jika *Coverage Area* < 5.0% ➔ **Sisa Sedikit**
    *   Jika *Coverage Area* 5.0% - 15.0% ➔ **Sisa Sedang (Tunda Makan)**
    *   Jika *Coverage Area* > 15.0% ➔ **Pakan Menumpuk Sangat Banyak**
5.  **Visualisasi**: Mengembalikan data hasil AI ke `Riverpod` UI.