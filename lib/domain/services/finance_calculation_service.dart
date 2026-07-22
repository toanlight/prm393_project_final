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

  /// Calculates total income for confirmed transactions.
  static int calculateConfirmedIncome(List<TransactionModel> transactions) {
    return calculateTotalIncome(
      transactions.where((tx) => tx.status == 'confirmed').toList(),
    );
  }

  /// Calculates total expense for confirmed transactions.
  static int calculateConfirmedExpense(List<TransactionModel> transactions) {
    return calculateTotalExpense(
      transactions.where((tx) => tx.status == 'confirmed').toList(),
    );
  }

  /// Calculates net balance (Số dư ròng = Tổng thu - Tổng chi).
  static int calculateNetBalance(int totalIncome, int totalExpense) {
    return totalIncome - totalExpense;
  }

  /// Calculates sum for a specific transaction type within an optional date range.
  static int calculateSumForPeriod(
    List<TransactionModel> transactions,
    TransactionType type, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return transactions.where((tx) {
      if (tx.type != type) return false;
      if (startDate != null && tx.date.isBefore(startDate)) return false;
      if (endDate != null && tx.date.isAfter(endDate)) return false;
      return true;
    }).fold(0, (sum, tx) => sum + tx.amountVnd);
  }

  /// Calculates trend percentage change between two values.
  static String calculateTrendPercentage(num current, num previous) {
    if (previous == 0) {
      if (current == 0) return '0%';
      return '+100%';
    }
    final change = ((current - previous) / previous) * 100;
    final prefix = change > 0 ? '+' : '';
    return '$prefix${change.toStringAsFixed(1)}%';
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
