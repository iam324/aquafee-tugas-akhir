#include "esp_camera.h"
#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Helper untuk Firebase
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

#include "HX711.h"

// ==========================================
// KONFIGURASI LOADCELL (HX711)
// ==========================================
const int LOADCELL_DOUT_PIN = 15;   // DT  -> Pin 2
const int LOADCELL_SCK_PIN  = 14;  // SCK -> Pin 14
HX711 scale;
float calibration_factor = 125.5; // KUNCI UTAMA agar bacaan dalam GRAM akurat!
unsigned long lastWeightUpdate = 0;
unsigned long lastPingMillis   = 0;

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
const char* password = "11111111";

#define API_KEY      "AIzaSyCPuyJBdxF2h-dwLCadbLHrGSYTVbyniVg"
#define DATABASE_URL "https://aquafeed-f3451-default-rtdb.firebaseio.com/"

// ===========================
// KONFIGURASI SERVO & DIAGNOSTIK
// ===========================
const int servoPin     = 13;  // PIN DATA SERVO (Kabel Oranye)
const int flashLedPin  = 4;   // Lampu Flash Putih Terang
const int statusLedPin = 33;  // LED kecil di belakang ESP32
const int freq         = 50;
const int pwmResolution = 10;

int dutyOpen  = 128;  // TEST: 180° (2.5ms)
int dutyClose = 26;   // 0° (0.5ms)

// Objek Firebase
FirebaseData   fbdo;
FirebaseAuth   auth;
FirebaseConfig configFb;
bool signupOK = false;

void startCameraServer();

// ===========================
// FUNGSI BERI MAKAN (HARDWARE PWM - SWEEP)
// ===========================
void dispenseAction() {
  Serial.println("\n[!] PERINTAH DITERIMA: SEDANG MEMBERI MAKAN...");
  digitalWrite(statusLedPin, LOW); 

  Serial.println("[Servo] Membuka Katup (Mulus)...");
  // Sweep menggunakan Hardware PWM. Karena kabel sudah bagus, ini akan sangat mulus!
  for (int d = dutyClose; d <= dutyOpen; d++) {
    ledcWrite(servoPin, d);
    delay(15); 
  }
  
  delay(1000); 

  Serial.println("[Servo] Menutup Katup (Mulus)...");
  for (int d = dutyOpen; d >= dutyClose; d--) {
    ledcWrite(servoPin, d);
    delay(15);
  }

  digitalWrite(statusLedPin, HIGH);
  Serial.println("[!] SELESAI.\n");
}

// ===========================
// SETUP
// ===========================
void setup() {
  Serial.begin(115200);

  pinMode(flashLedPin,  OUTPUT);
  pinMode(statusLedPin, OUTPUT);
  digitalWrite(flashLedPin,  LOW);
  digitalWrite(statusLedPin, HIGH);

  // --- SETUP LOADCELL HX711 (non-blocking dengan timeout) ---
  Serial.println("Menginisialisasi Loadcell HX711...");
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(calibration_factor);

  unsigned long hx711Timeout = millis();
  bool hx711Ready = false;
  while (millis() - hx711Timeout < 3000) {  // Tunggu max 3 detik
    if (scale.is_ready()) {
      scale.tare();
      hx711Ready = true;
      Serial.println("Loadcell siap dan sudah di-tare.");
      break;
    }
    delay(100);
  }
  if (!hx711Ready) {
    Serial.println("PERINGATAN: HX711 tidak terdeteksi! Cek kabel DT(Pin2)/SCK(Pin14).");
  }

  // --- CONFIG KAMERA ---
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
  
  // TURUNKAN KE 10MHz. 
  // 20MHz sering membuat sensor kamera gagal merespon (Camera capture failed) jika power kurang stabil
  config.xclk_freq_hz = 10000000; 
  config.frame_size   = FRAMESIZE_QVGA;
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode    = CAMERA_GRAB_LATEST;
  config.fb_location  = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count     = 1;

  esp_camera_init(&config);

  // --- SETUP SERVO (HARDWARE PWM) ---
  // Kita kembalikan ke Hardware PWM murni karena masalah kabel daya sudah beres
  ledcAttachChannel(servoPin, freq, pwmResolution, 2);
  ledcWrite(servoPin, dutyClose); // Posisi awal tertutup
  
  // TUNGGU 2 DETIK AGAR LISTRIK STABIL!
  // Servo yang bergerak awal + WiFi nyala bersamaan membuat daya habis seketika dan ESP32 crash.
  delay(2000); 

  // --- KONEKSI WIFI (dengan timeout 30 detik) ---
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  unsigned long wifiTimeout = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - wifiTimeout > 30000) {
      Serial.println("\nGAGAL konek WiFi! Cek SSID/password atau nyalakan hotspot.");
      Serial.println("ESP32 restart dalam 5 detik...");
      delay(5000);
      ESP.restart();
    }
    delay(500);
    Serial.print(".");
    digitalWrite(statusLedPin, !digitalRead(statusLedPin));
  }
  digitalWrite(statusLedPin, LOW);
  Serial.println("\nWiFi connected!");

  // --- CONFIG FIREBASE ---
  configFb.api_key      = API_KEY;
  configFb.database_url = DATABASE_URL;

  if (Firebase.signUp(&configFb, &auth, "", "")) {
    Serial.println("Firebase SignUp OK");
    signupOK = true;
  }

  configFb.token_status_callback = tokenStatusCallback;
  Firebase.begin(&configFb, &auth);
  Firebase.reconnectWiFi(true);

  startCameraServer();
  Serial.println("SYSTEM READY - MENUNGGU PERINTAH...");
}

// ===========================
// LOOP
// ===========================
void loop() {
  if (Firebase.ready() && signupOK) {

    // --- HEARTBEAT PING SETIAP 5 DETIK ---
    if (millis() - lastPingMillis > 5000 || lastPingMillis == 0) {
      lastPingMillis = millis();
      Firebase.RTDB.setInt(&fbdo, "/aquafeed/last_ping", millis());
    }

    // --- BACA BERAT LOADCELL SETIAP 3 DETIK ---
    if (millis() - lastWeightUpdate > 3000 || lastWeightUpdate == 0) {
      lastWeightUpdate = millis();
      if (scale.is_ready()) {
        float weight = scale.get_units(5);
        // Tampilkan nilai RAW termasuk negatif untuk diagnosa
        Serial.print("Berat RAW: ");
        Serial.print(weight);
        Serial.println(" gram");
        // Kirim nilai absolut ke Firebase (selalu positif)
        Firebase.RTDB.setFloat(&fbdo, "/aquafeed/current_weight", abs(weight));
      } else {
        Serial.println("HX711 tidak terdeteksi.");
      }
    }

    // --- BACA PERINTAH DARI FIREBASE ---
    if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/action")) {
      if (fbdo.dataType() == "string") {
        String action = fbdo.stringData();
        if (action == "dispense") {
          Firebase.RTDB.setString(&fbdo, "/aquafeed/command/action", "idle");
          dispenseAction();
        }
      }
    }
  }
  delay(300);
}
