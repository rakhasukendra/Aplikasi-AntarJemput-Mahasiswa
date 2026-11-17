import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/app_user.dart';
import 'package:aplikasi_antarjemput_mahasiswa/models/trip.dart';
import 'package:aplikasi_antarjemput_mahasiswa/screens/driver/available_trips_screen.dart';
import 'package:aplikasi_antarjemput_mahasiswa/widgets/trip_status_timeline.dart';

void main() {
  testWidgets('driver sees setup state when Firebase is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvailableTripsScreen(
            user: AppUser(
              uid: 'driver-1',
              role: UserRole.driver,
              displayName: '',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Firebase belum disiapkan'), findsOneWidget);
    expect(find.text('Live'), findsNothing);
  });

  testWidgets('timeline shows completed trip as terminal state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TripStatusTimeline(status: TripStatus.completed)),
      ),
    );

    expect(find.text('Selesai'), findsOneWidget);
  });
}
