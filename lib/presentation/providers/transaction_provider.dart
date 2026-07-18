import 'package:flutter/material.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/transaction_repository.dart';

enum TransactionStatus { initial, loading, success, error }

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository;

  List<TransactionModel> _transactions = [];
  TransactionStatus _status = TransactionStatus.initial;
  String _errorMessage = '';

  TransactionProvider({
    required TransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  List<TransactionModel> get transactions => _transactions;
  TransactionStatus get status => _status;
  String get errorMessage => _errorMessage;

  bool get isLoading => _status == TransactionStatus.loading;
  bool get isError => _status == TransactionStatus.error;
  bool get isSuccess => _status == TransactionStatus.success;

  Future<void> fetchTransactions(String userId) async {
    _status = TransactionStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final list = await _transactionRepository.getTransactions(userId);
      _transactions = List.from(list);
      // Sắp xếp giao dịch mới nhất lên đầu
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _status = TransactionStatus.success;
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> deleteTransaction(String id, String userId) async {
    // Không chuyển trạng thái sang loading chính để tránh biến mất toàn bộ danh sách,
    // nhưng ta có thể xóa tạm thời phần tử khỏi danh sách hoặc hiển thị loading riêng.
    try {
      await _transactionRepository.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Không thể xóa giao dịch: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _transactionRepository.createTransaction(transaction);
      _transactions.insert(0, transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Không thể thêm giao dịch: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _transactionRepository.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Không thể cập nhật giao dịch: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransactionStatus(String id, String newStatus, String userId) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        final currentTx = _transactions[index];
        final updatedTx = currentTx.copyWith(status: newStatus);
        await _transactionRepository.updateTransaction(updatedTx);
        _transactions[index] = updatedTx;
        notifyListeners();
      }
    } catch (e) {
      _status = TransactionStatus.error;
      _errorMessage = 'Không thể cập nhật trạng thái: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
