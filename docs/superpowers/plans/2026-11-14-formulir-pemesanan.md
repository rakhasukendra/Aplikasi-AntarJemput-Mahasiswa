# Formulir Pemesanan Bertahap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Perbaiki keterbacaan UI penumpang dan pecah pemesanan menjadi dua tahap yang tetap mempertahankan input serta validasi.

**Architecture:** Kelola tahap formulir di `PassengerHomeTab` tanpa mengubah repository atau model pesanan. Hapus konten estimasi yang tidak nyata, perjelas label, dan sederhanakan navigasi menjadi Beranda serta Riwayat.

**Tech Stack:** Flutter, Dart, widget tests.

**Spec:** `docs/superpowers/specs/2026-11-14-formulir-pemesanan-design.md`

## Global Constraints

- Gunakan dua tahap: Lokasi lalu Jadwal.
- Teks keterangan minimal 14 px dan teks isi utama 16 px.
- Jangan tampilkan klaim atau angka statis yang menyamar sebagai data aktual.
- Jangan menambah dependensi.
- Pertahankan validasi dan penyimpanan pesanan yang sudah ada.

## Review Focus

- Lokasi kosong atau sama: tampilkan validasi dan jangan maju/menyimpan.
- Kembali dari Jadwal: pertahankan lokasi yang telah dimasukkan.
- Waktu khusus dibatalkan: tetap di tahap Jadwal tanpa crash.
- Teks lokasi panjang: bungkus tanpa overflow pada lebar ponsel sempit.
- Batas jumlah penumpang: kontrol tetap menghormati rentang yang ada, 1 sampai 4.

---

### Task 1: Formulir lokasi dan jadwal bertahap

**Files:**
- Modify: `lib/screens/passenger/passenger_home_tab.dart`
- Test: `test/passenger_home_tab_test.dart`

**Interfaces:**
- Konsumsi: `RideRepository.instance`, `RideRequest`, dan callback `onOrderCreated` yang sudah ada.
- Hasil: tahap Lokasi dengan validasi titik jemput/tujuan; tahap Jadwal dengan waktu, penumpang, dan aksi kirim.

- [ ] Tambahkan widget test: input kosong menolak lanjut; tujuan sama menampilkan validasi.
- [ ] Jalankan `flutter test test/passenger_home_tab_test.dart` dan pastikan tes baru gagal pada implementasi lama.
- [ ] Tambahkan state langkah (`_stepIndex`), tombol Lanjut/Kembali, indikator langkah, dan pertahankan controller saat navigasi antartahap.
- [ ] Pindahkan waktu serta jumlah penumpang ke Jadwal; tombol pemesanan hanya muncul pada Jadwal dan tetap memvalidasi waktu.
- [ ] Tambahkan test kembali mempertahankan lokasi serta alur kirim membuat satu pesanan dan memanggil callback.
- [ ] Jalankan `flutter test test/passenger_home_tab_test.dart`; semua tes terkait harus lulus.

### Task 2: Sederhanakan teks dan isi beranda

**Files:**
- Modify: `lib/screens/passenger/passenger_home_tab.dart`
- Test: `test/passenger_home_tab_test.dart`

**Interfaces:**
- Konsumsi: tata letak dua tahap Task 1.
- Hasil: teks ringkas tanpa klaim buatan, dengan ukuran dan kontras yang lebih baik.

- [ ] Tambahkan tes yang memastikan angka pengemudi, estimasi tarif/jarak/durasi, diskon, status verifikasi, dan peta ilustratif tidak tampil.
- [ ] Ubah widget beranda sesuai rancangan: hapus peta, kartu estimasi, status dan angka tidak bersumber; pendekkan catatan keselamatan; ganti istilah teknis ke bahasa Indonesia langsung.
- [ ] Naikkan label kecil menjadi minimal 14 px dan teks utama menjadi 16 px; hapus teks dekoratif yang tidak membantu.
- [ ] Jalankan widget test; pastikan tidak ada teks klaim lama di layar.

### Task 3: Navigasi dan keterbacaan riwayat

**Files:**
- Modify: `lib/screens/passenger/passenger_shell.dart`
- Modify: `lib/screens/passenger/ride_list_tab.dart`
- Test: `test/passenger_navigation_test.dart`

**Interfaces:**
- Konsumsi: daftar status dan pesanan yang sudah ada.
- Hasil: hanya tab Beranda dan Riwayat; teks riwayat lebih terbaca.

- [ ] Tambahkan test bahwa navigasi hanya memiliki Beranda dan Riwayat serta keduanya dapat dipilih.
- [ ] Hapus tab Profil, placeholder profil, dan judul yang terkait.
- [ ] Tingkatkan ukuran dan kontras teks tanggal, lokasi, status, serta jumlah penumpang tanpa mengubah perilaku pembatalan.
- [ ] Jalankan `flutter test test/passenger_navigation_test.dart`.

### Task 4: Verifikasi seluruh perubahan

**Files:**
- Check: perubahan pada `lib/screens/passenger/` dan tes terkait.

- [ ] Jalankan `dart format lib/screens/passenger test`.
- [ ] Jalankan `flutter analyze` dan `flutter test`.
- [ ] Jalankan aplikasi pada ukuran ponsel sempit dan normal; periksa tahap, navigasi keyboard/tap, pembungkusan teks, serta overflow.
- [ ] Tinjau `git diff` agar perubahan terlingkup dan generated files yang telah berubah sebelumnya tidak tersentuh.
