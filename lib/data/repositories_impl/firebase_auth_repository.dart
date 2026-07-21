import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../domain/models/user_model.dart';
import '../../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  String _resolveRoleFromEmail(String? email) {
    if (email == null) return 'accountant';
    final e = email.trim().toLowerCase();
    if (e.contains('admin')) return 'admin';
    if (e.contains('chief')) return 'chiefAccountant';
    if (e.contains('sales')) return 'salesperson';
    if (e.contains('manager')) return 'manager';
    if (e.contains('partner')) return 'partner';
    if (e.contains('accountant')) return 'accountant';
    return 'accountant';
  }

  UserModel? _mapFirebaseUser(fb.User? user) {
    if (user == null) return null;
    final email = user.email ?? '';
    final role = _resolveRoleFromEmail(email);
    return UserModel(
      uid: user.uid,
      email: email,
      displayName: user.displayName ?? 'Người dùng Firebase',
      photoUrl: user.photoURL ?? 'https://api.dicebear.com/7.x/adventurer/png?seed=${user.uid}',
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      fullName: user.displayName ?? 'Người dùng Firebase',
      roleId: role,
      taxCode: role == 'partner' ? '0102030405' : null,
      isActive: true,
      passwordHash: null,
    );
  }

  @override
  UserModel? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  Future<UserModel> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw Exception('Không thể đăng nhập ẩn danh bằng Firebase');
    }
    return _mapFirebaseUser(user)!;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw Exception('Đăng nhập thất bại bằng Firebase');
    }
    return _mapFirebaseUser(user)!;
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw Exception('Đăng ký thất bại bằng Firebase');
    }
    
    // Update display name in Firebase Auth profile
    await user.updateDisplayName(displayName);
    // Reload user to ensure profile updates are loaded
    await user.reload();
    
    return _mapFirebaseUser(_firebaseAuth.currentUser)!;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
