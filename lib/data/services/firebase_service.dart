import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("🔥 Firebase initialized successfully.");
    } catch (e) {
      debugPrint("⚠️ Firebase initialization warning: $e");
    }
  }
}

