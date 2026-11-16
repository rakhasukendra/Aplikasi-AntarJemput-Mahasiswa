import 'package:flutter/foundation.dart';

import '../models/ride_request.dart';

class RideRepository extends ChangeNotifier {
  // Satu objek yang dipakai bersama oleh semua layar (singleton).
  static final RideRepository instance = RideRepository();

  final List<RideRequest> _items = [];

  // Pesanan terbaru di paling atas.
  List<RideRequest> get items => _items.reversed.toList();

  void add(RideRequest request) {
    _items.add(request);
    notifyListeners();
  }

  void updateStatus(String id, RideStatus status) {
    final request = _items.firstWhere((r) => r.id == id);
    request.status = status;
    notifyListeners();
  }
}
