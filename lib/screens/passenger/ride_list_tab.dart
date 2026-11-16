import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/ride_request.dart';
import '../../models/trip.dart';
import '../../services/ride_repository.dart';
import '../../utils/format.dart';
import '../../services/trip_repository.dart';
import '../../services/driver_location_service.dart';
import 'trip_tracking_screen.dart';

class RideListTab extends StatelessWidget {
  final String? passengerId;
  final TripRepository? tripRepository;

  const RideListTab({super.key, this.passengerId, this.tripRepository});

  @override
  Widget build(BuildContext context) {
    final repo = RideRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final localItems = repo.items;
        if (passengerId == null || tripRepository?.isConfigured != true) {
          return _list(context, localItems);
        }
        return StreamBuilder<List<Trip>>(
          stream: tripRepository!.passengerTrips(passengerId!),
          builder: (context, snapshot) {
            final byId = {for (final item in localItems) item.id: item};
            for (final trip in snapshot.data ?? const <Trip>[]) {
              byId[trip.id] = RideRequest(
                id: trip.id,
                pickup: trip.pickup.label,
                destination: trip.destination.label,
                scheduledAt:
                    trip.scheduledAt ?? trip.createdAt ?? DateTime.now(),
                passengerCount: trip.passengerCount,
                pickupLocation: trip.pickup,
                destinationLocation: trip.destination,
                status: switch (trip.status) {
                  TripStatus.requested => RideStatus.pending,
                  TripStatus.accepted ||
                  TripStatus.arrived ||
                  TripStatus.inProgress => RideStatus.accepted,
                  TripStatus.completed => RideStatus.completed,
                  TripStatus.cancelled => RideStatus.cancelled,
                },
              );
            }
            if (snapshot.hasError && byId.isEmpty) {
              return const Center(
                child: Text('Riwayat gagal dimuat. Periksa koneksi.'),
              );
            }
            return _list(context, byId.values.toList());
          },
        );
      },
    );
  }

  Widget _list(BuildContext context, List<RideRequest> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('Belum ada pesanan'),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _RideCard(
        request: items[i],
        passengerId: passengerId,
        tripRepository: tripRepository,
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideRequest request;
  final String? passengerId;
  final TripRepository? tripRepository;
  const _RideCard({
    required this.request,
    this.passengerId,
    this.tripRepository,
  });

  Color get _statusColor => switch (request.status) {
    RideStatus.pending => Colors.orange,
    RideStatus.accepted => Colors.blue,
    RideStatus.rejected => Colors.red,
    RideStatus.completed => Colors.green,
    RideStatus.cancelled => Colors.grey,
  };

  Future<void> _cancel(BuildContext context) async {
    try {
      if (tripRepository?.isConfigured == true &&
          passengerId != null &&
          request.pickupLocation != null &&
          request.destinationLocation != null) {
        await tripRepository!.updateTripStatus(
          request.id,
          TripStatus.cancelled,
        );
      }
      RideRepository.instance.updateStatus(request.id, RideStatus.cancelled);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan belum dapat dibatalkan. Coba lagi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDateTime(request.scheduledAt),
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
                  request.status.label,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(request.pickup)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.flag, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(child: Text(request.destination)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${request.passengerCount} penumpang',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          if (request.status == RideStatus.pending) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancel(context),
                child: const Text('Batalkan'),
              ),
            ),
          ],
          if (passengerId != null &&
              tripRepository?.isConfigured == true &&
              request.pickupLocation != null &&
              request.destinationLocation != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TripTrackingScreen(
                      tripId: request.id,
                      passengerId: passengerId!,
                      repository: tripRepository!,
                      locationService: DriverLocationService(
                        firestore: FirebaseFirestore.instance,
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Lacak perjalanan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
