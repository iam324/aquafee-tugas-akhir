#include "esp_camera.h"
#include <WiFi.h>
#include <ESPmDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>
#include <Firebase_ESP_Client.h>
#include <time.h> // Native ESP32 NTP support
#include <Preferences.h> // For saving schedule to NVS

// Helper untuk Firebase
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// Variabel global
unsigned long lastPingMillis = 0;
unsigned long lastScheduleCheck = 0;
const long scheduleCheckInterval = 10000; // per 10 detik (fallback polling)

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
const int dispenseDuration = 7400; // ms (adjust as needed)

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig configFb;
bool signupOK = false;

// Firebase Stream for schedule
StreamPath scheduleStreamPath = "/aquafeed/schedule";
StreamData scheduleStream;

// Preferences (NVS) for persisting schedule locally
Preferences preferences;

// NTP sync timing
unsigned long lastNtpSync = 0;
const unsigned long NTP_INTERVAL_MS = 30UL * 60 * 1000; // 30 menit

// Motor control (high‑impedance standby)
void nyalakanMotor() { pinMode(motorPin, OUTPUT); digitalWrite(motorPin, LOW); Serial.println("[Motor] ON"); }
void matikanMotor() { pinMode(motorPin, INPUT); Serial.println("[Motor] OFF (high‑Z)"); }

// Dispense action (non‑blocking as before, but we keep original blocking version? We'll keep original to not break behavior)
void dispenseAction() {
  Serial.println("\n[!] Memberi makan...");
  digitalWrite(statusLedPin, LOW);
  nyalakanMotor();
  delay(dispenseDuration);
  matikanMotor();
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

          // Days array is optional – if present we ignore for simplicity (default true)
          bool daysVal[7] = {true, true, true, true, true, true, true};

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
      Serial.printf("[Schedule] Loaded %d entries from Firebase\n", scheduleCount);
      saveScheduleToNVS(); // Persist to NVS after successful load
    }
  }
}

// Save schedule to NVS (Preferences)
void saveScheduleToNVS() {
  FirebaseJson json;
  for (int i = 0; i < scheduleCount; i++) {
    FirebaseJson obj;
    obj.set("time", scheduledFeedings[i].time);
    obj.set("dosage", scheduledFeedings[i].dosage);
    obj.set("active", scheduledFeedings[i].active);
    // days omitted (default all true)
    json.set(String(i).c_str(), obj);
  }
  String jsonStr;
  json.toString(jsonStr, true);
  preferences.putString("schedule", jsonStr);
  Serial.printf("[NVS] Jadwal disimpan (%d items)\n", scheduleCount);
}

// Load schedule from NVS (Preferences)
void loadScheduleFromNVS() {
  if (!preferences.isKey("schedule")) {
    Serial.println("[NVS] Tidak ada jadwal tersimpan");
    scheduleCount = 0;
    return;
  }
  String jsonStr = preferences.getString("schedule", "");
  FirebaseJson json;
  json.setJsonData(jsonStr);
  size_t len = json.iteratorBegin();
  scheduleCount = 0;
  String key; int type; String valueStr;
  for (size_t i = 0; i < len; i++) {
    json.iteratorGet(i, type, key, valueStr);
    if (type == FirebaseJson::JSON_OBJECT) {
      FirebaseJson obj; obj.setJsonData(valueStr);
      FirebaseJsonData res;
      String t; int d; bool a;
      if (obj.get(res, "time"))   t = res.stringValue;
      if (obj.get(res, "dosage")) d = res.intValue;
      if (obj.get(res, "active")) a = res.boolValue;
      if (!t.isEmpty() && scheduleCount < 10) {
        scheduledFeedings[scheduleCount].time   = t;
        scheduledFeedings[scheduleCount].dosage = d;
        scheduledFeedings[scheduleCount].active = a;
        // default: semua hari aktif
        for (int dy = 0; dy < 7; dy++) scheduledFeedings[scheduleCount].days[dy] = true;
        scheduleCount++;
      }
    }
  }
  json.iteratorEnd();
  Serial.printf("[NVS] Jadwal dimuat (%d items)\n", scheduleCount);
}

