import 'package:flutter/material.dart';
import '../../domain/models/invoice_status.dart';
import '../../domain/models/transaction_model.dart';
import '../../domain/models/transaction_status.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

enum TransactionProviderStatus { initial, loading, success, error }

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository;

  List<TransactionModel> _transactions = [];
  TransactionProviderStatus _status = TransactionProviderStatus.initial;
  String _errorMessage = '';

  TransactionProvider({
    required TransactionRepository transactionRepository,
  }) : _transactionRepository = transactionRepository;

  List<TransactionModel> get transactions => _transactions;
  TransactionProviderStatus get status => _status;
  String get errorMessage => _errorMessage;

  bool get isLoading => _status == TransactionProviderStatus.loading;
  bool get isError => _status == TransactionProviderStatus.error;
  bool get isSuccess => _status == TransactionProviderStatus.success;

  Future<void> fetchTransactions(String userId, {String? roleId}) async {
    _status = TransactionProviderStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final list = await _transactionRepository.getTransactions(userId, roleId: roleId);
      _transactions = List.from(list);
      _status = TransactionProviderStatus.success;
    } catch (e) {
      _status = TransactionProviderStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> deleteTransaction(
    String id,
    String userId, {
    InvoiceRepository? invoiceRepository,
  }) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        final tx = _transactions[index];
        // Quy tắc BA: Giao dịch đã xác nhận (confirmed) tuyệt đối không cho phép xóa
        if (tx.status.toLowerCase() == 'confirmed') {
          throw StateError('Giao dịch đã xác nhận không thể xóa.');
        }

        // Cascade xóa hóa đơn liên kết nếu có
        if (tx.invoiceId != null && tx.invoiceId!.isNotEmpty && invoiceRepository != null) {
          try {
            await invoiceRepository.deleteInvoice(tx.transactionId, tx.invoiceId!);
          } catch (e) {
            debugPrint('⚠️ Lỗi xóa hóa đơn liên kết: $e');
          }
        }
      }

      await _transactionRepository.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _status = TransactionProviderStatus.error;
      _errorMessage = 'Không thể xóa giao dịch: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _transactionRepository.createTransaction(transaction);
      _transactions.insert(0, transaction);
      notifyListeners();
    } catch (e) {
      _status = TransactionProviderStatus.error;
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
        notifyListeners();
      }
    } catch (e) {
      _status = TransactionProviderStatus.error;
      _errorMessage = 'Không thể cập nhật giao dịch: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTransactionStatus(
    String id,
    String newStatus,
    String userId, {
    InvoiceRepository? invoiceRepository,
  }) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        final currentTx = _transactions[index];
        final updatedTx = currentTx.copyWith(status: newStatus);
        await _transactionRepository.updateTransaction(updatedTx);
        _transactions[index] = updatedTx;

        // Đồng bộ trạng thái Hóa đơn liên kết theo đúng InvoiceStatus enum
        if (currentTx.invoiceId != null && invoiceRepository != null) {
          try {
            final invoice = await invoiceRepository.getInvoiceForTransaction(currentTx.transactionId);
            if (invoice != null) {
              final txDomainStatus = TransactionStatus.fromString(newStatus);
              final mappedInvoiceStatus = InvoiceStatus.fromTransactionStatus(txDomainStatus).value;
              final updatedInvoice = invoice.copyWith(status: mappedInvoiceStatus);
              await invoiceRepository.createInvoice(updatedInvoice);
            }
          } catch (e) {
            debugPrint('Lỗi đồng bộ trạng thái hóa đơn: $e');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      _status = TransactionProviderStatus.error;
      _errorMessage = 'Không thể cập nhật trạng thái: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
