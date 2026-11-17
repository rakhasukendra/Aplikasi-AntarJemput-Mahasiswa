import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String nim;
  final String email;
  final String role;
  final String? phone;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.nim,
    required this.email,
    required this.role,
    this.phone,
    this.createdAt,
  });

  // Mengubah objek AppUser menjadi Map
  // agar dapat disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'nim': nim,
      'email': email,
      'role': role,
      'phone': phone,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }

  // Mengubah data dari Firestore menjadi AppUser.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    final timestamp = map['createdAt'];

    DateTime? date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    }

    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String,
      nim: map['nim'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      phone: map['phone'] as String?,
      createdAt: date,
    );
  }
}
