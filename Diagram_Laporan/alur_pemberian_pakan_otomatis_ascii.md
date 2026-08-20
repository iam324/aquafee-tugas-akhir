# Diagram Alir Pemberian Pakan Otomatis (Format Teks / ASCII)

Karena limitasi *Mermaid*, berikut adalah diagram alir yang dibuat menggunakan karakter teks murni (ASCII Art). Diagram ini **100% aman disalin ke Microsoft Word** tanpa butuh aplikasi tambahan.

**💡 TIPS PENTING SEBELUM COPY-PASTE KE WORD:**
1. Blok seluruh teks kotak di bawah ini.
2. Salin (*Copy*) dan tempel (*Paste*) ke Microsoft Word.
3. Sorot teksnya di Word, lalu ubah jenis *Font*-nya menjadi **Courier New** atau **Consolas**. (Wajib dilakukan agar kotak-kotaknya tidak hancur dan sejajar rapi!).
4. Perkecil ukuran *font* (misalnya ukuran 8 atau 9) agar muat dalam satu halaman.

```text
       ┌───────────────────────────────────────────┐
       │                  MULAI                    │
       └────────────────────┬──────────────────────┘
                            │
                            ▼
       ┌───────────────────────────────────────────┐
       │      Inisialisasi Sistem (ESP32-CAM)      │
       │  Mengkoneksikan WiFi & Akses Server NTP   │
       │    (Untuk Sinkronisasi Jam Atom Global)   │
       └────────────────────┬──────────────────────┘
                            │
                            ▼
       ┌───────────────────────────────────────────┐
       │     Mengunduh Array Data Jadwal dari      │
       │        Firebase Realtime Database         │
       └────────────────────┬──────────────────────┘
                            │
                            ▼
           [ Loop Pengecekan Waktu Tiap Detik ]
     ┌──────────────────────┴──────────────────────┐
     │                                             │
     ▼                                             │
 ┌───────────────────────────────────────┐         │
 │     Apakah Waktu Sekarang (NTP)       │         │
 │   Sama dengan Waktu Aktif di Jadwal?  │──(TIDAK)┘
 └──────────────────┬────────────────────┘
                    │
                  (YA)
                    │
                    ▼
 ┌───────────────────────────────────────┐
 │ Kirim Sinyal Arus Rendah (GPIO 15) ke │
 │         Modul Motor Driver L298N      │
 └──────────────────┬────────────────────┘
                    │
                    ▼
 ┌───────────────────────────────────────┐
 │   L298N Mengalirkan Arus Kuat (5V)    │
 │    Motor DC Berputar Membuka Katup    │
 │       (Selama durasi 7400 ms)         │
 └──────────────────┬────────────────────┘
                    │
                    ▼
 ┌───────────────────────────────────────┐
 │   Motor Berhenti (Katup Menutup),     │
 │ Mengirim Log Status "Pakan Diberikan" │
 │        Kembali ke Firebase            │
 └──────────────────┬────────────────────┘
                    │
                    ▼
       ┌─────────────────────────────────────┐
       │               SELESAI               │
       │        (Kembali ke Loop Awal)       │
       └─────────────────────────────────────┘
```
