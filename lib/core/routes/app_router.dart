import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/transaction_list_screen.dart'; // DEV-3: Import màn hình Giao dịch
import '../../presentation/screens/transaction_form_screen.dart'; // DEV-3: Import màn hình Form
import '../../domain/models/transaction_model.dart'; // DEV-3: Import Model
import '../../presentation/widgets/app_navigation_shell.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
    final homeBranchKey = GlobalKey<NavigatorState>(debugLabel: 'homeBranch');
    final transactionBranchKey = GlobalKey<NavigatorState>(debugLabel: 'transactionBranch'); // DEV-3: Key cho branch Giao dịch
    final profileBranchKey = GlobalKey<NavigatorState>(debugLabel: 'profileBranch');
    final settingsBranchKey = GlobalKey<NavigatorState>(debugLabel: 'settingsBranch');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final auth = authProvider;
        final isLoggingIn = state.matchedLocation == '/login';
        final isSplash = state.matchedLocation == '/splash';
        
        // Wait until AuthProvider finishes its initial load
        if (auth.isLoading && !isSplash) {
          return '/splash';
        }
        
        // User is not authenticated
        if (!auth.isAuthenticated) {
          if (isLoggingIn || isSplash) {
            return null; // Stay where we are
          }
          return '/login'; // Redirect to login
        }
        
        // User is authenticated
        if (isLoggingIn || isSplash) {
          return '/'; // Go to homepage
        }
        
        return null; // Keep going
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
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppNavigationShell(navigationShell: navigationShell);
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
            // DEV-3: Bổ sung StatefulShellBranch cho tab Giao dịch
            StatefulShellBranch(
              navigatorKey: transactionBranchKey,
              routes: [
                GoRoute(
                  path: '/transactions',
                  builder: (context, state) => const TransactionListScreen(),
                  routes: [
                    GoRoute(
                      path: 'create',
                      builder: (context, state) => const TransactionFormScreen(),
                    ),
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) {
                        final transaction = state.extra as TransactionModel?;
                        return TransactionFormScreen(transactionToEdit: transaction);
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
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: settingsBranchKey,
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
