# DRAF LAPORAN TUGAS AKHIR
**Judul:** Rancang Bangun Sistem Pemberi Pakan Ikan Otomatis (Smart Feeder) Berbasis Internet of Things (IoT) dengan Integrasi Computer Vision untuk Deteksi Sisa Pakan

---

## BAB I: PENDAHULUAN

### 1.1 Latar Belakang
Kegiatan budidaya ikan sangat bergantung pada manajemen pakan yang baik. Pemberian pakan yang tidak teratur atau berlebihan (overfeeding) tidak hanya membuang biaya pakan secara sia-sia, tetapi juga merusak kualitas air akibat penumpukan amonia dari sisa pakan yang membusuk. Sebaliknya, pemberian pakan yang kurang (underfeeding) dapat menghambat pertumbuhan ikan. 

Di era digital saat ini, teknologi Internet of Things (IoT) memungkinkan otomatisasi pemberian pakan secara presisi dan terintegrasi. Namun, sebagian besar *Smart Feeder* di pasaran hanya beroperasi berdasarkan jadwal waktu tanpa memperhatikan apakah pakan sebelumnya sudah habis dimakan atau belum. Oleh karena itu, diperlukan sebuah sistem cerdas yang mampu mendeteksi ketersediaan sisa pakan di permukaan air secara *real-time* sebelum menjatuhkan pakan baru. Penelitian ini mengusulkan pengembangan "AquaFeed", sebuah sistem otomasi pemberian pakan ikan yang terintegrasi dengan kamera ESP32-CAM dan pengolahan citra (*Computer Vision*) pada sisi klien (*Client-Side AI*) untuk menganalisis sisa pakan, sehingga pemberian pakan menjadi lebih efisien dan kualitas air tetap terjaga.

### 1.2 Rumusan Masalah
1. Bagaimana merancang bangun perangkat keras (*hardware*) pemberi pakan otomatis menggunakan mikrokontroler ESP32-CAM dan modul motor driver L298N?
2. Bagaimana menerapkan arsitektur *Dual-Core* (FreeRTOS) pada ESP32 untuk memisahkan beban *streaming* video dan kendali aktuator?
3. Bagaimana membangun algoritma pengolahan citra (*Computer Vision*) berbasis *Color Thresholding* di sisi klien (Aplikasi Flutter) untuk mendeteksi sisa pakan secara akurat?

### 1.3 Tujuan Penelitian
1. Menghasilkan purwarupa *Smart Feeder* yang dapat dikendalikan dan dipantau dari jarak jauh melalui aplikasi seluler.
2. Menerapkan arsitektur perangkat lunak yang stabil pada ESP32 dengan meminimalisir risiko kegagalan sistem akibat *noise* kelistrikan (EMI) dan kehabisan memori.
3. Mengembangkan aplikasi Android/iOS menggunakan *framework* Flutter yang mampu memproses deteksi sisa pakan secara mandiri tanpa membebani mikrokontroler.

---

## BAB II: TINJAUAN PUSTAKA

### 2.1 Internet of Things (IoT) dan ESP32-CAM
Internet of Things adalah konsep keterhubungan perangkat keras dengan jaringan internet untuk saling bertukar data. ESP32-CAM dipilih sebagai otak dari purwarupa ini karena memiliki modul Wi-Fi internal dan dukungan kamera antarmuka SCCB. ESP32 memiliki prosesor *dual-core* Tensilica LX6 yang memungkinkan penerapan *Real-Time Operating System* (FreeRTOS).

### 2.2 Modul Motor Driver L298N
L298N adalah IC motor driver *H-Bridge* ganda yang mampu mengendalikan kecepatan dan arah putaran motor DC. Penggunaan modul ini sangat vital dalam proyek ini untuk memisahkan beban arus (*current draw*) antara mikrokontroler dan motor, serta berfungsi sebagai peredam lonjakan arus kotor (*Electromagnetic Interference / EMI*) yang kerap menyebabkan mikrokontroler membeku (*hang*).

### 2.3 Computer Vision dan Color Thresholding
*Computer vision* adalah bidang ilmu komputer yang meniru cara pandang manusia dalam mengenali objek digital. *Color Thresholding* adalah salah satu metode segmentasi citra paling efisien. Metode ini bekerja dengan mengubah ruang warna gambar (misal dari RGB ke HSV) untuk mengisolasi piksel dengan pigmen warna tertentu (seperti warna pelet ikan) sambil mengabaikan warna latar belakang (air).

---

## BAB III: METODOLOGI DAN PERANCANGAN SISTEM

### 3.1 Arsitektur Sistem Terdistribusi (Distributed Architecture)
Sistem AquaFeed dirancang dengan memisahkan beban kerja komputasi (Desentralisasi):
1. **Edge (ESP32-CAM):** Bertugas semata-mata sebagai pelayan *Video Streaming* MJPEG dan mengeksekusi kendali motor.
2. **Cloud Broker (Firebase):** Bertindak sebagai *database real-time* yang menjembatani status dan perintah antara perangkat IoT dan aplikasi seluler.
3. **Client-Side (Aplikasi Flutter):** Mengambil alih beban komputasi berat, yaitu menjalankan algoritma *Computer Vision* (AI) untuk mendeteksi sisa pakan menggunakan *resource* *smartphone* pengguna.

