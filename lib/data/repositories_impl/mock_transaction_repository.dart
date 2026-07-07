import 'dart:async';
import '../../domain/models/transaction_model.dart';
import '../../domain/repositories/transaction_repository.dart';

class MockTransactionRepository implements TransactionRepository {
  final List<TransactionModel> _mockTransactions = [];
  final StreamController<List<TransactionModel>> _controller = StreamController<List<TransactionModel>>.broadcast();

  MockTransactionRepository() {
    // Khởi tạo một số giao dịch mẫu ban đầu
    // ==========================================
    // [DEV-3 MOCK DATA] - CẦN THAY THẾ KHI TÍCH HỢP FIREBASE
    // Chức năng: Khởi tạo dữ liệu giả lập ban đầu
    // ==========================================
    final now = DateTime.now();
    _mockTransactions.addAll([
      TransactionModel(
        id: 't1',
        amountVnd: 150000,
        type: 'chi',
        category: 'Ăn uống',
        date: now.subtract(const Duration(hours: 2)),
        receiptImageUrl: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&q=80&w=400',
        createdBy: 'mock-user-123',
      ),
      TransactionModel(
        id: 't2',
        amountVnd: 15000000,
        type: 'thu',
        category: 'Lương',
        date: now.subtract(const Duration(days: 1)),
        receiptImageUrl: null,
        createdBy: 'mock-user-123',
      ),
      TransactionModel(
        id: 't3',
        amountVnd: 450000,
        type: 'chi',
        category: 'Mua sắm',
        date: now.subtract(const Duration(days: 2)),
        receiptImageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&q=80&w=400',
        createdBy: 'mock-user-123',
      ),
      TransactionModel(
        id: 't4',
        amountVnd: 2500000,
        type: 'thu',
        category: 'Kinh doanh',
        date: now.subtract(const Duration(days: 3)),
        receiptImageUrl: null,
        createdBy: 'mock-user-123',
      ),
      TransactionModel(
        id: 't5',
        amountVnd: 120000,
        type: 'chi',
        category: 'Di chuyển',
        date: now.subtract(const Duration(days: 4)),
        receiptImageUrl: null,
        createdBy: 'mock-user-123',
      ),
    ]);
    // Phát dữ liệu ban đầu
    _controller.add(List.unmodifiable(_mockTransactions));
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(String userId) {
    // Trả về Stream và phát lại trạng thái hiện tại ngay lập tức
    Timer.run(() {
      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(_mockTransactions));
      }
    });
    return _controller.stream;
  }

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    // Giả lập delay mạng 1 giây để kiểm thử UI loading
    await Future.delayed(const Duration(seconds: 1));
    return List.unmodifiable(_mockTransactions);
  }

  @override
  Future<void> createTransaction(TransactionModel transaction) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockTransactions.insert(0, transaction);
    _controller.add(List.unmodifiable(_mockTransactions));
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockTransactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _mockTransactions[index] = transaction;
      _controller.add(List.unmodifiable(_mockTransactions));
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // Giả lập delay mạng 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    _mockTransactions.removeWhere((t) => t.id == id);
    _controller.add(List.unmodifiable(_mockTransactions));
  }
}
