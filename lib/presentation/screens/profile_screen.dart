import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar Frame with Gradient border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppDesignTokens.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(user?.photoUrl ?? ''),
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spaceLg),

                // Display Name
                Text(
                  user?.displayName ?? 'Khách Demo',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spaceXs),
                
                // Account Type Badge
                Chip(
                  label: Text(
                    user?.isAnonymous == true ? 'Tài khoản khách (Demo)' : 'Tài khoản chính thức',
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
                const SizedBox(height: AppDesignTokens.spaceLg),

                const Divider(),
                const SizedBox(height: AppDesignTokens.spaceMd),

                // Info Section
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppDesignTokens.primary),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'N/A'),
                ),
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded, color: AppDesignTokens.primary),
                  title: const Text('User ID'),
                  subtitle: Text(
                    user?.uid ?? 'N/A',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () => copyToClipboard(user?.uid ?? ''),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined, color: AppDesignTokens.primary),
                  title: const Text('Ngày tham gia'),
                  subtitle: Text(user?.createdAt.toString().split(' ').first ?? 'N/A'),
                ),
                
                const SizedBox(height: AppDesignTokens.spaceLg),
                const Divider(),
                const SizedBox(height: AppDesignTokens.spaceLg),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => authProvider.signOut(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignTokens.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng xuất'),
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
