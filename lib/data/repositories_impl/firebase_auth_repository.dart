import 'package:firebase_core/firebase_core.dart';
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
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Đăng nhập thất bại bằng Firebase');
      }
      return _mapFirebaseUser(user)!;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-not-found') {
        throw Exception('Email hoặc mật khẩu không chính xác.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Tài khoản này đã bị vô hiệu hóa.');
      }
      throw Exception(e.message ?? e.toString());
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
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
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email này đã được đăng ký bởi một tài khoản khác.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Địa chỉ email không hợp lệ.');
      } else if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu.');
      }
      throw Exception(e.message ?? e.toString());
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  @override
  Future<String> createUserInAuth(String email, String password) async {
    final appName = 'TempAdminCreateUserApp_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      
      final tempAuth = fb.FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('Không nhận được UID từ tài khoản mới.');
      }
      
      return uid;
    } catch (e) {
      throw Exception('Lỗi tạo tài khoản Auth: $e');
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Không tìm thấy phiên đăng nhập hiện tại.');
    }
    try {
      // Reauthenticate with current email and old password
      final credential = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Mật khẩu cũ không chính xác.');
      }
      if (e.code == 'requires-recent-login') {
        throw Exception('Vì lý do bảo mật, bạn cần đăng xuất và đăng nhập lại trước khi thay đổi mật khẩu.');
      }
      throw Exception(e.message ?? e.toString());
    } catch (e) {
      throw Exception('Lỗi thay đổi mật khẩu: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
