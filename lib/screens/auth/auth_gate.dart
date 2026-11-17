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
      final user = authSnapshot.data!;
      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
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
          final role = data?['role'] == 'driver'
              ? UserRole.driver
              : UserRole.passenger;
          final appUser = AppUser(
            uid: user.uid,
            role: role,
            displayName: data?['displayName'] as String? ?? '',
          );
          return appUser.role == UserRole.driver
              ? DriverShell(
                  user: appUser,
                  tripRepository: TripRepository(
                    firestore: FirebaseFirestore.instance,
                  ),
                )
              : PassengerShell(
                  user: appUser,
                  tripRepository: TripRepository(
                    firestore: FirebaseFirestore.instance,
                  ),
                );
        },
      );
    },
  );
}
