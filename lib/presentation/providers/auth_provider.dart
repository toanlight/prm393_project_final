import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<UserModel?>? _authSubscription;
  Map<String, dynamic> _appConfig = {};

  AuthProvider({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository {
    _init();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get appConfig => _appConfig;

  void _init() {
    _authSubscription = _authRepository.onAuthStateChanged.listen(
      (UserModel? user) async {
        // Hold splash screen for a brief moment for smooth UI experience
        if (_isLoading) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }

        _user = user;
        _errorMessage = null;
        if (user != null) {
          // Synced database user or create if not exists
          try {
            final dbUser = await _userRepository.getUser(user.uid);
            if (dbUser == null) {
              await _userRepository.createUser(user);
            } else {
              // Update user fields
              await _userRepository.updateUser(user);
            }
          } catch (e) {
            debugPrint("Failed to sync user to database: $e");
          }
          // Fetch application config
          await fetchAppConfig();
        } else {
          _appConfig = {};
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> fetchAppConfig() async {
    try {
      _appConfig = await _userRepository.getAppConfiguration();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load app config: $e");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signInAnonymously();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signUpWithEmailAndPassword(email, password, displayName);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
