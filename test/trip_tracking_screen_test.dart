import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/driver_location.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/ride_location.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/trip.dart';
import 'package:aplikasi_antarjemput_mahasiswa/screens/passenger/trip_tracking_screen.dart';
import 'package:aplikasi_antarjemput_mahasiswa/services/driver_location_service.dart';
import 'package:aplikasi_antarjemput_mahasiswa/services/trip_repository.dart';

void main() {
  testWidgets('tracking keeps the map behind a draggable trip panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trip = Trip(
      id: 'trip-1',
      passengerId: 'passenger-1',
      driverId: null,
      pickup: const RideLocation(
        latitude: -7.558,
        longitude: 110.856,
        label: 'Gerbang kampus',
      ),
      destination: const RideLocation(
        latitude: -7.56,
        longitude: 110.86,
        label: 'Perpustakaan',
      ),
      passengerCount: 1,
      status: TripStatus.requested,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-tracking'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TripTrackingScreen(
                      tripId: trip.id,
                      passengerId: trip.passengerId,
                      repository: _FakeTripRepository(trip),
                      locationService: DriverLocationService(),
                    ),
                  ),
                ),
                child: const Text('Buka tracking'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-tracking')));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Mencari driver'), findsOneWidget);
    expect(find.text('Pesanan #TRIP-1'), findsOneWidget);
    expect(find.byTooltip('Pusatkan peta'), findsOneWidget);
    expect(find.text('Menunggu driver menerima pesanan.'), findsOneWidget);
    await tester.tap(find.byTooltip('Pusatkan peta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Gerbang kampus'), findsOneWidget);
    expect(find.text('Perpustakaan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Buka tracking'), findsOneWidget);
  });

  testWidgets('live driver updates move the map and show the driver marker', (
    tester,
  ) async {
    final locations = StreamController<DriverLocation?>();
    addTearDown(locations.close);
    final trip = Trip(
      id: 'trip-live',
      passengerId: 'passenger-1',
      driverId: 'driver-1',
      driverName: 'Budi',
      pickup: const RideLocation(
        latitude: -7.558,
        longitude: 110.856,
        label: 'Gerbang kampus',
      ),
      destination: const RideLocation(
        latitude: -7.56,
        longitude: 110.86,
        label: 'Perpustakaan',
      ),
      passengerCount: 1,
      status: TripStatus.accepted,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TripTrackingScreen(
          tripId: trip.id,
          passengerId: trip.passengerId,
          repository: _FakeTripRepository(trip),
          locationService: _FakeLocationService(locations.stream),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Menghubungkan ke lokasi driver...'), findsOneWidget);

    locations.add(
      DriverLocation(
        driverId: 'driver-1',
        tripId: trip.id,
        latitude: -7.557,
        longitude: 110.858,
        updatedAt: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Budi'));
    expect(find.text('Lokasi driver diperbarui.'), findsOneWidget);
    expect(find.text('LOKASI LIVE'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markers.markers, hasLength(3));
    expect(markers.markers.last.point.latitude, closeTo(-7.557, 0.0001));
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center.latitude, closeTo(-7.557, 0.0001));
    expect(
      map.mapController!.camera.center.longitude,
      closeTo(110.858, 0.0001),
    );
  });
}

class _FakeTripRepository extends TripRepository {
  final Trip trip;

  _FakeTripRepository(this.trip) : super.unconfigured();

  @override
  Stream<Trip?> watchTrip(String tripId) => Stream.value(trip);
}

class _FakeLocationService extends DriverLocationService {
  final Stream<DriverLocation?> locations;

  _FakeLocationService(this.locations);

  @override
  Stream<DriverLocation?> watchDriverLocation({
    required String driverId,
    required String tripId,
  }) => locations;
}
