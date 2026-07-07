import '../models/transaction_model.dart';

abstract class TransactionRepository {
  Stream<List<TransactionModel>> watchTransactions(String userId);
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<void> createTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}
