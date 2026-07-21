import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/seed_data_service.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.responsiveValue(
            mobile: AppDesignTokens.spaceMd,
            tablet: AppDesignTokens.spaceLg,
            desktop: AppDesignTokens.spaceXl,
          )),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: AppDesignTokens.primary, size: 28),
                    const SizedBox(width: AppDesignTokens.spaceSm),
                    Text(
                      'Tùy chỉnh Giao diện & Chế độ',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.spaceLg),
                const Divider(),
                const SizedBox(height: AppDesignTokens.spaceMd),

                // Theme Settings
                Text(
                  'Giao diện ứng dụng',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spaceSm),
                SwitchListTile(
                  title: const Text('Chế độ Tối (Dark Mode)'),
                  subtitle: const Text('Tiết kiệm pin và bảo vệ mắt vào ban đêm'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: themeProvider.isDarkMode,
                  activeColor: AppDesignTokens.primary,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),

                const SizedBox(height: AppDesignTokens.spaceLg),
                const Divider(),
                const SizedBox(height: AppDesignTokens.spaceMd),

                // Firebase/Mock Switcher
                Text(
                  'Cấu hình nền tảng Firebase',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spaceSm),
                
                SwitchListTile(
                  title: const Text('Chế độ Mock (Offline)'),
                  subtitle: const Text(
                    'Sử dụng dữ liệu giả lập bộ nhớ tạm mà không kết nối Firebase Real'
                  ),
                  secondary: const Icon(Icons.developer_mode_outlined),
                  value: firebaseService.isMockMode,
                  activeColor: AppDesignTokens.warning,
                  onChanged: (value) {
                    firebaseService.forceMockMode(value);
                    
                    // Alert user to Re-authenticate to trigger matching repository
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppDesignTokens.warning),
                            const SizedBox(width: 8),
                            const Text('Thay đổi chế độ'),
                          ],
                        ),
                        content: Text(
                          'Đã thiết lập Mock Mode thành $value. Bạn nên Đăng xuất và Đăng nhập lại để cập nhật Repository thích ứng (Mock vs Firebase Real).'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              authProvider.signOut(); // Auto logout to apply
                            },
                            child: const Text('Đăng xuất ngay'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Bỏ qua'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppDesignTokens.spaceLg),
                const Divider(),
                const SizedBox(height: AppDesignTokens.spaceMd),

                // Seed Data Section
                Text(
                  'Quản lý dữ liệu mẫu (Seed Data)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spaceSm),
                ListTile(
                  leading: const Icon(Icons.grass_rounded, color: AppDesignTokens.success),
                  title: const Text('🌱 Xóa sạch & Đẩy dữ liệu mẫu lên Firebase (Cách 1)'),
                  subtitle: const Text(
                    'Xóa toàn bộ data cũ, tạo mới 6 Roles, 6 Accounts (1/role), 15 Categories, 15 Transactions, 12 Invoices và 12 OCR Scans',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    _showSeedConfirmDialog(context);
                  },
                ),

                const SizedBox(height: AppDesignTokens.spaceLg),
                const Divider(),
                const SizedBox(height: AppDesignTokens.spaceMd),

                // Version Info
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Kiến trúc Nền tảng Smart Finance v1.0.0',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clean Architecture + Provider + GoRouter',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSeedConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.grass_rounded, color: AppDesignTokens.success),
            SizedBox(width: 8),
            Text('Xác nhận Clean & Seed Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thao tác này sẽ XÓA SẠCH toàn bộ dữ liệu cũ trên Firestore và tạo lại dữ liệu mẫu:',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppDesignTokens.warning),
            ),
            SizedBox(height: 8),
            Text('• 6 Vai trò (Roles)'),
            Text('• 6 Tài khoản người dùng (1 account / role)'),
            Text('• 15 Danh mục (Categories)'),
            Text('• 15 Giao dịch mẫu (Transactions)'),
            Text('• 12 Hóa đơn chứng từ (Invoices)'),
            Text('• 12 Bản ghi quét OCR (OCR Scans)'),
            SizedBox(height: 12),
            Text(
              'Bạn có muốn tiến hành ngay không?',
              style: TextStyle(color: AppDesignTokens.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignTokens.success,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Tiến hành Seed'),
            onPressed: () {
              Navigator.pop(dialogCtx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  _executeSeedProcess(context);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _executeSeedProcess(BuildContext context) {
    String statusLog = '🚀 Đang chuẩn bị Seed...';
    BuildContext? dialogProgressContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (progressCtx) {
        dialogProgressContext = progressCtx;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Đang Seed Dữ liệu mẫu...'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusLog),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ),
            );
          },
        );
      },
    );

    SeedDataService.run(
      onStatus: (msg) {
        debugPrint(msg);
      },
    ).then((_) {
      if (dialogProgressContext != null && dialogProgressContext!.mounted) {
        Navigator.of(dialogProgressContext!).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Seed dữ liệu mẫu lên Firebase thành công! (Cách 1)'),
            backgroundColor: AppDesignTokens.success,
          ),
        );
      }
    }).catchError((error) {
      if (dialogProgressContext != null && dialogProgressContext!.mounted) {
        Navigator.of(dialogProgressContext!).pop();
      }
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (errCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppDesignTokens.error),
                SizedBox(width: 8),
                Text('Lỗi Seed Data'),
              ],
            ),
            content: Text(
              'Không thể seed dữ liệu lên Firebase:\n$error\n\nHãy đảm bảo bạn đã tắt Mock Mode và đã Đăng nhập tài khoản.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(errCtx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    });
  }
}
