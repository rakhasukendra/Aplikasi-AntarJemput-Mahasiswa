class DriverLocation {
  final String driverId;
  final String tripId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final DateTime updatedAt;

  const DriverLocation({
    required this.driverId,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    required this.updatedAt,
  });
}
