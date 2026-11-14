enum RideStatus {
  pending('Menunggu'),
  accepted('Diterima'),
  rejected('Ditolak'),
  completed('Selesai'),
  cancelled('Dibatalkan');

  final String label;
  const RideStatus(this.label);
}

class RideRequest {
  final String id;
  final String pickup;
  final String destination;
  final DateTime scheduledAt;
  final int passengerCount;
  RideStatus status;

  RideRequest({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.scheduledAt,
    required this.passengerCount,
    this.status = RideStatus.pending,
  });
}