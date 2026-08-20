# Analisis Integrasi ESP32-CAM pada Project AquaFeed

## 📋 Ringkasan Project Saat Ini

Project AquaFeed Anda sudah menggunakan **ESP32-CAM (AI Thinker)** sebagai kontroler utama dengan komponen berikut:

| Komponen | Pin | Fungsi |
|---|---|---|
| Kamera OV2640 | GPIO 0,5,18,19,21,22,23,25,26,27,32,34,35,36,39 | Stream video + analisis kekeruhan air |
| Servo SG90 | GPIO 13 | Katup dispenser pakan |
| HX711 (Loadcell) | GPIO 15 (DT), GPIO 14 (SCK) | Timbangan pakan |
| Flash LED | GPIO 4 | Lampu flash kamera |
| Status LED | GPIO 33 | Indikator status |

Komunikasi: **WiFi → Firebase RTDB → Flutter App**

---

## ❓ Pertanyaan: "Bisa Ditambahi ESP32-CAM?"

### Jawaban: **YA, BISA!** ✅

Namun perlu diperjelas dulu **tujuannya**, karena ada 2 skenario yang berbeda:

---

## Skenario 1: Menambah ESP32-CAM **Kedua** (2 Board)

> **Tujuan:** Kamera kedua untuk sudut pandang berbeda (misal: monitor kolam dari atas + monitor dispenser dari samping)

### Arsitektur 2-Board

```
┌─────────────────────────────┐     ┌────────────────────────────┐
│   ESP32-CAM #1 (UTAMA)     │     │  ESP32-CAM #2 (KAMERA)     │
│   Board yang sudah ada      │     │  Board TAMBAHAN             │
│                             │     │                            │
│  ┌──────────┐               │     │  ┌──────────┐              │
│  │ OV2640   │ Kamera #1     │     │  │ OV2640   │ Kamera #2    │
│  └──────────┘               │     │  └──────────┘              │
│                             │     │                            │
│  GPIO 13 ─── Servo SG90    │     │  GPIO 4 ── Flash LED       │
│  GPIO 15 ─── HX711 (DT)   │     │  GPIO 33 ─ Status LED      │
│  GPIO 14 ─── HX711 (SCK)  │     │                            │
│  GPIO 4  ─── Flash LED     │     │  Endpoint:                 │
│  GPIO 33 ─── Status LED    │     │  - http://IP2/capture      │
│                             │     │  - http://IP2:81/stream    │
│  Endpoint:                  │     │                            │
│  - http://IP1/capture       │     │  Firebase:                 │
│  - http://IP1:81/stream     │     │  /aquafeed/camera2/...     │
│                             │     │                            │
│  Firebase:                  │     └────────────────────────────┘
│  /aquafeed/command/...      │                │
│  /aquafeed/current_weight   │                │
│  /aquafeed/last_ping        │                │
└─────────────────────────────┘                │
         │                                      │
         │          ┌──────────────┐            │
         └─────────►│  WiFi Router │◄───────────┘
                    │  (Hotspot)   │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │   Firebase   │
                    │  Realtime DB │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │  Flutter App │
                    │  (AquaFeed)  │
                    └──────────────┘
```

### Wiring ESP32-CAM #2 (Board Tambahan)

Board kedua **hanya butuh power**, karena kamera sudah built-in:

```
Wiring ESP32-CAM #2 (Kamera Tambahan):

   ┌─────────────────────────────────────────┐
   │         ESP32-CAM #2 (AI Thinker)       │
   │                                         │
   │  5V ●──────── VCC (Power Supply 5V)     │
   │  GND ●──────── GND (Power Supply)       │
   │                                         │
   │  ┌──────────┐                           │
   │  │ OV2640   │  (sudah built-in)         │
   │  │ Kamera   │                           │
   │  └──────────┘                           │
   │                                         │
   │  GPIO 4 ──── (Flash LED built-in)       │
   │                                         │
   │  *Tidak perlu wiring tambahan!*         │
   │  Cukup power saja.                      │
   └─────────────────────────────────────────┘

   Power Supply:
   ┌─────────────┐
   │ Adaptor 5V  │──── VCC ──► ESP32-CAM #2
   │ 2A          │──── GND ──► ESP32-CAM #2
   └─────────────┘
   
   ⚠️  PENTING: GND ESP32-CAM #1 dan #2 HARUS DISAMBUNG
       (common ground) jika menggunakan power supply berbeda!
```

