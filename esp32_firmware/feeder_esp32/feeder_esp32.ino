#include "esp_camera.h"
#include <WiFi.h>
#include <ESPmDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>
#include <Firebase_ESP_Client.h>
#include <time.h> // Native ESP32 NTP support

// Helper untuk Firebase
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// Variabel global
unsigned long lastPingMillis = 0;
unsigned long lastScheduleCheck = 0;
const long scheduleCheckInterval = 10000; // per 15 detik

// Konfigurasi NTP WIB
const long gmtOffset_sec = 25200; // GMT+7
const int daylightOffset_sec = 0;
const char* ntpServer = "pool.ntp.org";

// Struktur jadwal
struct ScheduledFeeding {
  String time;   // HH:MM
  int dosage;    // gram
  bool active;   // aktif/tidak
  bool days[7];  // Hari aktif (0=Sun ... 6=Sat)
};

ScheduledFeeding scheduledFeedings[10];
int scheduleCount = 0;

// Pin definitions (AI Thinker)
#define PWDN_GPIO_NUM 32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 0
#define SIOD_GPIO_NUM 26
#define SIOC_GPIO_NUM 27
#define Y9_GPIO_NUM 35
#define Y8_GPIO_NUM 34
#define Y7_GPIO_NUM 39
#define Y6_GPIO_NUM 36
#define Y5_GPIO_NUM 21
#define Y4_GPIO_NUM 19
#define Y3_GPIO_NUM 18
#define Y2_GPIO_NUM 5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM 23
#define PCLK_GPIO_NUM 22

// WiFi & Firebase config
const char* ssid = "sendal0ucl";
const char* password = "11111112";
#define API_KEY "AIzaSyCPuyJBdxF2h-dwLCadbLHrGSYTVbyniVg"
#define DATABASE_URL "https://aquafeed-f3451-default-rtdb.firebaseio.com/"

// Transistor driver & LEDs
const int motorPin = 15;
const int flashLedPin = 4;
const int statusLedPin = 33;
const int dispenseDuration = 7700;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig configFb;
bool signupOK = false;

void startCameraServer();

// Motor control (high‑impedance standby)
void nyalakanMotor() { pinMode(motorPin, OUTPUT); digitalWrite(motorPin, LOW); Serial.println("[Motor] ON"); }
void matikanMotor() { pinMode(motorPin, INPUT); Serial.println("[Motor] OFF (high‑Z)"); }

bool motorRunning = false;
unsigned long motorStartTime = 0;

void dispenseAction() {
  Serial.println("\n[!] Memberi makan...");
  digitalWrite(statusLedPin, LOW);
  nyalakanMotor();
  motorRunning = true;
  motorStartTime = millis();

  // Non-blocking: tunggu motor selesai sambil tetap melayani WiFi & kamera
  while (millis() - motorStartTime < (unsigned long)dispenseDuration) {
    ArduinoOTA.handle();  // OTA tetap jalan
    delay(10);            // yield ke WiFi stack agar tidak disconnect
  }

  matikanMotor();
  motorRunning = false;
  digitalWrite(statusLedPin, HIGH);
  Serial.println("[!] Selesai\n");
}

