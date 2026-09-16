import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/role_navigation.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.drawerBackground,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          final isSuperAdmin = user?.role == 'SuperAdmin';
          final isKarigar = isKarigarUser(user);
          final isShop = user?.businessType == 'Shop';

          return Column(
            children: [
              _buildHeader(context, user),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  children: [
                    if (isSuperAdmin) ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        onTap: () => _navigate(context, '/dashboard'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.approval_outlined,
                        label: 'Pending Approvals',
                        onTap: () => _navigate(context, '/admin/approvals'),
                      ),
                    ] else if (isKarigar) ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        label: 'My Work',
                        onTap: () => _navigate(context, '/karigar/dashboard'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.assignment_outlined,
                        label: 'My Orders',
                        onTap: () => _navigate(context, '/karigar/orders'),
                      ),
                      _dottedDivider(),
                      _buildMenuItem(
                        context,
                        icon: Icons.hub_outlined,
                        label: 'Connections',
                        onTap: () => _navigate(context, '/connections'),
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
                    ] else ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        onTap: () => _navigate(context, '/dashboard'),
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
                      _dottedDivider(),
                      if (isShop)
                        _buildMenuItem(
                          context,
                          icon: Icons.people_outlined,
                          label: 'External Customers',
                          onTap: () =>
                              _navigate(context, '/external-businesses'),
                        ),
                      _buildMenuItem(
                        context,
                        icon: Icons.diamond_outlined,
                        label: 'Item Master',
                        onTap: () => _navigate(context, '/items'),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.hub_outlined,
                        label: 'Connections',
                        onTap: () => _navigate(context, '/connections'),
                      ),
                      _dottedDivider(),
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Column(
                  children: [
                    _dottedDivider(),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () {
                        final authBloc = context.read<AuthBloc>();
                        Navigator.pop(context);
                        authBloc.add(AuthLogoutRequested());
                        context.go('/login');
                      },
                      destructive: true,
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserInfo? user) {
    final title = user?.role == 'SuperAdmin'
        ? 'Platform Admin'
        : (user?.shopName ?? AppConstants.appName);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243447), AppColors.drawerBackground],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 150,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.drawerItem.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((user?.fullName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.fullName,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (user?.goldDeskId.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${user!.businessType} • ${user.goldDeskId}',
                    style: TextStyle(
                      color: AppColors.textOnDark.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (user != null && user.role != 'SuperAdmin') ...[
            const SizedBox(height: 10),
            FutureBuilder<List<UserInfo>>(
              future: getIt<AuthRepository>().getProfiles(),
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? const <UserInfo>[];
                if (profiles.length < 2) return const SizedBox.shrink();

                return OutlinedButton.icon(
                  onPressed: () => _showProfilePicker(context, user, profiles),
                  icon: const Icon(Icons.switch_account, size: 18),
                  label: const Text('Switch business'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    minimumSize: const Size(0, 36),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showProfilePicker(
    BuildContext context,
    UserInfo activeUser,
    List<UserInfo> profiles,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Switch business',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ...profiles.map(
              (profile) => ListTile(
                leading: Icon(
                  profile.tenantId == activeUser.tenantId
                      ? Icons.check_circle
                      : Icons.storefront_outlined,
                  color: profile.tenantId == activeUser.tenantId
                      ? AppColors.gold
                      : AppColors.primaryDark,
                ),
                title: Text(profile.shopName),
                subtitle: Text(
                  '${profile.businessType} • ${profile.goldDeskId}',
                ),
                onTap: profile.tenantId == activeUser.tenantId
                    ? () => Navigator.pop(sheetContext)
                    : () {
                        Navigator.pop(sheetContext);
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(
                              AuthProfileSwitchRequested(profile.tenantId),
                            );
                        context.go(homePathForUser(profile));
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dottedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 4.0;
          const dashSpace = 4.0;
          final count =
              (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                width: dashWidth,
                height: 1,
                color: AppColors.gold.withValues(alpha: 0.35),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final accent = destructive ? AppColors.error : AppColors.gold;
    final textColor =
        destructive ? AppColors.error : AppColors.textOnDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.drawerItem,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withValues(alpha: destructive ? 0.35 : 0.18),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: accent, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String path) {
    Navigator.pop(context);
    context.go(path);
  }
}
