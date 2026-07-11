import '../models/user_model.dart';

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
}
