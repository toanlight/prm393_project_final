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

}
