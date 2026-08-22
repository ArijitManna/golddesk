import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/order_repository.dart';

class OrderCommentsScreen extends StatefulWidget {
  final String orderId;
  final String channel;
  final String? conversationTitle;

  const OrderCommentsScreen({
    super.key,
    required this.orderId,
    required this.channel,
    this.conversationTitle,
  });

  @override
  State<OrderCommentsScreen> createState() => _OrderCommentsScreenState();
}

class _OrderCommentsScreenState extends State<OrderCommentsScreen> {
  final _messageController = TextEditingController();
  List<OrderCommentData> _comments = [];
  bool _loading = true;
  bool _sending = false;

  String get _title =>
      widget.conversationTitle ??
      (widget.channel == 'ShopKarigar' ? 'Shop & Karigar' : 'Showroom & Shop');

  @override
  void initState() {
    super.initState();
    _load();
    _markMessagesRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesRead() async {
    try {
      await getIt<NotificationRepository>()
          .markOrderCommentNotificationsRead(widget.orderId);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _comments = await getIt<OrderRepository>()
          .getComments(widget.orderId, widget.channel);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() => _sending = true);
    try {
      await getIt<OrderRepository>().addComment(
        widget.orderId,
        channel: widget.channel,
        message: message,
      );
      _messageController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.surface,
              child: Text(
                'Private conversation — visible only to these businesses.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(child: Text('No messages yet.'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _comments.length,
                            itemBuilder: (_, index) {
                              final comment = _comments[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(comment.authorBusinessName,
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(comment.message),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat(AppConstants.displayDateTimeFormat)
                                            .format(comment.createdAt.toLocal()),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: 'Write a message…'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                          : const Icon(Icons.send, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
