import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referensi collection users.
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // 1. Membuat profil pengguna.
  Future<void> createUserProfile(AppUser user) async {
    await _users.doc(user.uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Mengambil profil berdasarkan UID.
  Future<AppUser?> getUserProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AppUser.fromMap(snapshot.data()!);
  }

  // 3. Memantau perubahan profil secara real-time.
  Stream<AppUser?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return AppUser.fromMap(snapshot.data()!);
    });
  }

  // 4. Memperbarui informasi profil.
  // Role, UID, email, dan createdAt tidak dapat diubah di sini.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String nim,
    String? phone,
  }) async {
    await _users.doc(uid).update({
      'name': name,
      'nim': nim,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
