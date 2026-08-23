import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../core/widgets/message_icon_button.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/karigar_portal_repository.dart';
import '../../../data/repositories/order_repository.dart';

class KarigarUpdateStatusScreen extends StatefulWidget {
  final String orderId;
  const KarigarUpdateStatusScreen({super.key, required this.orderId});

  @override
  State<KarigarUpdateStatusScreen> createState() =>
      _KarigarUpdateStatusScreenState();
}

class _KarigarUpdateStatusScreenState extends State<KarigarUpdateStatusScreen> {
  String _selectedStatus = 'InProgress';
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _loadingOrder = true;
  KarigarOrderItem? _assignment;
  OrderDetail? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _loadingOrder = true);
    try {
      final detail = await getIt<OrderRepository>().getOrderById(widget.orderId);
      final orders = await getIt<KarigarPortalRepository>().getMyOrders();
      final match = orders.where((o) => o.orderId == widget.orderId).toList();
      if (mounted) {
        setState(() {
          _order = detail;
          _assignment = match.isNotEmpty ? match.first : null;
        });
      }
    } catch (_) {
      try {
        final orders = await getIt<KarigarPortalRepository>().getMyOrders();
        final match = orders.where((o) => o.orderId == widget.orderId).toList();
        if (mounted && match.isNotEmpty) {
          setState(() => _assignment = match.first);
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loadingOrder = false);
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);
    try {
      await getIt<KarigarPortalRepository>().updateStatus(
        widget.orderId,
        _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $_selectedStatus!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/karigar/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _acceptWork() async {
    setState(() => _isLoading = true);
    try {
      await getIt<KarigarPortalRepository>().acceptWork(widget.orderId);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work accepted. You can start making now.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String get _orderNo => _order?.orderNo ?? _assignment?.orderNo ?? '';
  String get _orderFrom =>
      _order?.orderFromBusinessName ?? _assignment?.orderFromBusinessName ?? '';
  String get _dueDate => _order?.dueDate ?? _assignment?.dueDate ?? '';
  String get _status => _order?.status ?? _assignment?.status ?? '';
  String get _assignmentStatus =>
      _order?.assignmentStatus ?? _assignment?.assignmentStatus ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/karigar/orders'),
        ),
        title: const Text('Update Status'),
        actions: [
          MessageIconButton(
            orderId: widget.orderId,
            onPressed: () => context.push(
              '/karigar/orders/${widget.orderId}/comments'
              '?title=${Uri.encodeComponent(_orderFrom.isNotEmpty ? _orderFrom : 'Shop')}',
            ),
          ),
        ],
      ),
      body: _loadingOrder
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Order No.', _orderNo),
                        const SizedBox(height: 8),
                        _infoRow('Order From', _orderFrom),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Total Weight',
                          '${(_order?.totalWeight ?? _assignment?.totalWeight ?? 0).toStringAsFixed(3)} gm',
                        ),
                        if (_dueDate.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _infoRow('Due Date', _dueDate),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Current Status',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusInProgress.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayOrderStatus(
                                  businessType: 'Karigar',
                                  status: _status,
                                  assignmentStatus: _assignmentStatus,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.statusInProgress,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_order != null && _order!.items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ..._order!.items.map(_buildItemRow),
                  ],
                  const SizedBox(height: 24),
                  if (_assignmentStatus == 'PendingAcceptance') ...[
                    const Text(
                      'The Shop has given you this work. Accept it before starting.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    GoldDeskButton(
                      text: 'ACCEPT WORK',
                      onPressed: _acceptWork,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Text(
                      'Status',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    _buildStatusOption(
                      'InProgress',
                      'Making',
                      Icons.engineering,
                      AppColors.statusInProgress,
                      'Mark that you have started working on this order',
                    ),
                    const SizedBox(height: 10),
                    _buildStatusOption(
                      'Ready',
                      'Work Ready',
                      Icons.check_circle_outline,
                      AppColors.statusReady,
                      'Mark that the work is complete and ready for delivery',
                    ),
                    const SizedBox(height: 24),
                    GoldDeskTextField(
                      label: 'Progress Notes (Optional)',
                      hint: 'Work in progress. Will be ready by due date.',
                      controller: _notesController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    GoldDeskButton(
                      text: 'UPDATE STATUS',
                      onPressed: _updateStatus,
                      isLoading: _isLoading,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildItemRow(OrderItemDetail item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '${item.weight.toStringAsFixed(3)} gm',
                      if (item.size != null && item.size!.isNotEmpty)
                        'Size ${item.size}',
                      '${item.quantity} pc',
                    ].join(' | '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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
      child: const Icon(
        Icons.diamond_outlined,
        color: AppColors.gold,
        size: 22,
      ),
    );
  }

  Widget _buildStatusOption(
    String value,
    String label,
    IconData icon,
    Color color,
    String description,
  ) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked, color: color)
            else
              const Icon(Icons.radio_button_off, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
