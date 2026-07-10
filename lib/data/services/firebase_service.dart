import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isMockMode = true;
  bool get isMockMode => _isMockMode;

  Future<void> initialize() async {
    if (kIsWeb) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isMockMode = false;
        debugPrint("🔥 Firebase Web initialized successfully in Real Mode.");
      } catch (e) {
        _isMockMode = true;
        debugPrint("⚠️ Firebase Web initialization failed ($e). Falling back to Mock Mode.");
      }
    } else {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
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