### 3.2 Perancangan Perangkat Lunak Mikrokontroler (FreeRTOS)
Untuk mencegah gambar kamera patah-patah (*stuttering*) saat motor bergerak, sistem di-program menggunakan arsitektur bawaan *Dual-Core*:
- **Core 0:** Didedikasikan khusus untuk menjalankan *HTTP Web Server* yang memancarkan bingkai gambar kamera (MJPEG Stream).
- **Core 1:** Menjalankan `loopTask` utama yang menangani sinkronisasi dengan Firebase, pemantauan jadwal internal, dan pengaktifan modul L298N untuk memutar motor selama 6.5 detik.

### 3.3 Perancangan Algoritma Deteksi Pakan (AI)
Algoritma deteksi pakan dibangun menggunakan bahasa Dart di dalam aplikasi Flutter dengan langkah berikut:
1. **Region of Interest (ROI):** Memotong (*crop*) 15% area luar gambar untuk menghilangkan gangguan visual dari dinding akuarium/kolam.
2. **Segmentasi Pigmen Warna:** Memfilter piksel untuk mendeteksi nilai merah/cokelat (karakteristik pelet pakan).
3. **Coverage Area Analysis:** Menghitung rasio jumlah piksel pakan berbanding piksel air untuk menentukan status (Makanan Habis, Sisa Sedikit, atau Menumpuk).
4. **Isolate Processing:** Mengeksekusi algoritma di luar *thread* utama UI menggunakan fungsi `compute()`, sehingga antarmuka aplikasi tidak membeku (*freeze*) selama pemindaian.

---

## BAB IV: IMPLEMENTASI DAN PENGUJIAN

### 4.1 Implementasi Perangkat Keras
Rangkaian terdiri dari ESP32-CAM yang dihubungkan ke modul Motor Driver L298N. Pin GPIO 15 digunakan untuk mengirim sinyal pemicu (trigger) putaran motor maju. Sebuah kapasitor elco (470uF) dipasang melintang pada jalur 5V dan Ground sebagai langkah mitigasi *hardware* untuk meredam *noise* kelistrikan motor yang dapat memicu malfungsi ESP32.

### 4.2 Implementasi Aplikasi Mobile
Aplikasi dibangun menggunakan *framework* Flutter dengan *state management* Riverpod. Aplikasi memiliki dasbor pemantauan *live stream*, kartu status AI dengan animasi *countdown* (hitung mundur 60 detik) untuk memindai otomatis, kartu kendali penjadwalan, dan *log* histori aktivitas.

### 4.3 Pengujian Kinerja Motor dan Kestabilan Sistem
Pada pengujian awal menggunakan transistor biasa, ESP32 mengalami *hang* atau *Crash/Guru Meditation Error* akibat tegangan *drop* (EMI). Setelah sistem dimigrasikan menggunakan modul L298N dan penambahan kapasitor Elco, motor berhasil berputar membuang pakan dengan durasi presisi 6.5 detik tanpa menyebabkan koneksi Wi-Fi maupun siaran video terputus.

### 4.4 Pengujian Algoritma Deteksi
Algoritma AI berhasil mendeteksi persebaran pakan secara akurat. Pengujian menunjukkan bahwa metode penentuan status menggunakan rasio persentase luasan (*Coverage Percentage*) jauh lebih akurat dibandingkan metode *blob counting*, mengingat pakan ikan di air cenderung menggumpal dan menempel satu sama lain. Proses deteksi yang dieksekusi di *Isolate* *smartphone* memakan waktu kurang dari 1 detik dan berhasil mengembalikan status pakan ke UI secara *real-time*.

---

## BAB V: KESIMPULAN DAN SARAN

### 5.1 Kesimpulan
1. Purwarupa *Smart Feeder* AquaFeed berhasil dirancang dan diimplementasikan. Penggunaan modul L298N serta peredam kapasitor terbukti efektif menyelesaikan masalah instabilitas (*hang*) pada ESP32 saat aktuator motor menyala.
2. Pemisahan tugas (*task delegation*) menggunakan kapabilitas *Dual-Core* (FreeRTOS) ESP32 sukses mengisolasi sistem transmisi *live video* sehingga tidak terganggu oleh proses koneksi sinkronisasi Firebase maupun putaran motor.
3. Pemrosesan *Computer Vision* (*Color Thresholding*) yang dipindahkan ke sisi aplikasi seluler (*Client-Side AI*) terbukti sangat efisien. Mikrokontroler ESP32-CAM terhindar dari *overheat* dan batas memori, sementara *smartphone* mampu menganalisis ribuan piksel gambar kurang dari satu detik tanpa membuat antarmuka membeku.

### 5.2 Saran
1. Pengembangan selanjutnya dapat menambahkan sensor beban (*Load Cell* HX711) di dalam tangki wadah pakan untuk mengukur sisa stok pakan dalam hitungan gram secara presisi.
2. Menambahkan fitur *Push Notification* (FCM) agar pengguna mendapatkan notifikasi di layar kunci HP saat pakan sudah dijatuhkan atau jika terjadi kesalahan perangkat.
3. Sistem kalibrasi sensitivitas warna dinamis (*Dynamic Color Threshold Calibration*) dapat ditambahkan di menu pengaturan aplikasi untuk menyesuaikan deteksi dengan merk atau warna pelet ikan yang berbeda-beda.
