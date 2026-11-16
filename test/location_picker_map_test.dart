import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/ride_location.dart';
import 'package:aplikasi_antarjemput_mahasiswa/widgets/location_picker_map.dart';

void main() {
  testWidgets('picker mengembalikan lokasi setelah konfirmasi', (tester) async {
    RideLocation? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPickerMap(
            title: 'Titik jemput',
            initialLocation: const RideLocation(
              latitude: -7.56,
              longitude: 110.85,
              label: 'UNS',
            ),
            onLocationSelected: (location) => selected = location,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Gunakan titik ini'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.latitude, closeTo(-7.56, 0.01));
    expect(selected!.longitude, closeTo(110.85, 0.01));
  });
}
