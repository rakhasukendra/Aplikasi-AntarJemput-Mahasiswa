import 'package:flutter/material.dart';
import 'screens/passenger/passenger_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1E3A8A);

    return MaterialApp(
      title: 'Antar Jemput Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy).copyWith(primary: navy),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      initialRoute: '/passenger', // sementara, supaya langsung terlihat
      routes: {
        '/': (context) => const PlaceholderScreen(title: 'Halaman Login/Register'),
        '/passenger': (context) => const PassengerShell(),
        '/driver': (context) => const PlaceholderScreen(title: 'Beranda Pengemudi (Area Rakha)'),
        '/history': (context) => const PlaceholderScreen(title: 'Riwayat Perjalanan (Area Dhani)'),
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}