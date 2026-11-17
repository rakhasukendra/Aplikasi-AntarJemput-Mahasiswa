import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/firebase_bootstrap.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/passenger/passenger_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1E3A8A);
    const green = Color(0xFF78A632);
    const canvas = Color(0xFFF5F7FA);
    const surface = Color(0xFFFFFFFF);

    return MaterialApp(
      title: 'Antar Jemput Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          brightness: Brightness.light,
        ).copyWith(primary: navy, surface: surface, secondary: green),
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: navy,
          surfaceTintColor: Colors.transparent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            minimumSize: const Size(44, 48),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const FirebaseGate(),
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
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class FirebaseGate extends StatelessWidget {
  const FirebaseGate({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseBootstrapStatus>(
    future: FirebaseBootstrap.initialize(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data != FirebaseBootstrapStatus.configured) {
        return const PassengerShell(localMode: true);
      }
      return const AuthGate();
    },
  );
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.directions_bike, size: 38),
              const SizedBox(height: 20),
              Text(
                'Firebase belum disiapkan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tambahkan konfigurasi Firebase untuk mengaktifkan akun, pemesanan, dan pelacakan perjalanan.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hubungkan Firebase untuk akun dan tracking driver. Peta dan form tetap bisa dicoba secara lokal.',
                style: TextStyle(fontSize: 14, color: Color(0xFF414958)),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PassengerShell(),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Coba peta dan form lokal'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pesanan lokal hanya tersimpan di perangkat ini dan tidak dikirim ke driver.',
                style: TextStyle(fontSize: 14, color: Color(0xFF414958)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
