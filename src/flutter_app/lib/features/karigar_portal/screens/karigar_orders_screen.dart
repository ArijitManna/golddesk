import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../core/widgets/order_image.dart';
import '../../../data/repositories/karigar_portal_repository.dart';
import '../../dashboard/widgets/side_drawer.dart';

class KarigarOrdersScreen extends StatefulWidget {
  final String? initialStatus;
  final String? initialAssignmentStatus;
  final String? initialDue;
  final String? initialShopId;
  final String? initialShopName;

  const KarigarOrdersScreen({
    super.key,
    this.initialStatus,
    this.initialAssignmentStatus,
    this.initialDue,
    this.initialShopId,
    this.initialShopName,
  });

  @override
  State<KarigarOrdersScreen> createState() => _KarigarOrdersScreenState();
}

class _KarigarOrderTab {
  final String label;
  final String? status;
  final String? assignmentStatus;
  final String? due;

  const _KarigarOrderTab(
    this.label, {
    this.status,
    this.assignmentStatus,
    this.due,
  });
}

class _KarigarOrdersScreenState extends State<KarigarOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<KarigarOrderItem> _orders = [];
  bool _isLoading = true;

  static const _tabs = [
    _KarigarOrderTab('All'),
    _KarigarOrderTab('New Work', assignmentStatus: 'PendingAcceptance'),
    _KarigarOrderTab(
      'Work Accepted',
      status: 'Assigned',
      assignmentStatus: 'Active',
    ),
    _KarigarOrderTab('Making', status: 'InProgress'),
    _KarigarOrderTab('Work Ready', status: 'Ready'),
    _KarigarOrderTab('Due Today', due: 'today'),
    _KarigarOrderTab('Overdue', due: 'overdue'),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = _resolveInitialTab();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _load();
    });
    _load();
  }

  int _resolveInitialTab() {
    final due = widget.initialDue?.toLowerCase();
    if (due != null && due.isNotEmpty) {
      final dueIndex = _tabs.indexWhere((tab) => tab.due?.toLowerCase() == due);
      if (dueIndex >= 0) return dueIndex;
    }

    final status = widget.initialStatus;
    final assignment = widget.initialAssignmentStatus;
    final exactIndex = _tabs.indexWhere(
      (tab) =>
          tab.status == status &&
          tab.assignmentStatus == assignment &&
          tab.due == null,
    );
    if (exactIndex >= 0) return exactIndex;

    if (assignment != null && assignment.isNotEmpty) {
      final assignmentIndex = _tabs.indexWhere(
        (tab) => tab.assignmentStatus == assignment,
      );
      if (assignmentIndex >= 0) return assignmentIndex;
    }

    if (status != null && status.isNotEmpty) {
      final statusIndex = _tabs.indexWhere((tab) => tab.status == status);
      if (statusIndex >= 0) return statusIndex;
    }

    return 0;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final tab = _tabs[_tabController.index];
      _orders = await getIt<KarigarPortalRepository>().getMyOrders(
        status: tab.status,
        assignmentStatus: tab.assignmentStatus,
        due: tab.due,
        shopId: widget.initialShopId,
      );
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
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
        title: Text(
          widget.initialShopName?.isNotEmpty == true
              ? widget.initialShopName!
              : 'My Orders',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [for (final tab in _tabs) Tab(text: tab.label)],
          isScrollable: true,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textLight,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OrderImage(
                imagePath: order.firstItemImage,
                size: 50,
                label: order.orderNo,
              ),
              const SizedBox(width: 12),
              Expanded(
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
                        if (order.firstItemSize != null &&
                            order.firstItemSize!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Size ${order.firstItemSize}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: dueColor),
                          const SizedBox(width: 4),
                          Text(
                            order.daysLeft <= 0
                                ? 'Overdue · Due ${order.dueDate}'
                                : 'Due: ${order.dueDate}',
                            style: TextStyle(fontSize: 12, color: dueColor),
                          ),
                        ],
                      ),
                    ],
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
