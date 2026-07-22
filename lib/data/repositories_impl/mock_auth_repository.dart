import 'dart:async';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  MockAuthRepository() {
    _currentUser = null;
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get onAuthStateChanged {
    // Create a controller for the subscriber
    final controller = StreamController<UserModel?>();
    // Emit the current state immediately
    controller.add(_currentUser);
    // Forward future events from the main controller
    final subscription = _authStateController.stream.listen(
      (user) => controller.add(user),
      onError: (e) => controller.addError(e),
      onDone: () => controller.close(),
    );
    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }

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
      roleId: 'accountant',
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
    String roleId = 'accountant';
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
      taxCode = '0102030405'; // test tax code for partner
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

    String roleId = 'accountant';
    String? taxCode;
    final prefix = email.split('@').first.toLowerCase();
    if (prefix.startsWith('admin')) {
      roleId = 'admin';
    } else if (prefix.startsWith('chief')) {
      roleId = 'chiefAccountant';
    } else if (prefix.startsWith('sales')) {
      roleId = 'salesperson';
    } else if (prefix.startsWith('manager')) {
      roleId = 'manager';
    } else if (prefix.startsWith('partner')) {
      roleId = 'partner';
      taxCode = '0102030405';
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
  Future<String> createUserInAuth(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Email không hợp lệ!');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải dài hơn 5 ký tự!');
    }
    return 'mock_user_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (oldPassword.isEmpty) {
      throw Exception('Mật khẩu cũ không chính xác.');
    }
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải dài hơn 5 ký tự!');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null);
  }
}
