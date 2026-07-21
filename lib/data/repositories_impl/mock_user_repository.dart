import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  final Map<String, UserModel> _usersDb = {};

  MockUserRepository() {
    final mockUsers = [
      UserModel(
        uid: 'uid_admin',
        email: 'admin@smartfinance.com',
        displayName: 'Admin Hệ thống',
        fullName: 'Nguyễn Văn Admin',
        roleId: 'admin',
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=admin',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 1),
        isActive: true,
      ),
      UserModel(
        uid: 'uid_chiefAccountant',
        email: 'chief@smartfinance.com',
        displayName: 'Kế toán trưởng',
        fullName: 'Trần Thị Hương',
        roleId: 'chiefAccountant',
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=chief',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 1),
        isActive: true,
      ),
      UserModel(
        uid: 'uid_accountant',
        email: 'accountant@smartfinance.com',
        displayName: 'Kế toán viên',
        fullName: 'Lê Văn Kế',
        roleId: 'accountant',
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=accountant',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 1),
        isActive: true,
      ),
      UserModel(
        uid: 'uid_salesperson',
        email: 'sales@smartfinance.com',
        displayName: 'Nhân viên Bán hàng',
        fullName: 'Phạm Thị Sales',
        roleId: 'salesperson',
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=sales',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 1),
        isActive: true,
      ),
      UserModel(
        uid: 'uid_manager',
        email: 'manager@smartfinance.com',
        displayName: 'Quản lý',
        fullName: 'Hoàng Văn Manager',
        roleId: 'manager',
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=manager',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 1),
        isActive: true,
      ),
      UserModel(
        uid: 'uid_partner',
        email: 'partner@smartbuilding.com',
        displayName: 'Đối tác Smart Building',
        fullName: 'Nguyễn Thành Đối Tác',
        roleId: 'partner',
        taxCode: '0102030405',
        photoUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=partner1',
        isAnonymous: false,
        createdAt: DateTime(2026, 1, 1),
        isActive: true,
      ),
    ];
    for (var u in mockUsers) {
      _usersDb[u.uid] = u;
    }
  }

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
  Future<List<UserModel>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _usersDb.values.toList();
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
