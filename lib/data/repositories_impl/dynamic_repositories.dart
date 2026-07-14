import '../../../domain/models/user_model.dart';
import '../../../domain/models/transaction_model.dart';
import '../../../domain/models/category_model.dart';
import '../../../domain/models/ocr_scan_model.dart';
import '../../../domain/models/invoice_model.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/ocr_scan_repository.dart';
import '../../../domain/repositories/invoice_repository.dart';
import '../services/firebase_service.dart';
import 'mock_auth_repository.dart';
import 'mock_user_repository.dart';
import 'mock_transaction_repository.dart';
import 'mock_category_repository.dart';
import 'mock_ocr_scan_repository.dart';
import 'mock_invoice_repository.dart';
import 'firebase_auth_repository.dart';
import 'firebase_user_repository.dart';
import 'firebase_transaction_repository.dart';
import 'firebase_category_repository.dart';
import 'firebase_ocr_scan_repository.dart';

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

class DynamicTransactionRepository implements TransactionRepository {
  final MockTransactionRepository _mock = MockTransactionRepository();
  FirebaseTransactionRepository? _realInstance;

  FirebaseTransactionRepository get _real => _realInstance ??= FirebaseTransactionRepository();

  TransactionRepository get _active => FirebaseService().isMockMode ? _mock : _real;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) => _active.getTransactions(userId);

  @override
  Stream<List<TransactionModel>> streamTransactions(String userId) {
    return FirebaseService().isMockMode 
        ? _mock.streamTransactions(userId) 
        : _real.streamTransactions(userId);
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) => _active.createTransaction(transaction);

  @override
  Future<void> updateTransaction(TransactionModel transaction) => _active.updateTransaction(transaction);

  @override
  Future<void> deleteTransaction(String transactionId) => _active.deleteTransaction(transactionId);
}


class DynamicCategoryRepository implements CategoryRepository {
  final MockCategoryRepository _mock = MockCategoryRepository();
  FirebaseCategoryRepository? _realInstance;

  FirebaseCategoryRepository get _real => _realInstance ??= FirebaseCategoryRepository();

  CategoryRepository get _active => FirebaseService().isMockMode ? _mock : _real;

  @override
  Future<List<CategoryModel>> getCategories() => _active.getCategories();

  @override
  Future<void> createCategory(CategoryModel category) => _active.createCategory(category);

  @override
  Future<void> deleteCategory(String categoryId) => _active.deleteCategory(categoryId);
}


class DynamicOCRScanRepository implements OCRScanRepository {
  final MockOCRScanRepository _mock = MockOCRScanRepository();
  FirebaseOCRScanRepository? _realInstance;

  FirebaseOCRScanRepository get _real => _realInstance ??= FirebaseOCRScanRepository();

  OCRScanRepository get _active => FirebaseService().isMockMode ? _mock : _real;

  @override
  Future<OCRScanModel?> getOCRScan(String scanId) => _active.getOCRScan(scanId);

  @override
  Future<List<OCRScanModel>> getOCRScansByUser(String userId) => _active.getOCRScansByUser(userId);

  @override
  Future<void> createOCRScan(OCRScanModel scan) => _active.createOCRScan(scan);

  @override
  Future<void> updateOCRScan(OCRScanModel scan) => _active.updateOCRScan(scan);
}

class DynamicInvoiceRepository implements InvoiceRepository {
  final MockInvoiceRepository _mock = MockInvoiceRepository();

  InvoiceRepository get _active => _mock;

  @override
  Future<InvoiceModel?> getInvoiceForTransaction(String transactionId) =>
      _active.getInvoiceForTransaction(transactionId);

  @override
  Future<void> createInvoice(InvoiceModel invoice) =>
      _active.createInvoice(invoice);

  @override
  Future<void> deleteInvoice(String transactionId, String invoiceId) =>
      _active.deleteInvoice(transactionId, invoiceId);
}
