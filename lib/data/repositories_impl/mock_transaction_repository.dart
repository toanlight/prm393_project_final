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
        // ==========================================
        // [DEV-3 MOCK DATA] - CẦN THAY THẾ KHI TÍCH HỢP FIREBASE
        // Chức năng: Khởi tạo dữ liệu giả lập ban đầu
        // ==========================================
        final now = DateTime.now();
        final initialData = [
          TransactionModel(
            transactionId: 't1',
            amount: 150000,
            type: TransactionType.expense,
            categoryId: 'Ăn uống',
            transactionDate: now.subtract(const Duration(hours: 2)),
            receiptImage: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&q=80&w=400',
            userId: 'mock-user-123',
            status: 'confirmed',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          TransactionModel(
            transactionId: 't2',
            amount: 15000000,
            type: TransactionType.income,
            categoryId: 'Lương',
            transactionDate: now.subtract(const Duration(days: 1)),
            receiptImage: null,
            userId: 'mock-user-123',
            status: 'confirmed',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          TransactionModel(
            transactionId: 't3',
            amount: 450000,
            type: TransactionType.expense,
            categoryId: 'Mua sắm',
            transactionDate: now.subtract(const Duration(days: 2)),
            receiptImage: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=400',
            userId: 'mock-user-123',
            status: 'confirmed',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          TransactionModel(
            transactionId: 't4',
            amount: 2500000,
            type: TransactionType.income,
            categoryId: 'Kinh doanh',
            transactionDate: now.subtract(const Duration(days: 3)),
            receiptImage: null,
            userId: 'mock-user-123',
            status: 'confirmed',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          TransactionModel(
            transactionId: 't5',
            amount: 120000,
            type: TransactionType.expense,
            categoryId: 'Di chuyển',
            transactionDate: now.subtract(const Duration(days: 4)),
            receiptImage: null,
            userId: 'mock-user-123',
            status: 'confirmed',
            createdAt: now.subtract(const Duration(days: 4)),
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
