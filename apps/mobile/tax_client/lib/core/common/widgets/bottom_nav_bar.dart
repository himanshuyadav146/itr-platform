import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';

/// Main app tab bar — matches Figma Welcome Dashboard `Nav` (auth shell + gradient).
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    if (location == '/') {
      return 0;
    }
    if (location.startsWith('/orders')) {
      return 1;
    }
    if (location.startsWith('/more')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).bottomNavigationBarTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.navBarGradient,
        border: Border(
          top: BorderSide(color: AppColors.borderOnDark),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: AppStrings.navDashboard,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: AppStrings.navOrders,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: AppStrings.navMore,
            ),
          ],
          currentIndex: _calculateSelectedIndex(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: navTheme.selectedItemColor,
          unselectedItemColor: navTheme.unselectedItemColor,
          selectedLabelStyle: navTheme.selectedLabelStyle,
          unselectedLabelStyle: navTheme.unselectedLabelStyle,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) => _onItemTapped(context, index),
        ),
      ),
    );
  }
}