// Parse JSON from Firebase Stream and update local schedule + NVS
void parseScheduleJson(FirebaseJson& json) {
  size_t len = json.iteratorBegin();
  scheduleCount = 0;
  String key; int type; String valueStr;
  for (size_t i = 0; i < len; i++) {
    json.iteratorGet(i, type, key, valueStr);
    if (type == FirebaseJson::JSON_OBJECT) {
      FirebaseJson obj; obj.setJsonData(valueStr);
      FirebaseJsonData res;
      String t; int d; bool a;
      if (obj.get(res, "time"))   t = res.stringValue;
      if (obj.get(res, "dosage")) d = res.intValue;
      if (obj.get(res, "active")) a = res.boolValue;
      if (!t.isEmpty() && scheduleCount < 10) {
        scheduledFeedings[scheduleCount].time   = t;
        scheduledFeedings[scheduleCount].dosage = d;
        scheduledFeedings[scheduleCount].active = a;
        for (int dy = 0; dy < 7; dy++) scheduledFeedings[scheduleCount].days[dy] = true;
        scheduleCount++;
      }
    }
  }
  json.iteratorEnd();
  Serial.printf("[Schedule] Parsed %d entries from stream\n", scheduleCount);
  saveScheduleToNVS(); // Persist updated schedule
}

// Callback for Firebase schedule stream
void scheduleStreamCallback(MultiPathData data) {
  if (streamGet(data, "data")) {   // ada payload baru
    FirebaseJson json; json.setJsonData(data.data().c_str());
    parseScheduleJson(json);
    Serial.println("[Stream] Jadwal diperbarui dari Firebase");
  }
}

// Sync NTP time
void syncNTP() {
  Serial.println("[NTP] Meminta sinkronisasi waktu...");
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  // tunggu hingga waktu ter-sync (maks 8 detik)
  unsigned long start = millis();
  while (!getLocalTime(nullptr) && (millis() - start < 8000)) {
    delay(100);
  }
  struct tm timeinfo;
  if (getLocalTime(&timeinfo)) {
    char buf[32];
    strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &timeinfo);
    Serial.printf("[NTP] Waktu disetel: %s\n", buf);
    lastNtpSync = millis();
  } else {
    Serial.println("[NTP] Gagal sinkronisasi – menggunakan RTC internal");
  }
}

// Compute delay (seconds) until next scheduled feeding
uint32_t computeNextAlarm() {
  struct tm now;
  if (!getLocalTime(&now)) return 0;   // waktu belum sinkron

  uint32_t bestDelay = UINT32_MAX;    // besar
  bool found = false;

  for (int i = 0; i < scheduleCount; i++) {
    if (!scheduledFeedings[i].active) continue;
    // cek hari aktif
    if (!scheduledFeedings[i].days[now.tm_wday]) continue;

    int alarmH, alarmM;
    if (sscanf(scheduledFeedings[i].time.c_str(), "%d:%d", &alarmH, &alarmM) != 2) continue;

    // buat tm untuk hari ini
    struct tm alarm = now;
    alarm.tm_hour = alarmH;
    alarm.tm_min  = alarmM;
    alarm.tm_sec  = 0;
    time_t alarmTime = mktime(&alarm);
    time_t nowTime   = mktime(&now);

    // jika waktu alarm sudah lewat today, coba besok
    if (alarmTime <= nowTime) {
      alarm.tm_mday += 1;   // tambah satu hari
      alarmTime = mktime(&alarm);
    }

    uint32_t delaySec = (uint32_t)(alarmTime - nowTime);
    if (delaySec < bestDelay) {
      bestDelay = delaySec;
      found = true;
    }
  }
  return found ? bestDelay : 0;   // 0 artinya tidak ada jadwal pada hari ini/besok
}

// Enter deep sleep for given seconds (microseconds)
void enterDeepSleep(uint32_t sleepSec) {
  Serial.printf("[DeepSleep] Tidur selama %d detik (~%d menit)\n", sleepSec, sleepSec/60);
  // Pastikan semua perifystik mati (kamu dapat menambah penanganan kamera jika mau)
  esp_sleep_enable_timer_wakeup(sleepSec * 1000000ULL); // microseconds
  esp_deep_sleep_start();   // tidak akan kembali dari sini kecuali wake‑up
}

