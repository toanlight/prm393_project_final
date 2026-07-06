import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../data/services/firebase_service.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final config = authProvider.appConfig;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check actual Firebase Initialization state
    final isMockMode = FirebaseService().isMockMode;

    Widget buildStatCard({
      required String title,
      required String value,
      required IconData icon,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.all(AppDesignTokens.spaceMd),
        decoration: BoxDecoration(
          color: isDark ? AppDesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          border: Border.all(
            color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
            width: 1,
          ),
          boxShadow: isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.spaceSm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppDesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => authProvider.fetchAppConfig(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.responsiveValue(
          mobile: AppDesignTokens.spaceMd,
          tablet: AppDesignTokens.spaceLg,
          desktop: AppDesignTokens.spaceXl,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
              decoration: BoxDecoration(
                gradient: AppDesignTokens.primaryGradient,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                boxShadow: AppDesignTokens.darkShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: NetworkImage(user?.photoUrl ?? ''),
                  ),
                  const SizedBox(width: AppDesignTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${user?.displayName ?? 'Khách'} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.isAnonymous == true
                              ? 'Bạn đang trải nghiệm với tài khoản Khách demo.'
                              : 'Email: ${user?.email}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.spaceLg),

            // Statistics Grid (Responsive)
            GridView.count(
              crossAxisCount: context.valueForDeviceType<int>(
                mobile: 1,
                tablet: 2,
                desktop: 3,
              ),
              crossAxisSpacing: AppDesignTokens.spaceMd,
              mainAxisSpacing: AppDesignTokens.spaceMd,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                buildStatCard(
                  title: 'Chế độ hoạt động',
                  value: isMockMode ? 'Mock Mode (Offline)' : 'Firebase Production',
                  icon: isMockMode ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                  color: isMockMode ? AppDesignTokens.warning : AppDesignTokens.success,
                ),
                buildStatCard(
                  title: 'Cơ sở dữ liệu Firestore',
                  value: isMockMode ? 'In-Memory (Mock)' : 'Connected (Real)',
                  icon: Icons.storage_rounded,
                  color: AppDesignTokens.secondary,
                ),
                buildStatCard(
                  title: 'Lưu trữ Storage client',
                  value: isMockMode ? 'Mock Storage' : 'Firebase Storage',
                  icon: Icons.snippet_folder_rounded,
                  color: AppDesignTokens.accent,
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spaceLg),

            // App configuration details card
            Text(
              'Cấu hình Ứng dụng (Firestore app_config)',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDesignTokens.spaceSm),
            
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.spaceLg),
              decoration: BoxDecoration(
                color: isDark ? AppDesignTokens.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                border: Border.all(
                  color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        config['appName'] ?? 'Tên ứng dụng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(config['appVersion'] ?? '1.0.0'),
                        backgroundColor: AppDesignTokens.primary.withOpacity(0.1),
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          color: AppDesignTokens.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppDesignTokens.spaceLg),
                  Text(
                    'Thông báo hệ thống:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config['systemMessage'] ?? 'Không có thông báo hệ thống nào.',
                    style: TextStyle(
                      color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceMd),
                  const Text(
                    'Tính năng khả dụng:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDesignTokens.spaceSm),
                  if (config['features'] != null)
                    ...(config['features'] as Map<String, dynamic>).entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              entry.value == true ? Icons.check_circle_outline : Icons.cancel_outlined,
                              color: entry.value == true ? AppDesignTokens.success : AppDesignTokens.error,
                              size: 18,
                            ),
                            const SizedBox(width: AppDesignTokens.spaceSm),
                            Text('${entry.key}: ${entry.value}'),
                          ],
                        ),
                      );
                    })
                  else
                    const Text('Không có tính năng cấu hình nào.'),
                  
                  const SizedBox(height: AppDesignTokens.spaceMd),
                  Text(
                    'Cập nhật lần cuối: ${config['lastUpdated'] ?? 'N/A'}',
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
    );
  }
}
