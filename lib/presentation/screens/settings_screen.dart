import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/seed_data_service.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSeeding = false;
  final List<String> _seedLogs = [];

  Future<void> _runSeed() async {
    if (_isSeeding) return;
    if (FirebaseService().isMockMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng tắt Mock Mode trước khi seed dữ liệu Firebase.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isSeeding = true;
      _seedLogs.clear();
    });
    try {
      await SeedDataService.run(
        onStatus: (msg) {
          if (mounted) setState(() => _seedLogs.add(msg));
        },
      );
    } catch (e) {
      if (mounted) setState(() => _seedLogs.add('❌ Lỗi: $e'));
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firebaseService = FirebaseService();
    final isAdmin = authProvider.user?.roleId == 'admin';

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

                // ── SEED DATA SECTION (Admin only) ──────────────
                if (isAdmin) ...[
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppDesignTokens.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Dữ liệu Firebase (Dev/Admin)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spaceSm),
                  Text(
                    'Tạo dữ liệu mẫu (categories, users, transactions, invoices…) lên Firebase. '
                    'Chỉ dùng 1 lần khi khởi tạo dự án.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceSm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _runSeed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignTokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                        ),
                      ),
                      icon: _isSeeding
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.rocket_launch_rounded),
                      label: Text(_isSeeding ? 'Đang upload dữ liệu...' : '🚀 Seed dữ liệu lên Firebase'),
                    ),
                  ),

                  // Live log output
                  if (_seedLogs.isNotEmpty) ...[
                    const SizedBox(height: AppDesignTokens.spaceSm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                        border: Border.all(
                          color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _seedLogs.map((log) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: log.startsWith('❌')
                                  ? Colors.redAccent
                                  : log.startsWith('✅') || log.startsWith('🎉')
                                      ? Colors.green
                                      : isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppDesignTokens.spaceLg),
                  const Divider(),
                  const SizedBox(height: AppDesignTokens.spaceMd),
                ],

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
