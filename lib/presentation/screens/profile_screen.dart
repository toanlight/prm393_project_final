import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Map<String, String> _roleLabels = {
    'admin': 'Quản trị viên',
    'chiefAccountant': 'Kế toán trưởng',
    'accountant': 'Kế toán viên',
    'salesperson': 'Nhân viên bán hàng',
    'manager': 'Quản lý',
    'partner': 'Đối tác',
  };

  static const Map<String, Color> _roleColors = {
    'admin': Color(0xFF7C3AED),
    'chiefAccountant': Color(0xFF0369A1),
    'accountant': Color(0xFF0891B2),
    'salesperson': Color(0xFF16A34A),
    'manager': Color(0xFFCA8A04),
    'partner': Color(0xFFEA580C),
  };

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void copyToClipboard(String text) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép User ID vào bộ nhớ tạm!'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Cá nhân'),
        toolbarHeight: 48,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              mobile: AppDesignTokens.spaceMd,
              tablet: AppDesignTokens.spaceLg,
              desktop: AppDesignTokens.spaceXl,
            ),
            vertical: AppDesignTokens.spaceSm,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
            decoration: BoxDecoration(
              color: isDark ? AppDesignTokens.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
              border: Border.all(
                color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                width: 1,
              ),
              boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar Frame gọn gàng
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppDesignTokens.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(user?.photoUrl ?? ''),
                  ),
                ),
                const SizedBox(height: 8),

                // Display Name
                Text(
                  user?.displayName ?? 'Khách Demo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (user?.fullName != null && user!.fullName.isNotEmpty && user.fullName != user.displayName) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppDesignTokens.darkTextSecondary
                          : AppDesignTokens.lightTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                
                // Account Type & Role Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        user?.isAnonymous == true ? 'Tài khoản khách (Demo)' : 'Tài khoản chính thức',
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: user?.isAnonymous == true
                          ? AppDesignTokens.warning.withOpacity(0.1)
                          : AppDesignTokens.success.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: user?.isAnonymous == true ? AppDesignTokens.warning : AppDesignTokens.success,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    if (user?.roleId != null)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        avatar: const Icon(Icons.shield_outlined, size: 14),
                        label: Text(
                          _roleLabels[user!.roleId] ?? user.roleId,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            (_roleColors[user.roleId] ?? Colors.grey).withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: _roleColors[user.roleId] ?? Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide.none,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                const Divider(height: 12),

                // Info Section
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.email_outlined, color: AppDesignTokens.primary, size: 20),
                  title: const Text('Email', style: TextStyle(fontSize: 12)),
                  subtitle: Text(user?.email ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.fingerprint_rounded, color: AppDesignTokens.primary, size: 20),
                  title: const Text('User ID', style: TextStyle(fontSize: 12)),
                  subtitle: Text(
                    user?.uid ?? 'N/A',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => copyToClipboard(user?.uid ?? ''),
                  ),
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.calendar_month_outlined, color: AppDesignTokens.primary, size: 20),
                  title: const Text('Ngày tham gia', style: TextStyle(fontSize: 12)),
                  subtitle: Text(
                    user?.createdAt != null
                        ? DateFormat('dd/MM/yyyy').format(user!.createdAt)
                        : 'N/A',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                if (user?.roleId == 'partner' && user?.taxCode != null)
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: const Icon(Icons.receipt_long_outlined, color: AppDesignTokens.primary, size: 20),
                    title: const Text('Mã số thuế', style: TextStyle(fontSize: 12)),
                    subtitle: Text(user!.taxCode!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                
                const Divider(height: 16),
                const SizedBox(height: 4),

                // Change Password Button (only for non-anonymous accounts)
                if (user?.isAnonymous != true) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showChangePasswordBottomSheet(context, authProvider, isDark),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: const Text('Đổi mật khẩu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => authProvider.signOut(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignTokens.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Đăng xuất', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordBottomSheet(BuildContext context, AuthProvider authProvider, bool isDark) {
    final oldPasswordController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? oldError;
    String? newError;
    String? confirmError;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppDesignTokens.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDesignTokens.radiusLg),
                  ),
                  border: Border.all(
                    color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header line indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceLg),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_reset_rounded,
                          color: AppDesignTokens.primary,
                          size: 24,
                        ),
                        const SizedBox(width: AppDesignTokens.spaceSm),
                        Text(
                          'Thay đổi mật khẩu',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDesignTokens.spaceSm),
                    Text(
                      'Nhập mật khẩu hiện tại và mật khẩu mới của bạn để cập nhật bảo mật tài khoản.',
                      style: TextStyle(
                        color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceLg),

                    // Old Password field
                    const Text(
                      'Mật khẩu cũ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceXs),
                    TextField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu hiện tại...',
                        border: const OutlineInputBorder(),
                        errorText: oldError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureOld = !obscureOld;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceMd),

                    // New Password field
                    const Text(
                      'Mật khẩu mới',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceXs),
                    TextField(
                      controller: passwordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)...',
                        border: const OutlineInputBorder(),
                        errorText: newError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceMd),

                    // Confirm Password field
                    const Text(
                      'Xác nhận mật khẩu mới',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceXs),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Nhập lại mật khẩu mới...',
                        border: const OutlineInputBorder(),
                        errorText: confirmError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spaceXl),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(bottomSheetCtx),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: AppDesignTokens.spaceMd),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppDesignTokens.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final oldPwd = oldPasswordController.text;
                                    final newPwd = passwordController.text;
                                    final confirmPwd = confirmController.text;

                                    setModalState(() {
                                      oldError = null;
                                      newError = null;
                                      confirmError = null;
                                    });

                                    bool hasError = false;
                                    if (oldPwd.isEmpty) {
                                      setModalState(() {
                                        oldError = 'Vui lòng nhập mật khẩu cũ!';
                                      });
                                      hasError = true;
                                    }

                                    if (newPwd.isEmpty) {
                                      setModalState(() {
                                        newError = 'Vui lòng nhập mật khẩu mới!';
                                      });
                                      hasError = true;
                                    } else if (newPwd.length < 6) {
                                      setModalState(() {
                                        newError = 'Mật khẩu mới phải từ 6 ký tự trở lên!';
                                      });
                                      hasError = true;
                                    } else if (newPwd == oldPwd) {
                                      setModalState(() {
                                        newError = 'Mật khẩu mới không được trùng mật khẩu cũ!';
                                      });
                                      hasError = true;
                                    }

                                    if (confirmPwd.isEmpty) {
                                      setModalState(() {
                                        confirmError = 'Vui lòng xác nhận mật khẩu mới!';
                                      });
                                      hasError = true;
                                    } else if (newPwd != confirmPwd) {
                                      setModalState(() {
                                        confirmError = 'Mật khẩu xác nhận không khớp!';
                                      });
                                      hasError = true;
                                    }

                                    if (hasError) return;

                                    setModalState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      await authProvider.changePassword(oldPwd, newPwd);
                                      if (bottomSheetCtx.mounted) {
                                        Navigator.pop(bottomSheetCtx);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Đổi mật khẩu thành công!'),
                                            backgroundColor: AppDesignTokens.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      final errMsg = e.toString().replaceAll('Exception: ', '');
                                      setModalState(() {
                                        if (errMsg.contains('Mật khẩu cũ')) {
                                          oldError = errMsg;
                                        } else {
                                          newError = errMsg;
                                        }
                                      });
                                    } finally {
                                      setModalState(() {
                                        isSaving = false;
                                      });
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Cập nhật'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
