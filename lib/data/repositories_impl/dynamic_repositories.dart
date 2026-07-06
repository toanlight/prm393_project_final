import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../services/firebase_service.dart';
import 'mock_auth_repository.dart';
import 'mock_user_repository.dart';
import 'firebase_auth_repository.dart';
import 'firebase_user_repository.dart';

class DynamicAuthRepository implements AuthRepository {
  final MockAuthRepository _mock = MockAuthRepository();
  FirebaseAuthRepository? _realInstance;

  FirebaseAuthRepository get _real => _realInstance ??= FirebaseAuthRepository();

  AuthRepository get _active => FirebaseService().isMockMode ? _mock : _real;

  @override
  UserModel? get currentUser => _active.currentUser;

  @override
  Stream<UserModel?> get onAuthStateChanged {
    // Return the active repository's stream.
    return FirebaseService().isMockMode ? _mock.onAuthStateChanged : _real.onAuthStateChanged;
  }

  @override
  Future<UserModel> signInAnonymously() => _active.signInAnonymously();

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) =>
      _active.signInWithEmailAndPassword(email, password);

  @override
  Future<UserModel> signUpWithEmailAndPassword(
          String email, String password, String displayName) =>
      _active.signUpWithEmailAndPassword(email, password, displayName);

  @override
  Future<void> signOut() => _active.signOut();
}

class DynamicUserRepository implements UserRepository {
  final MockUserRepository _mock = MockUserRepository();
  FirebaseUserRepository? _realInstance;

  FirebaseUserRepository get _real => _realInstance ??= FirebaseUserRepository();

  UserRepository get _active => FirebaseService().isMockMode ? _mock : _real;

  @override
  Future<UserModel?> getUser(String uid) => _active.getUser(uid);

  @override
  Future<void> createUser(UserModel user) async {
    await _active.createUser(user);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _active.updateUser(user);
  }

  @override
  Future<Map<String, dynamic>> getAppConfiguration() => _active.getAppConfiguration();
}