### Kelebihan & Kekurangan Skenario 1

| ✅ Kelebihan | ❌ Kekurangan |
|---|---|
| Board utama tidak perlu diubah | Butuh 2 power supply / splitter |
| Firmware #1 tetap sama | Harus manage 2 IP address |
| Bisa posisi kamera berbeda | Flutter app perlu update untuk 2 stream |
| Lebih stabil (beban terbagi) | Biaya tambahan ~Rp 50-70rb |

---

## Skenario 2: Mengganti ke ESP32 Biasa + ESP32-CAM Terpisah

> **Tujuan:** Memisahkan tugas kontroler (servo + loadcell) dan kamera

> [!CAUTION]
> Skenario ini memerlukan **refactoring besar** pada firmware dan **TIDAK DIREKOMENDASIKAN** untuk project Anda yang sudah jalan.

---

## 🏆 Rekomendasi: Skenario 1 (Tambah ESP32-CAM #2)

Berdasarkan analisis kode Anda, skenario terbaik adalah **menambah ESP32-CAM kedua** karena:

1. **Firmware utama tidak perlu diubah** — project sudah stabil
2. **Board kedua sangat simple** — hanya perlu firmware kamera saja (tanpa servo/loadcell)
3. **Bisa dipasang di posisi berbeda** — misal di atas kolam untuk monitoring lebih baik

---

## 📐 Rangkaian Lengkap (2 Board)

```
╔═══════════════════════════════════════════════════════════════════════╗
║                    RANGKAIAN LENGKAP AQUAFEED v2                     ║
║                    (2x ESP32-CAM + Servo + Loadcell)                 ║
╚═══════════════════════════════════════════════════════════════════════╝

    POWER SUPPLY 5V/3A
    ┌──────────────┐
    │   Adaptor    │
    │   5V / 3A    │
    │              │
    │  +5V ●───────┼──────────────┬──────────────────┬───────────────┐
    │              │              │                  │               │
    │  GND ●───────┼─────┬────────┼──────────┬───────┼───────┬───────┤
    └──────────────┘     │        │          │       │       │       │
                         │        │          │       │       │       │
    ┌────────────────────┼────────┼──────────┼───────┼───────┘       │
    │ ESP32-CAM #1       │        │          │       │               │
    │ (UTAMA)            │        │          │       │               │
    │                    │        │          │       │               │
    │ 5V  ●──────────────┘        │          │       │               │
    │ GND ●───────────────────────┘          │       │               │
    │                                        │       │               │
    │ GPIO 13 ●─────────────────── Data (Oranye) ── Servo SG90      │
    │                                        │       │               │
    │ GPIO 15 ●─── DT ──────────── HX711    │       │               │
    │ GPIO 14 ●─── SCK ─────────── Module   │       │               │
    │                              │  │      │       │               │
    │ GPIO 4  ●─── Flash LED      │  │      │       │               │
    │ GPIO 33 ●─── Status LED     │  │      │       │               │
    │                              │  │      │       │               │
    │ [OV2640 Kamera Built-in]     │  │      │       │               │
    └──────────────────────────────┘  │      │       │               │
                                      │      │       │               │
    ┌─────────────────────────────────┘      │       │               │
    │ HX711 Module                           │       │               │
    │ VCC ●──────────────────────────────────┘       │               │
    │ GND ●──────────────────────────────────────────┘               │
    │ E+  ●──── Kabel Merah ──── Loadcell                           │
    │ E-  ●──── Kabel Hitam ──── Loadcell                           │
    │ A+  ●──── Kabel Putih ──── Loadcell                           │
    │ A-  ●──── Kabel Hijau ──── Loadcell                           │
    └────────────────────────────────────────────────────────────────┘

    ┌────────────────────────────────────────────────────────────────┐
    │ ESP32-CAM #2 (KAMERA TAMBAHAN)                                │
    │                                                                │
    │ 5V  ●──────────────────────────────────────────────────────────┤
    │ GND ●──────────── (common ground dengan board #1)              │
    │                                                                │
    │ [OV2640 Kamera Built-in]                                       │
    │ GPIO 4  ●─── Flash LED (built-in, opsional)                    │
    │                                                                │
    │ Tidak ada wiring tambahan! Cukup power saja.                   │
    └────────────────────────────────────────────────────────────────┘

    Servo SG90:
    ┌──────────────────┐
    │ Cokelat (GND)  ●─┤── GND (common)
    │ Merah   (VCC)  ●─┤── 5V  (Power Supply langsung!)
    │ Oranye  (Data) ●─┤── GPIO 13 ESP32-CAM #1
    └──────────────────┘

    ⚠️  KUNCI STABILITAS:
    • VCC Servo JANGAN dari pin 5V ESP32! Ambil LANGSUNG dari adaptor!
    • Semua GND harus tersambung (common ground)
    • Gunakan adaptor minimal 5V/3A untuk 2 board + servo
```

