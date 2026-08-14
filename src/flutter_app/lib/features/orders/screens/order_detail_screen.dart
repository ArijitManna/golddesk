import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order_models.dart';
import '../bloc/order_detail_cubit.dart';

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
        final canEdit = state is OrderDetailLoaded && state.order.status == 'Pending';
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => context.go('/orders'),
            ),
            title: const Text('Order Details'),
            actions: [
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.go('/orders/${widget.orderId}/edit'),
                  tooltip: 'Edit Order',
                ),
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () => context.go('/orders/${widget.orderId}/receipt'),
                tooltip: 'View Receipt',
              ),
            ],
          ),
          body: () {
            if (state is OrderDetailLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(order),
          const SizedBox(height: 16),
          // Info card
          _buildInfoCard(order),
          const SizedBox(height: 16),
          // Items
          _buildSectionTitle('Items'),
          const SizedBox(height: 8),
          ...order.items.map((item) => _buildItemRow(item)),
          const SizedBox(height: 16),
          // Summary
          _buildSummaryCard(order),
          const SizedBox(height: 16),
          // Assignment
          _buildSectionTitle('Karigar Assignment'),
          const SizedBox(height: 8),
          if (order.assignments.isNotEmpty)
            ...order.assignments.map((a) => _buildAssignmentCard(a)),
          if (order.status == 'Assigned' || order.status == 'InProgress' || order.status == 'Pending')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildAssignButton(order, label: order.assignments.isEmpty ? 'Send to Karigar' : 'Reassign'),
            ),
          if (order.status == 'Pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/orders/${order.id}/edit'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primaryDark),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNo, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(order.customerName, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        _buildStatusChip(order.status),
      ],
    );
  }

  Widget _buildInfoCard(OrderDetail order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _infoRow('Order Date', order.orderDate),
          if (order.deliveryDate != null)
            _infoRow('Delivery Date', order.deliveryDate!),
          if (order.dueDate != null)
            _infoRow('Due Date', order.dueDate!),
          if (order.karigarName != null)
            _infoRow('Karigar', order.karigarName!),
          if (order.notes != null && order.notes!.isNotEmpty)
            _infoRow('Notes', order.notes!),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemDetail item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item image - tap to view full size
            GestureDetector(
              onTap: item.imagePath != null ? () => _showFullImage(item.imagePath!, item.itemName) : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imagePath != null
                    ? Image.network(
                        '${AppConstants.serverUrl}${item.imagePath}',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _itemPlaceholder(),
                      )
                    : _itemPlaceholder(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '${item.weight.toStringAsFixed(3)} gm',
                      if (item.size != null && item.size!.isNotEmpty) 'Size ${item.size}',
                      '${item.quantity} pc',
                    ].join(' | '),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (item.amount > 0)
              Text(
                '\u20B9${item.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(String imagePath, String itemName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${AppConstants.serverUrl}$imagePath',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    color: AppColors.surface,
                    child: const Center(child: Text('Image not available')),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
            // Item name at bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    itemName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Icon(Icons.diamond_outlined, color: AppColors.gold, size: 22),
    );
  }

  Widget _buildSummaryCard(OrderDetail order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _summaryRow('Total Weight', '${order.totalWeight.toStringAsFixed(3)} gm'),
          if (order.makingCharges > 0)
            _summaryRow('Making Charges', '\u20B9${order.makingCharges.toStringAsFixed(0)}'),
          if (order.advancePaid > 0)
            _summaryRow('Advance Paid', '\u20B9${order.advancePaid.toStringAsFixed(0)}'),
          if (order.estimatedAmount > 0) ...[
            const Divider(),
            _summaryRow('Estimated Amount', '\u20B9${order.estimatedAmount.toStringAsFixed(0)}', bold: true),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentDetail assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: assignment.isActive ? null : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: assignment.isActive ? AppColors.gold.withValues(alpha: 0.15) : AppColors.divider,
              child: Icon(Icons.engineering, size: 18,
                  color: assignment.isActive ? AppColors.gold : AppColors.textLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.karigarName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Due: ${assignment.dueDate}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            _buildStatusChip(assignment.isActive ? 'Active' : assignment.status, small: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignButton(OrderDetail order, {String label = 'Send to Karigar'}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.go('/orders/${order.id}/assign'),
        icon: const Icon(Icons.assignment_ind, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCancelButton(OrderDetail order) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmCancel(order),
        icon: const Icon(Icons.cancel_outlined, size: 18),
        label: const Text('Cancel Order'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(OrderDetail order) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel ${order.orderNo}? This cannot be undone.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Order')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await context.read<OrderDetailCubit>().cancelOrder(
          order.id,
          reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled'), backgroundColor: AppColors.success),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }

  Widget _buildStatusChip(String status, {bool small = false}) {
    final color = _getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'Assigned'
            ? 'Send to Karigar'
            : status == 'InProgress'
                ? 'In Progress'
                : status,
        style: TextStyle(color: color, fontSize: small ? 10 : 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.statusPending;
      case 'assigned': return AppColors.statusAssigned;
      case 'inprogress': return AppColors.statusInProgress;
      case 'ready': return AppColors.statusReady;
      case 'cancelled': return AppColors.statusCancelled;
      case 'active': return AppColors.success;
      case 'reassigned': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }
}
