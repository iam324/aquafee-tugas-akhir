Instructions for feeder_esp32.ino (Aquafeed Project)

1. Persyaratan (Arduino IDE):
   - Board: AI Thinker ESP32-CAM
   - Libraries (Install via Library Manager):
     * Firebase ESP32 Client (by Mobizt)
     * ESP32Servo (by Kevin Harrington)

2. Konfigurasi Firmware:
   - SSID & Password WiFi sudah diset di kodingan.
   - API Key & Database URL Firebase sudah diset sesuai project "aquafeed-f3451".
   - Jika ingin mengubah perilaku servo, sesuaikan `posOpen` dan `posClose` di dalam kode.

3. Skema Pemasangan Pin (Wiring):
   PENTING: Gunakan catu daya 5V yang stabil untuk ESP32-CAM dan Servo.
   
   Servo SG90 -> ESP32-CAM:
   - Kabel Cokelat (GND) -> Pin GND ESP32-CAM
   - Kabel Merah (VCC)   -> Pin 5V ESP32-CAM
   - Kabel Oranye (Data) -> Pin GPIO 13 ESP32-CAM

4. Logika Kerja:
   - Firmware memantau node `/aquafeed/command/action` di Firebase Realtime Database.
   - Jika Aplikasi Flutter mengirim perintah "dispense", Servo akan bergerak ke 90 derajat selama 2 detik, lalu kembali ke 0 derajat.
   - Setelah selesai, status di Firebase akan diubah kembali ke "idle".

5. Catatan Tambahan:
   - Pastikan antena ESP32-CAM terpasang dengan baik jika sinyal lemah.
   - Jika servo bergetar atau ESP32 restart saat servo bergerak, gunakan sumber daya eksternal 5V 2A untuk Servo dan hubungkan GND Servo ke GND ESP32.