---

## 💻 Firmware ESP32-CAM #2 (Kamera Saja)

Berikut firmware minimal untuk board kedua. Board ini **hanya** menjalankan streaming kamera, tanpa servo/loadcell:

```cpp
// File: camera_only_esp32cam.ino
// Firmware untuk ESP32-CAM #2 (hanya kamera streaming)

#include "esp_camera.h"
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// PIN DEFINITIONS (AI THINKER MODEL)
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// WIFI & FIREBASE (samakan dengan board utama)
const char* ssid     = "iPhone";
const char* password = "12345678";

#define API_KEY      "AIzaSyCPuyJBdxF2h-dwLCadbLHrGSYTVbyniVg"
#define DATABASE_URL "https://aquafeed-f3451-default-rtdb.firebaseio.com/"

const int flashLedPin  = 4;
const int statusLedPin = 33;

FirebaseData   fbdo;
FirebaseAuth   auth;
FirebaseConfig configFb;
bool signupOK = false;
unsigned long lastPingMillis = 0;

void startCameraServer();  // sama seperti app_httpd.cpp

void setup() {
  Serial.begin(115200);
  
  pinMode(flashLedPin, OUTPUT);
  pinMode(statusLedPin, OUTPUT);
  digitalWrite(flashLedPin, LOW);
  digitalWrite(statusLedPin, HIGH);

  // CONFIG KAMERA
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0       = Y2_GPIO_NUM;
  config.pin_d1       = Y3_GPIO_NUM;
  config.pin_d2       = Y4_GPIO_NUM;
  config.pin_d3       = Y5_GPIO_NUM;
  config.pin_d4       = Y6_GPIO_NUM;
  config.pin_d5       = Y7_GPIO_NUM;
  config.pin_d6       = Y8_GPIO_NUM;
  config.pin_d7       = Y9_GPIO_NUM;
  config.pin_xclk     = XCLK_GPIO_NUM;
  config.pin_pclk     = PCLK_GPIO_NUM;
  config.pin_vsync    = VSYNC_GPIO_NUM;
  config.pin_href     = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn     = PWDN_GPIO_NUM;
  config.pin_reset    = RESET_GPIO_NUM;
  config.xclk_freq_hz = 10000000;
  config.frame_size   = FRAMESIZE_VGA;     // Resolusi lebih tinggi karena task ringan
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode    = CAMERA_GRAB_LATEST;
  config.fb_location  = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 10;
  config.fb_count     = 2;

  esp_camera_init(&config);

  // KONEKSI WIFI
  Serial.print("Cam2: Connecting WiFi");
  WiFi.begin(ssid, password);
  unsigned long wifiTimeout = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - wifiTimeout > 30000) {
      Serial.println("\nGAGAL konek WiFi! Restart...");
      delay(5000);
      ESP.restart();
    }
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nCam2 WiFi connected!");
  Serial.print("Cam2 IP: ");
  Serial.println(WiFi.localIP());

  // FIREBASE (untuk publish IP address dan heartbeat)
  configFb.api_key      = API_KEY;
  configFb.database_url = DATABASE_URL;
  if (Firebase.signUp(&configFb, &auth, "", "")) {
    signupOK = true;
  }
  configFb.token_status_callback = tokenStatusCallback;
  Firebase.begin(&configFb, &auth);
  Firebase.reconnectWiFi(true);

  // Publish IP Address ke Firebase agar Flutter app tahu
  if (signupOK) {
    String streamUrl = "http://" + WiFi.localIP().toString() + ":81/stream";
    Firebase.RTDB.setString(&fbdo, "/aquafeed/camera2/stream_url", streamUrl.c_str());
    Firebase.RTDB.setString(&fbdo, "/aquafeed/camera2/ip", WiFi.localIP().toString().c_str());
  }

  startCameraServer();
  Serial.println("CAM2 READY - Streaming aktif!");
}

void loop() {
  if (Firebase.ready() && signupOK) {
    // Heartbeat setiap 5 detik
    if (millis() - lastPingMillis > 5000 || lastPingMillis == 0) {
      lastPingMillis = millis();
      Firebase.RTDB.setInt(&fbdo, "/aquafeed/camera2/last_ping", millis());
    }

    // Kontrol flash LED kamera 2
    if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/flash_cam2")) {
      if (fbdo.dataType() == "string") {
        String flashCmd = fbdo.stringData();
        if (flashCmd == "on") {
          digitalWrite(flashLedPin, HIGH);
        } else if (flashCmd == "off") {
          digitalWrite(flashLedPin, LOW);
        }
      }
    }
  }
  delay(300);
}
```

