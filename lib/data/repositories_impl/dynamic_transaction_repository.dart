import '../../../domain/models/transaction_model.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../services/firebase_service.dart';
import 'firebase_transaction_repository.dart';
import 'mock_transaction_repository.dart';

class DynamicTransactionRepository implements TransactionRepository {
  final MockTransactionRepository _mock;
  final FirebaseTransactionRepository _firebase;
  final FirebaseService _firebaseService;

  DynamicTransactionRepository({
    MockTransactionRepository? mockRepository,
    FirebaseTransactionRepository? firebaseRepository,
    FirebaseService? firebaseService,
  })  : _mock = mockRepository ?? MockTransactionRepository(),
        _firebase =
            firebaseRepository ?? FirebaseTransactionRepository(),
        _firebaseService = firebaseService ?? FirebaseService();

  TransactionRepository get _active {
    return _firebaseService.isMockMode ? _mock : _firebase;
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) {
    return _active.getTransactions(userId);
  }

  @override
  Stream<List<TransactionModel>> streamTransactions(String userId) {
    return _active.streamTransactions(userId);
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
  Future<void> deleteTransaction(String transactionId) {
    return _active.deleteTransaction(transactionId);
  }
}
