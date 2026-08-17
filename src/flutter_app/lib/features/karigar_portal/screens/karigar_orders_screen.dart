import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../data/repositories/karigar_portal_repository.dart';
import '../../dashboard/widgets/side_drawer.dart';

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
    Tab(text: 'New Work'),
    Tab(text: 'Making'),
    Tab(text: 'Work Ready'),
  ];
  final _statusFilters = [null, null, 'InProgress', 'Ready'];
  final _assignmentStatusFilters = [null, 'PendingAcceptance', null, null];

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
        status: _statusFilters[_tabController.index],
        assignmentStatus: _assignmentStatusFilters[_tabController.index],
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
      drawer: const SideDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textLight,
          indicatorWeight: 3,
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(
        selectedPath: '/karigar/orders',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'No orders found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _orders.length,
                itemBuilder: (context, index) =>
                    _buildOrderCard(_orders[index]),
              ),
            ),
    );
  }

  Widget _buildOrderCard(KarigarOrderItem order) {
    final isCompleted = order.status == 'Delivered' || order.status == 'Closed';
    final statusColor = _getStatusColor(order.status);
    final dueColor = order.daysLeft <= 0
        ? AppColors.due1Day
        : order.daysLeft <= 1
        ? AppColors.due1Day
        : order.daysLeft <= 2
        ? AppColors.due2Days
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
                  Text(
                    order.orderNo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _displayStatus(order),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.orderFromBusinessName,
                style: const TextStyle(fontSize: 13),
              ),
              if (order.sourceShopName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  order.sourceShopName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.scale_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${order.totalWeight.toStringAsFixed(3)} gm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 14, color: dueColor),
                    const SizedBox(width: 4),
                    Text(
                      order.daysLeft <= 0 ? 'Overdue' : 'Due: ${order.dueDate}',
                      style: TextStyle(fontSize: 12, color: dueColor),
                    ),
                  ],
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  order.notes!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppColors.statusAssigned;
      case 'inprogress':
        return AppColors.statusInProgress;
      case 'ready':
        return AppColors.statusReady;
      default:
        return AppColors.textSecondary;
    }
  }

  String _displayStatus(KarigarOrderItem order) => displayOrderStatus(
    businessType: 'Karigar',
    status: order.status,
    assignmentStatus: order.assignmentStatus,
  );
}
