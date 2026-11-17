import 'package:cloud_firestore/cloud_firestore.dart';

import 'ride_location.dart';

enum TripStatus {
  requested,
  accepted,
  arrived,
  inProgress,
  completed,
  cancelled,
}

class Trip {
  final String id;
  final String passengerId;
  final String? driverId;
  final String? driverName;
  final RideLocation pickup;
  final RideLocation destination;
  final int passengerCount;
  final TripStatus status;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Trip({
    required this.id,
    required this.passengerId,
    required this.driverId,
    this.driverName,
    required this.pickup,
    required this.destination,
    required this.passengerCount,
    required this.status,
    this.scheduledAt,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() => {
    'passengerId': passengerId,
    'driverId': driverId,
    'driverName': driverName,
    'pickup': pickup.toMap(),
    'destination': destination.toMap(),
    'passengerCount': passengerCount,
    'status': status.name,
    'scheduledAt': scheduledAt,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    DateTime? readDate(Object? value) {
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return Trip(
      id: id,
      passengerId: map['passengerId'] as String,
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String?,
      pickup: RideLocation.fromMap(
        Map<String, dynamic>.from(map['pickup'] as Map),
      ),
      destination: RideLocation.fromMap(
        Map<String, dynamic>.from(map['destination'] as Map),
      ),
      passengerCount: map['passengerCount'] as int,
      status: TripStatus.values.byName(map['status'] as String),
      scheduledAt: readDate(map['scheduledAt']),
      createdAt: readDate(map['createdAt']),
      updatedAt: readDate(map['updatedAt']),
    );
  }
}

class TripDraft {
  final String passengerId;
  final RideLocation pickup;
  final RideLocation destination;
  final int passengerCount;
  final DateTime scheduledAt;

  const TripDraft({
    required this.passengerId,
    required this.pickup,
    required this.destination,
    required this.passengerCount,
    required this.scheduledAt,
  });
}
