import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import '../../services/trip_repository.dart';
import 'available_trips_screen.dart';

class DriverShell extends StatelessWidget {
  final AppUser user;
  final TripRepository? tripRepository;

  const DriverShell({super.key, required this.user, this.tripRepository});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Perjalanan driver'),
      actions: [
        IconButton(
          tooltip: 'Keluar',
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: AvailableTripsScreen(
      user: user,
      repository: tripRepository ?? const TripRepository.unconfigured(),
    ),
  );
}
