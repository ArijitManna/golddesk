import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/dashboard_models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Summary'),
    Tab(text: 'Karigar-wise'),
    Tab(text: 'Due/Overdue'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textLight,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OrderSummaryTab(),
          _KarigarWiseTab(),
          _DueOverdueTab(),
        ],
      ),
    );
  }
}

// ========== Order Summary Tab ==========
class _OrderSummaryTab extends StatefulWidget {
  const _OrderSummaryTab();

  @override
  State<_OrderSummaryTab> createState() => _OrderSummaryTabState();
}

class _OrderSummaryTabState extends State<_OrderSummaryTab> {
  List<OrderSummary> _orders = [];
  bool _isLoading = true;
  final Map<String, int> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await getIt<OrderRepository>().getOrders(pageSize: 100);
      _orders = response.items;
      _statusCounts.clear();
      for (var o in _orders) {
        _statusCounts[o.status] = (_statusCounts[o.status] ?? 0) + 1;
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('${_orders.length}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.gold)),
                const SizedBox(height: 4),
                const Text('Total Orders', style: TextStyle(color: AppColors.textOnDark, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Status breakdown
          Text('Status Breakdown', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._statusCounts.entries.map((e) => _buildStatusRow(e.key, e.value)),
          const SizedBox(height: 20),
          // Amount summary
          Text('Amount Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildAmountRow('Total Estimated', _orders.fold(0.0, (s, o) => s + o.estimatedAmount)),
          _buildAmountRow('Total Advance Received', _orders.fold(0.0, (s, o) => s + o.advancePaid)),
          _buildAmountRow('Total Balance', _orders.fold(0.0, (s, o) => s + (o.estimatedAmount - o.advancePaid))),
          _buildAmountRow('Total Weight', _orders.fold(0.0, (s, o) => s + o.totalWeight), isWeight: true),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status, int count) {
    final color = _getColor(status);
    final percentage = _orders.isEmpty ? 0.0 : count / _orders.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(status == 'InProgress' ? 'In Progress' : status, style: const TextStyle(fontSize: 13))),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(value: percentage, backgroundColor: AppColors.divider, color: color, minHeight: 6,
              borderRadius: BorderRadius.circular(3)),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double value, {bool isWeight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            isWeight ? '${value.toStringAsFixed(3)} gm' : '\u20B9${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.statusPending;
      case 'assigned': return AppColors.statusAssigned;
      case 'inprogress': return AppColors.statusInProgress;
      case 'ready': return AppColors.statusReady;
      case 'delivered': return AppColors.statusDelivered;
      case 'cancelled': return AppColors.statusCancelled;
      default: return AppColors.textSecondary;
    }
  }
}

// ========== Karigar-wise Tab ==========
class _KarigarWiseTab extends StatefulWidget {
  const _KarigarWiseTab();

  @override
  State<_KarigarWiseTab> createState() => _KarigarWiseTabState();
}

class _KarigarWiseTabState extends State<_KarigarWiseTab> {
  List<OrderSummary> _orders = [];
  bool _isLoading = true;
  final Map<String, List<OrderSummary>> _byKarigar = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await getIt<OrderRepository>().getOrders(pageSize: 100);
      _orders = response.items;
      _byKarigar.clear();
      for (var o in _orders) {
        final name = o.karigarName ?? 'Unassigned';
        _byKarigar.putIfAbsent(name, () => []).add(o);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    if (_byKarigar.isEmpty) return const Center(child: Text('No data'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _byKarigar.length,
      itemBuilder: (context, index) {
        final name = _byKarigar.keys.elementAt(index);
        final orders = _byKarigar[name]!;
        final inProgress = orders.where((o) => o.status == 'InProgress').length;
        final ready = orders.where((o) => o.status == 'Ready').length;
        final assigned = orders.where((o) => o.status == 'Assigned').length;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryDark.withValues(alpha: 0.1),
                      child: const Icon(Icons.engineering, size: 18, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                    Text('${orders.length} orders', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip('Assigned', assigned, AppColors.statusAssigned),
                    const SizedBox(width: 6),
                    _chip('In Progress', inProgress, AppColors.statusInProgress),
                    const SizedBox(width: 6),
                    _chip('Ready', ready, AppColors.statusReady),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $count', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ========== Due/Overdue Tab ==========
class _DueOverdueTab extends StatefulWidget {
  const _DueOverdueTab();

  @override
  State<_DueOverdueTab> createState() => _DueOverdueTabState();
}

class _DueOverdueTabState extends State<_DueOverdueTab> {
  List<OrderSummary> _dueOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await getIt<OrderRepository>().getOrders(pageSize: 100);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _dueOrders = response.items.where((o) {
        if (o.dueDate == null) return false;
        if (o.status == 'Ready' || o.status == 'Delivered' || o.status == 'Closed' || o.status == 'Cancelled') return false;
        return o.dueDate!.compareTo(today) <= 0;
      }).toList();
      _dueOrders.sort((a, b) => (a.dueDate ?? '').compareTo(b.dueDate ?? ''));
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    if (_dueOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            SizedBox(height: 16),
            Text('No overdue orders!', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dueOrders.length,
      itemBuilder: (context, index) {
        final order = _dueOrders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/orders/${order.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.statusOverdue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(order.customerName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (order.karigarName != null)
                          Text('Karigar: ${order.karigarName}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Due: ${order.dueDate}', style: const TextStyle(fontSize: 11, color: AppColors.statusOverdue, fontWeight: FontWeight.w600)),
                      Text(order.status, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
