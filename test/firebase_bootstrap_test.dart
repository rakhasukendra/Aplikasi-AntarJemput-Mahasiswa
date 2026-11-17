import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_antarjemput_mahasiswa/services/firebase_bootstrap.dart';

void main() {
  test('reports unavailable when Firebase config is not supplied', () async {
    expect(
      await FirebaseBootstrap.initialize(),
      FirebaseBootstrapStatus.unavailable,
    );
  });
}
