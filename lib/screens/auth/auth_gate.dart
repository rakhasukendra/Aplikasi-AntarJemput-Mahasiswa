import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/trip_repository.dart';
import '../driver/driver_shell.dart';
import '../passenger/passenger_shell.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, authSnapshot) {
      if (!authSnapshot.hasData) {
        return SignInScreen(onSignedIn: () {});
      }
      final firebaseUser = authSnapshot.data!;
      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Profil akun gagal dimuat. Coba masuk kembali.'),
              ),
            );
          }
          if (!profileSnapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = profileSnapshot.data!.data();
          if (data == null) {
            // Dokumen profil belum ada — tampilkan penumpang tanpa profil
            return PassengerShell(
              user: AppUser(
                uid: firebaseUser.uid,
                name: firebaseUser.displayName ?? '',
                nim: '',
                email: firebaseUser.email ?? '',
                role: 'passenger',
              ),
              tripRepository: TripRepository(
                firestore: FirebaseFirestore.instance,
              ),
            );
          }

          // Pastikan 'uid' tersedia di map (bisa saja tidak tersimpan)
          final mapWithUid = {'uid': firebaseUser.uid, ...data};
          final appUser = AppUser.fromMap(mapWithUid);
          final tripRepo = TripRepository(
            firestore: FirebaseFirestore.instance,
          );

          return appUser.role == 'driver'
              ? DriverShell(user: appUser, tripRepository: tripRepo)
              : PassengerShell(user: appUser, tripRepository: tripRepo);
        },
      );
    },
  );
}
