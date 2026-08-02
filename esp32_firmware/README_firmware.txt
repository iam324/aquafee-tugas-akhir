Instructions for feeder_esp32.ino (Aquafeed Project)

1. Persyaratan (Arduino IDE):
   - Board: AI Thinker ESP32-CAM
   - Libraries (Install via Library Manager):
     * Firebase ESP32 Client (by Mobizt)
   - TIDAK perlu library tambahan lainnya.

2. Konfigurasi Firmware:
   - SSID & Password WiFi: diset di dalam kodingan.
   - API Key & Database URL Firebase: sesuai project "aquafeed-f3451".
   - Durasi motor: ubah variabel `dispenseDuration` (default: 2000ms = 2 detik).

3. Komponen:
   - ESP32-CAM (AI Thinker) + Kamera OV2640
   - FTDI FT232RL (USB-to-Serial, juga sebagai power bridge)
   - Relay Module 2 Channel 5V (pakai 1 channel saja)
   - Motor DC + Gear (dispenser pakan bawaan feeder)
   - Charger HP 5V/2A (power supply via USB FTDI)

4. Rangkaian Upload Firmware (via FTDI ke Laptop):
   FTDI VCC -> ESP32 VCC (kanan)
   FTDI GND -> ESP32 GND (kanan)
   FTDI TXO -> ESP32 U0R (kanan)
   FTDI RXI -> ESP32 U0T (kanan)
   FTDI GND -> ESP32 IO0 (kanan) *HANYA SAAT UPLOAD, cabut setelah selesai!

5. Rangkaian Operasional (FTDI ke Charger HP):
   
   Power (FTDI tetap terpasang, USB pindah ke charger HP):
   FTDI VCC -> ESP32 VCC (kanan)
   FTDI GND -> ESP32 GND (kanan)

   ESP32-CAM sisi KIRI -> Relay Module:
   ESP32 IO13 -> Relay IN1
   ESP32 5V   -> Relay VCC  (pelintir bersama dengan kabel ke NO1)
   ESP32 5V   -> Relay NO1  (pelintir bersama dengan kabel ke VCC)
   ESP32 GND  -> Relay GND  (pelintir bersama dengan kabel ke Motor-)
   
   Relay -> Motor:
   Relay COM1 -> Motor (+)
   ESP32 GND  -> Motor (-)  (pelintir bersama dengan kabel ke Relay GND)

6. Logika Kerja:
   - ESP32 konek WiFi -> konek Firebase.
   - Firmware memantau node `/aquafeed/command/action` di Firebase RTDB.
   - Jika Flutter app kirim "dispense":
     * GPIO 13 = HIGH -> Relay ON -> Motor nyala (2 detik)
     * GPIO 13 = LOW  -> Relay OFF -> Motor mati
     * Status di Firebase diubah ke "idle"
   - Kamera streaming: http://<IP_ESP32>:81/stream
   - Snapshot kamera:  http://<IP_ESP32>/capture

7. Catatan Penting:
   - IO0 HARUS dicabut dari GND setelah upload firmware!
   - Motor DC TIDAK BISA langsung ke GPIO, HARUS lewat Relay.
   - Jika relay aktif LOW (motor nyala terus saat boot), ubah logika di firmware.
   - Pastikan charger HP minimal 5V/2A agar stabil.
