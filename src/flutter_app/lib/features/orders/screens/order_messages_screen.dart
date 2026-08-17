import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_models.dart';

class OrderMessagesScreen extends StatelessWidget {
  final OrderDetail order;
  final String businessType;

  const OrderMessagesScreen({
    super.key,
    required this.order,
    required this.businessType,
  });

  @override
  Widget build(BuildContext context) {
    final conversations = _conversations;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Messages'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            order.orderNo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a conversation',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...conversations.map(
            (conversation) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.14),
                  child: Icon(conversation.icon, color: AppColors.gold),
                ),
                title: Text(
                  conversation.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(conversation.role),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/orders/${order.id}/comments/${conversation.channel}'
                  '?title=${Uri.encodeComponent(conversation.name)}',
                ),
              ),
            ),
          ),
          if (conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'No conversations are available for this order yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_Conversation> get _conversations {
    if (businessType == 'Showroom') {
      return [
        _Conversation(
          name: order.createdForBusinessName,
          role: 'Shop',
          channel: 'ShowroomShop',
          icon: Icons.storefront_outlined,
        ),
      ];
    }

    return [
      _Conversation(
        name: order.orderFromBusinessName,
        role: 'Showroom',
        channel: 'ShowroomShop',
        icon: Icons.storefront_outlined,
      ),
      if (order.karigarName != null && order.karigarName!.isNotEmpty)
        _Conversation(
          name: order.karigarName!,
          role: 'Karigar',
          channel: 'ShopKarigar',
          icon: Icons.engineering_outlined,
        ),
    ];
  }
}

class _Conversation {
  final String name;
  final String role;
  final String channel;
  final IconData icon;

  const _Conversation({
    required this.name,
    required this.role,
    required this.channel,
    required this.icon,
  });
}
