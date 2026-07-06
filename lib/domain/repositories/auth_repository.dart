import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get onAuthStateChanged;
  UserModel? get currentUser;
  
  Future<UserModel> signInAnonymously();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<void> signOut();
}
