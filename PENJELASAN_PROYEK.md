# Penjelasan Proyek AquaFeed untuk Tugas Akhir

Dokumen ini berisi penjelasan mendalam mengenai arsitektur, fitur, dan struktur kode proyek **AquaFeed**. Gunakan dokumen ini sebagai referensi saat mempresentasikan proyek kepada dosen pembimbing.

---

## 1. Konsep Utama Proyek (Architectural Overview)

Proyek ini dibangun menggunakan arsitektur **Clean UI & State Management Modern**.

*   **Framework**: Flutter (Dart). Dipilih karena kemampuannya membuat aplikasi lintas platform (Android/iOS) dengan satu basis kode (single codebase).
*   **State Management**: **Riverpod (versi 2.6.x)**. 
    *   *Mengapa Riverpod?* Riverpod adalah state management modern di Flutter yang lebih aman secara tipe (*type-safe*), mencegah error umum (seperti `ProviderNotFoundException`), dan performanya sangat efisien karena hanya merender ulang (*rebuild*) komponen UI yang datanya berubah.
*   **Theme & UI**: Menggunakan antarmuka mode gelap (**Dark Mode UI**) dengan skema warna *Midnight Blue* dan *Cyan*. Desain ini dipilih untuk memberikan kesan teknologi tinggi (High-Tech) yang sesuai dengan alat IoT.

---

## 2. Fitur Utama & Penjelasan Teknis Kode

### A. Real-time Monitoring (Live Camera & Status)
*   **Fungsi**: Menampilkan visualisasi area kolam (simulasi) dan memantau status perangkat keras (hardware) secara langsung.
*   **Implementasi Kode**:
    *   Berada di `lib/widgets/live_camera_card.dart` dan `lib/widgets/status_cards.dart`.
    *   **Kereaktifan**: Widget `StatusCardsSection` menggunakan `ref.watch(deviceProvider)`. Ini berarti UI "mendengarkan" perubahan pada `deviceProvider`. Jika status katup atau servo diubah (misalnya dari server/IoT), UI akan otomatis diperbarui tanpa perlu memuat ulang seluruh halaman.

### B. Smart Feeding Control (Sistem Kontrol Pakan Cerdas)
*   **Fungsi**: Memungkinkan pengguna menentukan dosis pakan dalam satuan gram dan mengirimkan perintah pemberian pakan.
*   **Implementasi Kode (`lib/widgets/feeding_control.dart`)**:
    *   **Logic (Logika)**: Menggunakan `FeedNotifier` di Riverpod untuk menyimpan *state* (kondisi) dosis saat ini.
    *   **Metode**: Terdapat fungsi `incrementDosage()` (tambah dosis) dan `decrementDosage()` (kurangi dosis).
    *   **Eksekusi**: Tombol "Beri Makan" memanggil fungsi `dispenseFeed()`, yang secara logis mengurangi total stok pakan berdasarkan dosis yang dikirimkan.

### C. Monitoring Stok Pakan (Inventory Tracking)
*   **Fungsi**: Menampilkan secara visual sisa pakan yang tersedia di dalam wadah perangkat IoT.
*   **Implementasi Kode**:
    *   Berada di `lib/widgets/status_cards.dart`.
    *   Menggunakan widget `LinearProgressIndicator` (bar progres).
    *   **Perhitungan Dinamis**: Nilai bar progres dihitung secara matematis menggunakan rumus: `feedState.currentStock / feedState.maxCapacity`. Hal ini menunjukkan pemahaman integrasi logika matematika dasar ke dalam antarmuka visual.

### D. Activity Log (Riwayat Aktivitas)
*   **Fungsi**: Mencatat riwayat historis operasional alat (misalnya kapan pakan terakhir diberikan).
*   **Implementasi Kode**:
    *   Berada di `lib/widgets/activity_log.dart`.
    *   Menggunakan `ListView.builder` untuk menampilkan daftar riwayat secara dinamis dan efisien, berapapun jumlah datanya.

---

## 3. Penjelasan Struktur Folder (Arsitektur Direktori)

Struktur proyek ini menerapkan prinsip *Separation of Concerns* (pemisahan tanggung jawab), yang sangat disukai oleh dosen penguji karena menunjukkan standar penulisan kode yang baik (Clean Code):

1.  **`lib/main.dart`**: Titik masuk (*entry point*) aplikasi. Di sini aplikasi dibungkus dengan `ProviderScope`, yang merupakan syarat mutlak agar Riverpod dapat mendistribusikan data ke seluruh aplikasi.
2.  **`lib/providers/`**: Direktori ini khusus menampung *Business Logic*. Semua perhitungan data, integrasi sensor, dan status tersimpan di sini, terpisah dari desain tampilan.
3.  **`lib/widgets/`**: Menampung komponen UI (*User Interface*) yang bersifat modular. Memecah layar utama menjadi potongan-potongan kecil (seperti `feeding_control.dart`, `custom_header.dart`) membuat kode mudah dibaca, dirawat, dan diuji.
4.  **`lib/theme.dart`**: Sentralisasi desain. Menyimpan definisi warna dan gaya huruf (*typography*), sehingga konsistensi desain terjamin di seluruh aplikasi.

---

## 4. Analisis Pemecahan Masalah (Problem Solving)

Jika dosen bertanya mengenai kendala teknis yang dihadapi selama pengembangan, gunakan penjelasan ini:

> *"Selama pengembangan, saya menghadapi tantangan terkait kompatibilitas alat pembangunan (build tools). Plugin penyimpanan lokal membutuhkan **Android NDK (Native Development Kit)** versi spesifik (27+). Selain itu, terjadi konflik *versioning* antara Flutter SDK dan library Riverpod versi 3 terbaru.*
>
> *Sebagai keputusan *engineering*, saya melakukan penyesuaian versi NDK di Gradle untuk memenuhi standar plugin, dan memutuskan untuk menggunakan **Riverpod versi 2.6.1**. Versi 2.x terbukti sangat stabil (Production Ready) dan memiliki kompatibilitas penuh dengan sistem Flutter yang saya gunakan, tanpa mengorbankan performa aplikasi."*

---
*Semoga sukses untuk presentasi Tugas Akhirnya!*