> [!IMPORTANT]
> File `app_httpd.cpp` yang sudah ada **bisa langsung dipakai** untuk board kedua. Cukup salin file tersebut ke folder firmware kamera kedua.

---

## 📸 Analisis Foto Alat Anda

Dari foto yang Anda kirim, saya bisa melihat:
- **PCB hijau kecil** → ini kemungkinan besar driver/kontroler dari dispenser pakan otomatis komersial
- **Kabel merah-hitam (tebal)** → power supply motor DC/servo
- **Kabel merah-putih (tipis, konektor JST)** → signal/sensor
- **Tabung putih** → housing/casing dispenser

Jika Anda ingin memasang ESP32-CAM di **dalam casing** ini, pertimbangkan:
1. **Posisi kamera** harus menghadap air/kolam (bukan ke dalam tabung)
2. **Ventilasi** — ESP32-CAM menghasilkan panas saat streaming
3. **Kabel data** bisa dilewatkan melalui celah-celah casing yang sudah ada

---

## 🔧 Daftar Belanja (Jika Tambah Board #2)

| Komponen | Harga Estimasi |
|---|---|
| ESP32-CAM (AI Thinker) + OV2640 | Rp 50.000 - 70.000 |
| Kabel jumper female-female (4 pcs) | Rp 5.000 |
| Adaptor 5V/3A (jika belum cukup) | Rp 25.000 - 40.000 |
| **Total** | **~Rp 80.000 - 115.000** |

---

## 🔌 Langkah Implementasi

1. **Beli ESP32-CAM** tambahan (AI Thinker, sama persis dengan yang sudah ada)
2. **Flash firmware** `camera_only_esp32cam.ino` ke board baru
3. **Sambungkan power** (5V + GND dari adaptor yang sama / adaptor terpisah dengan common ground)
4. **Posisikan kamera** menghadap area monitoring yang diinginkan
5. **Update Flutter app** untuk membaca stream URL dari `/aquafeed/camera2/stream_url`

> [!TIP]
> Board kedua **sangat ringan** karena hanya menjalankan kamera streaming. Tidak ada servo atau loadcell yang membebani, sehingga performanya akan sangat stabil.

---

## ❓ Yang Perlu Anda Tentukan

1. **Tujuan kamera kedua?** (monitoring kolam / monitoring dispenser / lainnya?)
2. **Apakah ingin 2 tampilan stream di Flutter app?** (split view atau tab?)
3. **Apakah analisis kekeruhan air akan pakai kamera #1 atau #2?**
