import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/driver_location.dart';
import '../../models/trip.dart';
import '../../services/driver_location_service.dart';
import '../../services/trip_repository.dart';
import '../../widgets/trip_status_timeline.dart';

/// Live tracking map untuk driver — menampilkan posisi driver sendiri
/// di peta bersama titik jemput dan tujuan penumpang.
class DriverTripMapScreen extends StatefulWidget {
  final String tripId;
  final String driverId;
  final TripRepository repository;
  final DriverLocationService locationService;

  const DriverTripMapScreen({
    super.key,
    required this.tripId,
    required this.driverId,
    required this.repository,
    required this.locationService,
  });

  @override
  State<DriverTripMapScreen> createState() => _DriverTripMapScreenState();
}

class _DriverTripMapScreenState extends State<DriverTripMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _followedCenter;
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _followSelf(DriverLocation? location) {
    if (location == null) return;
    final center = LatLng(location.latitude, location.longitude);
    if (_followedCenter == center) return;
    _followedCenter = center;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _mapController.move(center, _mapController.camera.zoom);
    });
  }

  void _onMapReady() {
    _mapReady = true;
    final center = _followedCenter;
    if (center != null) {
      _mapController.move(center, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Trip?>(
    stream: widget.repository.watchTrip(widget.tripId),
    builder: (context, tripSnapshot) {
      if (tripSnapshot.hasError) {
        return const Scaffold(
          body: Center(
            child: Text('Perjalanan gagal dimuat. Periksa koneksi.'),
          ),
        );
      }
      if (!tripSnapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final trip = tripSnapshot.data;
      if (trip == null) {
        return const Scaffold(
          body: Center(child: Text('Perjalanan tidak ditemukan.')),
        );
      }

      // Jika perjalanan sudah selesai atau dibatalkan, tampilkan tanpa tracking
      if (trip.status == TripStatus.completed ||
          trip.status == TripStatus.cancelled) {
        return _body(context, trip, null, 'Perjalanan sudah berakhir.');
      }

      // Stream lokasi driver sendiri
      return StreamBuilder<DriverLocation?>(
        stream: widget.locationService.watchDriverLocation(
          driverId: widget.driverId,
          tripId: widget.tripId,
        ),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.hasError) {
            return _body(context, trip, null, 'Koneksi lokasi terputus.');
          }
          final location = locationSnapshot.data;
          _followSelf(location);
          final message =
              locationSnapshot.connectionState == ConnectionState.waiting
              ? 'Menghubungkan ke GPS...'
              : location == null
              ? 'Lokasi belum tersedia. Pastikan GPS aktif.'
              : DateTime.now().difference(location.updatedAt) >
                    const Duration(seconds: 30)
              ? 'GPS tidak diperbarui lebih dari 30 detik.'
              : 'GPS aktif — posisi Anda ditampilkan.';
          return _body(context, trip, location, message);
        },
      );
    },
  );

  Widget _body(
    BuildContext context,
    Trip trip,
    DriverLocation? location,
    String message,
  ) {
    final pickup = LatLng(trip.pickup.latitude, trip.pickup.longitude);
    final destination = LatLng(
      trip.destination.latitude,
      trip.destination.longitude,
    );
    final locationIsFresh =
        location != null &&
        DateTime.now().difference(location.updatedAt) <=
            const Duration(seconds: 30);
    final center = location == null
        ? LatLng(
            (pickup.latitude + destination.latitude) / 2,
            (pickup.longitude + destination.longitude) / 2,
          )
        : LatLng(location.latitude, location.longitude);

    final primary = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Perjalanan #${_shortId(trip.id)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Pusatkan peta',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primary,
            ),
            onPressed: _mapReady
                ? () => _centerMap(trip, location)
                : null,
            icon: const Icon(Icons.my_location),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sheetWidth = constraints.maxWidth > 560
              ? 560.0
              : constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Peta ──────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 14,
                  onMapReady: _onMapReady,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.example.aplikasi_antarjemput_mahasiswa',
                  ),
                  // Garis rute jemput → tujuan
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [pickup, destination],
                        color: secondaryColor,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Titik jemput
                      Marker(
                        point: pickup,
                        child: Icon(
                          Icons.location_on,
                          color: primary,
                          size: 36,
                        ),
                      ),
                      // Tujuan
                      Marker(
                        point: destination,
                        child: const Icon(
                          Icons.flag,
                          color: Color(0xFFB04A3A),
                          size: 30,
                        ),
                      ),
                      // Posisi driver (diri sendiri) — ikon berbeda agar mudah dibedakan
                      if (location != null)
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),

              // ── Info sheet bawah ──────────────────────────────────
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: sheetWidth,
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.44,
                      minChildSize: 0.34,
                      maxChildSize: 0.86,
                      expand: false,
                      builder: (context, scrollController) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6EE),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            MediaQuery.paddingOf(context).bottom + 24,
                          ),
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4D9CE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // GPS live badge
                            if (locationIsFresh) ...[
                              const _GpsLiveTag(),
                              const SizedBox(height: 12),
                            ],

                            // Judul status
                            Text(
                              _statusTitle(trip.status),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 18),

                            // Timeline status perjalanan
                            TripStatusTimeline(status: trip.status),
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 14),

                            // Info penumpang
                            _PassengerInfoCard(
                              passengerCount: trip.passengerCount,
                              primary: primary,
                            ),
                            const SizedBox(height: 14),

                            // Rute
                            _RoutePoint(
                              icon: Icons.radio_button_checked,
                              color: primary,
                              title: 'Titik jemput',
                              label: trip.pickup.label,
                            ),
                            const SizedBox(height: 12),
                            _RoutePoint(
                              icon: Icons.flag_outlined,
                              color: const Color(0xFFB04A3A),
                              title: 'Tujuan',
                              label: trip.destination.label,
                            ),

                            // Koordinat posisi driver saat ini
                            if (location != null) ...[
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Text(
                                'Koordinat GPS Anda',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${location.latitude.toStringAsFixed(6)}, '
                                '${location.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (location.accuracy != null)
                                Text(
                                  'Akurasi: ±${location.accuracy!.toStringAsFixed(0)} m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _centerMap(Trip trip, DriverLocation? location) {
    final center = location == null
        ? LatLng(
            (trip.pickup.latitude + trip.destination.latitude) / 2,
            (trip.pickup.longitude + trip.destination.longitude) / 2,
          )
        : LatLng(location.latitude, location.longitude);
    _mapController.move(center, location == null ? 14 : 15);
  }

  String _shortId(String id) =>
      id.substring(0, id.length < 6 ? id.length : 6).toUpperCase();

  String _statusTitle(TripStatus status) => switch (status) {
    TripStatus.requested => 'Menunggu konfirmasi',
    TripStatus.accepted => 'Menuju titik jemput',
    TripStatus.arrived => 'Tiba di titik jemput',
    TripStatus.inProgress => 'Dalam perjalanan',
    TripStatus.completed => 'Perjalanan selesai',
    TripStatus.cancelled => 'Perjalanan dibatalkan',
  };
}

// ── Widget pembantu ────────────────────────────────────────────────────────────

class _GpsLiveTag extends StatelessWidget {
  const _GpsLiveTag();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF5F8A2E)),
            SizedBox(width: 6),
            Text(
              'GPS AKTIF',
              style: TextStyle(
                color: Color(0xFF3E6120),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PassengerInfoCard extends StatelessWidget {
  final int passengerCount;
  final Color primary;

  const _PassengerInfoCard({
    required this.passengerCount,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: primary.withValues(alpha: 0.1),
          child: Icon(Icons.people_outline, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Penumpang',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('$passengerCount orang'),
            ],
          ),
        ),
        Icon(Icons.person, color: primary),
      ],
    ),
  );
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String label;

  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.title,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF526052)),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
}
