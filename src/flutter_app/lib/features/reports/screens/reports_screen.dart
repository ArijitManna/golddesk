import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/karigar_portal_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _businessType = 'Shop';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      _businessType = auth.user.businessType;
    }
    final tabCount = _businessType == 'Karigar' ? 1 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  bool get _isShowroom => _businessType == 'Showroom';
  bool get _isKarigar => _businessType == 'Karigar';

  List<Tab> get _tabs => _isKarigar
      ? const [Tab(text: 'My Work')]
      : _isShowroom
      ? const [
          Tab(text: 'Summary'),
          Tab(text: 'Shop-wise'),
          Tab(text: 'Due/Overdue'),
        ]
      : const [
          Tab(text: 'Summary'),
          Tab(text: 'Karigar-wise'),
          Tab(text: 'Due/Overdue'),
        ];

  @override
  Widget build(BuildContext context) {
    final controller = _tabController;
    if (controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Reports'),
        bottom: TabBar(
          controller: controller,
          tabs: _tabs,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textLight,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: [
          if (_isKarigar)
            const _KarigarWorkReportTab()
          else ...[
            _OrderSummaryTab(businessType: _businessType),
            if (_isShowroom)
              _ShopWiseTab(businessType: _businessType)
            else
              _KarigarWiseTab(businessType: _businessType),
            _DueOverdueTab(businessType: _businessType),
          ],
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedPath: '/reports'),
    );
  }
}

class _KarigarWorkReportTab extends StatelessWidget {
  const _KarigarWorkReportTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<KarigarDashboardData>(
      future: getIt<KarigarPortalRepository>().getDashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Could not load your work report.'));
        }

