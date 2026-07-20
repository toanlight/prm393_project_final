import '../../domain/models/category_model.dart';
import '../../domain/models/invoice_model.dart';
import '../../domain/models/ocr_scan_model.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/user_model.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/ocr_scan_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';

import '../services/firebase_service.dart';

import 'firebase_auth_repository.dart';
import 'firebase_category_repository.dart';
import 'firebase_invoice_repository.dart';
import 'firebase_ocr_scan_repository.dart';
import 'firebase_transaction_repository.dart';
import 'firebase_user_repository.dart';

import 'mock_auth_repository.dart';
import 'mock_category_repository.dart';
import 'mock_invoice_repository.dart';
import 'mock_ocr_scan_repository.dart';
import 'mock_transaction_repository.dart';
import 'mock_user_repository.dart';

/// Chọn repository Firebase thật hoặc repository mock.
///
/// FirebaseService.isMockMode == true:
///   → sử dụng Mock Repository.
///
/// FirebaseService.isMockMode == false:
///   → sử dụng Firebase Repository.
class DynamicAuthRepository implements AuthRepository {
  final MockAuthRepository _mock = MockAuthRepository();

  FirebaseAuthRepository? _firebaseInstance;

  FirebaseAuthRepository get _firebase {
    return _firebaseInstance ??= FirebaseAuthRepository();
  }

  AuthRepository get _active {
    return FirebaseService().isMockMode
        ? _mock
        : _firebase;
  }

  @override
  UserModel? get currentUser => _active.currentUser;

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _active.onAuthStateChanged;
  }

  @override
  Future<UserModel> signInAnonymously() {
    return _active.signInAnonymously();
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
      String email,
      String password,
      ) {
    return _active.signInWithEmailAndPassword(
      email,
      password,
    );
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
      String email,
      String password,
      String displayName,
      ) {
    return _active.signUpWithEmailAndPassword(
      email,
      password,
      displayName,
    );
  }

  @override
  Future<void> signOut() async {
    await _active.signOut();

    if (FirebaseService().isMockMode) {
      try {
        await _firebase.signOut();
      } catch (_) {
        // Firebase có thể chưa được khởi tạo hoặc chưa đăng nhập.
      }
    }
  }
}

class DynamicUserRepository implements UserRepository {
  final MockUserRepository _mock = MockUserRepository();

  FirebaseUserRepository? _firebaseInstance;

  FirebaseUserRepository get _firebase {
    return _firebaseInstance ??= FirebaseUserRepository();
  }

  UserRepository get _active {
    return FirebaseService().isMockMode
        ? _mock
        : _firebase;
  }

  @override
  Future<UserModel?> getUser(String uid) {
    return _active.getUser(uid);
  }

  @override
  Future<void> createUser(UserModel user) {
    return _active.createUser(user);
  }

  @override
  Future<void> updateUser(UserModel user) {
    return _active.updateUser(user);
  }

  @override
  Future<Map<String, dynamic>> getAppConfiguration() {
    return _active.getAppConfiguration();
  }
}

class DynamicTransactionRepository
    implements TransactionRepository {
  final MockTransactionRepository _mock =
  MockTransactionRepository();

  FirebaseTransactionRepository? _firebaseInstance;

  FirebaseTransactionRepository get _firebase {
    return _firebaseInstance ??=
        FirebaseTransactionRepository();
  }

  TransactionRepository get _active {
    return FirebaseService().isMockMode
        ? _mock
        : _firebase;
  }

  @override
  Future<List<TransactionModel>> getTransactions(
      String userId,
      ) {
    return _active.getTransactions(userId);
  }

  @override
  Stream<List<TransactionModel>> streamTransactions(
      String userId,
      ) {
    return _active.streamTransactions(userId);
  }

  @override
  Future<void> createTransaction(
      TransactionModel transaction,
      ) {
    return _active.createTransaction(transaction);
  }

  @override
  Future<void> updateTransaction(
      TransactionModel transaction,
      ) {
    return _active.updateTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(
      String transactionId,
      ) {
    return _active.deleteTransaction(transactionId);
  }
}

class DynamicCategoryRepository
    implements CategoryRepository {
  final MockCategoryRepository _mock =
  MockCategoryRepository();

  FirebaseCategoryRepository? _firebaseInstance;

  FirebaseCategoryRepository get _firebase {
    return _firebaseInstance ??=
        FirebaseCategoryRepository();
  }

  CategoryRepository get _active {
    return FirebaseService().isMockMode
        ? _mock
        : _firebase;
  }

  @override
  Future<List<CategoryModel>> getCategories() {
    return _active.getCategories();
  }

  @override
  Future<void> createCategory(
      CategoryModel category,
      ) {
    return _active.createCategory(category);
  }

  @override
  Future<void> deleteCategory(
      String categoryId,
      ) {
    return _active.deleteCategory(categoryId);
  }
}

class DynamicOCRScanRepository
    implements OCRScanRepository {
  final MockOCRScanRepository _mock =
  MockOCRScanRepository();

  FirebaseOCRScanRepository? _firebaseInstance;

  FirebaseOCRScanRepository get _firebase {
    return _firebaseInstance ??=
        FirebaseOCRScanRepository();
  }

  OCRScanRepository get _active {
    return FirebaseService().isMockMode
        ? _mock
        : _firebase;
  }

  @override
  Future<OCRScanModel?> getOCRScan(
      String scanId,
      ) {
    return _active.getOCRScan(scanId);
  }

  @override
  Future<List<OCRScanModel>> getOCRScansByUser(
      String userId,
      ) {
    return _active.getOCRScansByUser(userId);
  }

  @override
  Future<void> createOCRScan(
      OCRScanModel scan,
      ) {
    return _active.createOCRScan(scan);
  }

  @override
  Future<void> updateOCRScan(
      OCRScanModel scan,
      ) {
    return _active.updateOCRScan(scan);
  }
}

class DynamicInvoiceRepository
    implements InvoiceRepository {
  final MockInvoiceRepository _mock =
  MockInvoiceRepository();

  FirebaseInvoiceRepository? _firebaseInstance;

  FirebaseInvoiceRepository get _firebase {
    return _firebaseInstance ??=
        FirebaseInvoiceRepository();
  }

  InvoiceRepository get _active {
    return FirebaseService().isMockMode
        ? _mock
        : _firebase;
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByUser(
      String userId,
      ) {
    return _active.getInvoicesByUser(userId);
  }

  @override
  Future<InvoiceModel?> getInvoiceForTransaction(
      String transactionId,
      ) {
    return _active.getInvoiceForTransaction(
      transactionId,
    );
  }

  @override
  Future<void> createInvoice(
      InvoiceModel invoice,
      ) {
    return _active.createInvoice(invoice);
  }

  @override
  Future<void> deleteInvoice(
      String transactionId,
      String invoiceId,
      ) {
    return _active.deleteInvoice(
      transactionId,
      invoiceId,
    );
  }
}