import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/repositories/team_user_repository.dart';

class TeamUsersScreen extends StatefulWidget {
  const TeamUsersScreen({super.key});

  @override
  State<TeamUsersScreen> createState() => _TeamUsersScreenState();
}

class _TeamUsersScreenState extends State<TeamUsersScreen> {
  List<TeamUserData> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _users = await getIt<TeamUserRepository>().getTeamUsers();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Team User', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Same shop-owner access. They can manage orders, masters, and reports.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              GoldDeskTextField(label: 'Full Name *', hint: 'Name', controller: nameCtrl),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Login Email *',
                hint: 'email used to log in',
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Mobile *',
                hint: '10-digit number',
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Password *',
                hint: 'Min 6 characters',
                controller: passwordCtrl,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              GoldDeskButton(
                text: 'SAVE TEAM USER',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final email = emailCtrl.text.trim();
                  final mobile = mobileCtrl.text.trim();
                  final password = passwordCtrl.text;

                  if (name.isEmpty || email.isEmpty || !email.contains('@') || mobile.length != 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter name, valid email, and 10-digit mobile'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  try {
                    await getIt<TeamUserRepository>().createTeamUser(
                      fullName: name,
                      email: email,
                      mobile: mobile,
                      password: password,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Team user added. Login: $email'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
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
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deactivated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/settings'),
        ),
        title: const Text('Team Users'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'No team users yet. Tap + to add.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _users.length,
                        itemBuilder: (context, index) => _buildUserCard(_users[index]),
                      ),
                    ),
    );
  }

  Widget _buildUserCard(TeamUserData user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.divider,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(
              color: user.isActive ? AppColors.gold : AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (user.isCurrentUser) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${user.email}\n${user.mobile}${user.isActive ? '' : ' • Inactive'}',
          style: TextStyle(
            fontSize: 12,
            color: user.isActive ? AppColors.textSecondary : AppColors.textLight,
          ),
        ),
        isThreeLine: true,
        trailing: (!user.isCurrentUser && user.isActive)
            ? IconButton(
                icon: const Icon(Icons.person_off_outlined, color: AppColors.error, size: 20),
                tooltip: 'Deactivate',
                onPressed: () => _deactivate(user),
              )
            : Icon(
                user.isActive ? Icons.check_circle_outline : Icons.block,
                color: user.isActive ? AppColors.success : AppColors.textLight,
                size: 20,
              ),
      ),
    );
  }
}
