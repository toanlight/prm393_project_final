import 'package:flutter_test/flutter_test.dart';
import 'package:project_final/domain/models/transaction_model.dart';
import 'package:project_final/domain/models/transaction_type.dart';
import 'package:project_final/domain/services/finance_calculation_service.dart';

void main() {
  group('FinanceCalculationService Unit Tests', () {
    final List<TransactionModel> transactions = [
      TransactionModel(
        transactionId: '1',
        amount: 1000000,
        type: TransactionType.income,
        categoryId: 'cat_doanhthu',
        transactionDate: DateTime.now(),
        userId: 'user_1',
        status: 'confirmed',
        createdAt: DateTime.now(),
      ),
      TransactionModel(
        transactionId: '2',
        amount: 500000,
        type: TransactionType.expense,
        categoryId: 'cat_luong',
        transactionDate: DateTime.now(),
        userId: 'user_1',
        status: 'confirmed',
        createdAt: DateTime.now(),
      ),
      TransactionModel(
        transactionId: '3',
        amount: 3000000,
        type: TransactionType.income,
        categoryId: 'cat_doanhthu',
        transactionDate: DateTime.now(),
        userId: 'user_1',
        status: 'confirmed',
        createdAt: DateTime.now(),
      ),
      TransactionModel(
        transactionId: '4',
        amount: 1200000,
        type: TransactionType.expense,
        categoryId: 'cat_matbang',
        transactionDate: DateTime.now(),
        userId: 'user_1',
        status: 'confirmed',
        createdAt: DateTime.now(),
      ),
    ];

    test('1. Test calculateTotalIncome (Tính tổng thu)', () {
      final totalIncome = FinanceCalculationService.calculateTotalIncome(transactions);
      expect(totalIncome, 4000000); // 1,000,000 + 3,000,000
    });

    test('2. Test calculateTotalExpense (Tính tổng chi)', () {
      final totalExpense = FinanceCalculationService.calculateTotalExpense(transactions);
      expect(totalExpense, 1700000); // 500,000 + 1,200,000
    });

  });
}
