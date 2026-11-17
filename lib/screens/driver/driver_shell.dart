import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import '../../services/trip_repository.dart';
import 'available_trips_screen.dart';
import 'driver_history_tab.dart';

class DriverShell extends StatefulWidget {
  final AppUser user;
  final TripRepository? tripRepository;

  const DriverShell({super.key, required this.user, this.tripRepository});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  static const _titles = ['Perjalanan', 'Riwayat'];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final repo = widget.tripRepository ?? const TripRepository.unconfigured();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.two_wheeler, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_index],
              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          AvailableTripsScreen(user: widget.user, repository: repo),
          DriverHistoryTab(driverId: widget.user.uid, repository: repo),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Perjalanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
