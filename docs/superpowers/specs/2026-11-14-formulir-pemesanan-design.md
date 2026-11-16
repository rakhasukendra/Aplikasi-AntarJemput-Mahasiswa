# Rancangan: Formulir Pemesanan Bertahap

## Tujuan

Membuat pemesanan antar-jemput lebih mudah dibaca dengan menampilkan lebih sedikit informasi pada satu layar dan mengganti teks teknis dengan istilah langsung.

## Cakupan

- Ubah formulir beranda menjadi dua tahap: **Lokasi** (titik jemput dan tujuan), lalu **Jadwal** (waktu dan jumlah penumpang).
- Pertahankan validasi, pilihan lokasi, dan penyimpanan pesanan yang sudah ada.
- Hapus peta ilustratif serta estimasi jarak, durasi, tarif, penghematan, jumlah pengemudi aktif, dan status terverifikasi yang tidak bersumber dari data nyata.
- Ringkas catatan keselamatan dan gunakan bahasa Indonesia yang jelas untuk semua label yang tersisa.
- Tingkatkan ukuran dan kontras teks kecil pada beranda dan riwayat.
- Hapus tujuan Profil yang masih berupa placeholder dari navigasi.

## Di luar cakupan

- Integrasi peta, GPS, tarif, jumlah pengemudi, profil, dan notifikasi.
- Perubahan model pesanan atau repository.

## Pendekatan

1. Formulir satu layar yang diringkas. Lebih sederhana, tetapi semua input tetap terlihat bersamaan.
2. Formulir dua langkah dalam satu layar bergulir. Mengurangi beban baca per tahap dan mempertahankan konteks; dipilih karena pengguna memilih opsi 2.

## Keputusan desain

- Gunakan indikator langkah dan tombol **Lanjut** / **Kembali**; tombol pemesanan muncul pada langkah jadwal.
- Validasi lokasi sebelum lanjut dan validasi waktu sebelum menyimpan.
- Pertahankan nilai input jika pengguna kembali ke langkah lokasi.
- Hindari informasi yang belum didukung layanan nyata daripada menggantinya dengan estimasi perkiraan.
- Pertahankan satu warna aksen tema saat ini; prioritaskan kontras serta teks minimal 14 px untuk keterangan dan 16 px untuk isi utama.
- Hapus tab Profil sampai halaman dengan isi nyata tersedia.

## Kriteria selesai

- Pengguna dapat mengisi lokasi, lanjut, kembali tanpa kehilangan input, lalu mengajukan pesanan.
- Input kosong dan tujuan yang sama menampilkan validasi yang jelas.
- Beranda tidak menampilkan angka atau klaim statis yang menyamar sebagai data aktual.
- Label teks utama terbaca dan tidak bertumpuk pada lebar ponsel umum.
- Navigasi hanya memuat Beranda dan Riwayat yang berfungsi.
