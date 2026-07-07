import '../../../domain/models/transaction_model.dart';
import '../../../domain/repositories/transaction_repository.dart';
import 'mock_transaction_repository.dart';

class DynamicTransactionRepository implements TransactionRepository {
  final MockTransactionRepository _mock = MockTransactionRepository();
  
  // Dev-2 sẽ tích hợp FirebaseTransactionRepository vào đây ở Ngày 2/3
  // Bằng cách kế thừa tương tự DynamicAuthRepository/DynamicUserRepository

  // ==========================================
  // [DEV-3 MOCK DATA] - CẦN THAY THẾ KHI TÍCH HỢP FIREBASE
  // Chức năng: Quản lý active repo (cần trỏ sang FirebaseTransactionRepository)
  // ==========================================
  TransactionRepository get _active => _mock;

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _active.watchTransactions(userId);
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) {
    return _active.getTransactions(userId);
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) {
    return _active.createTransaction(transaction);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) {
    return _active.updateTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _active.deleteTransaction(id);
  }
}
