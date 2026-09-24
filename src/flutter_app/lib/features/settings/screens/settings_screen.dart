import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/dashboard_preferences.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAtAGlance = true;
  bool _showLiveGoldRate = true;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardPrefs();
  }

  Future<void> _loadDashboardPrefs() async {
    final glance = await DashboardPreferences.isAtAGlanceVisible();
    final gold = await DashboardPreferences.isLiveGoldRateVisible();
    if (!mounted) return;
    setState(() {
      _showAtAGlance = glance;
      _showLiveGoldRate = gold;
      _prefsLoaded = true;
    });
  }

  Future<void> _setAtAGlanceVisible(bool value) async {
    setState(() => _showAtAGlance = value);
    await DashboardPreferences.setAtAGlanceVisible(value);
  }

  Future<void> _setLiveGoldRateVisible(bool value) async {
    setState(() => _showLiveGoldRate = value);
    await DashboardPreferences.setLiveGoldRateVisible(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNavigation(selectedPath: '/settings'),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, packageSnapshot) {
          final appVersion =
              packageSnapshot.data?.version ?? AppConstants.appVersion;
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state is AuthAuthenticated ? state.user : null;
              final canToggleGlance =
                  user?.businessType == 'Shop' ||
                  user?.businessType == 'Showroom';
              final topInset = MediaQuery.of(context).padding.top;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildProfileHeader(user, topInset),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Account'),
                              _settingsTile(
                                icon: Icons.person_outline,
                                title: 'Edit Profile',
                                subtitle:
                                    'Shop name, address, GST, company logo',
                                onTap: () =>
                                    context.go('/settings/edit-profile'),
                              ),
                              _settingsTile(
                                icon: Icons.lock_outline,
                                title: 'Change Password',
                                subtitle: 'Update your login password',
                                onTap: () =>
                                    _showChangePasswordDialog(context),
                              ),
                              if (user?.businessType == 'Shop' ||
                                  user?.businessType == 'Showroom')
                                _settingsTile(
                                  icon: Icons.group_outlined,
                                  title: 'Team Users',
                                  subtitle:
                                      'Add co-users with shop owner access',
                                  onTap: () =>
                                      context.go('/settings/team-users'),
                                ),
                              const SizedBox(height: 14),
                              _sectionTitle('Notifications'),
                              _settingsTile(
                                icon: Icons.notifications_outlined,
                                title: 'Notification Preferences',
                                subtitle: 'Configure due-date reminders',
                                onTap: () => context
                                    .go('/settings/notification-prefs'),
                              ),
                              if (canToggleGlance) ...[
                                const SizedBox(height: 14),
                                _sectionTitle('Dashboard'),
                                _settingsSwitchTile(
                                  icon: Icons.dashboard_customize_outlined,
                                  title: 'At a Glance',
                                  subtitle:
                                      'Show Total / Direct / Showroom summary on dashboard',
                                  value: _showAtAGlance,
                                  onChanged: _prefsLoaded
                                      ? _setAtAGlanceVisible
                                      : null,
                                ),
                                if (user?.businessType == 'Shop')
                                  _settingsSwitchTile(
                                    icon: Icons.trending_up,
                                    title: 'Live Gold Rate',
                                    subtitle:
                                        'Show 24K / 22K market rate card on dashboard',
                                    value: _showLiveGoldRate,
                                    onChanged: _prefsLoaded
                                        ? _setLiveGoldRateVisible
                                        : null,
                                  ),
                              ],
                              const SizedBox(height: 14),
                              _sectionTitle('App'),
                              _settingsTile(
                                icon: Icons.info_outline,
                                title: 'About',
                                subtitle:
                                    '${AppConstants.appName} v$appVersion',
                                onTap: () =>
                                    _showAboutDialog(context, appVersion),
                              ),
                              _settingsTile(
                                icon: Icons.description_outlined,
                                title: 'Terms & Privacy',
                                subtitle: 'View terms of service',
                                onTap: () {},
                              ),
                              const SizedBox(height: 20),
                              _logoutButton(),
                              const SizedBox(height: 28),
                              Center(
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/logo.png',
                                      width: 80,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Version $appVersion',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserInfo? user, double topInset) {
    final initial = (user?.fullName ?? 'U').trim().isEmpty
        ? 'U'
        : (user!.fullName.trim()[0].toUpperCase());

    return SizedBox(
      height: topInset + 210,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: topInset + 110,
            width: double.infinity,
            color: AppColors.navBar,
          ),
          Positioned(
            left: 16,
            right: 16,
            top: topInset + 28,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.goldLight,
                    AppColors.gold,
                    AppColors.goldBronze,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    user?.fullName ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F0E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.goldBronze,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if ((user?.shopName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user!.shopName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: topInset + 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.goldBronze],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navBar,
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFF2A3A4E),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _iconBox(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.gold.withValues(alpha: 0.85),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.gold,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold, width: 1.2),
        color: AppColors.gold.withValues(alpha: 0.06),
      ),
      child: Icon(icon, color: AppColors.gold, size: 20),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<AuthBloc>().add(AuthLogoutRequested());
          context.go('/login');
        },
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text(
          'Logout',
          style: TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await getIt<AuthRepository>().changePassword(
                          currentPassword: currentCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, String appVersion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              AppConstants.appName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              AppConstants.appTagline,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Version $appVersion',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            const Text(
              'A lightweight business network for Showrooms, Shops, and Karigars to manage work orders and track completion.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
