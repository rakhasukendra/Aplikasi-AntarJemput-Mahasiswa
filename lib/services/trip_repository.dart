import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trip.dart';

class TripRepository {
  final FirebaseFirestore? _firestore;

  TripRepository({this._firestore});
  const TripRepository.unconfigured() : _firestore = null;

  bool get isConfigured => _firestore != null;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore!.collection('trips');

  Future<String> createTrip(TripDraft draft) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firebase belum disiapkan.');
    if (draft.passengerId.isEmpty || draft.passengerCount < 1) {
      throw ArgumentError('Data pesanan tidak valid.');
    }
    final doc = _trips.doc();
    await doc.set({
      'passengerId': draft.passengerId,
      'driverId': null,
      'pickup': draft.pickup.toMap(),
      'destination': draft.destination.toMap(),
      'passengerCount': draft.passengerCount,
      'scheduledAt': Timestamp.fromDate(draft.scheduledAt),
      'status': TripStatus.requested.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<Trip>> availableTrips() {
    if (_firestore == null) return const Stream.empty();
    return _trips
        .where('status', isEqualTo: TripStatus.requested.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Trip.fromMap(doc.id, _fromFirestore(doc.data())))
              .toList(),
        );
  }

  Stream<List<Trip>> passengerTrips(String passengerId) {
    if (_firestore == null) return const Stream.empty();
    return _trips
        .where('passengerId', isEqualTo: passengerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Trip.fromMap(doc.id, _fromFirestore(doc.data())))
              .toList(),
        );
  }

  Stream<Trip?> watchTrip(String tripId) {
    if (_firestore == null) return const Stream.empty();
    return _trips
        .doc(tripId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? Trip.fromMap(doc.id, _fromFirestore(doc.data()!))
              : null,
        );
  }

  Future<void> acceptTrip(
    String tripId,
    String driverId, {
    required String driverName,
  }) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firebase belum disiapkan.');
    await firestore.runTransaction((transaction) async {
      final ref = _trips.doc(tripId);
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || data['status'] != TripStatus.requested.name) {
        throw StateError('Pesanan sudah diambil atau tidak tersedia.');
      }
      transaction.update(ref, {
        'driverId': driverId,
        'driverName': driverName,
        'status': TripStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateTripStatus(String tripId, TripStatus status) async {
    final firestore = _firestore;
    if (firestore == null) throw StateError('Firebase belum disiapkan.');
    final ref = _trips.doc(tripId);
    await ref.update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Map<String, dynamic> _fromFirestore(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    for (final key in ['createdAt', 'updatedAt', 'scheduledAt']) {
      final value = result[key];
      if (value is Timestamp) result[key] = value.toDate();
    }
    return result;
  }

  static Trip draftPreview(TripDraft draft) => Trip(
    id: '',
    passengerId: draft.passengerId,
    driverId: null,
    pickup: draft.pickup,
    destination: draft.destination,
    passengerCount: draft.passengerCount,
    status: TripStatus.requested,
  );
}
