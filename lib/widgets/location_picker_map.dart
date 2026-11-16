import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/ride_location.dart';

class LocationPickerMap extends StatefulWidget {
  final String title;
  final RideLocation? initialLocation;
  final ValueChanged<RideLocation> onLocationSelected;
  final VoidCallback? onCancel;

  const LocationPickerMap({
    super.key,
    required this.title,
    required this.initialLocation,
    required this.onLocationSelected,
    this.onCancel,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  static const _campusCenter = LatLng(-7.558, 110.856);
  late LatLng _center = widget.initialLocation == null
      ? _campusCenter
      : LatLng(
          widget.initialLocation!.latitude,
          widget.initialLocation!.longitude,
        );
  final _mapController = MapController();

  void _select(LatLng point) {
    setState(() => _center = point);
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            if (widget.onCancel != null)
              IconButton(
                tooltip: 'Kembali',
                onPressed: widget.onCancel,
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('Geser peta agar pin berada tepat di lokasi pilihan.'),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 15,
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) setState(() => _center = camera.center);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.example.aplikasi_antarjemput_mahasiswa',
                    maxZoom: 19,
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
              IgnorePointer(
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: colors.primary,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'center-map',
                  tooltip: 'Pusatkan peta ke Kampus UNS',
                  onPressed: () => _select(_campusCenter),
                  child: const Icon(Icons.school_outlined),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => widget.onLocationSelected(
                  RideLocation(
                    latitude: _center.latitude,
                    longitude: _center.longitude,
                    label:
                        'Titik peta (${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)})',
                  ),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Gunakan titik ini'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
