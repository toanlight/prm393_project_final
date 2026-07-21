import '../models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUser(String uid);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<List<UserModel>> getUsers();
  
  /// Fetches application configuration data (e.g. settings, feature flags) from database
  Future<Map<String, dynamic>> getAppConfiguration();
}
