#include "esp_camera.h"
#include <WiFi.h>
#include <ESPmDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>
#include <Firebase_ESP_Client.h>

// Helper untuk Firebase
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

unsigned long lastPingMillis = 0;

// ==========================================
// PIN DEFINITIONS (AI THINKER MODEL)
// ==========================================
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

// ===========================
// KONFIGURASI WIFI & FIREBASE
// ===========================
const char* ssid     = "sendal0ucl";
const char* password = "11111112";

#define API_KEY      "AIzaSyCPuyJBdxF2h-dwLCadbLHrGSYTVbyniVg"
#define DATABASE_URL "https://aquafeed-f3451-default-rtdb.firebaseio.com/"

// ===========================
// KONFIGURASI MODUL RELAY 5V (GPIO 13) & LED
// ===========================
// Pin GPIO 13 untuk memicu Modul Relay 5V
// Mode Active-LOW (0 = LOW = NYALA/CLICK, 1 = HIGH = MATI)
const int relayPin     = 13; 
const int flashLedPin  = 4;   // Flash LED Onboard (GPIO 4)
const int statusLedPin = 33;  // Status LED Onboard (GPIO 33)

// Durasi motor berputar saat memberi makan (dalam milidetik)
const int dispenseDuration = 7000;

// Objek Firebase
FirebaseData   fbdo;
FirebaseAuth   auth;
FirebaseConfig configFb;
bool signupOK = false;

void startCameraServer();

// ===========================
// FUNGSI KONTROL RELAY (ACTIVE LOW: 0 = NYALA, 1 = MATI)
// ===========================
void nyalakanMotor() {
  digitalWrite(relayPin, LOW); // GPIO 13 = 0 -> Relay NYALA (Motor Berputar)
  Serial.println("[Relay] Status Relay: NYALA (LOW = 0)");
}

void matikanMotor() {
  digitalWrite(relayPin, HIGH); // GPIO 13 = 1 -> Relay MATI
  Serial.println("[Relay] Status Relay: MATI (HIGH = 1)");
}

void dispenseAction() {
  Serial.println("\n[!] PERINTAH DITERIMA: SEDANG MEMBERI MAKAN...");
  digitalWrite(statusLedPin, LOW); // Indikator LED Onboard Nyala

  nyalakanMotor();
  delay(dispenseDuration);
  matikanMotor();

  digitalWrite(statusLedPin, HIGH); // Indikator LED Onboard Mati
  Serial.println("[!] SELESAI MEMBERI MAKAN.\n");
}

// ===========================
// SETUP
// ===========================
void setup() {
  Serial.begin(115200);
  Serial.println("\n========================================");
  Serial.println("  AQUAFEED - Smart Fish Feeder");
  Serial.println("  ESP32-CAM + Modul Relay 5V (GPIO 13)");
  Serial.println("========================================");

  // --- SETUP PIN RELAY & LED ---
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, HIGH); // Set HIGH awal (Relay MATI saat booting)

  pinMode(flashLedPin,  OUTPUT);
  pinMode(statusLedPin, OUTPUT);
  digitalWrite(flashLedPin,  LOW);  // Flash MATI
  digitalWrite(statusLedPin, LOW);  // LED status nyala tanda booting

  // --- CONFIG KAMERA (OTOMATIS CEK PSRAM / DRAM) ---
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
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode    = CAMERA_GRAB_LATEST;

  if (psramFound()) {
    Serial.println("[OK] PSRAM Ditemukan.");
    config.frame_size   = FRAMESIZE_VGA;
    config.jpeg_quality = 12;
    config.fb_count     = 2;
    config.fb_location  = CAMERA_FB_IN_PSRAM;
  } else {
    Serial.println("[WARN] PSRAM Tidak Ditemukan / Disabled. Menggunakan DRAM internal...");
    config.frame_size   = FRAMESIZE_QVGA;
    config.jpeg_quality = 15;
    config.fb_count     = 1;
    config.fb_location  = CAMERA_FB_IN_DRAM;
  }

  // Inisialisasi Kamera
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("[!] GAGAL init kamera! Error: 0x%x\n", err);
  } else {
    Serial.println("[OK] Kamera berhasil diinisialisasi.");
    sensor_t * s = esp_camera_sensor_get();
    if (s != NULL) {
      s->set_vflip(s, 1);
      s->set_hmirror(s, 1);
    }
  }

  // --- KONEKSI WIFI ---
  Serial.print("[WiFi] Menghubungkan ke ");
  Serial.println(ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  unsigned long wifiTimeout = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - wifiTimeout > 20000) {
      Serial.println("\n[!] GAGAL konek WiFi! Restarting...");
      delay(2000);
      ESP.restart();
    }
    delay(500);
    Serial.print(".");
  }
  
  digitalWrite(statusLedPin, HIGH); // Selesai booting / WiFi terhubung
  Serial.println("\n[OK] WiFi Terhubung!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  // --- KONFIGURASI ARDUINO OTA (WIRELESS UPLOAD) ---
  ArduinoOTA.setHostname("aquafeed-esp32cam");
  ArduinoOTA
    .onStart([]() {
      Serial.println("[OTA] Proses Update Firmware Dimulai...");
    })
    .onEnd([]() {
      Serial.println("\n[OTA] Update Selesai! Restarting...");
    })
    .onProgress([](unsigned int progress, unsigned int total) {
      Serial.printf("[OTA] Progress: %u%%\r", (progress / (total / 100)));
    })
    .onError([](ota_error_t error) {
      Serial.printf("[OTA Error] Code: %u\n", error);
    });

  ArduinoOTA.begin();
  Serial.println("[OK] Server OTA Siap!");

  // --- KONEKSI FIREBASE ---
  configFb.api_key      = API_KEY;
  configFb.database_url = DATABASE_URL;

  if (Firebase.signUp(&configFb, &auth, "", "")) {
    Serial.println("[Firebase] SignUp Anonim Berhasil.");
    signupOK = true;
  } else {
    Serial.printf("[Firebase] SignUp Gagal: %s\n", configFb.signer.signupError.message.c_str());
  }

  configFb.token_status_callback = tokenStatusCallback;
  Firebase.begin(&configFb, &auth);
  Firebase.reconnectWiFi(true);

  startCameraServer();
  Serial.println("\n===== SYSTEM READY =====");
  Serial.println("Menunggu perintah dari Firebase / OTA...\n");
}

// ===========================
// LOOP UTAMA
// ===========================
void loop() {
  // Handle ArduinoOTA (Wajib dipanggil terus-menerus)
  ArduinoOTA.handle();

  if (Firebase.ready() && signupOK) {
    // Ping device status & last_ping per 5 detik
    if (millis() - lastPingMillis > 5000 || lastPingMillis == 0) {
      lastPingMillis = millis();
      Firebase.RTDB.setString(&fbdo, "/aquafeed/device_status", "Online");
      Firebase.RTDB.setInt(&fbdo, "/aquafeed/last_ping", millis());
    }

    // Cek Perintah Action (dispense)
    if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/action")) {
      if (fbdo.dataType() == "string" && fbdo.stringData() == "dispense") {
        Firebase.RTDB.setString(&fbdo, "/aquafeed/command/action", "idle");
        dispenseAction();
      }
    }

    // Cek Perintah Flash LED (jika diaktifkan dari HP)
    if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/flash")) {
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

  delay(50);
}