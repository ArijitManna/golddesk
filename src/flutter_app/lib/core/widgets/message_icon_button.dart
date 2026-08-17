import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../di/injection.dart';
import '../../data/repositories/notification_repository.dart';

class MessageIconButton extends StatefulWidget {
  final String orderId;
  final VoidCallback onPressed;
  final String tooltip;

  const MessageIconButton({
    super.key,
    required this.orderId,
    required this.onPressed,
    this.tooltip = 'Messages',
  });

  @override
  State<MessageIconButton> createState() => _MessageIconButtonState();
}

class _MessageIconButtonState extends State<MessageIconButton> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  @override
  void didUpdateWidget(covariant MessageIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _loadCount();
    }
  }

  Future<void> _loadCount() async {
    try {
      final count = await getIt<NotificationRepository>().getUnreadCount(
        type: 'CommentAdded',
        orderId: widget.orderId,
      );
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _open() async {
    widget.onPressed();
    try {
      await getIt<NotificationRepository>()
          .markOrderCommentNotificationsRead(widget.orderId);
      if (mounted) setState(() => _unreadCount = 0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      onPressed: _open,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
