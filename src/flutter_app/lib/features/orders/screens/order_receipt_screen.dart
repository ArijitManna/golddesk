import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/tenant_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class OrderReceiptScreen extends StatefulWidget {
  final String orderId;
  const OrderReceiptScreen({super.key, required this.orderId});

  @override
  State<OrderReceiptScreen> createState() => _OrderReceiptScreenState();
}

class _OrderReceiptScreenState extends State<OrderReceiptScreen> {
  OrderDetail? _order;
  TenantProfile? _shop;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<OrderRepository>().getOrderById(widget.orderId),
        getIt<TenantRepository>().getProfile(),
      ]);
      _order = results[0] as OrderDetail;
      _shop = results[1] as TenantProfile;
    } catch (_) {
      try {
        _order = await getIt<OrderRepository>().getOrderById(widget.orderId);
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/orders/${widget.orderId}'),
        ),
        title: const Text('Order Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share/PDF export coming soon')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _order == null
          ? const Center(child: Text('Order not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildReceipt(),
            ),
    );
  }

  Widget _buildReceipt() {
    final order = _order!;
    final balance = order.estimatedAmount - order.advancePaid;
    final shopName = _shop?.shopName ?? 'Gold Shop';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_shop?.logoPath != null && _shop!.logoPath!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                '${AppConstants.serverUrl}${_shop!.logoPath}',
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            shopName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (_shop?.address != null && _shop!.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _shop!.address!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (_shop?.gstNumber != null && _shop!.gstNumber!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'GST: ${_shop!.gstNumber}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'ORDER RECEIPT',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _receiptRow('Order No.', order.orderNo),
          _receiptRow('Order From', order.orderFromBusinessName),
          _receiptRow('Order To', order.createdForBusinessName),
          _receiptRow('Order Date', order.orderDate),
          _receiptRow('Delivery Date', order.deliveryDate ?? '-'),
          if (_shop?.businessType == 'Shop' && order.karigarName != null)
            _receiptRow('Karigar Name', order.karigarName!),
          _receiptRow('Status', _displayStatus(order)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '#',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Item Name',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Weight',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Rate',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...order.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.itemName,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.weight.toStringAsFixed(3),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.rate.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.amount.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),
          _receiptRow(
            'Total Weight',
            '${order.totalWeight.toStringAsFixed(3)} gm',
          ),
          _receiptRow(
            'Making Charges',
            '\u20B9${order.makingCharges.toStringAsFixed(0)}',
          ),
          _receiptRow(
            'Advance Paid',
            '\u20B9${order.advancePaid.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Balance Amount',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  '\u20B9${balance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Thank you for your trust!',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Gold',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'Desk',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayStatus(OrderDetail order) {
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

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
