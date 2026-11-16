import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/ride_request.dart';

class LocalRideTrackingScreen extends StatelessWidget {
  final RideRequest request;
  final String message;

  const LocalRideTrackingScreen({
    super.key,
    required this.request,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = request.pickupLocation;
    final destination = request.destinationLocation;
    final center = pickup != null && destination != null
        ? LatLng(
            (pickup.latitude + destination.latitude) / 2,
            (pickup.longitude + destination.longitude) / 2,
          )
        : pickup != null
        ? LatLng(pickup.latitude, pickup.longitude)
        : destination != null
        ? LatLng(destination.latitude, destination.longitude)
        : const LatLng(-7.558, 110.856);

    return Scaffold(
      appBar: AppBar(title: const Text('Peta perjalanan')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.aplikasi_antarjemput_mahasiswa',
              ),
              if (pickup != null || destination != null)
                MarkerLayer(
                  markers: [
                    if (pickup != null)
                      Marker(
                        point: LatLng(pickup.latitude, pickup.longitude),
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 36,
                        ),
                      ),
                    if (destination != null)
                      Marker(
                        point: LatLng(
                          destination.latitude,
                          destination.longitude,
                        ),
                        child: Icon(
                          Icons.flag,
                          color: Color(0xFFB04A3A),
                          size: 30,
                        ),
                      ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 560),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rute perjalanan',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(message),
                  const SizedBox(height: 16),
                  _RouteLine(label: request.pickup, isPickup: true),
                  const SizedBox(height: 12),
                  _RouteLine(label: request.destination, isPickup: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String label;
  final bool isPickup;

  const _RouteLine({required this.label, required this.isPickup});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        isPickup ? Icons.radio_button_checked : Icons.flag_outlined,
        size: 20,
        color: isPickup
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFFB04A3A),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          '${isPickup ? 'Titik jemput' : 'Tujuan'}: $label',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
