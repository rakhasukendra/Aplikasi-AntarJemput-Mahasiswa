import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/trip.dart';
import '../../services/trip_repository.dart';
import 'active_trip_screen.dart';

class AvailableTripsScreen extends StatelessWidget {
  final AppUser user;
  final TripRepository repository;

  const AvailableTripsScreen({
    super.key,
    required this.user,
    this.repository = const TripRepository.unconfigured(),
  });

  @override
  Widget build(BuildContext context) {
    if (!repository.isConfigured) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Firebase belum disiapkan. Hubungkan Firebase untuk melihat pesanan yang tersedia.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return StreamBuilder<List<Trip>>(
      stream: repository.availableTrips(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Pesanan gagal dimuat. Coba lagi.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada permintaan jemput.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final trip = snapshot.data![index];
            return Card(
              child: ListTile(
                title: Text(
                  '${trip.pickup.label} ke ${trip.destination.label}',
                ),
                subtitle: Text('${trip.passengerCount} penumpang'),
                trailing: FilledButton(
                  onPressed: () async {
                    await repository.acceptTrip(
                      trip.id,
                      user.uid,
                      driverName: user.name.trim().isEmpty
                          ? 'Driver'
                          : user.name.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ActiveTripScreen(
                          tripId: trip.id,
                          driver: user,
                          repository: repository,
                        ),
                      ),
                    );
                  },
                  child: const Text('Ambil'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
