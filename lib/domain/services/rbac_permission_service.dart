import '../models/user_model.dart';
import '../models/invoice_model.dart';
import '../models/transaction_model.dart';

class RbacPermissionService {
  /// Check if a user can view the Transactions tab/screen.
  /// Admin, Chief Accountant, Accountant, Salesperson, and Manager can view transactions.
  /// Partner is restricted to Invoices matching their tax code.
  static bool canViewTransactions(UserModel? user) {
    if (user == null) return false;
    return user.roleId == 'admin' ||
        user.roleId == 'chiefAccountant' ||
        user.roleId == 'accountant' ||
        user.roleId == 'salesperson' ||
        user.roleId == 'manager';
  }

  /// Check if a user can view the Invoices tab/screen.
  static bool canViewInvoices(UserModel? user) {
    if (user == null) return false;
    return true; // All authenticated roles can view invoices (filtered as applicable)
  }

  /// Check if a user is allowed to confirm/approve transactions or invoices.
  /// Chief Accountant and Admin can confirm.
  static bool canConfirm(UserModel? user) {
    if (user == null) return false;
    return user.roleId == 'chiefAccountant' || user.roleId == 'admin';
  }

  /// Alias for transaction confirmation
  static bool canConfirmTransaction(UserModel? user) => canConfirm(user);

  /// Check if a user is allowed to create transactions or record invoices.
  /// Admin, Chief Accountant, Accountant, and Salesperson can create.
  static bool canCreate(UserModel? user) {
    if (user == null) return false;
    return user.roleId == 'admin' ||
        user.roleId == 'chiefAccountant' ||
        user.roleId == 'accountant' ||
        user.roleId == 'salesperson';
  }

  static bool canCreateTransaction(UserModel? user) => canCreate(user);
  static bool canCreateInvoice(UserModel? user) => canCreate(user);

  /// Check if a user is allowed to edit existing transactions/invoices.
  /// Admin, Chief Accountant, Accountant, and Salesperson can edit.
  static bool canEditTransaction(UserModel? user) {
    if (user == null) return false;
    return user.roleId == 'admin' ||
        user.roleId == 'chiefAccountant' ||
        user.roleId == 'accountant' ||
        user.roleId == 'salesperson';
  }

  /// Check if a user is allowed to delete transactions.
  /// Only Admin and Chief Accountant can delete.
  static bool canDeleteTransaction(UserModel? user) {
    if (user == null) return false;
    return user.roleId == 'admin' || user.roleId == 'chiefAccountant';
  }

  /// Check if a user is allowed to view financial reports.
  /// Admin, Chief Accountant, Accountant, and Manager can view reports.
  static bool canViewReports(UserModel? user) {
    if (user == null) return false;
    return user.roleId == 'admin' ||
        user.roleId == 'chiefAccountant' ||
        user.roleId == 'accountant' ||
        user.roleId == 'manager';
  }

  /// Check if a user is allowed to export/download a PDF invoice.
  /// Admin, Chief Accountant, and Accountant can export any invoice.
  /// Partners can ONLY export their own confirmed/processed invoices (matching taxCode).
  static bool canExportPdf(UserModel? user, InvoiceModel invoice) {
    if (user == null) return false;
    if (user.roleId == 'admin' ||
        user.roleId == 'chiefAccountant' ||
        user.roleId == 'accountant') {
      return true;
    }
    if (user.roleId == 'partner') {
      final isMatchingTaxCode = user.taxCode != null &&
          user.taxCode!.isNotEmpty &&
          invoice.taxCode == user.taxCode;
      final isConfirmed = invoice.status == 'confirmed' || invoice.status == 'processed';
      return isMatchingTaxCode && isConfirmed;
    }
    return false;
  }

  /// Check if a user can manage system users / seed data.
  static bool canManageUsers(UserModel? user) {
    return user?.roleId == 'admin';
  }

  /// Filter invoices that a user is allowed to view.
  /// Partners can only see invoices matching their taxCode.
  /// Others can see all invoices.
  static List<InvoiceModel> filterVisibleInvoices(
      UserModel? user, List<InvoiceModel> invoices) {
    if (user == null) return [];
    if (user.roleId == 'partner') {
      if (user.taxCode == null || user.taxCode!.isEmpty) return [];
      return invoices.where((inv) => inv.taxCode == user.taxCode).toList();
    }
    return invoices;
  }

  /// Filter transactions that a user is allowed to view.
  /// Partners do not view internal transactions.
  static List<TransactionModel> filterVisibleTransactions(
      UserModel? user, List<TransactionModel> transactions) {
    if (user == null) return [];
    if (user.roleId == 'partner') {
      return []; // Partner does not view internal cashbook transactions
    }
    return transactions;
  }
}

