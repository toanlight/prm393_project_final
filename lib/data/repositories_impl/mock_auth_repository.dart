import 'dart:async';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  MockAuthRepository() {
    // Start session as logged out (null)
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get onAuthStateChanged => _authStateController.stream;

  @override
  Future<UserModel> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    _currentUser = UserModel(
      uid: 'anon_${DateTime.now().millisecondsSinceEpoch}',
      email: 'anonymous@demo.com',
      displayName: 'Khách Demo',
      photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=anon',
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network latency
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email không hợp lệ!');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải dài hơn 5 ký tự!');
    }
    
    // Create mock user
    final name = email.split('@').first;
    _currentUser = UserModel(
      uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name[0].toUpperCase() + name.substring(1),
      photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=$name',
      isAnonymous: false,
      createdAt: DateTime.now(),
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email không hợp lệ!');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải dài hơn 5 ký tự!');
    }
    if (displayName.isEmpty) {
      throw Exception('Tên hiển thị không được bỏ trống!');
    }

    _currentUser = UserModel(
      uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=$displayName',
      isAnonymous: false,
      createdAt: DateTime.now(),
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }
}
