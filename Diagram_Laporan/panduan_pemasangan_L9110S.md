# Panduan Pemasangan Modul L9110S ke ESP32-CAM

## Rangkaian Anda Saat Ini (SEBELUM)

```
FTDI (USB ke Komputer)
  ├── Merah (5V)  ──────────┬──→ ESP32-CAM pin 5V
  ├── Putih (GND) ──────────┬──→ ESP32-CAM pin GND
  ├── TX ───────────────────────→ ESP32-CAM pin UOR
  └── RX ───────────────────────→ ESP32-CAM pin UOT

ESP32-CAM pin GPIO 15 ──→ Transistor ──→ Motor DC (+)
ESP32-CAM pin GND ──────→ Transistor ──→ Motor DC (-)
ESP32-CAM pin 5V ───────→ Transistor ──→ Motor DC (daya)

(IO0 disambung ke GND saat upload program)
```

---

## Rangkaian Baru (SESUDAH - dengan L9110S)

### Langkah 1: Matikan Semua Daya
- Cabut kabel USB/adaptor dari FTDI
- Pastikan tidak ada listrik yang mengalir

### Langkah 2: Lepas Transistor
- Potong atau lepas solder **3 kabel** yang menghubungkan transistor ke ESP32-CAM
- Khususnya: kabel dari **GPIO 15**, **GND**, dan **5V** yang mengarah ke transistor
- **Buang transistor** beserta kabelnya (tidak dipakai lagi)
- **Kabel motor** (2 kabel yang mengarah ke motor DC) biarkan dulu, nanti disambung ke modul L9110S

### Langkah 3: Kenali Pin Modul L9110S

```
Tampak Atas Modul L9110S (Warna Merah):

    ┌─────────────────────┐
    │  IN1  IN2  IN3  IN4 │  ← Pin INPUT (dari ESP32)
    │   ●    ●    ●    ●  │
    │                  (+) │  ← Pin VCC (Daya Motor)
    │  [IC Chip]     ●    │
    │                  (-) │  ← Pin GND
    │  [Kapasitor] [Kap]  │
    │   ●    ●    ●    ●  │
    │ MOTOR-B    MOTOR-A  │  ← Pin OUTPUT (ke Motor)
    └─────────────────────┘
```

> [!IMPORTANT]
> Anda hanya akan menggunakan sisi **MOTOR-A** (IN1 & IN2).
> Sisi MOTOR-B (IN3 & IN4) dibiarkan kosong.

### Langkah 4: Sambungkan Kabel (6 Koneksi)

Siapkan kabel jumper secukupnya, lalu sambungkan satu per satu:

| No | Dari | Ke | Fungsi |
|----|------|----|--------|
| 1 | **ESP32-CAM → 5V** | **L9110S → VCC (+)** | Daya untuk motor |
| 2 | **ESP32-CAM → GND** | **L9110S → GND (-)** | Ground bersama |
| 3 | **ESP32-CAM → GPIO 15** | **L9110S → IN1** | Sinyal putar MAJU |
| 4 | **ESP32-CAM → GPIO 14** | **L9110S → IN2** | Sinyal putar MUNDUR |
| 5 | **Motor DC → Kabel (+)** | **L9110S → MOTOR-A (kiri)** | Output ke motor |
| 6 | **Motor DC → Kabel (-)** | **L9110S → MOTOR-A (kanan)** | Output ke motor |

### Langkah 5: Diagram Sambungan Final

```
FTDI (USB ke Komputer) — TIDAK BERUBAH
  ├── Merah (5V)  ──→ ESP32-CAM pin 5V
  ├── Putih (GND) ──→ ESP32-CAM pin GND
  ├── TX ───────────→ ESP32-CAM pin UOR
  └── RX ───────────→ ESP32-CAM pin UOT

ESP32-CAM                    L9110S                    Motor DC
  │                            │                         │
  ├── 5V  ──────────────────→ VCC (+)                    │
  ├── GND ──────────────────→ GND (-)                    │
  ├── GPIO 15 ──────────────→ IN1 (Maju)                 │
  ├── GPIO 14 ──────────────→ IN2 (Mundur)               │
  │                            │                         │
  │                     MOTOR-A (kiri)  ────────────→ Kabel (+)
  │                     MOTOR-A (kanan) ────────────→ Kabel (-)
  │
  ├── IO0 → GND (hanya saat upload program)
  ├── UOR → FTDI TX
  └── UOT → FTDI RX
```

> [!WARNING]
> **Jangan sambungkan IN3 dan IN4!** Biarkan kosong. Itu untuk motor kedua yang tidak Anda pakai.

> [!TIP]
> **Soal polaritas motor (kabel + dan -):** Jika setelah dipasang motor berputar ke arah yang salah (makanan tidak jatuh), cukup **tukar posisi 2 kabel motor** di pin MOTOR-A. Tidak perlu ubah kode.

---

## Langkah 6: Upload Program Baru

Setelah semua kabel tersambung:
1. Sambungkan **IO0 ke GND** (mode upload)
2. Colokkan FTDI ke komputer
3. Upload kode terbaru dari Arduino IDE
4. **Cabut IO0 dari GND** setelah upload selesai
5. Tekan tombol **RESET** di ESP32-CAM
6. Selesai! 🎉

---

## Checklist Sebelum Menyalakan

- [ ] Transistor lama sudah dilepas total
- [ ] 5V dan GND dari ESP32 terhubung ke VCC dan GND di L9110S
- [ ] GPIO 15 terhubung ke IN1
- [ ] GPIO 14 terhubung ke IN2
- [ ] 2 kabel motor terhubung ke MOTOR-A (kiri & kanan)
- [ ] IN3 dan IN4 dibiarkan kosong
- [ ] MOTOR-B dibiarkan kosong
