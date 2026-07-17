import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/transaction_model.dart';
import '../../domain/services/mock_ocr_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/invoice_capture_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/receipt_image_preview_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/transaction_form_screen.dart';
import '../../presentation/screens/transaction_list_screen.dart';
import '../../presentation/widgets/app_navigation_shell.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    final rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
    final homeBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'homeBranch');
    final transactionBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'transactionBranch');
    final profileBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'profileBranch');
    final settingsBranchKey =
    GlobalKey<NavigatorState>(debugLabel: 'settingsBranch');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggingIn = state.matchedLocation == '/login';
        final isSplash = state.matchedLocation == '/splash';

        // ── 1. Đang khởi tạo Auth → giữ màn hình Splash ──────────────────
        if (authProvider.isLoading) {
          return isSplash ? null : '/splash';
        }

        // ── 2. Auth xong, chưa đăng nhập → chuyển về Login ───────────────
        if (!authProvider.isAuthenticated) {
          return isLoggingIn ? null : '/login';
        }

        // ── 3. Đã đăng nhập mà vẫn ở Splash / Login → vào trang chủ ──────
        if (isSplash || isLoggingIn) {
          return '/';
        }

        return null; // Tiếp tục điều hướng bình thường
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppNavigationShell(
              navigationShell: navigationShell,
            );
          },
          branches: [
            StatefulShellBranch(
              navigatorKey: homeBranchKey,
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: transactionBranchKey,
              routes: [
                GoRoute(
                  path: '/transactions',
                  builder: (context, state) =>
                  const TransactionListScreen(),
                  routes: [
                    GoRoute(
                      path: 'create',
                      builder: (context, state) {
                        final extra = state.extra;
                        return TransactionFormScreen(
                          initialOcrData:
                          extra is OcrInvoiceData ? extra : null,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'scan',
                      builder: (context, state) =>
                      const InvoiceCaptureScreen(),
                    ),
                    GoRoute(
                      path: 'receipt',
                      builder: (context, state) {
                        final transaction =
                        state.extra as TransactionModel?;
                        if (transaction == null) {
                          return const _InvalidRouteScreen(
                            message: 'Không tìm thấy giao dịch.',
                          );
                        }
                        return ReceiptImagePreviewScreen(
                          transaction: transaction,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) {
                        final transaction =
                        state.extra as TransactionModel?;
                        return TransactionFormScreen(
                          transactionToEdit: transaction,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: profileBranchKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) =>
                  const ProfileScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: settingsBranchKey,
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) =>
                  const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _InvalidRouteScreen extends StatelessWidget {
  final String message;

  const _InvalidRouteScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(message)),
    );
  }
}
