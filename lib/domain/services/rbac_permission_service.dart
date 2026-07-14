import '../models/user_model.dart';
import '../models/invoice_model.dart';

class RbacPermissionService {
  /// Check if a user is allowed to confirm/approve transactions or invoices.
  /// Chief Accountant and Admin can confirm.
  static bool canConfirm(UserModel user) {
    return user.roleId == 'chiefAccountant' || user.roleId == 'admin';
  }

  /// Check if a user is allowed to create transactions or record invoices.
  /// Accountant, Salesperson, and Admin can create.
  static bool canCreate(UserModel user) {
    return user.roleId == 'accountant' || 
           user.roleId == 'salesperson' || 
           user.roleId == 'admin';
  }

  /// Check if a user is allowed to export/download a PDF invoice.
  /// Chief Accountant and Admin can export any invoice.
  /// Partners can ONLY export their own confirmed invoices (matching taxCode).
  /// Other roles are not allowed.
  static bool canExportPdf(UserModel user, InvoiceModel invoice) {
    if (user.roleId == 'chiefAccountant' || user.roleId == 'admin') {
      return true;
    }
    if (user.roleId == 'partner') {
      // Must match taxCode and the invoice must be confirmed by Chief Accountant
      return invoice.taxCode == user.taxCode && invoice.status == 'confirmed';
    }
    return false;
  }

  /// Filter invoices that a user is allowed to view.
  /// Partners can only see invoices matching their taxCode.
  /// Others can see all invoices.
  static List<InvoiceModel> filterVisibleInvoices(UserModel user, List<InvoiceModel> invoices) {
    if (user.roleId == 'partner') {
      return invoices.where((inv) => inv.taxCode == user.taxCode).toList();
    }
    return invoices;
  }
}
