import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../providers/auth_provider.dart';

class AppNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.user?.roleId == 'admin';

    final desktopLayout = Row(
      children: [
        // Side Navigation Rail for Desktop/Tablet/Landscape
        SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 30,
              ),
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => _onTap(context, index),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: isDark ? AppDesignTokens.darkSurface : Colors.white,
                  elevation: 1,
                  minWidth: 72,
                  leading: Column(
                    children: [
                      const SizedBox(height: AppDesignTokens.spaceXs),
                      Container(
                        padding: const EdgeInsets.all(AppDesignTokens.spaceXs),
                        decoration: BoxDecoration(
                          gradient: AppDesignTokens.primaryGradient,
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spaceSm),
                    ],
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                    size: 20,
                  ),
                  selectedIconTheme: const IconThemeData(
                    color: AppDesignTokens.primary,
                    size: 20,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppDesignTokens.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                    fontSize: 10,
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Tổng quan'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('Giao dịch'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Hóa đơn'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Cá nhân'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Cài đặt'),
                    ),
                    if (isAdmin)
                      const NavigationRailDestination(
                        icon: Icon(Icons.people_alt_outlined),
                        selectedIcon: Icon(Icons.people_alt),
                        label: Text('Quản lý User'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        // Main content area
        Expanded(
          child: navigationShell,
        ),
      ],
    );

    return Scaffold(
      body: AppResponsiveLayout(
        mobile: navigationShell,
        tablet: desktopLayout,
        desktop: desktopLayout,
      ),
      bottomNavigationBar: context.isMobile
          ? Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppDesignTokens.darkBorder : AppDesignTokens.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(context, index),
          backgroundColor: isDark ? AppDesignTokens.darkSurface : Colors.white,
          selectedItemColor: AppDesignTokens.primary,
          unselectedItemColor: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          iconSize: 22,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Tổng quan',
            ),
            // DEV-3: Thêm tab Giao dịch trong BottomNavigationBar
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Giao dịch',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Hóa đơn',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Cài đặt',
            ),
            if (isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined),
                activeIcon: Icon(Icons.people_alt),
                label: 'Quản lý User',
              ),
          ],
        ),
      )
    : null,
  );
  }
}
