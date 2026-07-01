# Dokumentasi Rangkaian Hardware AquaFeed (Smart Fish Feeder)

Dokumen ini berisi panduan skema kelistrikan dan penyambungan pin (wiring) untuk memastikan alat AquaFeed dapat dirakit ulang tanpa terjadi *crash* (mati mendadak) atau *brownout* pada ESP32-CAM.

---

## 1. Daftar Komponen
- **Otak Sistem:** ESP32-CAM (AI Thinker)
- **Motor Katup:** Servo SG90 (Biru)
- **Sensor Berat:** Loadcell + Modul HX711
- **Power Supply 1 (Untuk Otak & Kamera):** Kabel USB dari Laptop / Modul FTDI (USB-to-TTL)
- **Power Supply 2 (Untuk Otot / Servo):** Kepala Charger HP 5V (Minimal 2 Ampere)

> [!WARNING]
> **ATURAN EMAS KELISTRIKAN AQUAFEED:**
> Motor Servo menyedot arus listrik sangat besar (bisa mencapai ~650mA saat mulai bergerak). USB Laptop memiliki batas maksimal 500mA. Jika Servo dan ESP32 digabung dalam satu sumber daya laptop, ESP32 akan langsung *crash* (Restart). **Pisahkan sumber dayanya sesuai panduan di bawah, dan WAJIB gabungkan kabel GND-nya.**

---

## 2. Skema Penyambungan Pin (Wiring Diagram)

### A. Konfigurasi Power Supply (Daya Ganda)
1. **ESP32-CAM:** Mengambil daya dari Laptop (Kabel 5V dan GND dari modul FTDI dicolok ke pin 5V dan GND ESP32).
2. **Servo SG90:** Kabel VCC (Merah) servo **TIDAK** dicolok ke laptop, melainkan dicolok LANGSUNG ke kabel Positif (+) dari Charger HP.
3. **Penyatuan GND (Sangat Penting):** 
   Kabel Negatif (-) dari Charger HP, Kabel Coklat/Hitam dari Servo, dan Pin GND di ESP32 **HARUS DISATUKAN** (dihubungkan bersama) dalam satu jalur di Breadboard.

### B. Pinout Motor Servo
| Kabel Servo | Sambungan | Keterangan |
| :--- | :--- | :--- |
| **Merah (VCC)** | Positif (+) Charger HP | Sumber tenaga mekanik |
| **Coklat/Hitam (GND)**| Jalur GND Bersama | Grounding |
| **Oranye/Kuning (Data)**| **Pin 13** ESP32-CAM | Menerima sinyal Hardware PWM |

### C. Pinout Sensor Berat (HX711)
Modul HX711 dapat mengambil daya langsung dari ESP32/Laptop (karena arusnya sangat kecil).
| Pin HX711 | Sambungan | Keterangan |
| :--- | :--- | :--- |
| **VCC** | Pin 5V (Jalur ESP32) | Sumber tegangan logika |
| **GND** | Jalur GND Bersama | Grounding |
| **DT (Data)** | **Pin 15** ESP32-CAM | Mengirim data berat |
| **SCK (Clock)** | **Pin 14** ESP32-CAM | Sinyal sinkronisasi bacaan |

### D. Pinout Modul Upload (FTDI / USB-to-TTL)
Hanya digunakan saat melakukan proses *Upload* atau pemantauan Serial Monitor.
| Pin FTDI | Sambungan ESP32-CAM | Keterangan |
| :--- | :--- | :--- |
| **5V** | 5V | Sumber daya utama ESP32 |
| **GND** | GND | - |
| **TX** | **Pin 3 (U0RX)** | Kabel silang (Transmit ke Receive) |
| **RX** | **Pin 1 (U0TX)** | Kabel silang (Receive ke Transmit) |
| *(Kabel Jumper Tambahan)*| **IO0** disambung ke **GND** | **HANYA SAAT UPLOAD!** Cabut kabel ini setelah ada tulisan *"Done uploading"* agar ESP32 bisa berjalan normal. |

---

## 3. Catatan Tambahan (Software)
- **Frekuensi Kamera:** Kecepatan *clock* kamera diturunkan menjadi **10 MHz** (di `feeder_esp32.ino`) untuk menjaga kestabilan daya sensor gambar saat beban listrik memuncak.
- **Pergerakan Servo:** Menggunakan fungsi `ledcWrite` (Hardware PWM) dengan sistem *looping/sweep* yang memberikan delay `15ms` di setiap pergerakan. Ini berfungsi sebagai fitur "Soft-Start" untuk mencegah tarikan arus kejut (Spike/Brownout).
- **Lampu Flash:** Sengaja dinonaktifkan (`LOW`) selama motor servo bergerak untuk mencegah ESP32 kehabisan tegangan. Sebagai indikator, LED status merah (Pin 33) digunakan.
