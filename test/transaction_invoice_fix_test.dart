import 'package:flutter_test/flutter_test.dart';
import 'package:project_final/domain/models/invoice_status.dart';
import 'package:project_final/domain/models/transaction_model.dart';
import 'package:project_final/domain/models/transaction_status.dart';
import 'package:project_final/domain/models/transaction_type.dart';
import 'package:project_final/domain/services/finance_calculation_service.dart';

void main() {
  group('FinanceCalculationService Tests', () {
    test('calculateSumForPeriod includes transactions occurring on the end date', () {
      final now = DateTime(2026, 7, 22); // 2026-07-22 00:00:00
      final tx1 = TransactionModel(
        transactionId: 'tx1',
        userId: 'u1',
        categoryId: 'c1',
        amount: 100000,
        type: TransactionType.expense,
        transactionDate: DateTime(2026, 7, 22, 14, 30, 0), // 14:30 on end date
        status: 'confirmed',
        createdAt: now,
      );
      final tx2 = TransactionModel(
        transactionId: 'tx2',
        userId: 'u1',
        categoryId: 'c1',
        amount: 200000,
        type: TransactionType.expense,
        transactionDate: DateTime(2026, 7, 23, 10, 0, 0), // Next day
        status: 'confirmed',
        createdAt: now,
      );

      final total = FinanceCalculationService.calculateSumForPeriod(
        [tx1, tx2],
        TransactionType.expense,
        startDate: DateTime(2026, 7, 20),
        endDate: DateTime(2026, 7, 22),
      );

      expect(total, equals(100000));
    });

    test('calculateTrendPercentage returns N/A when previous is 0 and current > 0', () {
      expect(FinanceCalculationService.calculateTrendPercentage(50000, 0), equals('N/A'));
      expect(FinanceCalculationService.calculateTrendPercentage(0, 0), equals('0%'));
      expect(FinanceCalculationService.calculateTrendPercentage(150, 100), equals('+50.0%'));
    });

    test('calculateVatAmount and calculateTotalInvoiceAmount handle double VAT rates', () {
      final vatAmount = FinanceCalculationService.calculateVatAmount(100000, 8.5);
      expect(vatAmount, equals(8500));

      final total = FinanceCalculationService.calculateTotalInvoiceAmount(100000, 8.5);
      expect(total, equals(108500));
    });
  });

  group('Status Mapping Tests', () {
    test('TransactionStatus correctly maps to InvoiceStatus', () {
      expect(InvoiceStatus.fromTransactionStatus(TransactionStatus.confirmed), equals(InvoiceStatus.confirmed));
      expect(InvoiceStatus.fromTransactionStatus(TransactionStatus.rejected), equals(InvoiceStatus.cancelled));
      expect(InvoiceStatus.fromTransactionStatus(TransactionStatus.pending), equals(InvoiceStatus.draft));
    });
  });
}
