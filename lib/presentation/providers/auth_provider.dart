import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  UserModel? _user;
  bool _isInitializing = true;
  bool _isActionLoading = false;
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
  bool get isInitializing => _isInitializing;
  bool get isActionLoading => _isActionLoading;
  bool get isLoading => _isInitializing || _isActionLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get appConfig => _appConfig;

  void _init() {
    _authSubscription = _authRepository.onAuthStateChanged.listen(
      (UserModel? user) async {
        _errorMessage = null;
        if (user != null) {
          UserModel syncedUser = user;
          // Synced database user or create if not exists
          try {
            final dbUser = await _userRepository.getUser(user.uid);
            if (dbUser == null) {
              await _userRepository.createUser(user);
            } else {
              if (!dbUser.isActive) {
                await _authRepository.signOut();
                _user = null;
                _errorMessage = 'Tài khoản của bạn đã bị vô hiệu hóa hoặc bị khóa bởi Admin.';
                _isInitializing = false;
                _isActionLoading = false;
                notifyListeners();
                return;
              }
              // Preserve roleId, fullName, taxCode, and other fields stored in Firestore database
              // Sync updated fields from auth to DB (email, displayName, photoUrl)
              final updatedUser = dbUser.copyWith(
                email: user.email,
                displayName: user.displayName.isNotEmpty ? user.displayName : dbUser.displayName,
                photoUrl: user.photoUrl.isNotEmpty ? user.photoUrl : dbUser.photoUrl,
              );
              await _userRepository.updateUser(updatedUser);
              syncedUser = updatedUser;
            }
          } catch (e) {
            debugPrint("Failed to sync user to database: $e");
          }
          _user = syncedUser;
          // Fetch application config
          await fetchAppConfig();
        } else {
          _user = null;
          _appConfig = {};
        }
        _isInitializing = false;
        _isActionLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isInitializing = false;
        _isActionLoading = false;
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

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final dbUser = await _userRepository.getUser(_user!.uid);
      if (dbUser != null) {
        _user = dbUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to refresh user profile from DB: $e");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    _setActionLoading(true);
    _clearError();
    try {
      await _authRepository.signInAnonymously();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setActionLoading(false);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _setActionLoading(true);
    _clearError();
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setActionLoading(false);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    _setActionLoading(true);
    _clearError();
    try {
      await _authRepository.signUpWithEmailAndPassword(email, password, displayName);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setActionLoading(false);
    }
  }

  Future<void> signOut() async {
    _setActionLoading(true);
    try {
      await _authRepository.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setActionLoading(false);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    _setActionLoading(true);
    _clearError();
    try {
      await _authRepository.changePassword(oldPassword, newPassword);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      _setActionLoading(false);
    }
  }

  void _setActionLoading(bool value) {
    _isActionLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message.replaceAll('Exception: ', '');
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
