# Penjelasan Proyek AquaFeed untuk Tugas Akhir

Dokumen ini berisi penjelasan mendalam mengenai arsitektur, fitur, dan struktur kode proyek **AquaFeed**. Gunakan dokumen ini sebagai referensi utama untuk memahami ekosistem sistem IoT ini secara keseluruhan.

---

## 1. Konsep Utama Proyek (Architectural Overview)

Proyek ini adalah sistem **Smart Fish Feeder** berbasis IoT yang menghubungkan perangkat keras (Hardware) dengan aplikasi mobile secara *real-time*.

*   **Framework Aplikasi**: Flutter (Dart) dengan arsitektur **Clean UI**.
*   **State Management**: **Riverpod (versi 2.6.x)**. Memastikan aliran data yang *type-safe* dan reaktif di seluruh aplikasi.
*   **Backend & Jembatan Komunikasi**: **Firebase Realtime Database (RTDB)**. Digunakan untuk sinkronisasi perintah (*command*) dan status antara aplikasi dan alat.
*   **Hardware Core**: **ESP32-CAM**. Menangani pengambilan gambar (video streaming) dan kontrol aktuator (Servo).
*   **Theme & UI**: Desain **Dark Mode** modern dengan skema warna *Midnight Blue* dan *Cyan* untuk kesan teknologi tinggi.

---

## 2. Fitur Utama & Penjelasan Teknis

### A. Real-time Monitoring (Live Camera & Status)
*   **Fungsi**: Menampilkan visualisasi kolam secara langsung dan memantau status komponen hardware.
*   **Teknis**: 
    *   **Video**: Menggunakan `flutter_mjpeg` untuk menangkap stream dari ESP32-CAM.
    *   **Status**: UI "mendengarkan" node `/aquafeed/device/` di Firebase melalui `deviceProvider`. Jika status berubah di sisi alat, UI diperbarui secara otomatis tanpa refresh.

### B. Smart Feeding Control (Kontrol Pakan Cerdas)
*   **Fungsi**: Kontrol presisi pemberian pakan berdasarkan dosis (gram).
*   **Implementasi**:
    *   Pengguna mengatur dosis di `lib/widgets/feeding_control.dart`.
    *   Saat tombol ditekan, aplikasi mengirim string `"dispense"` ke node `/aquafeed/command/action` di Firebase.
    *   ESP32 mendeteksi perubahan ini, menggerakkan servo, lalu mengembalikan status ke `"idle"`.

### C. Monitoring Stok Pakan (Inventory Tracking)
*   **Fungsi**: Melacak sisa pakan di wadah.
*   **Logika**: Menggunakan perhitungan matematis dinamis: `currentStock / maxCapacity`. Data stok dikelola oleh `feed_provider.dart` dan disinkronkan ke Firebase.

### D. Activity Log (Riwayat)
*   **Activity Log**: Mencatat setiap sesi pemberian pakan (Waktu, Dosis, Status) di `lib/providers/log_provider.dart`.

---

## 3. Integrasi Hardware & Backend

### A. Firmware ESP32-CAM (`esp32_firmware/feeder_esp32.ino`)
*   **Konektivitas**: Menggunakan library `Firebase_ESP_Client` untuk komunikasi RTDB.
*   **Kamera**: Menginisialisasi sensor kamera AI-Thinker untuk streaming MJPEG di port lokal.
*   **Aktuator**: Menggunakan `ledcWrite` untuk kontrol presisi motor servo yang membuka/menutup katup pakan.

### B. Struktur Database (Firebase RTDB)
*   `/aquafeed/command/action`: Menerima instruksi (contoh: `"dispense"`).
*   `/aquafeed/status/`: Menyimpan data sensor dan kondisi alat saat ini.
*   `/aquafeed/logs/`: Menyimpan data historis pemberian pakan.

---

## 4. Struktur Folder & Clean Code

1.  **`lib/providers/`**: (Business Logic) Tempat pengelolaan data dan komunikasi API/Firebase.
2.  **`lib/widgets/`**: (Modular UI) Komponen antarmuka yang dapat digunakan kembali (Reusable).
3.  **`lib/screens/`**: (Pages) Definisi halaman utama dan navigasi.
4.  **`lib/theme.dart`**: (Styling) Pusat konfigurasi warna dan tipografi.

---

## 5. Analisis Pemecahan Masalah (Engineering Decisions)

*   **Pemilihan Versi Library**: Menggunakan Riverpod 2.6.1 karena stabilitasnya dibandingkan versi 3 yang masih memiliki banyak perubahan mendasar (*breaking changes*).
*   **Android Compatibility**: Penyesuaian NDK versi 27+ di `build.gradle` untuk mendukung library native yang dibutuhkan oleh plugin penyimpanan.
*   **Efisiensi Data**: Penggunaan Firebase RTDB (bukan Firestore) dipilih karena latensi yang lebih rendah untuk perintah kontrol real-time.

---
*Dokumen ini diperbarui secara otomatis untuk mencerminkan status pengembangan terbaru.*