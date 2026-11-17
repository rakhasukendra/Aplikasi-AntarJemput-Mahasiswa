import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/trip.dart';
import '../../services/trip_repository.dart';
import '../../services/driver_location_service.dart';
import '../../utils/format.dart';
import 'driver_trip_map_screen.dart';

/// Tab riwayat perjalanan driver — menampilkan semua trip yang pernah
/// ditangani oleh driver ini, mirip dengan RideListTab pada sisi penumpang.
class DriverHistoryTab extends StatelessWidget {
  final String driverId;
  final TripRepository repository;

  const DriverHistoryTab({
    super.key,
    required this.driverId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (!repository.isConfigured) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Firebase belum disiapkan. Hubungkan Firebase untuk melihat riwayat perjalanan.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<List<Trip>>(
      stream: repository.driverTrips(driverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Riwayat gagal dimuat. Periksa koneksi.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = snapshot.data!;
        if (trips.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.two_wheeler_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text('Belum ada perjalanan yang ditangani'),
              ],
            ),
          );
        }

        // Urutkan: perjalanan aktif duluan, lalu yang terbaru
        final sorted = [...trips]..sort((a, b) {
          final aActive = _isActive(a.status);
          final bActive = _isActive(b.status);
          if (aActive != bActive) return aActive ? -1 : 1;
          final aTime = a.updatedAt ?? a.createdAt ?? DateTime(0);
          final bTime = b.updatedAt ?? b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _TripCard(
            trip: sorted[i],
            driverId: driverId,
            repository: repository,
          ),
        );
      },
    );
  }

  static bool _isActive(TripStatus s) =>
      s == TripStatus.accepted ||
      s == TripStatus.arrived ||
      s == TripStatus.inProgress;
}

// ─────────────────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  final String driverId;
  final TripRepository repository;

  const _TripCard({
    required this.trip,
    required this.driverId,
    required this.repository,
  });

  Color get _statusColor => switch (trip.status) {
    TripStatus.requested => Colors.orange,
    TripStatus.accepted => Colors.blue,
    TripStatus.arrived => Colors.indigo,
    TripStatus.inProgress => Colors.purple,
    TripStatus.completed => Colors.green,
    TripStatus.cancelled => Colors.grey,
  };

  String get _statusLabel => switch (trip.status) {
    TripStatus.requested => 'Menunggu',
    TripStatus.accepted => 'Menuju jemput',
    TripStatus.arrived => 'Tiba di jemput',
    TripStatus.inProgress => 'Dalam perjalanan',
    TripStatus.completed => 'Selesai',
    TripStatus.cancelled => 'Dibatalkan',
  };

  bool get _isActive =>
      trip.status == TripStatus.accepted ||
      trip.status == TripStatus.arrived ||
      trip.status == TripStatus.inProgress;

  @override
  Widget build(BuildContext context) {
    final dateTime = trip.scheduledAt ?? trip.createdAt ?? DateTime.now();
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _isActive
            ? Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tanggal + badge status
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDateTime(dateTime),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Titik jemput
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.pickup.label)),
            ],
          ),
          const SizedBox(height: 6),

          // Tujuan
          Row(
            children: [
              Icon(
                Icons.flag,
                size: 18,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.destination.label)),
            ],
          ),
          const SizedBox(height: 8),

          // Jumlah penumpang
          Text(
            '${trip.passengerCount} penumpang',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          // Tombol lihat peta — hanya untuk trip aktif
          if (_isActive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DriverTripMapScreen(
                      tripId: trip.id,
                      driverId: driverId,
                      repository: repository,
                      locationService: DriverLocationService(
                        firestore: FirebaseFirestore.instance,
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Lihat peta perjalanan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
