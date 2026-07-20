import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/services/firebase_service.dart';
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

                // Version Info
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Kiến trúc Nền tảng Viper v1.0.0',
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
}
