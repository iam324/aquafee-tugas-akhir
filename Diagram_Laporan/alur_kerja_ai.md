# Gambar Diagram Alur Kerja (Workflow) Sistem AI Deteksi Pakan

Sesuai dengan Bagian 4 di file `PENJELASAN_PROYEK.md`, berikut adalah diagram alir (*Flowchart*) yang memvisualisasikan bagaimana AI bekerja dari awal (Pemicu) hingga akhir (Tampil di Layar).

## Kode Mermaid Diagram

```mermaid
flowchart TD
    %% Titik Awal
    Start(("Pemicu Analisis AI")) --> Trigger{Jenis Pemicu}
    
    Trigger -->|Otomatis| Interval["Timer Background<br/>(Setiap 1 Menit)"]
    Trigger -->|Manual| Tombol["Tombol 'Cek Pakan'<br/>di Antarmuka Aplikasi"]
    
    Interval --> Ekstrak
    Tombol --> Ekstrak
    
    %% Proses Utama (Berjalan di latar belakang agar HP tidak lag)
    subgraph Isolate ["Pengolahan Citra (Flutter Isolate)"]
        direction TB
        Ekstrak["1. Frame Extraction<br/>(Mengambil Snapshot dari Live Stream)"]
        ROI["2. Cropping ROI<br/>(Membuang 15% tepi gambar frame)"]
        Warna["3. Color Thresholding<br/>(Mendeteksi piksel warna pelet)"]
        Hitung["4. Blob Counting & Coverage<br/>(Menghitung butiran dan % luas area)"]
        
        Ekstrak --> ROI --> Warna --> Hitung
    end
    
    Hitung --> Logika{Penentuan Status}
    
    %% Kondisi Percabangan
    Logika -->|Butir ≤ 2 DAN<br/>Luas Area < 1.5%| Habis["Kategori: Makanan Habis"]
    Logika -->|Luas Area ≥ 1.5%| Ada["Kategori: Pakan Terdeteksi"]
    
    %% Tampilan Akhir
    Habis --> UI["5. Visualisasi Layar (UI)<br/>via State Management Riverpod"]
    Ada --> UI
    
    UI --> End(("Selesai"))
    
    %% Styling Warna
    classDef mulai fill:#E8F5E9,stroke:#2E7D32,stroke-width:2px,color:#000;
    classDef proses fill:#FFF8E1,stroke:#F57C00,stroke-width:2px,color:#000;
    classDef akhir fill:#E3F2FD,stroke:#1565C0,stroke-width:2px,color:#000;
    
    class Start,End mulai;
    class Ekstrak,ROI,Warna,Hitung proses;
    class Habis,Ada,UI akhir;
```

## Penjelasan Singkat (Bisa dilampirkan di bawah gambar)
Diagram ini menjelaskan alur deteksi citra (Computer Vision) yang sepenuhnya dieksekusi secara mandiri oleh aplikasi *mobile*. AI dapat dipicu secara otomatis setiap 1 menit atau secara manual lewat tombol. Untuk mencegah aplikasi menjadi lambat (lag/freeze), seluruh proses berat (seperti *Frame Extraction*, pemotongan area *ROI*, filter warna RGB, dan *Blob Counting*) dialihkan ke dalam **Flutter Isolate** (*thread* CPU sekunder pada HP). Hasil kalkulasi dari *Isolate* (apakah makanan habis atau masih sisa) kemudian dikembalikan ke layar utama dan diperbarui ke pengguna menggunakan *Riverpod State Management*.
