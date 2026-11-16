import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/driver_location.dart';
import '../../models/trip.dart';
import '../../services/driver_location_service.dart';
import '../../services/trip_repository.dart';
import '../../widgets/trip_status_timeline.dart';

class TripTrackingScreen extends StatefulWidget {
  final String tripId;
  final String passengerId;
  final TripRepository repository;
  final DriverLocationService locationService;

  const TripTrackingScreen({
    super.key,
    required this.tripId,
    required this.passengerId,
    required this.repository,
    required this.locationService,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _followedCenter;
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _followDriver(DriverLocation? location) {
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
      if (trip == null || trip.passengerId != widget.passengerId) {
        return const Scaffold(
          body: Center(
            child: Text('Perjalanan tidak tersedia untuk akun ini.'),
          ),
        );
      }
      if (trip.driverId == null) {
        return _body(context, trip, null, 'Menunggu driver menerima pesanan.');
      }
      if (trip.status == TripStatus.completed ||
          trip.status == TripStatus.cancelled) {
        return _body(context, trip, null, 'Perjalanan sudah berakhir.');
      }
      return StreamBuilder<DriverLocation?>(
        stream: widget.locationService.watchDriverLocation(
          driverId: trip.driverId!,
          tripId: trip.id,
        ),
        builder: (context, locationSnapshot) {
          if (locationSnapshot.hasError) {
            return _body(context, trip, null, 'Koneksi lokasi terputus.');
          }
          final location = locationSnapshot.data;
          _followDriver(location);
          final message =
              locationSnapshot.connectionState == ConnectionState.waiting
              ? 'Menghubungkan ke lokasi driver...'
              : location == null
              ? 'Driver belum membagikan lokasi.'
              : DateTime.now().difference(location.updatedAt) >
                    const Duration(seconds: 30)
              ? 'Lokasi terakhir lebih dari 30 detik lalu.'
              : 'Lokasi driver diperbarui.';
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
    final progressColor = Theme.of(context).colorScheme.secondary;
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
            'Pesanan #${_shortOrderId(trip.id)}',
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
            onPressed: _mapReady ? () => _centerMap(trip, location) : null,
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
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [pickup, destination],
                        color: progressColor,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pickup,
                        child: Icon(
                          Icons.location_on,
                          color: primary,
                          size: 36,
                        ),
                      ),
                      Marker(
                        point: destination,
                        child: const Icon(
                          Icons.flag,
                          color: Color(0xFFB04A3A),
                          size: 30,
                        ),
                      ),
                      if (location != null)
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.two_wheeler,
                              color: Colors.white,
                              size: 24,
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
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: sheetWidth,
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.46,
                      minChildSize: 0.36,
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
                            if (locationIsFresh) ...[
                              const _LiveLocationTag(),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              _statusTitle(trip.status),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(message, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 18),
                            TripStatusTimeline(status: trip.status),
                            if (trip.driverId != null) ...[
                              const SizedBox(height: 18),
                              _DriverCard(
                                name: trip.driverName?.isNotEmpty == true
                                    ? trip.driverName!
                                    : 'Driver terhubung',
                                detail: location == null
                                    ? 'Menunggu pembaruan lokasi'
                                    : 'Pembaruan ${TimeOfDay.fromDateTime(location.updatedAt).format(context)}',
                                primary: primary,
                              ),
                            ],
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
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

  String _shortOrderId(String id) =>
      id.substring(0, id.length < 6 ? id.length : 6).toUpperCase();

  String _statusTitle(TripStatus status) => switch (status) {
    TripStatus.requested => 'Mencari driver',
    TripStatus.accepted => 'Driver menuju Anda',
    TripStatus.arrived => 'Driver sudah tiba',
    TripStatus.inProgress => 'Dalam perjalanan',
    TripStatus.completed => 'Perjalanan selesai',
    TripStatus.cancelled => 'Perjalanan dibatalkan',
  };
}

class _LiveLocationTag extends StatelessWidget {
  const _LiveLocationTag();

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
              'LOKASI LIVE',
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

class _DriverCard extends StatelessWidget {
  final String name;
  final String detail;
  final Color primary;

  const _DriverCard({
    required this.name,
    required this.detail,
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
          child: Icon(Icons.person_outline, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.two_wheeler, color: primary),
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
