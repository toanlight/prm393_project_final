import 'dart:async';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  MockAuthRepository() {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get onAuthStateChanged => _authStateController.stream;

  @override
  Future<UserModel> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = UserModel(
      uid: 'anon_${DateTime.now().millisecondsSinceEpoch}',
      email: 'anonymous@demo.com',
      displayName: 'Khách Demo',
      photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=anon',
      isAnonymous: true,
      createdAt: DateTime.now(),
      fullName: 'Khách Demo',
      roleId: 'viewer',
      taxCode: null,
      isActive: true,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email không hợp lệ!');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải dài hơn 5 ký tự!');
    }
    
    // Assign role based on email prefix for easy testing
    String roleId = 'viewer';
    String? taxCode;
    final prefix = email.split('@').first.toLowerCase();
    
    if (prefix.startsWith('admin')) {
      roleId = 'admin';
    } else if (prefix.startsWith('chief')) {
      roleId = 'chiefAccountant';
    } else if (prefix.startsWith('accountant')) {
      roleId = 'accountant';
    } else if (prefix.startsWith('sales')) {
      roleId = 'salesperson';
    } else if (prefix.startsWith('manager')) {
      roleId = 'manager';
    } else if (prefix.startsWith('partner')) {
      roleId = 'partner';
      taxCode = '12345'; // default test tax code for partner
    }

    final name = prefix;
    _currentUser = UserModel(
      uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name[0].toUpperCase() + name.substring(1),
      photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=$name',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: name[0].toUpperCase() + name.substring(1) + ' User',
      roleId: roleId,
      taxCode: taxCode,
      isActive: true,
      passwordHash: 'mock_password_hash',
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email không hợp lệ!');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải dài hơn 5 ký tự!');
    }
    if (displayName.isEmpty) {
      throw Exception('Tên hiển thị không được bỏ trống!');
    }

    String roleId = 'viewer';
    String? taxCode;
    final prefix = email.split('@').first.toLowerCase();
    if (prefix.startsWith('partner')) {
      roleId = 'partner';
      taxCode = '12345';
    } else if (prefix.startsWith('chief')) {
      roleId = 'chiefAccountant';
    } else if (prefix.startsWith('accountant')) {
      roleId = 'accountant';
    }

    _currentUser = UserModel(
      uid: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=$displayName',
      isAnonymous: false,
      createdAt: DateTime.now(),
      fullName: displayName,
      roleId: roleId,
      taxCode: taxCode,
      isActive: true,
      passwordHash: 'mock_password_hash',
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null);
  }
}
