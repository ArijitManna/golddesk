import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/karigar_portal_repository.dart';

class KarigarOrdersScreen extends StatefulWidget {
  const KarigarOrdersScreen({super.key});

  @override
  State<KarigarOrdersScreen> createState() => _KarigarOrdersScreenState();
}

class _KarigarOrdersScreenState extends State<KarigarOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KarigarOrderItem> _orders = [];
  bool _isLoading = true;

  final _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'In Progress'),
    Tab(text: 'Send to Karigar'),
    Tab(text: 'Ready'),
  ];
  final _filters = [null, 'InProgress', 'Assigned', 'Ready'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _orders = await getIt<KarigarPortalRepository>().getMyOrders(
        status: _filters[_tabController.index],
      );
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/karigar/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textLight,
          indicatorWeight: 3,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _orders.isEmpty
              ? const Center(child: Text('No orders found', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(KarigarOrderItem order) {
    final statusColor = _getStatusColor(order.status);
    final dueColor = order.daysLeft <= 0 ? AppColors.due1Day
        : order.daysLeft <= 1 ? AppColors.due1Day
        : order.daysLeft <= 2 ? AppColors.due2Days
        : AppColors.due3Days;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/karigar/orders/${order.orderId}/update'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status == 'Assigned'
                          ? 'Send to Karigar'
                          : order.status == 'InProgress'
                              ? 'In Progress'
                              : order.status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(order.customerName, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.scale_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${order.totalWeight.toStringAsFixed(3)} gm', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: dueColor),
                  const SizedBox(width: 4),
                  Text(
                    order.daysLeft <= 0 ? 'Overdue' : 'Due: ${order.dueDate}',
                    style: TextStyle(fontSize: 12, color: dueColor),
                  ),
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(order.notes!, style: const TextStyle(fontSize: 11, color: AppColors.textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return AppColors.statusAssigned;
      case 'inprogress': return AppColors.statusInProgress;
      case 'ready': return AppColors.statusReady;
      default: return AppColors.textSecondary;
    }
  }
}
