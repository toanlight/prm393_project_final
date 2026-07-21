import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/responsive_helper.dart';
import '../../domain/services/rbac_permission_service.dart';
import '../providers/auth_provider.dart';

class _NavItem {
  final int branchIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.branchIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class AppNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigationShell({
    super.key,
    required this.navigationShell,
  });

  List<_NavItem> _getVisibleItems(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    final allItems = [
      const _NavItem(
        branchIndex: 0,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Tổng quan',
      ),
      if (RbacPermissionService.canViewTransactions(user))
        const _NavItem(
          branchIndex: 1,
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet,
          label: 'Giao dịch',
        ),
      if (RbacPermissionService.canViewInvoices(user))
        const _NavItem(
          branchIndex: 2,
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long,
          label: 'Hóa đơn',
        ),
      const _NavItem(
        branchIndex: 3,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Cá nhân',
      ),
      const _NavItem(
        branchIndex: 4,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Cài đặt',
      ),
      if (RbacPermissionService.canManageUsers(user))
        const _NavItem(
          branchIndex: 5,
          icon: Icons.people_alt_outlined,
          activeIcon: Icons.people_alt,
          label: 'Quản lý User',
        ),
    ];

    return allItems;
  }

  void _onTap(BuildContext context, List<_NavItem> visibleItems, int visibleIndex) {
    if (visibleIndex < 0 || visibleIndex >= visibleItems.length) return;
    final targetBranch = visibleItems[visibleIndex].branchIndex;
    navigationShell.goBranch(
      targetBranch,
      initialLocation: targetBranch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleItems = _getVisibleItems(context);

    // Find the matching index in visibleItems array for the active branch
    int currentVisibleIndex = visibleItems.indexWhere(
      (item) => item.branchIndex == navigationShell.currentIndex,
    );
    if (currentVisibleIndex < 0) {
      currentVisibleIndex = 0;
    }

    final railDestinations = visibleItems.map((item) {
      return NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.activeIcon),
        label: Text(item.label),
      );
    }).toList();

    final navBarItems = visibleItems.map((item) {
      return BottomNavigationBarItem(
        icon: Icon(item.icon),
        activeIcon: Icon(item.activeIcon),
        label: item.label,
      );
    }).toList();

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
                  selectedIndex: currentVisibleIndex,
                  onDestinationSelected: (index) => _onTap(context, visibleItems, index),
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
                  destinations: railDestinations,
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
                currentIndex: currentVisibleIndex,
                onTap: (index) => _onTap(context, visibleItems, index),
                backgroundColor: isDark ? AppDesignTokens.darkSurface : Colors.white,
                selectedItemColor: AppDesignTokens.primary,
                unselectedItemColor: isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.lightTextSecondary,
                showUnselectedLabels: true,
                selectedFontSize: 11,
                unselectedFontSize: 10,
                iconSize: 22,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                items: navBarItems,
              ),
            )
          : null,
    );
  }
}
