#include "HX711.h"

HX711 scale;

// Konfigurasi PIN sesuai dengan ESP32-CAM Anda
const int LOADCELL_DOUT_PIN = 15; // Sesuai dengan skema Anda (Pin 15)
const int LOADCELL_SCK_PIN = 14;  // Sesuai dengan skema Anda (Pin 14)

void setup() {
  Serial.begin(115200); 
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  
  Serial.println("\n\n===============================================");
  Serial.println("  PROSES KALIBRASI LOAD CELL (ESP32-CAM)");
  Serial.println("===============================================");
  Serial.println("Langkah 1: KOSONGKAN timbangan (jangan ada beban).");
  Serial.println("Ketik huruf 'a' lalu tekan Enter di Serial Monitor jika sudah kosong...");
  
  while (!Serial.available()); 
  String input = Serial.readStringUntil('\n');
  
  Serial.println("\nMencari nilai nol (Tare)...");
  scale.set_scale();
  scale.tare(20); 
  Serial.println("Nilai nol berhasil disimpan.");
  Serial.println("----------------------------------------------");
  
  Serial.println("Langkah 2: LETAKKAN beban yang sudah Anda ketahui beratnya (misal: 2 koin = 6.2).");
  Serial.println("Ketik angka berat beban tersebut dalam gram (contoh: 6.2) lalu tekan Enter:");
  
  while (!Serial.available()); 
  float berat_nyata = Serial.parseFloat();
  
  if (berat_nyata > 0) {
    Serial.print("\nMembaca beban seberat: ");
    Serial.print(berat_nyata);
    Serial.println(" gram...");
    
    // Ambil rata-rata 20 kali bacaan mentah agar akurat
    long raw_reading = scale.get_value(20); 
    
    // Menghitung faktor kalibrasi: (Nilai Mentah / Berat Nyata)
    float calibration_factor = (float)raw_reading / berat_nyata;
    
    Serial.println("\n==============================================");
    Serial.print("HASIL FAKTOR KALIBRASI ANDA: ");
    Serial.println(calibration_factor, 2); 
    Serial.println("-> Buka file feeder_esp32.ino, cari baris 'calibration_factor'");
    Serial.println("-> Ganti angkanya dengan angka di atas!");
    Serial.println("==============================================");
    
    scale.set_scale(calibration_factor);
  }
}

void loop() {
  Serial.print("Pengujian Real-time: ");
  Serial.print(scale.get_units(5), 1); 
  Serial.println(" gram");
  delay(500);
}
