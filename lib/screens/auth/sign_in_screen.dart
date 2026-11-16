import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignedIn;

  const SignInScreen({super.key, required this.onSignedIn});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegistering = false;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Masukkan email dan kata sandi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isRegistering) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'role': 'passenger',
              'displayName': '',
              'createdAt': FieldValue.serverTimestamp(),
            });
      } else {
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
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email kampus',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_isRegistering) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Akun baru memakai peran Penumpang. Akses Driver diberikan admin setelah verifikasi.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF414958)),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: 20),
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
