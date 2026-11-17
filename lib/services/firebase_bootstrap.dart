import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

enum FirebaseBootstrapStatus { configured, unavailable, failed }

class FirebaseBootstrap {
  static Future<FirebaseBootstrapStatus> initialize({
    FirebaseOptions? options,
  }) async {
    // Hindari inisialisasi Firebase berulang.
    if (Firebase.apps.isNotEmpty) {
      return FirebaseBootstrapStatus.configured;
    }

    try {
      await Firebase.initializeApp(
        options: options ?? DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('Firebase berhasil diinisialisasi.');

      return FirebaseBootstrapStatus.configured;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrint('$stackTrace');

      return FirebaseBootstrapStatus.failed;
    }
  }
}
