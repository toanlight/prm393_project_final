import '../models/transaction_model.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions(String userId);
  Stream<List<TransactionModel>> streamTransactions(String userId);
  Future<void> createTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String transactionId);
}
