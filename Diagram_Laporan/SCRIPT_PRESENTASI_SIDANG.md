# 🎓 Naskah Presentasi Sidang Tugas Akhir: AquaFeed

Dokumen ini dirancang sebagai panduan lisan (script) untuk mempresentasikan sistem Anda di depan dosen penguji. Gunakan poin-poin ini saat mendemonstrasikan alat.

---

## 1. Pembukaan & Alur Keseluruhan Sistem (System Flow)

**[Sambil menunjukkan alat atau slide arsitektur]**
> *"Bapak/Ibu Dosen Penguji yang saya hormati, perkenalkan ini adalah **AquaFeed**, sebuah sistem pemberi pakan ikan cerdas berbasis IoT dan Kecerdasan Buatan (AI).* 
> 
> *Alur kerja sistem ini menggunakan arsitektur **Terdistribusi (Edge-to-Client)**. Pusat komunikasinya menggunakan **Firebase Realtime Database** sebagai jembatan. Saat aplikasi di HP mengirim perintah atau jadwal, data tersebut masuk ke Firebase. Kemudian, ESP32-CAM yang selalu siaga akan membaca perintah tersebut dan menggerakkan motor.*
> 
> *Di saat yang bersamaan, kamera ESP32-CAM terus mengirimkan video langsung (live streaming) ke aplikasi HP. Aplikasi HP inilah yang bertugas menangkap gambar dari video tersebut, memprosesnya dengan AI, dan menentukan apakah pakan di kolam masih tersisa atau sudah habis."*

---

## 2. Penjelasan Fitur Utama dan Kode (Engineering Solutions)

Dosen penguji biasanya akan menguji pemahaman Anda tentang **"Bagaimana kode ini bekerja?"** dan **"Mengapa Anda memilih cara ini?"**. Berikut adalah jawaban teknisnya:

### A. Penggunaan FreeRTOS (Dual-Core Load Balancing)
**[Tunjukkan file `feeder_esp32.ino` bagian `xTaskCreatePinnedToCore`]**
> *"Kelemahan utama ESP32-CAM adalah rawan putus koneksi (disconnect) jika dipaksa mengirim video dan mengambil data internet secara bersamaan. Untuk mengatasi bottleneck ini, saya mengimplementasikan **FreeRTOS (Real-Time Operating System)**.*
> 
> *Saya membelah tugas ke dalam dua otak prosesor ESP32:*
> 1. *Core 0: Secara eksklusif didedikasikan oleh sistem untuk menangani server HTTP streaming video.*
> 2. *Core 1: Saya buatkan tugas khusus bernama `feederTask` untuk mengecek jadwal di Firebase dan mengatur pergerakan Motor.*
> 
> *Dengan pembagian (Load Balancing) ini, video tidak akan patah-patah secara drastis atau hang saat alat sedang mengeksekusi pakan."*

### B. Fitur Anti-Macet pada Motor (L298N H-Bridge)
**[Tunjukkan bagian fungsi `dispenseAction()` di kode Arduino]**
> *"Untuk aktuator pakan, saya tidak menggunakan relay atau transistor biasa, melainkan modul **Motor Driver L298N Mini (H-Bridge)**. Alasannya bukan sekadar perlindungan daya listrik (Brownout protection), melainkan untuk fitur logika **Anti-Jamming (Anti-Macet)**.*
> 
> *Di dalam fungsi `dispenseAction()`, ketika perintah pakan turun, motor tidak langsung berputar maju. Motor diprogram untuk berputar **MUNDUR** selama 0.3 detik terlebih dahulu untuk menghancurkan pelet yang menyumbat corong, berhenti sejenak, baru berputar **MAJU** dengan durasi yang dikunci tepat 7000 ms (7 detik). Ini memastikan konsistensi volume pakan baik secara jadwal otomatis maupun manual."*

### C. Client-Side AI Processing (Mengapa AI di HP?)
**[Tunjukkan file Flutter `food_detection_provider.dart` atau layar HP]**
> *"Untuk mendeteksi sisa pakan, saya membuat keputusan arsitektur kelas industri yaitu: **Client-Side AI Processing**.*
> 
> *Jika algoritma Computer Vision (deteksi piksel, Blob counting, RGB thresholding) dipaksakan berjalan di ESP32, perangkat tersebut akan mengalami Overheat (kepanasan) dan kehabisan RAM. Oleh karena itu, saya menjadikan ESP32 murni hanya sebagai 'Mata' (pengirim video), sedangkan 'Otak' AI-nya sepenuhnya dijalankan di Smartphone.*
> 
> *Aplikasi menangkap frame gambar, mengeksekusinya di thread terpisah (Isolate) agar UI aplikasi tidak freeze, lalu menghitung persentase area (*Coverage Percentage*) warna pelet untuk menyimpulkan status 'Sisa Sedikit' atau 'Menumpuk'."*

### D. Sistem Pengaman Restart (Boot Guard Flag)
**[Tunjukkan variabel `bootReady` di kode Arduino]**
> *"Seringkali perangkat IoT yang menggunakan GPIO tertentu (seperti GPIO 15) akan mengalami 'kedutan' saat alat baru dihidupkan, menyebabkan motor berputar tanpa sengaja. Selain itu, perangkat bisa mengeksekusi perintah basi yang masih tersisa di Firebase.*
> 
> *Untuk itu saya memprogram mekanisme **Boot Guard**. Variabel `bootReady` menahan motor tetap mati selama 3 detik pertama setelah alat menyala. Di waktu yang sama, sistem secara otomatis menimpa status di Firebase menjadi "idle" (menghapus perintah lama). Setelah alat stabil, barulah kunci dibuka. Motor dijamin 100% tidak akan pernah berputar liar tanpa perintah sah."*

---

## 3. Kesimpulan Presentasi (Closing)

> *"Kesimpulannya, sistem AquaFeed tidak hanya sekadar alat otomasi on/off biasa. Proyek ini mendemonstrasikan penyelesaian masalah keterbatasan hardware (IoT) melalui optimasi software yang meliputi implementasi RTOS, pemindahan komputasi AI ke Edge-Client, sistem penjadwalan presisi, dan pertahanan kelistrikan menggunakan Driver H-Bridge.*
> 
> *Sekian presentasi dari saya, saya siap menerima pertanyaan dari Bapak/Ibu Penguji."*
