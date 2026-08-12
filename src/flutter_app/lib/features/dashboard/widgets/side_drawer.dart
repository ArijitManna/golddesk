import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/auth_models.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return Column(
            children: [
              _buildHeader(context, user),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      onTap: () => _navigate(context, '/dashboard'),
                    ),
                    if (user?.role == 'SuperAdmin')
                      _buildMenuItem(
                        context,
                        icon: Icons.approval_outlined,
                        label: 'Pending Approvals',
                        onTap: () => _navigate(context, '/admin/approvals'),
                        color: AppColors.gold,
                      ),
                    _buildMenuItem(
                      context,
                      icon: Icons.add_box_outlined,
                      label: 'New Order',
                      onTap: () => _navigate(context, '/orders/new'),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.list_alt_outlined,
                      label: 'Order List',
                      onTap: () => _navigate(context, '/orders'),
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      icon: Icons.engineering_outlined,
                      label: 'Karigar Master',
                      onTap: () => _navigate(context, '/karigars'),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.people_outlined,
                      label: 'Customer Master',
                      onTap: () => _navigate(context, '/customers'),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.diamond_outlined,
                      label: 'Item Master',
                      onTap: () => _navigate(context, '/items'),
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      icon: Icons.bar_chart_outlined,
                      label: 'Reports',
                      onTap: () => _navigate(context, '/reports'),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () => _navigate(context, '/notifications'),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => _navigate(context, '/settings'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildMenuItem(
                context,
                icon: Icons.logout,
                label: 'Logout',
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserInfo? user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
      decoration: const BoxDecoration(color: AppColors.primaryDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/logo.png', width: 160, height: 60, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text(
            user?.shopName ?? AppConstants.appName,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.fullName ?? '',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primaryDark, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  void _navigate(BuildContext context, String path) {
    Navigator.pop(context);
    context.go(path);
  }
}
