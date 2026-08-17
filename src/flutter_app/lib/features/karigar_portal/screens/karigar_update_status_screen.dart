import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../core/widgets/message_icon_button.dart';
import '../../../data/repositories/karigar_portal_repository.dart';

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
  KarigarOrderItem? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final orders = await getIt<KarigarPortalRepository>().getMyOrders();
      final match = orders.where((o) => o.orderId == widget.orderId).toList();
      if (match.isNotEmpty) {
        setState(() => _order = match.first);
      }
    } catch (_) {}
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
              '?title=${Uri.encodeComponent(_order?.sourceShopName.isNotEmpty == true ? _order!.sourceShopName : 'Shop')}',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info
            if (_order != null) ...[
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
                    Row(
                      children: [
                        const Text(
                          'Order No.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _order!.orderNo,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Order From',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _order!.orderFromBusinessName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Due Date',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _order!.dueDate,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
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
                              status: _order!.status,
                              assignmentStatus: _order!.assignmentStatus,
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
              const SizedBox(height: 24),
            ],
            if (_order?.assignmentStatus == 'PendingAcceptance') ...[
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
              // Status selection
              Text(
                'Status',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
              // Progress notes
              GoldDeskTextField(
                label: 'Progress Notes (Optional)',
                hint: 'Work in progress. Will be ready by due date.',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              // Update button
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
