import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/app_user.dart';
import '../../models/trip.dart';
import '../../services/driver_location_service.dart';
import '../../services/trip_repository.dart';

class ActiveTripScreen extends StatefulWidget {
  final String tripId;
  final AppUser driver;
  final TripRepository repository;
  final DriverLocationService? locationService;

  const ActiveTripScreen({
    super.key,
    required this.tripId,
    required this.driver,
    required this.repository,
    this.locationService,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late final DriverLocationService _locationService =
      widget.locationService ?? DriverLocationService();
  String? _message;
  TripStatus? _lastPublishedStatus;
  bool _startingLocation = false;
  bool _locationAttempted = false;

  Future<void> _ensurePublishing() async {
    if (_startingLocation ||
        _lastPublishedStatus != null ||
        _locationAttempted) {
      return;
    }
    _locationAttempted = true;
    _startingLocation = true;
    try {
      await _locationService.startPublishing(
        driverId: widget.driver.uid,
        tripId: widget.tripId,
      );
      _lastPublishedStatus = TripStatus.accepted;
      if (mounted) setState(() => _message = 'Lokasi driver sedang dibagikan.');
    } on PermissionDeniedException {
      if (mounted) {
        setState(
          () => _message = 'Izin lokasi ditolak. Aktifkan izin lokasi untuk membagikan posisi.',
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(() => _message = 'Aktifkan GPS untuk membagikan posisi.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Lokasi belum dapat dibagikan. Periksa koneksi dan konfigurasi.',
        );
      }
    } finally {
      _startingLocation = false;
    }
  }

  Future<void> _setStatus(TripStatus status) async {
    try {
      await widget.repository.updateTripStatus(widget.tripId, status);
      if (status == TripStatus.accepted ||
          status == TripStatus.arrived ||
          status == TripStatus.inProgress) {
        _lastPublishedStatus = status;
      } else {
        await _locationService.stopPublishing(deleteLastLocation: true);
        _lastPublishedStatus = null;
      }
      if (mounted) setState(() => _message = 'Status perjalanan diperbarui.');
    } on PermissionDeniedException {
      if (mounted) {
        setState(
          () => _message = 'Izin lokasi ditolak. Aktifkan izin lokasi untuk membagikan posisi.',
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(() => _message = 'Aktifkan GPS untuk membagikan posisi.');
      }
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  @override
  void dispose() {
    _locationService.stopPublishing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Trip?>(
    stream: widget.repository.watchTrip(widget.tripId),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Scaffold(
          body: Center(child: Text('Perjalanan gagal dimuat.')),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final trip = snapshot.data;
      if (trip == null) {
        return const Scaffold(
          body: Center(child: Text('Perjalanan tidak ditemukan.')),
        );
      }
      if ((trip.status == TripStatus.accepted ||
              trip.status == TripStatus.arrived ||
              trip.status == TripStatus.inProgress) &&
          _lastPublishedStatus == null &&
          !_locationAttempted) {
        _ensurePublishing();
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Perjalanan aktif')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jemput: ${trip.pickup.label}'),
                    const SizedBox(height: 10),
                    Text('Tujuan: ${trip.destination.label}'),
                    const SizedBox(height: 12),
                    Text('Status: ${trip.status.name}'),
                  ],
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
            const SizedBox(height: 12),
            if (trip.status == TripStatus.accepted)
              FilledButton(
                onPressed: () => _setStatus(TripStatus.arrived),
                child: const Text('Saya tiba di titik jemput'),
              ),
            if (trip.status == TripStatus.arrived)
              FilledButton(
                onPressed: () => _setStatus(TripStatus.inProgress),
                child: const Text('Mulai perjalanan'),
              ),
            if (trip.status == TripStatus.inProgress)
              FilledButton(
                onPressed: () => _setStatus(TripStatus.completed),
                child: const Text('Selesaikan perjalanan'),
              ),
            if (_locationAttempted && _lastPublishedStatus == null)
              OutlinedButton.icon(
                onPressed: () {
                  _locationAttempted = false;
                  _ensurePublishing();
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Coba bagikan lokasi lagi'),
              ),
            if (trip.status == TripStatus.accepted ||
                trip.status == TripStatus.arrived ||
                trip.status == TripStatus.inProgress)
              TextButton(
                onPressed: () => _setStatus(TripStatus.cancelled),
                child: const Text('Batalkan perjalanan'),
              ),
          ],
        ),
      );
    },
  );
}
