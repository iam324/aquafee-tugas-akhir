# Gambar 3.1 Arsitektur Sistem IoT Pemberi Pakan Ikan (AquaFeed)

Berikut adalah diagram blok Arsitektur Sistem untuk laporan Anda. Anda bisa merendernya menjadi gambar resolusi tinggi menggunakan [Mermaid Live Editor](https://mermaid.live/).

## Kode Mermaid Diagram

```mermaid
flowchart TD
      %% Node Definitions
      subgraph MobileApp ["Aplikasi Mobile Flutter"]
          direction TB
          UI["UI Flutter/Riverpod"]
          AI["AI Image Processing<br/>Isolate"]
          LiveCountdown["Live Countdown UI<br/>1 menit sekali"]
          ManualButton["Tombol Manual Deteksi"]
      end

      subgraph Firebase ["Firebase Realtime Database"]
          direction TB
          Commands["Perintah<br/>Start/Stop Deteksi"]
          Scheduling["Array Jadwal<br/>dari Flutter"]
          DeviceStatus["Status Perangkat<br/>Online/Offline"]
          AutoIPDiscovery["Auto-IP Discovery"]
      end

      subgraph ESP32CAM ["ESP32-CAM Edge Device"]
          direction TB
          Core0["Core 0<br/>HTTP Server<br/>MJPEG Stream"]
          Core1["Core 1<br/>FreeRTOS Loop<br/>Firebase Sync<br/>Penjadwalan<br/>Kontrol Motor L298N"]
          MotorCtrl["Kontrol Motor DC 5V<br/>melalui L298N"]
      end

      subgraph Hardware ["Aktuator dan Sensor"]
          Motor["Motor DC 5V"]
          NTP["Server NTP<br/>pool.ntp.org"]
      end

      %% Connections
      %% App <-> Firebase
      UI -->|"Mengirim/terima perintah<br/>dan jadwal"| Commands
      UI -->|"Mengunduh jadwal<br/>saat ESP32 menyala"| Scheduling
      DeviceStatus -->|"Status perangkat<br/>online/offline"| UI
      AutoIPDiscovery -->|"Menemukan IP ESP32"| UI

      %% App <-> ESP32-CAM (Video Stream)
      UI -->|"Mengambil snapshot<br/>dari live stream<br/>MJPEG"| Core0
      Core0 -->|"Mengirimkan stream<br/>video MJPEG"| UI

      %% Firebase <-> ESP32-CAM
      Commands -->|"Menerima perintah<br/>start/stop"| Core1
      Scheduling -->|"Mengunduh array jadwal<br/>dan mengeksekusi"| Core1
      Core1 -->|"Mengirim status<br/>perangkat ke Firebase"| DeviceStatus
      NTP -->|"Mengambil jam atom<br/>WIB GMT+7"| Core1

      %% ESP32-CAM <-> Hardware
      Core1 -->|"Mengendalikan motor<br/>lewat GPIO 15/14"| MotorCtrl
      MotorCtrl -->|"Menggerakkan motor DC"| Motor

      %% Styling
      classDef mobile fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#000;
      classDef firebase fill:#FFF8E1,stroke:#F57C00,stroke-width:2px,color:#000;
      classDef esp fill:#F3E5F5,stroke:#6A1B9A,stroke-width:2px,color:#000;
      classDef hardware fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#000;

      class UI,AI,LiveCountdown,ManualButton mobile;
      class Commands,Scheduling,DeviceStatus,AutoIPDiscovery firebase;
      class Core0,Core1,MotorCtrl esp;
      class Motor,NTP hardware;
```

## Penjelasan Arsitektur Sistem (Untuk Teks Laporan)

Arsitektur sistem IoT cerdas *AquaFeed* terdiri dari tiga bagian utama, yaitu perangkat keras (*Hardware/Node*), peladen *cloud* (*Backend*), dan aplikasi seluler (*Frontend*). Alur komunikasi dan pengolahan data pada sistem ini berjalan sebagai berikut:

1. **Aplikasi Mobile (Flutter)**: Bertindak sebagai pusat kendali bagi pengguna. Pengguna dapat memberikan perintah (misalnya menekan tombol "Beri Pakan") atau mengatur jadwal otomatis. Aplikasi ini terhubung langsung ke **Firebase Realtime Database** untuk menulis perintah (operasi *Write*) dan membaca status terbaru dari alat (operasi *Read*).
2. **Firebase Realtime Database (Cloud)**: Berfungsi sebagai *broker* atau penyedia *database* JSON waktu-nyata (*real-time*). Firebase bertugas menyinkronkan setiap perubahan data antara aplikasi *mobile* dan mikrokontroler. Misalnya, jika aplikasi mengubah status *feed_now* menjadi `true`, Firebase akan langsung meneruskannya ke ESP32.
3. **Router / Jaringan WiFi**: Perantara konektivitas internet agar Aplikasi dan ESP32-CAM dapat saling terhubung. Khusus untuk *streaming* video dari kamera, koneksi tidak melalui Firebase, melainkan aplikasi *mobile* akan mengakses *IP Address* ESP32 (melalui peladen HTTP internal ESP32) untuk menarik data video (*MJPEG stream*) secara langsung.
4. **Mikrokontroler (ESP32-CAM)**: Bertindak sebagai otak di sisi perangkat keras. ESP32 secara terus-menerus memantau *Firebase* untuk mendapatkan jadwal terbaru dan mengeksekusi perintah.
5. **Sensor dan Aktuator**: 
   - **Kamera OV2640**: Mengambil data visual dari lingkungan kolam/akuarium dan menyajikannya dalam bentuk peladen *web* gambar berjalan (HTTP *Stream*). Gambar ini juga ditarik oleh aplikasi *mobile* untuk diolah menggunakan AI (*Computer Vision*) guna mendeteksi sisa pakan tanpa memerlukan sensor berat fisik.
   - **Motor Servo**: Bertindak sebagai aktuator fisik (*output*). Saat perintah pakan diterima (baik manual dari Firebase maupun otomatis berdasarkan jam internal NTP), ESP32 akan mengirimkan sinyal PWM ke Motor Servo untuk membuka katup penampung pakan, lalu menutupnya kembali.
