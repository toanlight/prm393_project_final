import 'dart:async';
import 'package:hive/hive.dart';
import '../../../domain/models/transaction_model.dart';
import '../../../domain/models/transaction_type.dart';
import '../../../domain/repositories/transaction_repository.dart';

class MockTransactionRepository implements TransactionRepository {
  static const String _boxName = 'mock_transactions_box';
  
  final StreamController<List<TransactionModel>> _streamController = 
      StreamController<List<TransactionModel>>.broadcast();

  Box? _box;

  Future<Box> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
      if (_box!.isEmpty) {
        final initialData = [
          TransactionModel(
            transactionId: 'mock_tx_1',
            userId: 'mock_user',
            categoryId: 'cat_doanhthu',
            invoiceId: null,
            scanId: null,
            amount: 50000000,
            type: TransactionType.income,
            transactionDate: DateTime.now().subtract(const Duration(days: 5)),
            note: 'Doanh thu bán lẻ đợt 1',
            receiptImage: null,
            status: 'confirmed',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          TransactionModel(
            transactionId: 'mock_tx_2',
            userId: 'mock_user',
            categoryId: 'cat_matbang',
            invoiceId: 'mock_inv_1',
            scanId: 'mock_scan_1',
            amount: 12000000,
            type: TransactionType.expense,
            transactionDate: DateTime.now().subtract(const Duration(days: 3)),
            note: 'Thanh toán tiền nhà tháng 7',
            receiptImage: 'assets/images/sample_receipt.png',
            status: 'confirmed',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          TransactionModel(
            transactionId: 'mock_tx_3',
            userId: 'mock_user',
            categoryId: 'cat_luong',
            invoiceId: null,
            scanId: null,
            amount: 20000000,
            type: TransactionType.expense,
            transactionDate: DateTime.now().subtract(const Duration(days: 1)),
            note: 'Chi lương nhân viên kỹ thuật',
            receiptImage: null,
            status: 'pending',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        for (var tx in initialData) {
          await _box!.put(tx.transactionId, tx.toMap());
        }
      }
    }
    return _box!;
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final box = await _getBox();
    final list = box.values
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return list;
  }

  @override
  Stream<List<TransactionModel>> streamTransactions(String userId) {
    _emitTransactions(userId);
    return _streamController.stream;
  }

  Future<void> _emitTransactions(String userId) async {
    final list = await getTransactions(userId);
    if (!_streamController.isClosed) {
      _streamController.add(list);
    }
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.put(transaction.transactionId, transaction.toMap());
    _emitTransactions(transaction.userId);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    await box.put(transaction.transactionId, transaction.toMap());
    _emitTransactions(transaction.userId);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final box = await _getBox();
    final txData = box.get(transactionId);
    String userId = 'mock_user';
    if (txData != null) {
      final tx = TransactionModel.fromMap(Map<String, dynamic>.from(txData));
      userId = tx.userId;
    }
    await box.delete(transactionId);
    _emitTransactions(userId);
  }
}
