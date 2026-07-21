import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';

class UserManagementProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserManagementProvider({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userRepository.getUsers();
      // Sort users by name
      _users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('UserManagementProvider error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
