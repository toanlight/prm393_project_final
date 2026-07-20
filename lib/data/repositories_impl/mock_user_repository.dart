import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  final Map<String, UserModel> _usersDb = {};

  @override
  Future<UserModel?> getUser(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _usersDb[uid];
  }

  @override
  Future<void> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _usersDb[user.uid] = user;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _usersDb[user.uid] = user;
  }

  @override
  Future<Map<String, dynamic>> getAppConfiguration() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'appName': 'Smart Finance App',
      'appVersion': '1.0.0-mock',
      'features': {
        'enablePremiumThemes': true,
        'maintenanceMode': false,
        'maxUploadSizeMB': 25,
      },
      'systemMessage': 'Ứng dụng đang chạy ở chế độ Demo (Mock Mode). Toàn bộ dữ liệu được lưu trên bộ nhớ tạm thời.',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
