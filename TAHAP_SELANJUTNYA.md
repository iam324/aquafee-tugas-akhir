# Tahapan Selanjutnya: Menjembatani Aplikasi dengan Hardware

Setelah aplikasi Flutter (User Interface) selesai dan bisa di-build dengan baik, langkah selanjutnya sebelum merakit alat fisik adalah **Membangun Jembatan Komunikasi (Technical Bridge)**. Sesuai dengan metode *Waterfall*, tahap perancangan teknis ini krusial agar perangkat keras (ESP32) dan perangkat lunak (Flutter) dapat saling berkomunikasi.

Berikut adalah tahapan-tahapan yang harus kamu lakukan:

---

## 1. Integrasi Database Real-time (Firebase)
Aplikasi seluler dan alat IoT tidak bisa berkomunikasi secara langsung (kecuali lewat Bluetooth/Lokal, yang mana tidak ideal untuk jarak jauh). Keduanya membutuhkan "server penengah". **Firebase Realtime Database** adalah pilihan standar industri untuk IoT.

*   **Yang harus dilakukan di Flutter:**
    *   Mendaftarkan proyek di Firebase Console.
    *   Mengunduh `google-services.json` dan memasukkannya ke folder `android/app/`.
    *   Menambahkan package `firebase_core` dan `firebase_database` ke `pubspec.yaml`.
    *   Mengubah logika di `FeedNotifier` agar tidak hanya mengubah state lokal, tetapi juga mengirim (Push) perintah ke Firebase.

## 2. Merancang Struktur Data Komunikasi (JSON Schema)
Sebelum memprogram ESP32, kamu harus menetapkan format data baku di Firebase. Ini adalah "bahasa" yang disepakati antara aplikasi dan alat.

**Contoh Struktur Data yang disarankan:**
```json
{
  "aquafeed": {
    "device_status": "standby",  // 'standby', 'offline', 'error'
    "command": {
      "action": "idle",          // Berubah menjadi 'dispense' saat tombol ditekan
      "target_dosage_gram": 25   // Angka yang dikirim dari aplikasi
    },
    "sensors": {
      "current_stock_gram": 342, // Data riil dari Load Cell
      "valve_status": "closed"
    },
    "last_activity": "2024-05-22 10:30:15"
  }
}
```
*Dengan struktur ini, saat aplikasi mengubah `action` menjadi `dispense`, ESP32 yang terus memantau (listen) Firebase akan langsung merespons dan menggerakkan servo.*

## 3. Desain Skema Elektronika (Wiring Diagram)
Sebelum merakit, petakan jalur kabel terlebih dahulu untuk menghindari *short-circuit* (korsleting) atau kesalahan penggunaan Pin.
*   **ESP32 Pinout:** ESP32 memiliki banyak pin, tetapi tidak semua aman digunakan. Beberapa pin akan mengeluarkan sinyal saat perangkat baru dinyalakan (booting), yang bisa membuat servo bergerak tiba-tiba (*jitter*).
*   **Panduan Pin:**
    *   **Motor Servo:** Gunakan pin yang mendukung PWM (misal: GPIO 18, 19, 21).
    *   **Sensor Berat (Load Cell HX711):** Gunakan GPIO standar (misal: DT ke GPIO 4, SCK ke GPIO 5).
    *   **Kelistrikan:** Modul kamera (ESP32-CAM) dan Motor Servo butuh arus listrik (Ampere) yang besar. **Jangan** mengambil daya servo langsung dari pin 5V ESP32 jika menggunakan power bank kecil, gunakan Modul Step-Down/Regulator jika perlu.

## 4. Penulisan Firmware Dasar ESP32 (Skeleton Code)
Jangan langsung menulis kode lengkap untuk servo, kamera, dan timbangan sekaligus. Mulailah dengan program sederhana secara bertahap:
1.  **Tahap 1:** Tulis kode ESP32 untuk konek ke WiFi rumah/kampus.
2.  **Tahap 2:** Tulis kode ESP32 untuk membaca angka `target_dosage_gram` dari Firebase dan menampilkannya di Serial Monitor komputer.
3.  **Tahap 3:** Tulis kode untuk mengirim angka *dummy* (acak) dari ESP32 ke Firebase untuk melihat apakah angka di aplikasi Flutter kamu berubah.

---

### 💡 Tips Presentasi Progress ke Dosen Pembimbing
Untuk menunjukkan bahwa kamu menguasai proyek ini, buatlah sebuah **Diagram Alir Komunikasi Data (Data Flow Diagram)** saat bimbingan:
1.  **Aplikasi (Flutter)**: Pengguna memasukkan dosis (25g) -> Tekan tombol "Beri Makan".
2.  **Server (Firebase)**: Menerima perintah -> Mengubah status `command` menjadi `dispense`.
3.  **Hardware (ESP32)**: Mendeteksi perubahan di Firebase -> Menggerakkan Katup (Servo).
4.  **Hardware (Load Cell)**: Membaca berat pakan yang jatuh -> Jika sudah mencapai 25g, tutup katup.
5.  **Feedback**: ESP32 update data sisa stok di Firebase -> Aplikasi Flutter memperbarui tampilan progres bar di HP pengguna.