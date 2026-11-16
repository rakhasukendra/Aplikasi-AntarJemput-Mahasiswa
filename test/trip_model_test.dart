import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/ride_location.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/trip.dart';
import 'package:aplikasi_antarjemput_mahasiswa/services/trip_repository.dart';

void main() {
  test('trip serializes coordinates and status', () {
    const trip = Trip(
      id: 'trip-1',
      passengerId: 'passenger-1',
      driverId: 'driver-1',
      driverName: 'Budi',
      pickup: RideLocation(latitude: -7.5, longitude: 110.8, label: 'Kampus'),
      destination: RideLocation(
        latitude: -7.6,
        longitude: 110.9,
        label: 'Stasiun',
      ),
      passengerCount: 2,
      status: TripStatus.accepted,
    );

    final decoded = Trip.fromMap(trip.id, trip.toMap());
    expect(decoded.pickup.latitude, -7.5);
    expect(decoded.destination.longitude, 110.9);
    expect(decoded.status, TripStatus.accepted);
    expect(decoded.driverName, 'Budi');
  });

  test('unconfigured repository rejects live trip creation', () async {
    final draft = TripDraft(
      passengerId: 'passenger-1',
      pickup: RideLocation(latitude: -7.5, longitude: 110.8, label: 'Kampus'),
      destination: RideLocation(
        latitude: -7.6,
        longitude: 110.9,
        label: 'Stasiun',
      ),
      passengerCount: 1,
      scheduledAt: DateTime.utc(2030),
    );
    expect(TripRepository.unconfigured().createTrip(draft), throwsStateError);
  });
}
