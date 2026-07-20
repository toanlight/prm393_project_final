import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  @override
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
  }

  @override
  Future<List<UserModel>> getUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getAppConfiguration() async {
    try {
      final doc = await _firestore.collection('app_config').doc('settings').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      
      // Fallback configuration if document doesn't exist yet in Firestore
      return {
        'appName': 'Smart Finance App (Firebase)',
        'appVersion': '1.0.0-production',
        'features': {
          'enablePremiumThemes': true,
          'maintenanceMode': false,
          'maxUploadSizeMB': 50,
        },
        'systemMessage': 'Đang tải cấu hình ứng dụng từ Cloud Firestore.',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Return default configuration if something fails (e.g. permission denied)
      return {
        'appName': 'Smart Finance App (Firebase)',
        'appVersion': '1.0.0-fallback',
        'features': {
          'enablePremiumThemes': false,
          'maintenanceMode': false,
          'maxUploadSizeMB': 10,
        },
        'systemMessage': 'Lỗi kết nối khi lấy cấu hình Firebase: $e',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
