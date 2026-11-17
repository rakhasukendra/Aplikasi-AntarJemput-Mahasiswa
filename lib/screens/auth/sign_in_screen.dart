import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignedIn;

  const SignInScreen({super.key, required this.onSignedIn});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _nim = TextEditingController();
  bool _isRegistering = false;
  String _role = 'passenger';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _nim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validasi field wajib
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Masukkan email dan kata sandi.');
      return;
    }
    if (_isRegistering) {
      if (_name.text.trim().isEmpty) {
        setState(() => _error = 'Masukkan nama lengkap.');
        return;
      }
      if (_nim.text.trim().isEmpty) {
        setState(() => _error = 'Masukkan NIM.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isRegistering) {
        // Buat akun Firebase Auth
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );

        // Simpan profil lengkap ke Firestore via UserService
        await UserService().createUserProfile(
          AppUser(
            uid: credential.user!.uid,
            name: _name.text.trim(),
            nim: _nim.text.trim(),
            email: _email.text.trim(),
            role: _role,
          ),
        );
      } else {
        // Masuk dengan akun yang sudah ada
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      widget.onSignedIn();
    } on FirebaseAuthException catch (error) {
      setState(
        () => _error = switch (error.code) {
          'email-already-in-use' => 'Email sudah terdaftar.',
          'weak-password' => 'Kata sandi terlalu mudah ditebak.',
          'invalid-credential' => 'Email atau kata sandi tidak cocok.',
          'invalid-email' => 'Format email tidak valid.',
          _ => 'Akun tidak dapat diproses. Periksa koneksi dan coba lagi.',
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.school_outlined, size: 42, color: colors.primary),
                  const SizedBox(height: 18),
                  Text(
                    'Antar Jemput Mahasiswa',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Perjalanan kampus, lebih mudah diatur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 28),

                  // Toggle Masuk / Daftar
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Masuk')),
                      ButtonSegment(value: true, label: Text('Daftar')),
                    ],
                    selected: {_isRegistering},
                    onSelectionChanged: (value) =>
                        setState(() => _isRegistering = value.first),
                  ),
                  const SizedBox(height: 18),

                  // Email
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email kampus',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Kata sandi
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  // Field tambahan saat registrasi
                  if (_isRegistering) ...[
                    const SizedBox(height: 12),

                    // Nama lengkap
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // NIM
                    TextField(
                      controller: _nim,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'NIM',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilih peran
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'passenger',
                          label: Text('Penumpang'),
                          icon: Icon(Icons.person_outline),
                        ),
                        ButtonSegment(
                          value: 'driver',
                          label: Text('Driver'),
                          icon: Icon(Icons.two_wheeler),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (value) =>
                          setState(() => _role = value.first),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _role == 'driver'
                          ? 'Akun driver langsung aktif untuk mode demo dan dapat menerima pesanan penumpang.'
                          : 'Akun penumpang dapat membuat pesanan dan melacak driver.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF414958),
                      ),
                    ),
                  ],

                  // Pesan error
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 20),

                  // Tombol submit
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? 'Memproses...'
                          : _isRegistering
                          ? 'Buat akun'
                          : 'Masuk',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