// Load schedule from Firebase – days array parsing removed (default all true)
void loadSchedulesFromFirebase() {
  if (!Firebase.ready() || !signupOK) return;
  if (Firebase.RTDB.getJSON(&fbdo, "/aquafeed/schedule")) {
    if (fbdo.dataType() == "json") {
      FirebaseJson &json = fbdo.jsonObject();
      size_t len = json.iteratorBegin();
      scheduleCount = 0;
      String key, valueStr; int type;
      for (size_t i = 0; i < len; i++) {
        json.iteratorGet(i, type, key, valueStr);
        if (type == FirebaseJson::JSON_OBJECT) {
          FirebaseJson scheduleObj; scheduleObj.setJsonData(valueStr);
          FirebaseJsonData result;
          String timeVal = ""; int dosageVal = 0; bool activeVal = true;

          if (scheduleObj.get(result, "time"))   timeVal   = result.stringValue;
          if (scheduleObj.get(result, "dosage")) dosageVal = result.intValue;
          if (scheduleObj.get(result, "active")) activeVal = result.boolValue;

          // Default to true
          bool daysVal[7] = {true, true, true, true, true, true, true};
          
          if (scheduleObj.get(result, "days")) {
             FirebaseJsonArray arr;
             arr.setJsonArrayData(result.stringValue);
             for(size_t d = 0; d < 7; d++) {
                 FirebaseJsonData arrRes;
                 if (arr.get(arrRes, d)) daysVal[d] = arrRes.boolValue;
             }
          }

          if (!timeVal.isEmpty() && scheduleCount < 10) {
            scheduledFeedings[scheduleCount].time   = timeVal;
            scheduledFeedings[scheduleCount].dosage = dosageVal;
            scheduledFeedings[scheduleCount].active = activeVal;
            for (int d = 0; d < 7; d++) scheduledFeedings[scheduleCount].days[d] = daysVal[d];
            scheduleCount++;
          }
        }
      }
      json.iteratorEnd();
      Serial.printf("[Schedule] Loaded %d entries\n", scheduleCount);
    }
  }
}

