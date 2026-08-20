# Implementasi Pembaruan UI & Fitur AquaFeed

Pembaruan ini mencakup beberapa permintaan perubahan UI dan fitur berdasarkan permintaan Anda.

## Proposed Changes

### Menghapus Satuan "gram" dan "g" & Penyesuaian Layout
Akan menghapus teks satuan gram pada seluruh aplikasi agar tampilan angka lebih bersih.
#### [MODIFY] [schedule_card.dart](file:///f:/TA/aquafeed/lib/widgets/schedule_card.dart)
- Hapus teks `g` pada tampilan dosis (misal: `25g` menjadi `25`).
- Sembunyikan card "Jadwal Pakan Berikutnya" jika tidak ada jadwal (jika `nextSchedule == null`).

#### [MODIFY] [feeding_control.dart](file:///f:/TA/aquafeed/lib/widgets/feeding_control.dart)
- Hapus teks "gram" pada `_DosageDisplay`.
- Sesuaikan layout tombol plus dan minus agar lebih nyaman (misalnya dibuat lebih besar atau tata letak diubah agar lebih intuitif).
- Hapus teks "g" pada log pemberian manual.

#### [MODIFY] [activity_log.dart](file:///f:/TA/aquafeed/lib/widgets/activity_log.dart)
- Ubah format judul log dari `Pakan 25g diberikan` menjadi `Pakan 25 diberikan`.

---

### Fitur Kekeruhan Air (Dihapus)
#### [MODIFY] [home_screen.dart](file:///f:/TA/aquafeed/lib/home_screen.dart)
- Hapus widget `TurbidityStatusCard()` dari layar utama.
- Hapus import yang terkait.

#### [DELETE] [turbidity_card.dart](file:///f:/TA/aquafeed/lib/widgets/turbidity_card.dart)
- File dihapus secara keseluruhan karena fitur tidak lagi dibutuhkan.

---

### Floating Video (PIP) Bisa Digeser (Draggable)
#### [MODIFY] [home_screen.dart](file:///f:/TA/aquafeed/lib/home_screen.dart)
- Ganti `Positioned(bottom: 24, right: 16)` dengan variabel state `_pipX` dan `_pipY`.
- Bungkus widget Mjpeg Mini Player dengan `GestureDetector` dan gunakan event `onPanUpdate` untuk mengubah nilai koordinat X dan Y secara dinamis, sehingga PIP bebas digeser (drag-and-drop).

---

### Notifikasi Jadwal & Pembaruan "Jadwal Berikutnya"
Saat ini firmware ESP32 menjalankan jadwal pakan secara mandiri namun tidak mengirim catatan ke riwayat (Activity Log), sehingga aplikasi tidak menyadarinya.
#### [MODIFY] [feeder_esp32.ino](file:///f:/TA/aquafeed/esp32_firmware/feeder_esp32/feeder_esp32.ino)
- Tambahkan kode agar saat jadwal otomatis tercapai, ESP32 mengirim log baru ke Firebase (`/aquafeed/logs`).
- Log otomatis ini akan dibaca oleh aplikasi.
#### [MODIFY] [home_screen.dart](file:///f:/TA/aquafeed/lib/home_screen.dart)
- Tambahkan `ref.listen(logProvider, ...)` untuk mendengarkan penambahan log otomatis.
- Jika ada log baru dari jadwal otomatis, munculkan `Fluttertoast` (notifikasi Toast) di layar HP: "Jadwal otomatis tercapai".
#### [MODIFY] [schedule_provider.dart](file:///f:/TA/aquafeed/lib/providers/schedule_provider.dart)
- Pastikan UI merender ulang waktu (atau setiap kali log bertambah) sehingga bagian "Jadwal Berikutnya" otomatis mengarah ke jam/jadwal yang baru jika jadwal sebelumnya sudah berlalu.

## Open Questions
> [!NOTE]
> Pada fitur penggeseran video (Draggable PIP), video akan bisa dipindah ke mana saja di dalam layar utama. Apakah ini sesuai dengan yang Anda bayangkan?

## Verification Plan
1. Verifikasi UI: Pastikan tidak ada kata "gram" atau "g".
2. Verifikasi Kekeruhan: Fitur dan card kekeruhan air sudah hilang.
3. Verifikasi Drag: Buka floating camera dan coba geser.
4. Verifikasi Notifikasi: Saat jadwal tercapai, toast notifikasi muncul dan jadwal berlanjut.
