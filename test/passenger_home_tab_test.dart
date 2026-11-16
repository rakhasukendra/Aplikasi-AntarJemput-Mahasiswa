import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:aplikasi_antarjemput_mahasiswa/screens/passenger/passenger_home_tab.dart';
import 'package:aplikasi_antarjemput_mahasiswa/services/ride_repository.dart';

void main() {
  testWidgets('beranda menampilkan peta OpenStreetMap', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.textContaining('Ketuk peta'), findsOneWidget);
  });

  testWidgets('lokasi kosong tidak bisa lanjut ke tahap jadwal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );

    await tester.ensureVisible(find.text('Lanjut'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Waktu Jemput'), findsNothing);
    expect(find.text('Titik jemput wajib diisi'), findsOneWidget);
    expect(find.text('Tujuan wajib diisi'), findsOneWidget);
  });

  testWidgets('tujuan sama dengan titik jemput menolak lanjut', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Perpustakaan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Perpustakaan');
    await tester.ensureVisible(find.text('Lanjut'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Waktu Jemput'), findsNothing);
    expect(
      find.text('Tujuan tidak boleh sama dengan titik jemput'),
      findsOneWidget,
    );
  });

  testWidgets('lokasi panjang tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Gedung Kuliah Bersama Universitas',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Area Kos Putri Sekarwangi yang jauh',
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('beranda tidak menampilkan klaim dan estimasi simulasi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );

    expect(find.text('18 Pengemudi Aktif'), findsNothing);
    expect(find.text('Jarak Perjalanan'), findsNothing);
    expect(find.text('Estimasi Tarif'), findsNothing);
    expect(find.text('Hemat s.d 50%'), findsNothing);
    expect(find.text('Live Telemetry'), findsNothing);
    expect(find.text('Rute Kampus Terverifikasi'), findsNothing);
  });

  testWidgets('pilih lokasi lewat peta membuka peta OpenStreetMap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );

    // Peta header sudah ada 1 FlutterMap
    expect(find.byType(FlutterMap), findsOneWidget);

    await tester.ensureVisible(find.text('Pilih titik jemput lewat peta'));
    await tester.tap(find.text('Pilih titik jemput lewat peta'));
    await tester.pumpAndSettle();

    // Header + picker = 2 FlutterMap
    expect(find.byType(FlutterMap), findsNWidgets(2));
    expect(find.textContaining('Geser peta'), findsOneWidget);
    expect(find.text('Gunakan titik ini'), findsOneWidget);
  });

  testWidgets('lokasi terpilih disimpan bersama pesanan', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final initialRideCount = RideRepository.instance.items.length;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );
    await tester.ensureVisible(find.text('Pilih titik jemput lewat peta'));
    await tester.tap(find.text('Pilih titik jemput lewat peta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gunakan titik ini'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Stasiun Kampus');
    await tester.ensureVisible(find.text('Lanjut'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pesan jemput'));
    await tester.tap(find.text('Pesan jemput'));
    await tester.pumpAndSettle();

    final saved = RideRepository.instance.items[initialRideCount];
    expect(saved.pickupLocation, isNotNull);
    expect(saved.pickupLocation!.latitude, closeTo(-7.558, 0.001));
    expect(saved.destinationLocation, isNull);
  });

  testWidgets('kembali dari jadwal mempertahankan lokasi', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassengerHomeTab(onOrderCreated: (_) {})),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Perpustakaan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Stasiun Kampus');
    await tester.ensureVisible(find.text('Lanjut'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Atur jadwal'), findsOneWidget);

    await tester.ensureVisible(find.text('Kembali'));
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!
          .text,
      'Perpustakaan',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      'Stasiun Kampus',
    );
  });

  testWidgets('pesanan tersimpan setelah melewati dua tahap', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final initialRideCount = RideRepository.instance.items.length;
    var created = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PassengerHomeTab(onOrderCreated: (_) => created = true),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Perpustakaan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Stasiun Kampus');
    await tester.ensureVisible(find.text('Lanjut'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Pesan jemput'));
    await tester.tap(find.text('Pesan jemput'));
    await tester.pumpAndSettle();

    expect(created, isTrue);
    expect(RideRepository.instance.items, hasLength(initialRideCount + 1));
  });
}
