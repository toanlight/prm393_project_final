import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';

class UserManagementProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadError;

  UserManagementProvider({
    required UserRepository userRepository,
    required AuthRepository authRepository,
  })  : _userRepository = userRepository,
        _authRepository = authRepository;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get loadError => _loadError;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _loadError = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userRepository.getUsers();
      // Sort users by name
      _users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    } catch (e) {
      _loadError = e.toString().replaceAll('Exception: ', '');
      debugPrint('UserManagementProvider load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required String roleId,
    String? taxCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Enforce constraint: Only one active Admin / Chief Accountant allowed in the system
      if (roleId == 'admin' || roleId == 'chiefAccountant') {
        final alreadyExists = _users.any((u) => u.roleId == roleId && u.isActive);
        if (alreadyExists) {
          final roleName = roleId == 'admin' ? 'Admin Hệ thống' : 'Kế toán trưởng';
          throw Exception('Hệ thống đã tồn tại một tài khoản $roleName đang hoạt động.');
        }
      }

      // 1. Create user credentials in Auth repository
      final uid = await _authRepository.createUserInAuth(email, password);

      // 2. Create the user model representation
      final newUser = UserModel(
        uid: uid,
        email: email.trim(),
        displayName: fullName,
        fullName: fullName,
        roleId: roleId,
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=${Uri.encodeComponent(fullName)}',
        isAnonymous: false,
        createdAt: DateTime.now(),
        isActive: true,
        taxCode: roleId == 'partner' ? taxCode : null,
      );

      // 3. Save to user database repository
      await _userRepository.createUser(newUser);

      // 4. Update locally and sort
      _users.add(newUser);
      _users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(UserModel updatedUser, String currentAdminUid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (updatedUser.uid == currentAdminUid) {
        if (updatedUser.roleId != 'admin') {
          throw Exception('Bạn không thể tự thay đổi vai trò của chính mình.');
        }
        if (!updatedUser.isActive) {
          throw Exception('Bạn không thể tự khóa tài khoản của chính mình.');
        }
      }

      // Enforce constraint: Only one active Admin / Chief Accountant allowed in the system
      if (updatedUser.isActive && (updatedUser.roleId == 'admin' || updatedUser.roleId == 'chiefAccountant')) {
        final alreadyExists = _users.any(
          (u) => u.roleId == updatedUser.roleId && u.isActive && u.uid != updatedUser.uid,
        );
        if (alreadyExists) {
          final roleName = updatedUser.roleId == 'admin' ? 'Admin Hệ thống' : 'Kế toán trưởng';
          throw Exception('Hệ thống đã tồn tại một tài khoản $roleName đang hoạt động.');
        }
      }

      await _userRepository.updateUser(updatedUser);
      final index = _users.indexWhere((u) => u.uid == updatedUser.uid);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }



  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
