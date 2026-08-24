import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/role_navigation.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _notifications = await getIt<NotificationRepository>().getNotifications();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _markAllRead() async {
    try {
      await getIt<NotificationRepository>().markAllAsRead();
      _load();
    } catch (_) {}
  }

  Future<void> _markRead(NotificationItem item) async {
    if (!item.isRead) {
      try {
        await getIt<NotificationRepository>().markAsRead(item.id);
        _load();
      } catch (_) {}
    }
    if (!mounted) return;

    if (item.type == 'RegistrationRequested') {
      context.go('/admin/approvals');
      return;
    }

    if (item.orderId != null) {
      final authState = context.read<AuthBloc>().state;
      final user = authState is AuthAuthenticated ? authState.user : null;
      if (isKarigarUser(user)) {
        context.go('/karigar/orders/${item.orderId}/update');
      } else {
        context.go('/orders/${item.orderId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go(homePathForAuthState(authState)),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark All Read', style: TextStyle(color: AppColors.gold, fontSize: 12)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppColors.textLight),
                      SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) => _buildNotificationTile(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    final icon = _getIcon(item.type);
    final color = _getColor(item.type);
    final timeAgo = _formatTime(item.createdAt);

    return InkWell(
      onTap: () => _markRead(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: item.isRead ? null : AppColors.gold.withValues(alpha: 0.04),
          border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.message,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'AssignmentCreated': return Icons.assignment_ind;
      case 'DueSoon3Days':
      case 'DueSoon2Days':
      case 'DueSoon1Day': return Icons.schedule;
      case 'DueToday': return Icons.today;
      case 'Overdue': return Icons.warning_amber;
      case 'StatusChangedToReady': return Icons.check_circle;
      case 'OrderReassigned': return Icons.swap_horiz;
      case 'CommentAdded': return Icons.chat_bubble_outline;
      case 'ConnectionRequested': return Icons.person_add_alt_1;
      case 'ConnectionAccepted': return Icons.handshake_outlined;
      case 'OrderAccepted': return Icons.task_alt;
      case 'OrderRejected': return Icons.cancel_outlined;
      case 'RegistrationRequested': return Icons.approval_outlined;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'AssignmentCreated': return AppColors.statusAssigned;
      case 'DueSoon3Days': return AppColors.due3Days;
      case 'DueSoon2Days': return AppColors.due2Days;
      case 'DueSoon1Day': return AppColors.due1Day;
      case 'DueToday': return AppColors.statusPending;
      case 'Overdue': return AppColors.statusOverdue;
      case 'StatusChangedToReady': return AppColors.statusReady;
      case 'OrderReassigned': return AppColors.statusInProgress;
      case 'CommentAdded': return AppColors.gold;
      case 'ConnectionRequested': return AppColors.statusPending;
      case 'ConnectionAccepted': return AppColors.statusReady;
      case 'OrderAccepted': return AppColors.statusReady;
      case 'OrderRejected': return AppColors.error;
      case 'RegistrationRequested': return AppColors.statusPending;
      default: return AppColors.gold;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
