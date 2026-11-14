import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antar Jemput Mahasiswa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      // Fondasi routing untuk seluruh anggota tim
      routes: {
        '/': (context) => const PlaceholderScreen(title: 'Halaman Login/Register'),
        '/passenger': (context) => const PlaceholderScreen(title: 'Beranda Penumpang (Area Alan)'),
        '/driver': (context) => const PlaceholderScreen(title: 'Beranda Pengemudi (Area Rakha)'),
        '/history': (context) => const PlaceholderScreen(title: 'Riwayat Perjalanan (Area Dhani)'),
      },
    );
  }
}

// Widget sementara agar routing di atas bisa berjalan dan tidak error
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}