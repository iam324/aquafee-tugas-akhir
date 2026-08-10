# 📘 Dokumentasi Teknis & Penjelasan Sistem "AquaFeed" (Untuk Sidang Tugas Akhir)

Dokumen ini merupakan referensi akademis dan teknis yang sangat mendalam mengenai arsitektur, algoritma, serta keputusan rekayasa perangkat lunak (*software engineering*) dan perangkat keras (*hardware*) dari proyek **AquaFeed - Smart Fish Feeder & AI-Based Live Monitor**.

---

## 1. Arsitektur Sistem (System Architecture)

Proyek ini menggunakan pendekatan arsitektur **Terdistribusi (Distributed Architecture)** di mana beban komputasi dibagi secara presisi antara mikrokontroler (Edge) dan perangkat *mobile* (Client).

*   **Microcontroller (Edge Device)**: **ESP32-CAM (AI-Thinker Model)**. Dioptimalkan menggunakan arsitektur **FreeRTOS (Real-Time Operating System)** untuk manajemen *Dual-Core*.
*   **Backend & Jembatan Komunikasi**: **Firebase Realtime Database (RTDB)**. Berfungsi sebagai *Message Broker* untuk perintah (*command*), penjadwalan (*scheduling*), status perangkat, dan *Auto-IP Discovery*.
*   **Aplikasi Mobile (Client)**: Dibangun menggunakan **Flutter (Dart)** dengan state management **Riverpod**. Aplikasi tidak hanya bertindak sebagai *remote control*, tetapi juga memikul beban berat komputasi Kecerdasan Buatan (AI) untuk pengolahan citra (*Image Processing*).
*   **Aktuator Elektromekanis**: **Motor DC 5V** yang dikendalikan melalui pin **GPIO 15** dengan rangkaian penguat arus (*Transistor Driver*) berlapis Dioda Flyback.

---

## 2. Inovasi Utama & Penyelesaian Masalah (Engineering Solutions)

Sistem ini telah melewati berbagai tahap optimalisasi kelas industri untuk mengatasi kelemahan bawaan (keterbatasan memori dan *bandwidth*) pada ESP32-CAM. Berikut adalah rincian mendalam fitur inovatifnya:

### A. AI Color-Based Food Detection & Coverage Analysis (Kecerdasan Buatan di Sisi Klien)
Mendeteksi sisa pakan di dalam air bukanlah hal mudah karena air kolam seringkali keruh atau gelap. AI pada proyek ini menggunakan metode **Computer Vision** yang dirancang khusus (Custom Algorithm):
1.  **Region of Interest (ROI) Cropping**: AI secara otomatis membuang 15% area pinggiran gambar (atas, bawah, kiri, kanan). Hal ini mengeleminasi *noise* berupa tembok wadah, bayangan sudut, atau mesin filter yang sering disalahartikan sebagai pakan. AI murni hanya memindai area tengah air.
2.  **Color-Pigment Thresholding**: Berbeda dengan algoritma kuno yang mencari noda gelap (*grayscale*), AI ini membedah setiap piksel gambar ke dalam struktur RGB (Red, Green, Blue). AI diprogram secara spesifik untuk mencari pelet dengan pigmen dominan **Merah/Pink** (`R > G + 20 && R > B + 20`) dan **Hijau Terang** (`G > R + 15 && G > B + 15`). Ini membuat AI sangat tahan terhadap air kolam yang gelap atau kusam, karena air kusam tidak memiliki pigmen cerah.
3.  **Blob Counting vs Coverage Percentage**: Jika sisa pakan sedikit (misal 5 butir), AI akan menghitung gumpalan (*Blob Counting*). Namun, jika pakan **menumpuk sangat banyak (menyerupai karpet)**, algoritma blob akan gagal karena menganggapnya sebagai 1 objek raksasa. Untuk mengatasinya, AI mengkalkulasi **Coverage Percentage (Persentase Luas Area)**. Jika area yang tertutup warna pelet > 15%, sistem langsung membunyikan alarm "Menumpuk Sangat Banyak".
4.  **Isolate Processing**: Agar aplikasi tidak macet (*freeze*) saat melakukan perulangan matematika pada jutaan piksel, seluruh perhitungan AI dipindahkan ke **Isolate (Thread terpisah dari UI utama)** pada perangkat HP.