void checkAndExecuteSchedule() {
  if (!Firebase.ready() || !signupOK) return;
  if (millis() - lastScheduleCheck > scheduleCheckInterval || lastScheduleCheck == 0) {
    lastScheduleCheck = millis();
    loadSchedulesFromFirebase();
  }
  if (scheduleCount == 0) return;
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return;
  char cur[6]; sprintf(cur, "%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min);
  static int lastMinute = -1;
  if (timeinfo.tm_min != lastMinute) { lastMinute = timeinfo.tm_min; Serial.printf("[ESP32 Clock] %s day %d\n", cur, timeinfo.tm_wday); }
  for (int i = 0; i < scheduleCount; i++) {
    ScheduledFeeding &sf = scheduledFeedings[i];
    if (!sf.active) continue;
    if (!sf.days[timeinfo.tm_wday]) continue;
    if (strcmp(sf.time.c_str(), cur) == 0) {
      static int lastFeedDay[10] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
      static int lastFeedMinute[10] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
      
      if (lastFeedDay[i] != timeinfo.tm_yday || lastFeedMinute[i] != timeinfo.tm_min) {
        Serial.printf("\n=== Jadwal tercapai %s ===\n", sf.time.c_str());
        dispenseAction();
        lastFeedDay[i] = timeinfo.tm_yday;
        lastFeedMinute[i] = timeinfo.tm_min;

        // Push activity log to Firebase
        FirebaseJson logJson;
        logJson.set("title", "Pakan otomatis diberikan");
        logJson.set("time", sf.time);
        logJson.set("type", 0);
        logJson.set("status", "Selesai");
        logJson.set("dosage", sf.dosage);
        struct timeval tv; gettimeofday(&tv, NULL);
        double timestamp_ms = (double)tv.tv_sec * 1000.0 + (double)tv.tv_usec / 1000.0;
        logJson.set("timestamp", timestamp_ms);
        Firebase.RTDB.pushJSON(&fbdo, "/aquafeed/logs", &logJson);

        break;
      }
    }
  }
}

void setup() {
  matikanMotor();
  pinMode(flashLedPin, OUTPUT); pinMode(statusLedPin, OUTPUT);
  digitalWrite(flashLedPin, LOW); digitalWrite(statusLedPin, LOW);
  Serial.begin(115200);
  Serial.println("\n=== AQUAFEED START ===");

  // Camera config (unchanged – omitted for brevity – same as before)
  camera_config_t config; config.ledc_channel=LEDC_CHANNEL_0; config.ledc_timer=LEDC_TIMER_0;
  config.pin_d0=Y2_GPIO_NUM; config.pin_d1=Y3_GPIO_NUM; config.pin_d2=Y4_GPIO_NUM; config.pin_d3=Y5_GPIO_NUM;
  config.pin_d4=Y6_GPIO_NUM; config.pin_d5=Y7_GPIO_NUM; config.pin_d6=Y8_GPIO_NUM; config.pin_d7=Y9_GPIO_NUM;
  config.pin_xclk=XCLK_GPIO_NUM; config.pin_pclk=PCLK_GPIO_NUM; config.pin_vsync=VSYNC_GPIO_NUM; config.pin_href=HREF_GPIO_NUM;
  config.pin_sccb_sda=SIOD_GPIO_NUM; config.pin_sccb_scl=SIOC_GPIO_NUM; config.pin_pwdn=PWDN_GPIO_NUM; config.pin_reset=RESET_GPIO_NUM;
  config.xclk_freq_hz=20000000; config.pixel_format=PIXFORMAT_JPEG; config.grab_mode=CAMERA_GRAB_LATEST;
  if (psramFound()) { Serial.println("[OK] PSRAM"); config.frame_size=FRAMESIZE_CIF; config.jpeg_quality=12; config.fb_count=2; config.fb_location=CAMERA_FB_IN_PSRAM; }
  else { Serial.println("[WARN] No PSRAM"); config.frame_size=FRAMESIZE_QVGA; config.jpeg_quality=15; config.fb_count=1; config.fb_location=CAMERA_FB_IN_DRAM; }
  if (esp_camera_init(&config) != ESP_OK) Serial.println("[!] Camera init failed");

  // WiFi
  Serial.print("[WiFi] Connecting "); Serial.println(ssid);
  WiFi.mode(WIFI_STA); WiFi.begin(ssid, password);
  unsigned long t = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - t > 20000) { Serial.println("[!] WiFi fail"); ESP.restart(); }
    delay(500); Serial.print('.');
  }
  digitalWrite(statusLedPin, HIGH);
  Serial.println("\n[OK] WiFi connected"); Serial.println(WiFi.localIP());

  // OTA
  ArduinoOTA.setHostname("aquafeed-esp32cam");
  ArduinoOTA.onStart([](){ Serial.println("[OTA] Start"); });
  ArduinoOTA.onEnd([](){ Serial.println("[OTA] End"); });
  ArduinoOTA.onProgress([](unsigned int p, unsigned int t){ Serial.printf("[OTA] %u%%\r", (p*100)/t); });
  ArduinoOTA.onError([](ota_error_t e){ Serial.printf("[OTA] err %u\n", e); });
  ArduinoOTA.begin(); Serial.println("[OK] OTA ready");

  // NTP native
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  Serial.println("[NTP] Configured GMT+7");

  // Firebase
  configFb.api_key = API_KEY; configFb.database_url = DATABASE_URL;
  if (Firebase.signUp(&configFb, &auth, "", "")) { Serial.println("[Firebase] sign‑up ok"); signupOK = true; } else { Serial.printf("[Firebase] sign‑up fail: %s\n", configFb.signer.signupError.message.c_str()); }
  configFb.token_status_callback = tokenStatusCallback;
  Firebase.begin(&configFb, &auth);
  Firebase.reconnectWiFi(true);

  startCameraServer();
  Serial.println("=== SYSTEM READY ===");

  // Auto-publish stream URL ke Firebase agar aplikasi bisa auto-detect IP
  if (Firebase.ready() && signupOK) {
    String streamUrl = "http://" + WiFi.localIP().toString() + ":81/stream";
    Firebase.RTDB.setString(&fbdo, "/aquafeed/stream_url", streamUrl);
    Serial.printf("[Auto-IP] Published: %s\n", streamUrl.c_str());
  }
}

void loop() {
  ArduinoOTA.handle();
  if (Firebase.ready() && signupOK) {
    if (millis() - lastPingMillis > 5000) { lastPingMillis = millis(); Firebase.RTDB.setString(&fbdo, "/aquafeed/device_status", "Online"); Firebase.RTDB.setInt(&fbdo, "/aquafeed/last_ping", millis()); }
    // Action command
    if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/action") && fbdo.stringData() == "dispense") {
      Firebase.RTDB.setString(&fbdo, "/aquafeed/command/action", "idle"); dispenseAction();
    }
    // Flash command
    if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/flash")) {
      String cmd = fbdo.stringData();
      if (cmd == "on") digitalWrite(flashLedPin, HIGH);
      else if (cmd == "off") digitalWrite(flashLedPin, LOW);
    }
    // Automatic schedule
    checkAndExecuteSchedule();
  }
  delay(50);
}