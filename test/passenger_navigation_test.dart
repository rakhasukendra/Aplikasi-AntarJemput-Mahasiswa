import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_antarjemput_mahasiswa/screens/passenger/passenger_shell.dart';
import 'package:aplikasi_antarjemput_mahasiswa/screens/passenger/local_ride_tracking_screen.dart';
import 'package:aplikasi_antarjemput_mahasiswa/services/ride_repository.dart';

void main() {
  testWidgets('navigasi hanya memuat Beranda dan Riwayat', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PassengerShell()));

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Profil'), findsNothing);

    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pesanan'), findsOneWidget);
  });

  testWidgets('pesanan berhasil langsung membuka peta perjalanan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PassengerShell()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Perpustakaan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Stasiun Kampus');
    await tester.ensureVisible(find.text('Lanjut'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pesan jemput'));
    await tester.tap(find.text('Pesan jemput'));
    await tester.pumpAndSettle();

    expect(RideRepository.instance.items, isNotEmpty);
    expect(find.byType(LocalRideTrackingScreen), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Peta perjalanan'), findsOneWidget);
    expect(find.textContaining('lokasi driver belum tersedia'), findsOneWidget);
  });
}
