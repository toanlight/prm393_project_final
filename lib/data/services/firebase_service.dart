import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isMockMode = true;
  bool get isMockMode => _isMockMode;

  Future<void> initialize() async {
    if (kIsWeb) {
      // On web, if Firebase options are not set up properly, it will fail.
      // We wrap it in try-catch to enable seamless mock fallback.
      try {
        // Try initializing with options. We try to load options reflectively or standard.
        // If they don't exist, we will fail and fallback.
        await Firebase.initializeApp();
        _isMockMode = false;
        debugPrint("🔥 Firebase Web initialized successfully in Real Mode.");
      } catch (e) {
        _isMockMode = true;
        debugPrint("⚠️ Firebase Web initialization failed ($e). Falling back to Mock Mode.");
      }
    } else {
      // Mobile / Desktop
      try {
        // On mobile, if GoogleServices-Info.plist or google-services.json is missing, it crashes/throws.
        await Firebase.initializeApp();
        _isMockMode = false;
        debugPrint("🔥 Firebase initialized successfully in Real Mode.");
      } catch (e) {
        _isMockMode = true;
        debugPrint("⚠️ Firebase initialization failed ($e). Falling back to Mock Mode.");
      }
    }
  }

  /// Manually force mock mode (e.g. for testing/demo offline)
  void forceMockMode(bool force) {
    _isMockMode = force;
    debugPrint("⚙️ FirebaseService: Mock Mode set to $_isMockMode");
  }
}