// Check and execute schedule based on current time (still needed for minute‑granularity)
void checkAndExecuteSchedule() {
  if (!Firebase.ready() || !signupOK) return;
  if (millis() - lastScheduleCheck > scheduleCheckInterval || lastScheduleCheck == 0) {
    lastScheduleCheck = millis();
    // We rely on stream/NVS for schedule; polling only as fallback
    loadSchedulesFromFirebase(); // will also save to NVS if successful
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
      static int lastFeedDay[10] = {-1};
      if (lastFeedDay[i] != timeinfo.tm_yday) {
        Serial.printf("\n=== Jadwal tercapai %s ===\n", sf.time.c_str());
        dispenseAction();
        lastFeedDay[i] = timeinfo.tm_yday;

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

void startCameraServer();

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

  // NTP native initial sync
  syncNTP();

  // Preferences init
  preferences.begin("feed-sched", false); // namespace "feed-sched", read/write
  loadScheduleFromNVS(); // load persisted schedule (if any)

  // Firebase
  configFb.api_key = API_KEY; configFb.database_url = DATABASE_URL;
  if (Firebase.signUp(&configFb, &auth, "", "")) { Serial.println("[Firebase] sign‑up ok"); signupOK = true; } else { Serial.printf("[Firebase] sign‑up fail: %s\n", configFb.signer.signupError.message.c_str()); }
  configFb.token_status_callback = tokenStatusCallback;
  Firebase.begin(&configFb, &auth);
  Firebase.reconnectWiFi(true);

  // Start Firebase stream for schedule (if sign up ok)
  if (signupOK) {
    if (!Firebase.RTDB.beginStream(&scheduleStream, scheduleStreamPath)) {
      Serial.printf("[Stream] start failed: %s\n", scheduleStream.errorReason().c_str());
    } else {
      Serial.println("[Stream] Jadwal stream started");
    }
  }

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

  // ------- Wi‑Fi / Firebase keep‑alive -------------
  if (WiFi.status() == WL_CONNECTED) {
    if (!Firebase.ready()) {
      Firebase.reconnectWiFi(true);
    }
    if (Firebase.ready() && signupOK) {
      // ping ke Firebase tiap 5 detik (seperti sebelumnya)
      if (millis() - lastPingMillis > 5000) {
        lastPingMillis = millis();
        Firebase.RTDB.setString(&fbdo, "/aquafeed/device_status", "Online");
        Firebase.RTDB.setInt(&fbdo, "/aquafeed/last_ping", millis());
      }

      // handle manual command
      if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/action") &&
          fbdo.stringData() == "dispense") {
        Firebase.RTDB.setString(&fbdo, "/aquafeed/command/action", "idle");
        dispenseAction();
      }
      // handle flash command (optional)
      if (Firebase.RTDB.getString(&fbdo, "/aquafeed/command/flash")) {
        String cmd = fbdo.stringData();
        if (cmd == "on")  digitalWrite(flashLedPin, HIGH);
        else if (cmd == "off") digitalWrite(flashLedPin, LOW);
      }

      // baca stream jadwal (non‑blocking)
      if (Firebase.RTDB.available(&scheduleStream)) {
        scheduleStreamCallback(scheduleStream);
      }

      // cek eksekusi jadwal (berdasarkan waktu aktual) – still needed for minute‑granularity
      checkAndExecuteSchedule();
    }
  } else {
    // Wi‑Fi putus – coba reconnect setiap 5 detik
    static unsigned long lastWifiRetry = 0;
    if (millis() - lastWifiRetry > 5000) {
      lastWifiRetry = millis();
      Serial.println("[WiFi] Putus, mencoba reconnect...");
      WiFi.reconnect();
    }
  }

  // ------- NTP periodic resync -----
  if (millis() - lastNtpSync > NTP_INTERVAL_MS) {
    if (WiFi.status() == WL_CONNECTED) {
      syncNTP();
    }
  }

  // ------- Hitung jeda waktu sampai jadwal berikutnya -----
  uint32_t sleepSec = computeNextAlarm();
  if (sleepSec == 0) {
    // Tidak ada jadwal Hari ini/besok – kita tetap stay awake
    // untuk menunggu perubahan jadwal dari Firebase (stream).
    delay(1000); // jeda singkat agar watchdog tidak reboot
    return;
  }

  // Jika waktu sampai jadwal berikutnya lebih dari 30 menit,
  // kita masuk deep‑sleep untuk menghemat daya.
  // Jika kurang dari 30 menit, tetap awake agar kita bisa menangkap
  // perubahan jadwal yang mungkin masuk melalui stream.
  if (sleepSec > 30 * 60) {   // lebih dari 30 menit
    enterDeepSleep(sleepSec);
    // Tidak akan pernah sampai sini karena ESP akan reset setelah tidur.
  } else {
    // masih awake, tapi kita tidur sebentar supaya tidak CPU‑bound
    delay(1000);
  }
}