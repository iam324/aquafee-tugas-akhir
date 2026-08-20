# Gambar Struktur Firebase Realtime Database

Berikut adalah diagram pohon yang menggambarkan struktur JSON dari Firebase Realtime Database yang digunakan pada proyek AquaFeed. Anda dapat membukanya di Mermaid Live Editor untuk melihat visualisasinya.

## Kode Mermaid

```mermaid
flowchart TD
    %% Memaksa tata letak vertikal (Atas ke Bawah lurus) agar muat di kertas A4
    Jadwal ~~~ Riwayat
    Riwayat ~~~ Status

    %% Root of JSON tree
    Root["/ (Root Node)"] --> Jadwal
    Root --> Riwayat
    Root --> Status

    subgraph Jadwal ["Jadwal - Jadwal Pemberian Pakan Otomatis"]
        direction TB
        JadwalHeader["Jadwal (Array of Objects)"]
        JadwalItem0["Index 0"]
        
        JadwalHeader --> JadwalItem0
        JadwalItem0 --> jadwal_time0["time: HH:MM"]
        JadwalItem0 --> jadwal_active0["active: boolean"]
        JadwalItem0 --> jadwal_days0["days: [bool, bool, bool, bool, bool, bool, bool]"]
        JadwalItem0 --> jadwal_dot["..."]
        
        JadwalItemN["Index N"]
        JadwalItem0 -.-> JadwalItemN
        JadwalItemN --> jadwal_timeN["time: HH:MM"]
        JadwalItemN --> jadwal_activeN["active: boolean"]
        JadwalItemN --> jadwal_daysN["days: [bool,...]"]
    end

    subgraph Riwayat ["Riwayat - Log Aktivitas Pemberian Pakan"]
        direction TB
        RiwayatHeader["Riwayat (Array of Objects)"]
        LogItem0["Log 0"]
        
        RiwayatHeader --> LogItem0
        LogItem0 --> riwayat_title0["title: string"]
        LogItem0 --> riwayat_time0["time: string (HH:MM)"]
        LogItem0 --> riwayat_type0["type: 0 = otomatis, 1 = manual"]
        LogItem0 --> riwayat_status0["status: string (Selesai / Gagal)"]
        LogItem0 --> riwayat_timestamp0["timestamp: double (ms)"]
        LogItem0 --> riwayat_dot["..."]
        
        LogItemN["Log N"]
        LogItem0 -.-> LogItemN
        LogItemN --> riwayat_titleN["title: string"]
        LogItemN --> riwayat_timeN["time: string"]
        LogItemN --> riwayat_typeN["type: int"]
        LogItemN --> riwayat_statusN["status: string"]
        LogItemN --> riwayat_timestampN["timestamp: double"]
    end

    subgraph Status ["Variabel Alat & Command"]
        direction TB
        StatusHeader["Root: /aquafeed/"]
        
        StatusHeader --> device_status["device_status: string ('Online')"]
        StatusHeader --> last_ping["last_ping: integer (ms)"]
        StatusHeader --> stream_url["stream_url: string (http://IP:81/stream)"]
        
        command["command (Object)"]
        StatusHeader --> command
        command --> action["action: string ('idle' / 'dispense')"]
        command --> flash["flash: string ('on' / 'off')"]
    end

    %% Styling Warna
    classDef root fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#000;
    classDef jadwal fill:#FFF8E1,stroke:#F57C00,stroke-width:2px,color:#000;
    classDef riwayat fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#000;
    classDef status fill:#F3E5F5,stroke:#6A1B9A,stroke-width:2px,color:#000;

    class Root root;
    class Jadwal jadwal;
    class Riwayat riwayat;
    class Status status;
```
