import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/tenant_repository.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _due3 = true;
  bool _due2 = true;
  bool _due1 = true;
  bool _dueToday = true;
  bool _overdue = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await getIt<TenantRepository>().getProfile();
      _due3 = profile.notifyDueSoon3Days;
      _due2 = profile.notifyDueSoon2Days;
      _due1 = profile.notifyDueSoon1Day;
      _dueToday = profile.notifyDueToday;
      _overdue = profile.notifyOverdue;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await getIt<TenantRepository>().updateNotificationPrefs(
        notifyDueSoon3Days: _due3,
        notifyDueSoon2Days: _due2,
        notifyDueSoon1Day: _due1,
        notifyDueToday: _dueToday,
        notifyOverdue: _overdue,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
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
        title: const Text('Notification Reminders'),
        actions: [
          TextButton(
            onPressed: _loading || _saving ? null : _save,
            child: Text(
              _saving ? 'Saving...' : 'Save',
              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _loading
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Choose which due-date reminders your shop should receive.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _switchTile(
                      title: 'Due in 3 days',
                      subtitle: 'Reminder when order is due in 3 days',
                      value: _due3,
                      onChanged: (v) => setState(() => _due3 = v),
                    ),
                    _switchTile(
                      title: 'Due in 2 days',
                      subtitle: 'Reminder when order is due in 2 days',
                      value: _due2,
                      onChanged: (v) => setState(() => _due2 = v),
                    ),
                    _switchTile(
                      title: 'Due tomorrow',
                      subtitle: 'Reminder one day before due date',
                      value: _due1,
                      onChanged: (v) => setState(() => _due1 = v),
                    ),
                    _switchTile(
                      title: 'Due today',
                      subtitle: 'Reminder on the due date',
                      value: _dueToday,
                      onChanged: (v) => setState(() => _dueToday = v),
                    ),
                    _switchTile(
                      title: 'Overdue',
                      subtitle: 'Alert when order is past due date',
                      value: _overdue,
                      onChanged: (v) => setState(() => _overdue = v),
                    ),
                  ],
                ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        value: value,
        activeThumbColor: AppColors.gold,
        onChanged: onChanged,
      ),
    );
  }
}
