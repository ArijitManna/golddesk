import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/team_user_repository.dart';

class TeamUserDetailScreen extends StatefulWidget {
  final String userId;
  final TeamUserData? initialUser;

  const TeamUserDetailScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  State<TeamUserDetailScreen> createState() => _TeamUserDetailScreenState();
}

class _TeamUserDetailScreenState extends State<TeamUserDetailScreen> {
  TeamUserData? _user;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    if (_user == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await getIt<TeamUserRepository>().getTeamUsers();
      final match = users.where((u) => u.id == widget.userId);
      _user = match.isEmpty ? null : match.first;
      if (_user == null) _error = 'Team user not found';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings/team-users');
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _showResetPasswordDialog(TeamUserData user) async {
    final ownerCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var saving = false;
    var showPasswords = false;
    String? dialogError;

    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> submit() async {
            final ownerPassword = ownerCtrl.text;
            final newPassword = newCtrl.text;
            String? validation;
            if (ownerPassword.isEmpty) {
              validation = 'Enter your own password to confirm';
            } else if (newPassword.length < 6) {
              validation = 'New password must be at least 6 characters';
            } else if (newPassword != confirmCtrl.text) {
              validation = 'New passwords do not match';
            }
            if (validation != null) {
              setDialogState(() => dialogError = validation);
              return;
            }

            setDialogState(() {
              saving = true;
              dialogError = null;
            });
            try {
              await getIt<TeamUserRepository>().resetTeamUserPassword(
                userId: user.id,
                ownerPassword: ownerPassword,
                newPassword: newPassword,
              );
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              setDialogState(() {
                saving = false;
                dialogError = '$e';
              });
            }
          }

          InputDecoration decoration(String label) => InputDecoration(
                labelText: label,
                isDense: true,
              );

          return AlertDialog(
            title: const Text('Reset Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set a new login password for ${user.fullName}.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ownerCtrl,
                    obscureText: !showPasswords,
                    enabled: !saving,
                    decoration: decoration('Your Password').copyWith(
                      helperText: 'To confirm it is you',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: !showPasswords,
                    enabled: !saving,
                    decoration: decoration('New Password for Team User')
                        .copyWith(helperText: 'Min 6 characters'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: !showPasswords,
                    enabled: !saving,
                    decoration: decoration('Confirm New Password'),
                    onSubmitted: (_) => saving ? null : submit(),
                  ),
                  CheckboxListTile(
                    value: showPasswords,
                    onChanged: saving
                        ? null
                        : (v) => setDialogState(() => showPasswords = v ?? false),
                    title: const Text('Show passwords', style: TextStyle(fontSize: 13)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  if (dialogError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dialogError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving ? null : submit,
                child: Text(saving ? 'Saving...' : 'Reset'),
              ),
            ],
          );
        },
      ),
    );

    ownerCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();

    if (done == true && mounted) {
      _showSnack('Password reset for ${user.fullName}. Share the new password with them.');
    }
  }

  Future<void> _deactivate(TeamUserData user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Deactivate ${user.fullName}? They will no longer be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await getIt<TeamUserRepository>().deactivateTeamUser(user.id);
      if (mounted) _showSnack('User deactivated');
      await _load();
    } catch (e) {
      if (mounted) _showSnack('Error: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _close,
        ),
        title: const Text('Team User'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error ?? 'Team user not found',
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: 16),
                      _buildDetails(user),
                      const SizedBox(height: 24),
                      ..._buildActions(user),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(TeamUserData user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor:
              user.isActive ? AppColors.gold.withValues(alpha: 0.15) : AppColors.divider,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 28,
              color: user.isActive ? AppColors.gold : AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _chip(
              user.isActive ? 'Active' : 'Inactive',
              user.isActive ? AppColors.success : AppColors.textLight,
            ),
            if (user.isCurrentUser) _chip('You', AppColors.primaryDark),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildDetails(TeamUserData user) {
    final dateFmt = DateFormat('d MMM yyyy');
    final dateTimeFmt = DateFormat('d MMM yyyy, h:mm a');
    return Card(
      child: Column(
        children: [
          _detailRow(Icons.email_outlined, 'Login Email', user.email),
          const Divider(height: 1),
          _detailRow(Icons.phone_outlined, 'Mobile', user.mobile.isEmpty ? '-' : user.mobile),
          const Divider(height: 1),
          _detailRow(Icons.admin_panel_settings_outlined, 'Access', 'Full shop access'),
          const Divider(height: 1),
          _detailRow(
            Icons.calendar_today_outlined,
            'Added On',
            dateFmt.format(user.createdAt.toLocal()),
          ),
          const Divider(height: 1),
          _detailRow(
            Icons.login,
            'Last Login',
            user.lastLoginAt != null
                ? dateTimeFmt.format(user.lastLoginAt!.toLocal())
                : 'Never',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.gold, size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: SelectableText(
        value,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      ),
    );
  }

  List<Widget> _buildActions(TeamUserData user) {
    if (user.isCurrentUser) {
      return const [
        Text(
          'This is your account. Use Settings > Change Password to change your own password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ];
    }

    return [
      SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => _showResetPasswordDialog(user),
          icon: const Icon(Icons.lock_reset),
          label: const Text('Reset Password'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      if (user.isActive) ...[
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _deactivate(user),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Deactivate User'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    ];
  }
}
