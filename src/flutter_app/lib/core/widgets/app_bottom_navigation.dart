import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../constants/app_colors.dart';
import '../utils/role_navigation.dart';

class AppBottomNavigation extends StatelessWidget {
  final String selectedPath;

  const AppBottomNavigation({super.key, required this.selectedPath});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    final isKarigar = isKarigarUser(user);
    final isShop = user?.businessType == 'Shop';
    final dashboardPath = isKarigar ? '/karigar/dashboard' : '/dashboard';
    final ordersPath = isKarigar ? '/karigar/orders' : '/orders';
    final destinations = <_Destination>[
      _Destination('Dashboard', Icons.dashboard_outlined, dashboardPath),
      _Destination(
        isKarigar ? 'My Orders' : 'Orders',
        Icons.receipt_long_outlined,
        ordersPath,
      ),
      const _Destination('Reports', Icons.bar_chart_outlined, '/reports'),
      if (isShop || isKarigar)
        const _Destination('Profile', Icons.person_outline, '/settings'),
    ];
    final index = destinations.indexWhere((item) => item.path == selectedPath);

    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (value) => context.go(destinations[value].path),
      backgroundColor: Colors.white,
      indicatorColor: AppColors.gold.withValues(alpha: 0.18),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: destinations
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.icon, color: AppColors.gold),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final String path;

  const _Destination(this.label, this.icon, this.path);
}