        final data = snapshot.data!;
        final metrics = [
          ('Total Assigned', data.totalAssigned, AppColors.primaryDark),
          ('New Work', data.newWork, AppColors.statusPending),
          ('In Progress', data.inProgress, AppColors.statusInProgress),
          ('Work Ready', data.ready, AppColors.statusReady),
          ('Due Today', data.dueToday, AppColors.due1Day),
          ('Overdue', data.overdue, AppColors.statusOverdue),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'My Work Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'A summary of work currently assigned to you.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
              children: metrics
                  .map(
                    (metric) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: metric.$3.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: metric.$3.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${metric.$2}',
                            style: TextStyle(
                              color: metric.$3,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metric.$1,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

Future<List<OrderSummary>> _loadOrders() async {
  final response = await getIt<OrderRepository>().getOrders(pageSize: 200);
  return response.items;
}

String _statusLabel(String businessType, OrderSummary order) =>
    displayOrderStatus(
      businessType: businessType,
      status: order.status,
      acceptanceStatus: order.acceptanceStatus,
      assignmentStatus: order.assignmentStatus,
    );

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return AppColors.statusPending;
    case 'assigned':
      return AppColors.statusAssigned;
    case 'inprogress':
      return AppColors.statusInProgress;
    case 'ready':
      return AppColors.statusReady;
    case 'delivered':
    case 'closed':
      return AppColors.statusDelivered;
    case 'cancelled':
      return AppColors.statusCancelled;
    default:
      return AppColors.textSecondary;
  }
}

Widget _countChip(String label, int count, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label: $count',
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

void _openOrderListSheet({
  required BuildContext context,
  required String title,
  required List<OrderSummary> orders,
  required String businessType,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${orders.length} orders',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: orders.isEmpty
                    ? const Center(
                        child: Text(
                          'No orders',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final order = orders[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              title: Text(
                                order.orderNo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${_statusLabel(businessType, order)}'
                                '${order.dueDate != null ? ' • Due ${order.dueDate}' : ''}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                context.go('/orders/${order.id}');
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

// ========== Order Summary Tab ==========
class _OrderSummaryTab extends StatefulWidget {
  final String businessType;
  const _OrderSummaryTab({required this.businessType});

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
      _orders = await _loadOrders();
      _statusCounts.clear();
      for (final o in _orders) {
        final label = _statusLabel(widget.businessType, o);
        _statusCounts[label] = (_statusCounts[label] ?? 0) + 1;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${_orders.length}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Orders',
                  style: TextStyle(color: AppColors.textOnDark, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Status Breakdown',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_statusCounts.isEmpty)
            const Text(
              'No orders yet.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ..._statusCounts.entries.map(
              (e) => _buildStatusRow(e.key, e.value),
            ),
          const SizedBox(height: 20),
          Text(
            'Amount Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildAmountRow(
            'Total Estimated',
            _orders.fold(0.0, (s, o) => s + o.estimatedAmount),
          ),
          _buildAmountRow(
            'Total Advance Received',
            _orders.fold(0.0, (s, o) => s + o.advancePaid),
          ),
          _buildAmountRow(
            'Total Balance',
            _orders.fold(
              0.0,
              (s, o) => s + (o.estimatedAmount - o.advancePaid),
            ),
          ),
          _buildAmountRow(
            'Total Weight',
            _orders.fold(0.0, (s, o) => s + o.totalWeight),
            isWeight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status, int count) {
    final percentage = _orders.isEmpty ? 0.0 : count / _orders.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(status, style: const TextStyle(fontSize: 13))),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.divider,
              color: AppColors.gold,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            isWeight
                ? '${value.toStringAsFixed(3)} gm'
                : '\u20B9${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ========== Showroom: Shop-wise ==========
class _ShopWiseTab extends StatefulWidget {
  final String businessType;
  const _ShopWiseTab({required this.businessType});

  @override
  State<_ShopWiseTab> createState() => _ShopWiseTabState();
}

class _ShopWiseTabState extends State<_ShopWiseTab> {
  List<OrderSummary> _orders = [];
  bool _isLoading = true;
  final Map<String, List<OrderSummary>> _byShop = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _orders = await _loadOrders();
      _byShop.clear();
      for (final o in _orders) {
        final name = o.createdForBusinessName.isNotEmpty
            ? o.createdForBusinessName
            : 'Unknown Shop';
        _byShop.putIfAbsent(name, () => []).add(o);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_byShop.isEmpty) {
      return const Center(
        child: Text(
          'No shop orders yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final shops = _byShop.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final name = shops[index];
        final orders = _byShop[name]!;
        final awaiting = orders
            .where((o) => o.acceptanceStatus == 'Pending')
            .length;
        final withShop = orders
            .where(
              (o) =>
                  o.acceptanceStatus == 'Accepted' &&
                  (o.status == 'Pending' || o.status == 'Assigned'),
            )
            .length;
        final making = orders.where((o) => o.status == 'InProgress').length;
        final ready = orders.where((o) => o.status == 'Ready').length;
        final done = orders
            .where((o) => o.status == 'Delivered' || o.status == 'Closed')
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openOrderListSheet(
              context: context,
              title: name,
              orders: orders,
              businessType: widget.businessType,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryDark.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.store_outlined,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${orders.length} orders',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _countChip('New', awaiting, AppColors.statusPending),
                      _countChip(
                        'With Shop',
                        withShop,
                        AppColors.statusAssigned,
                      ),
                      _countChip('Making', making, AppColors.statusInProgress),
                      _countChip('Work Ready', ready, AppColors.statusReady),
                      _countChip('Done', done, AppColors.statusDelivered),
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

// ========== Shop: Karigar-wise ==========
class _KarigarWiseTab extends StatefulWidget {
  final String businessType;
  const _KarigarWiseTab({required this.businessType});

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
      _orders = await _loadOrders();
      _byKarigar.clear();
      for (final o in _orders) {
        final name = (o.karigarName == null || o.karigarName!.isEmpty)
            ? 'Unassigned'
            : o.karigarName!;
        _byKarigar.putIfAbsent(name, () => []).add(o);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_byKarigar.isEmpty) {
      return const Center(
        child: Text(
          'No data',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final names = _byKarigar.keys.toList()
      ..sort((a, b) {
        if (a == 'Unassigned') return 1;
        if (b == 'Unassigned') return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        final orders = _byKarigar[name]!;
        final given = orders
            .where(
              (o) =>
                  o.status == 'Assigned' &&
                  o.assignmentStatus == 'PendingAcceptance',
            )
            .length;
        final accepted = orders
            .where(
              (o) =>
                  o.status == 'Assigned' &&
                  o.assignmentStatus != 'PendingAcceptance',
            )
            .length;
        final making = orders.where((o) => o.status == 'InProgress').length;
        final ready = orders.where((o) => o.status == 'Ready').length;
        final done = orders
            .where((o) => o.status == 'Delivered' || o.status == 'Closed')
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openOrderListSheet(
              context: context,
              title: name,
              orders: orders,
              businessType: widget.businessType,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryDark.withValues(
                          alpha: 0.1,
                        ),
                        child: Icon(
                          name == 'Unassigned'
                              ? Icons.person_off_outlined
                              : Icons.handyman_outlined,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${orders.length} orders',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (name == 'Unassigned')
                        _countChip(
                          'To Give Work',
                          orders.where((o) => o.status == 'Pending').length,
                          AppColors.statusPending,
                        )
                      else ...[
                        _countChip(
                          'Work Given',
                          given,
                          AppColors.statusAssigned,
                        ),
                        _countChip(
                          'Accepted',
                          accepted,
                          AppColors.statusInProgress,
                        ),
                      ],
                      _countChip('Making', making, AppColors.statusInProgress),
                      _countChip('Work Ready', ready, AppColors.statusReady),
                      _countChip('Done', done, AppColors.statusDelivered),
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

// ========== Due/Overdue Tab ==========
class _DueOverdueTab extends StatefulWidget {
  final String businessType;
  const _DueOverdueTab({required this.businessType});

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
      final orders = await _loadOrders();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _dueOrders = orders.where((o) {
        if (o.dueDate == null) return false;
        if (o.status == 'Ready' ||
            o.status == 'Delivered' ||
            o.status == 'Closed' ||
            o.status == 'Cancelled') {
          return false;
        }
        return o.dueDate!.compareTo(today) <= 0;
      }).toList();
      _dueOrders.sort((a, b) => (a.dueDate ?? '').compareTo(b.dueDate ?? ''));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_dueOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            SizedBox(height: 16),
            Text(
              'No overdue orders!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
                  const Icon(
                    Icons.warning_amber,
                    color: AppColors.statusOverdue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.businessType == 'Showroom'
                              ? order.createdForBusinessName
                              : order.orderFromBusinessName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (widget.businessType == 'Shop' &&
                            order.karigarName != null)
                          Text(
                            'Karigar: ${order.karigarName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Due: ${order.dueDate}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.statusOverdue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _statusLabel(widget.businessType, order),
                        style: TextStyle(
                          fontSize: 10,
                          color: _statusColor(order.status),
                        ),
                      ),
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