### B. FreeRTOS Dual-Core Load Balancing
ESP32 memiliki dua otak (Core 0 dan Core 1), namun pengaturan bawaan sering menumpuk semua tugas di satu Core. Proyek ini membelah tugas secara paksa:
*   **Core 0**: Didedikasikan 100% secara eksklusif untuk menjalankan Server HTTP guna menangani *streaming video (MJPEG)*.
*   **Core 1 (Feeder Task)**: Menjalankan *Task* mandiri (`xTaskCreatePinnedToCore`) berkapasitas memori besar (8192 Bytes). Tugas ini menangani sinkronisasi Firebase, mengecek jam internet (NTP), fitur OTA Update, dan menjalankan motor. Dengan pemisahan ini, video tidak akan putus saat alat sedang menjatuhkan pakan, dan alat tidak akan hang.

### C. Watchdog Optimization & Extreme Bandwidth Compression
ESP32-CAM rentan mengalami *Hardware Watchdog Reset* (alat mati dan *restart* sendiri) jika *bandwidth* Wi-Fi melemah atau kepanasan. Solusi yang diterapkan:
1.  **Resolusi QVGA + Kompresi Agresif**: Resolusi kamera diturunkan menjadi **320x240 (QVGA)** dengan tingkat kualitas kompresi JPEG ditingkatkan ke **angka 20**. Ini membuat ukuran data video menjadi **super kecil**, sehingga jaringan Wi-Fi selemah apa pun sanggup memutar video pada **30 FPS (sangat mulus tanpa patah-patah)**.
2.  **Delay Yielding**: Disematkan `vTaskDelay(1)` pada loop pemompaan frame kamera untuk memberikan 1 milidetik waktu bernapas bagi modul Wi-Fi dan sistem keamanan mikrokontroler (Watchdog).

### D. Anti-Spam Memory Lock (Pencegah Crash DMA)
Kamera ESP32-CAM mengirimkan gambar utuh (*Full JPEG*). Jika *user* menekan tombol deteksi pakan berkali-kali secara brutal, ESP32 akan kehabisan RAM (*DMA Memory Exhaustion*) karena dipaksa melayani banyak request bersamaan, yang berujung pada alat terputus (*disconnect*).
*   **Solusi**: Diimplementasikan *State Lock* pada aplikasi Flutter. Saat tombol deteksi ditekan, tombol langsung berubah menjadi *Loading Spinner* dan **dikunci secara fisik** hingga AI selesai menganalisis. Ini melindungi ESP32 dari pemboman *request*.

### E. Silent Auto-Reconnect Stream
Jika video tiba-tiba putus (*drop*) karena gangguan sesaat pada sinyal Wi-Fi, aplikasi tidak lagi macet di layar putih. Sistem *Error Builder* di Flutter akan mendeteksinya, kemudian memicu fungsi *Silent Auto-Reconnect* setiap 3 detik secara diam-diam di latar belakang hingga koneksi video pulih kembali tanpa menyusahkan pengguna.

### F. Independent Smart Schedule System (NTP & Firebase)
Pemberian pakan otomatis tidak bergantung pada HP. Saat ESP32 menyala, ia mengambil jam atom dari server `pool.ntp.org` (WIB GMT+7). Ia mengunduh array jadwal dari Firebase dan mengeksekusinya secara absolut. Jika waktu cocok, alat menumpahkan pakan dan mengirimkan histori/log aktivitas kembali ke Firebase. Walaupun HP dimatikan, sistem penjadwalan ini tetap berjalan mandiri di dalam mikrokontroler.

