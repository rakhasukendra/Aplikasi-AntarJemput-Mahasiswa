class RideLocation {
  final double latitude;
  final double longitude;
  final String label;

  const RideLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  Map<String, Object> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
  };

  factory RideLocation.fromMap(Map<String, dynamic> map) => RideLocation(
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    label: map['label'] as String? ?? 'Lokasi dipilih di peta',
  );
}
