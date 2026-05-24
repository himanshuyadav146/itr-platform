import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
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
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: AppStrings.navDashboard,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: AppStrings.navOrders,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: AppStrings.navMore,
        ),
      ],
      currentIndex: _calculateSelectedIndex(context),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      onTap: (int index) => _onItemTapped(context, index),
    );
  }
}
