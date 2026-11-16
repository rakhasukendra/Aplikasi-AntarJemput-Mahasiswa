# Rancangan: Peta dan Tracking Antar-Jemput

## Tujuan

Melanjutkan tampilan referensi dengan pemilihan lokasi melalui peta, peta perjalanan, dan pembaruan posisi driver yang benar-benar berasal dari GPS.

## Pendekatan

Satu aplikasi Flutter dengan pilihan peran Penumpang dan Driver. Pendekatan aplikasi driver terpisah tidak dipilih agar proyek ini dapat menguji kedua sisi alur tanpa membuat proyek Flutter kedua.

## Arah visual

- Gunakan biru navy sebagai warna utama dan tombol aksi, dengan latar terang dan permukaan kartu putih.
- Gunakan hijau hemat sebagai aksen status aktif atau sukses, bukan warna untuk semua elemen.
- Terapkan hierarki teks jelas, kontras tinggi, dan struktur ringkas yang merujuk pada screenshot autentikasi yang dikirim pengguna.
- Logo kampus tidak dibuat tanpa aset resmi; tampilkan nama produk sebagai teks sampai aset diberikan.

## Teknologi

- `flutter_map` untuk peta dan marker OpenStreetMap.
- `geolocator` untuk izin dan pembacaan lokasi perangkat.
- Firebase Authentication untuk identitas akun.
- Cloud Firestore untuk permintaan perjalanan dan stream lokasi driver.
- Tile OpenStreetMap standar hanya untuk pengembangan ringan; pemakaian produksi harus mematuhi kebijakan tile OSM atau menggunakan penyedia tile yang sesuai.

## Alur

1. Penumpang memilih titik jemput dan tujuan melalui input atau peta; koordinat disimpan pada pesanan.
2. Driver masuk ke mode Driver, menerima permintaan yang tersedia, dan menerima perjalanan.
3. Driver membagikan posisi GPS saat perjalanan aktif. Aplikasi hanya mengirim posisi saat driver telah menerima perjalanan.
4. Penumpang membuka detail perjalanan, melihat marker driver, titik jemput/tujuan, status perjalanan, dan stream lokasi terbaru.
5. Driver mengubah status perjalanan melalui aksi nyata: menerima, tiba di jemput, mulai, dan selesai.

## Data dan keamanan

- Dokumen perjalanan berisi passengerId, driverId nullable, status, titik jemput/tujuan (lat/lng dan label), jumlah penumpang, dan waktu.
- Dokumen lokasi driver menyimpan lat, lng, heading opsional, accuracy opsional, updatedAt server timestamp, serta tripId aktif.
- Firestore Rules membatasi penumpang membaca perjalanan miliknya, driver membaca perjalanan yang dapat diterima, dan driver menulis lokasi hanya untuk perjalanan yang ditugaskan kepadanya.
- Login memakai Firebase Authentication; tidak membuat identitas atau posisi driver palsu.
- Jangan menyimpan API key rahasia di source. Firebase client config bukan rahasia backend, tetapi Rules tetap wajib sebelum produksi.

## Batasan dan kriteria selesai

- Kode integrasi, Rules awal, dan panduan konfigurasi Firebase disertakan.
- Tanpa file konfigurasi Firebase dan akun uji, build/test lokal harus tetap jalan dalam mode konfigurasi belum tersedia; aplikasi menjelaskan konfigurasi yang diperlukan.
- Pemilih lokasi memakai peta interaktif dan mengembalikan koordinat yang dipilih.
- Tracking hanya diberi label live jika Firestore stream dan update GPS benar-benar aktif; selain itu tampilkan status koneksi/konfigurasi.
- Widget tests membuktikan validasi lokasi, perubahan status, dan tampilan stream tanpa membuat klaim lokasi live palsu.
- Simulasi GPS atau data driver contoh tidak boleh tampil sebagai perjalanan nyata.

## Di luar cakupan

- Membuat proyek Firebase atas nama pengguna, mengaktifkan billing, atau mengunggah kredensial.
- Publikasi aplikasi, penagihan, geocoding berbayar, push notification, dan audit keamanan produksi menyeluruh.
