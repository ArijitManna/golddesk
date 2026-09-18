import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../core/widgets/message_icon_button.dart';
import '../../../core/widgets/order_image.dart';
import '../../../data/models/order_models.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/order_detail_cubit.dart';
import 'order_messages_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderDetailCubit>().loadOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDetailCubit, OrderDetailState>(
      builder: (context, state) {
        final canEdit =
            state is OrderDetailLoaded && _canEditOrder(state.order);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.navBar,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => context.go('/orders'),
            ),
            title: const Text(
              'Order Details',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.go('/orders/${widget.orderId}/edit'),
                  tooltip: 'Edit Order',
                ),
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () =>
                    context.go('/orders/${widget.orderId}/receipt'),
                tooltip: 'View Receipt',
              ),
              if (state is OrderDetailLoaded)
                MessageIconButton(
                  orderId: widget.orderId,
                  onPressed: () {
                    final auth = context.read<AuthBloc>().state;
                    final businessType =
                        auth is AuthAuthenticated ? auth.user.businessType : '';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderMessagesScreen(
                          order: state.order,
                          businessType: businessType,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: () {
            if (state is OrderDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }
            if (state is OrderDetailError) {
              return Center(child: Text(state.message));
            }
            if (state is OrderDetailLoaded) {
              return _buildDetail(context, state.order);
            }
            return const SizedBox();
          }(),
        );
      },
    );
  }

  Widget _buildDetail(BuildContext context, OrderDetail order) {
    final showReady = _isShop() &&
        (order.status == 'Assigned' || order.status == 'InProgress');
    final showDelivered = _isShop() && order.status == 'Ready';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(order),
          const SizedBox(height: 10),
          _buildInfoCard(order),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: showReady || showDelivered ? 2 : 1,
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/orders/${order.id}/timeline'),
                    icon: const Icon(Icons.timeline_outlined, size: 16),
                    label: const Text('Progress'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.primaryDark),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (showReady) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmMarkWorkReady(order),
                      icon: const Icon(Icons.verified_outlined, size: 16),
                      label: const Text('MARK WORK READY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusReady,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (showDelivered) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmMarkDelivered(order),
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      label: const Text('MARK DELIVERED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_canRespond(order)) ...[
            const SizedBox(height: 10),
            _buildResponseActions(order),
          ],
          const SizedBox(height: 14),
          _buildSectionTitle('Items'),
          const SizedBox(height: 6),
          ...order.items.map((item) => _buildItemRow(item)),
          const SizedBox(height: 6),
          _buildSummaryCard(order),
          if (_isShop()) ...[
            const SizedBox(height: 14),
            _buildSectionTitle('Karigar Assignment'),
            const SizedBox(height: 6),
            if (order.assignments.isNotEmpty)
              ...order.assignments.map((a) => _buildAssignmentCard(a)),
            if (_canAssignKarigar(order))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _buildAssignButton(
                  order,
                  label: order.assignments.isEmpty
                      ? 'Send to Karigar'
                      : 'Reassign',
                ),
              ),
          ],
          if (_canEditOrder(order)) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/orders/${order.id}/edit'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primaryDark),
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
          if (_isShop() && _canCancelOrder(order)) ...[
            const SizedBox(height: 8),
            _buildCancelButton(order),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(OrderDetail order) {
    return Row(
      children: [
        Expanded(
          child: Text(
            order.orderNo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _buildStatusChip(order.status, label: _displayOrderStatus(order)),
      ],
    );
  }

  Widget _buildInfoCard(OrderDetail order) {
    final dateChips = <Widget>[
      _compactChip(Icons.calendar_today_outlined, 'Order', order.orderDate),
      if (order.deliveryDate != null)
        _compactChip(Icons.local_shipping_outlined, 'Del', order.deliveryDate!),
      if (order.dueDate != null && order.dueDate!.isNotEmpty)
        _compactChip(Icons.alarm_outlined, 'Due', order.dueDate!),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dateChips,
          ),
          const SizedBox(height: 8),
          _infoRow(
            'Order From',
            order.orderFromBusinessName,
            icon: Icons.apartment_outlined,
          ),
          _infoRow(
            'Order To',
            order.createdForBusinessName,
            icon: Icons.storefront_outlined,
          ),
          _infoRow(
            'Accept',
            _displayAcceptanceStatus(order.acceptanceStatus),
            icon: Icons.thumb_up_alt_outlined,
          ),
          if (_isShop() && order.karigarName != null)
            _infoRow(
              'Karigar',
              order.karigarName!,
              icon: Icons.person_outline,
            ),
          if (order.notes != null && order.notes!.isNotEmpty)
            _infoRow(
              'Short Note',
              order.notes!,
              icon: Icons.notes_outlined,
            ),
        ],
      ),
    );
  }

  Widget _compactChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.pastelGold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.goldBronze),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  bool _canRespond(OrderDetail order) {
    return _isShop() && order.acceptanceStatus == 'Pending';
  }

  bool _canEditOrder(OrderDetail order) {
    if (order.status == 'Cancelled' || order.status == 'Closed') return false;
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) return false;
    final tenantId = state.user.tenantId;
    final isFulfillingShop =
        order.createdForBusinessId.isNotEmpty &&
        order.createdForBusinessId == tenantId;
    final isCreator =
        order.createdByBusinessId.isNotEmpty &&
        order.createdByBusinessId == tenantId;
    // Fallback for older payloads missing IDs: Shop can still edit.
    if (order.createdForBusinessId.isEmpty &&
        order.createdByBusinessId.isEmpty) {
      return _isShop() || _isShowroom();
    }
    return isFulfillingShop || isCreator;
  }

  bool _isShop() {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated && state.user.businessType == 'Shop';
  }

  bool _isShowroom() {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated && state.user.businessType == 'Showroom';
  }

  bool _canAssignKarigar(OrderDetail order) {
    if (!_isShop()) return false;
    if (order.acceptanceStatus != 'Accepted') return false;
    return order.status == 'Assigned' ||
        order.status == 'InProgress' ||
        order.status == 'Pending';
  }

  Widget _buildResponseActions(OrderDetail order) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.read<OrderDetailCubit>().respondToOrder(
              order.id,
              accept: false,
            ),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('REJECT'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.read<OrderDetailCubit>().respondToOrder(
              order.id,
              accept: true,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('ACCEPT ORDER'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmMarkWorkReady(OrderDetail order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark work ready?'),
        content: Text(
          'Mark ${order.orderNo} as Work Ready. Use this when Karigar already handed over the work offline and did not update status in the app. You can mark Delivered after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusReady,
            ),
            child: const Text('Mark Work Ready'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final updated = await context.read<OrderDetailCubit>().updateOrderStatus(
      order.id,
      status: 'Ready',
    );
    if (updated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as Work Ready'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _confirmMarkDelivered(OrderDetail order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark order delivered?'),
        content: Text(
          'Mark ${order.orderNo} as delivered to complete this work.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Mark Delivered'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final updated = await context.read<OrderDetailCubit>().updateOrderStatus(
      order.id,
      status: 'Delivered',
    );
    if (updated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as delivered'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _infoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.goldBronze),
            const SizedBox(width: 6),
          ],
          SizedBox(
            width: icon != null ? 88 : 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemDetail item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: item.imagePath != null
                ? () => showZoomableOrderImagePath(
                      context,
                      imagePath: item.imagePath!,
                      label: item.itemName,
                    )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imagePath != null
                  ? Image.network(
                      '${AppConstants.serverUrl}${item.imagePath}',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _itemPlaceholder(),
                    )
                  : _itemPlaceholder(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.scale_outlined,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        [
                          '${item.weight.toStringAsFixed(3)} gm',
                          if (item.size != null && item.size!.isNotEmpty)
                            'Sz ${item.size}',
                          '${item.quantity} pc',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item.amount > 0)
            Text(
              '\u20B9${item.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.goldBronze,
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.pastelGold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
    );
  }

  Widget _buildSummaryCard(OrderDetail order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.pastelGold.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          _summaryRow(
            Icons.monitor_weight_outlined,
            'Total Weight',
            '${order.totalWeight.toStringAsFixed(3)} gm',
          ),
          if (order.finalWeight != null)
            _summaryRow(
              Icons.fitness_center_outlined,
              'Final Weight',
              '${order.finalWeight!.toStringAsFixed(3)} gm',
            ),
          if (order.makingCharges > 0)
            _summaryRow(
              Icons.build_circle_outlined,
              'Making Charges',
              '\u20B9${order.makingCharges.toStringAsFixed(0)}',
            ),
          if (order.advancePaid > 0)
            _summaryRow(
              Icons.payments_outlined,
              'Advance Paid',
              '\u20B9${order.advancePaid.toStringAsFixed(0)}',
            ),
          if (order.estimatedAmount > 0) ...[
            const Divider(height: 10),
            _summaryRow(
              Icons.currency_rupee,
              'Estimated Amount',
              '\u20B9${order.estimatedAmount.toStringAsFixed(0)}',
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.goldBronze),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.goldBronze : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentDetail assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: assignment.isActive ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: assignment.isActive
              ? AppColors.gold.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: assignment.isActive
                ? AppColors.pastelGold
                : AppColors.divider,
            child: Icon(
              Icons.person_outline,
              size: 16,
              color: assignment.isActive
                  ? AppColors.goldBronze
                  : AppColors.textLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.karigarName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Due ${assignment.dueDate}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusChip(
            assignment.isActive ? 'Active' : assignment.status,
            label: _displayAssignmentStatus(assignment),
            small: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignButton(
    OrderDetail order, {
    String label = 'Send to Karigar',
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => context.go('/orders/${order.id}/assign'),
        icon: Icon(
          label == 'Reassign'
              ? Icons.swap_horiz
              : Icons.person_add_alt_1_outlined,
          size: 18,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldBronze,
          side: const BorderSide(color: AppColors.gold),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(OrderDetail order) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _confirmCancel(order),
        icon: const Icon(Icons.highlight_off_outlined, size: 18),
        label: const Text('Cancel Order'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(OrderDetail order) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel ${order.orderNo}? This cannot be undone.'
                '${order.assignments.any((a) => a.isActive) ? ' The Karigar assignment will be revoked.' : ''}',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cancellation comment *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a cancellation comment';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await context.read<OrderDetailCubit>().cancelOrder(
      order.id,
      reason: reasonCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  bool _canCancelOrder(OrderDetail order) {
    return order.status != 'Delivered' &&
        order.status != 'Closed' &&
        order.status != 'Cancelled';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildStatusChip(String status, {String? label, bool small = false}) {
    final color = _getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label ?? status,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.statusPending;
      case 'assigned':
        return AppColors.statusAssigned;
      case 'inprogress':
        return AppColors.statusInProgress;
      case 'ready':
        return AppColors.statusReady;
      case 'cancelled':
        return AppColors.statusCancelled;
      case 'active':
        return AppColors.success;
      case 'reassigned':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _displayOrderStatus(OrderDetail order) {
    final auth = context.read<AuthBloc>().state;
    final businessType = auth is AuthAuthenticated
        ? auth.user.businessType
        : 'Shop';

    return displayOrderStatus(
      businessType: businessType,
      status: order.status,
      acceptanceStatus: order.acceptanceStatus,
      assignmentStatus: order.assignmentStatus,
    );
  }

  String _displayAcceptanceStatus(String status) =>
      displayAcceptanceStatus(status);

  String _displayAssignmentStatus(AssignmentDetail assignment) =>
      displayAssignmentStatus(
        status: assignment.status,
        isActive: assignment.isActive,
      );
}