### G. Non-Blocking Motor (High-Impedance Zero-Leakage)
*   **Non-Blocking**: Putaran motor tidak menggunakan fungsi usang `delay()` yang membekukan sistem. Digunakan *Yielding While-Loop* `vTaskDelay` sehingga jadwal dan koneksi Wi-Fi tidak *timeout*.
*   **High-Z State**: Saat motor diam (idle), pin mikrokontroler (GPIO 15) diubah ke mode `INPUT`. Ini memutus aliran listrik secara sempurna (*High-Impedance*), memastikan tidak ada satu mili-Ampere pun arus bocor yang masuk ke Transistor yang berisiko membuat motor berdengung atau panas.

---

## 3. Skema Perangkat Keras & Kelistrikan (Hardware Wiring)

Aliran daya sangat krusial. Motor DC menarik arus yang kuat (Spike Current) yang bisa menyebabkan *Voltage Drop*, membuat ESP32 merestart sistem Wi-Fi nya. Oleh karena itu digunakan **Adaptor Eksternal 5V berdaya tinggi (Minimal 2 Ampere)** dengan skema proteksi sbb:

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 |                            ESP32-CAM BOARD                             |
 ├────────────────────────────────────────────────────────────────────────┤
 |  Pin 5V (Tegangan Utama) ──────────────────┬─────► Kabel MERAH Motor (+)
 |                                            |                           |
 |                                          [DIODA 1N4007]                |
 |  Pin 15 (Sinyal/Trigger) ─► Kaki BASE      | (Dipasang arah terbalik   |
 |                             Transistor     |  / paralel dengan Motor   |
 |                             │              |  sebagai penahan arus     |
 |                             ▼              |  balik/Flyback)           |
 |                    [TRANSISTOR NPN] ───────┼─────► Kabel PUTIH Motor (-)
 |                             │                                          |
 |  Pin GND (Massa) ───────────┴────────────────────► Ke GND (Massa)      |
 └────────────────────────────────────────────────────────────────────────┘
```
**Peran Dioda Flyback**: Saat motor berhenti, kumparan dinamo menghasilkan tendangan tegangan mundur (*Back EMF*) yang bisa merusak mikrokontroler. Dioda ini membuang tegangan liar tersebut.

---

## 4. Alur Kerja (Workflow) Sistem AI Deteksi Pakan

1.  **Pemicu**: Fitur AI dipicu secara otomatis dari dalam aplikasi *background* (berdasarkan perulangan Timer **6 jam sekali**) atau secara **Manual** lewat sentuhan ikon kaca pembesar.
2.  **Frame Extraction**: Aplikasi tidak merepotkan ESP32 untuk mengambil foto baru. Aplikasi mengambil *snapshot* (tangkapan layar digital) langsung dari aliran video (*live stream*) yang sudah berjalan di UI.
3.  **Color Filtering & Masking**: Gambar masuk ke pemrosesan matriks *Isolate*. Tepi gambar dibuang (ROI). Setiap sisa piksel dievaluasi warnanya (Merah/Hijau/Gelap). Piksel yang lolos uji warna ditandai (*Masking = True*).
4.  **Blob Detection (DFS)**: Algoritma *Depth-First Search* menelusuri piksel-piksel yang bersentuhan untuk membentuk kelompok objek (Pelet).
5.  **Status Determination**:
    *   Jika Butir Pelet <= 2 dan *Coverage Area* < 1.5% ➔ **Kosong / Makanan Habis**
    *   Jika *Coverage Area* < 5.0% ➔ **Sisa Sedikit**
    *   Jika *Coverage Area* 5.0% - 15.0% ➔ **Sisa Sedang (Tunda Makan)**
    *   Jika *Coverage Area* > 15.0% ➔ **Pakan Menumpuk Sangat Banyak (Bahaya Air Keruh)**
6.  **Visualisasi**: Mengembalikan data hasil AI ke state `Riverpod`, membuka gembok pelindung tombol (*loading spinner*), dan menampilkan hasil status di aplikasi.