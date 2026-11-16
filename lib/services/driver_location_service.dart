import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/driver_location.dart';

class DriverLocationService {
  final FirebaseFirestore? _firestore;
  StreamSubscription<Position>? _subscription;
  DateTime? _lastSentAt;
  Position? _lastSentPosition;
  String? _activeTripId;
  String? _activeDriverId;

  DriverLocationService({this._firestore});

  Future<LocationPermission> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<void> startPublishing({
    required String driverId,
    required String tripId,
  }) async {
    if (_firestore == null) throw StateError('Firebase belum disiapkan.');
    final permission = await requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('Izin lokasi belum diberikan.');
    }
    await stopPublishing();
    _activeTripId = tripId;
    _activeDriverId = driverId;
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          ),
        ).listen(
          (position) async {
            final now = DateTime.now();
            final previous = _lastSentPosition;
            final movedMeters = previous == null
                ? double.infinity
                : Geolocator.distanceBetween(
                    previous.latitude,
                    previous.longitude,
                    position.latitude,
                    position.longitude,
                  );
            if (_lastSentAt != null &&
                now.difference(_lastSentAt!) < const Duration(seconds: 5) &&
                movedMeters < 20) {
              return;
            }
            try {
              await _firestore
                  .collection('drivers')
                  .doc(driverId)
                  .collection('locations')
                  .doc('current')
                  .set({
                    'tripId': tripId,
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                    'accuracy': position.accuracy,
                    'heading': position.heading,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              _lastSentAt = now;
              _lastSentPosition = position;
            } catch (error) {
              debugPrint('Driver location update failed: $error');
            }
          },
          onError: (Object error) {
            debugPrint('Driver GPS stream failed: $error');
          },
        );
  }

  Future<void> stopPublishing({bool deleteLastLocation = false}) async {
    await _subscription?.cancel();
    _subscription = null;
    if (deleteLastLocation && _firestore != null && _activeDriverId != null) {
      await _firestore
          .collection('drivers')
          .doc(_activeDriverId)
          .collection('locations')
          .doc('current')
          .delete();
    }
    _activeTripId = null;
    _activeDriverId = null;
    _lastSentAt = null;
    _lastSentPosition = null;
  }

  Stream<DriverLocation?> watchDriverLocation({
    required String driverId,
    required String tripId,
  }) {
    if (_firestore == null) return const Stream.empty();
    return _firestore
        .collection('drivers')
        .doc(driverId)
        .collection('locations')
        .doc('current')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || data['tripId'] != tripId) return null;
          final updatedAt = data['updatedAt'];
          if (updatedAt is! Timestamp) return null;
          return DriverLocation(
            driverId: driverId,
            tripId: tripId,
            latitude: (data['latitude'] as num).toDouble(),
            longitude: (data['longitude'] as num).toDouble(),
            accuracy: (data['accuracy'] as num?)?.toDouble(),
            heading: (data['heading'] as num?)?.toDouble(),
            updatedAt: updatedAt.toDate(),
          );
        });
  }

  @visibleForTesting
  String? get activeTripId => _activeTripId;
}
