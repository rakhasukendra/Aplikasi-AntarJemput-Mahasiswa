import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Mengambil pengguna yang sedang login.
  User? get currentUser => _auth.currentUser;

  // Memantau status autentikasi.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Registrasi pengguna.
  Future<UserCredential> register({
    required String name,
    required String nim,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw StateError('Gagal mendapatkan identitas pengguna.');
    }

    final user = AppUser(
      uid: firebaseUser.uid,
      name: name.trim(),
      nim: nim.trim(),
      email: email.trim(),
      role: role,
      createdAt: DateTime.now(),
    );

    try {
      // Membuat profil di Cloud Firestore.
      await _userService.createUserProfile(user);
    } catch (e) {
      // Membatalkan akun Auth yang baru dibuat jika
      // penyimpanan profil gagal.
      try {
        await firebaseUser.delete();
      } catch (_) {
        // Pertahankan error penyimpanan profil.
      }

      rethrow;
    }

    return credential;
  }

  // 2. Login pengguna.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // 3. Logout pengguna.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 4. Mengambil UID pengguna yang sedang login.
  String? get currentUid => _auth.currentUser?.uid;
}
