import '../models/transaction_model.dart';
import '../models/transaction_type.dart';

class FinanceCalculationService {
  /// Calculates the total income (Tổng Thu) from a list of transactions.
  static int calculateTotalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0, (sum, tx) => sum + tx.amountVnd);
  }

  /// Calculates the total expense (Tổng Chi) from a list of transactions.
  static int calculateTotalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0, (sum, tx) => sum + tx.amountVnd);
  }

  /// Calculates the VAT amount (Tiền thuế VAT) from subtotal (Tiền hàng) and rate (percentage as int e.g. 8 or 10).
  static int calculateVatAmount(int subtotal, int vatRate) {
    if (subtotal < 0 || vatRate < 0) return 0;
    return ((subtotal * vatRate) / 100).round();
  }

  /// Calculates the total invoice payment (Tổng thanh toán = Tiền hàng + Tiền thuế VAT).
  static int calculateTotalInvoiceAmount(int subtotal, int vatRate) {
    final vatAmount = calculateVatAmount(subtotal, vatRate);
    return subtotal + vatAmount;
  }
}
