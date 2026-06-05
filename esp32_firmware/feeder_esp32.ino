#include "esp_camera.h"
#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Helper untuk Firebase
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

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
const char* ssid = "pejuybahlil";
const char* password = "12345678";

#define API_KEY "AIzaSyCPuyJBdxF2h-dwLCadbLHrGSYTVbyniVg"
#define DATABASE_URL "https://aquafeed-f3451-default-rtdb.firebaseio.com/"

// ===========================
// KONFIGURASI SERVO
// ===========================
const int servoPin = 13;      // PIN DATA SERVO (Warna Oranye)
const int statusLedPin = 33;  // LED kecil merah/biru di belakang
const int freq = 50;          
const int pwmResolution = 10; 

int dutyOpen = 77;   
int dutyClose = 26;  

// Objek Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig configFb;
bool signupOK = false;

void startCameraServer();

void dispenseAction() {
  Serial.println("\n[Action] MEMBERI MAKAN...");
  
  // LED belakang menyala (tanda proses)
  digitalWrite(statusLedPin, LOW); 
  
  // BUKA
  ledcWrite(servoPin, dutyOpen);
  delay(2000); 
  
  // TUTUP
  ledcWrite(servoPin, dutyClose);
  delay(1000); 
  
  digitalWrite(statusLedPin, HIGH); 
  Serial.println("[Action] SELESAI.\n");
}

void setup() {
  Serial.begin(115200);
  
  pinMode(statusLedPin, OUTPUT);
  digitalWrite(statusLedPin, HIGH); 

  // SETUP SERVO
  ledcAttach(servoPin, freq, pwmResolution);
  ledcWrite(servoPin, dutyClose); 

  // --- CONFIG KAMERA ---
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_QVGA;
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_LATEST;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  esp_camera_init(&config);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  digitalWrite(statusLedPin, LOW); 
  Serial.println("\nWiFi connected!");

  configFb.api_key = API_KEY;
  configFb.database_url = DATABASE_URL;
  Firebase.signUp(&configFb, &auth, "", "");
  Firebase.begin(&configFb, &auth);
  Firebase.reconnectWiFi(true);

  startCameraServer();
  Serial.println("SYSTEM READY!");
}

void loop() {
  if (Firebase.ready()) {
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
