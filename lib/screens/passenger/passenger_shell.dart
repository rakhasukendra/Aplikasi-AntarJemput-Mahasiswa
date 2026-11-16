import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_user.dart';
import '../../models/ride_request.dart';
import '../../services/driver_location_service.dart';
import '../../services/trip_repository.dart';

import 'passenger_home_tab.dart';
import 'ride_list_tab.dart';
import 'trip_tracking_screen.dart';
import 'local_ride_tracking_screen.dart';

class PassengerShell extends StatefulWidget {
  final AppUser? user;
  final TripRepository? tripRepository;
  final bool localMode;

  const PassengerShell({
    super.key,
    this.user,
    this.tripRepository,
    this.localMode = false,
  });

  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  static const _titles = ['Beranda', 'Riwayat'];
  int _index = 0;

  void _openTracking(RideRequest request) {
    final repository = widget.tripRepository;
    final userId = widget.user?.uid;
    final hasRoute =
        request.pickupLocation != null && request.destinationLocation != null;

    final Widget screen;
    if (repository?.isConfigured == true && userId != null && hasRoute) {
      screen = TripTrackingScreen(
        tripId: request.id,
        passengerId: userId,
        repository: repository!,
        locationService: DriverLocationService(
          firestore: FirebaseFirestore.instance,
        ),
      );
    } else {
      final message = repository?.isConfigured != true || widget.localMode
          ? 'Mode lokal: pesanan tidak dikirim ke driver, jadi lokasi driver belum tersedia.'
          : userId == null
          ? 'Akun penumpang diperlukan untuk membuka pelacakan perjalanan.'
          : 'Titik jemput dan tujuan dari peta diperlukan untuk melacak perjalanan.';
      screen = LocalRideTrackingScreen(request: request, message: message);
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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
        actions: widget.user == null
            ? null
            : [
                IconButton(
                  tooltip: 'Keluar',
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                ),
              ],
      ),
      // IndexedStack menjaga isi form tetap ada saat pindah tab.
      body: IndexedStack(
        index: _index,
        children: [
          PassengerHomeTab(
            localMode: widget.localMode,
            passengerId: widget.user?.uid,
            tripRepository: widget.tripRepository,
            onOrderCreated: _openTracking,
          ),
          RideListTab(
            passengerId: widget.user?.uid,
            tripRepository: widget.tripRepository,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
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
