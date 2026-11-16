import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

enum FirebaseBootstrapStatus { configured, unavailable, failed }

class FirebaseBootstrap {
  static const enabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );

  static Future<FirebaseBootstrapStatus> initialize({
    FirebaseOptions? options,
  }) async {
    if (Firebase.apps.isNotEmpty) return FirebaseBootstrapStatus.configured;
    if (!enabled && options == null) return FirebaseBootstrapStatus.unavailable;
    final resolvedOptions = options ?? _webOptionsFromEnvironment;
    if (kIsWeb && resolvedOptions == null) {
      return FirebaseBootstrapStatus.unavailable;
    }
    try {
      await Firebase.initializeApp(options: resolvedOptions);
      return FirebaseBootstrapStatus.configured;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error\n$stackTrace');
      return FirebaseBootstrapStatus.failed;
    }
  }

  static FirebaseOptions? get _webOptionsFromEnvironment {
    if (_apiKey.isEmpty ||
        _appId.isEmpty ||
        _messagingSenderId.isEmpty ||
        _projectId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
    );
  }
}
