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
    final selectedIndex = index < 0 ? 0 : index;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBar,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => context.go(destinations[i].path),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(destination.icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            destination.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  final String label;
  final IconData icon;
  final String path;

  const _Destination(this.label, this.icon, this.path);
}
