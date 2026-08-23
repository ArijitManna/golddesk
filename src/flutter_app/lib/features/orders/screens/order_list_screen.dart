import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../core/widgets/order_image.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../data/models/dashboard_models.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/order_list_cubit.dart';

class OrderListScreen extends StatefulWidget {
  final String? initialStatus;
  final String? initialDue;
  final String? initialSource;
  final String? initialShopId;
  final String? initialShopName;
  final String? initialShowroomId;
  final String? initialExternalCustomerId;

  const OrderListScreen({
    super.key,
    this.initialStatus,
    this.initialDue,
    this.initialSource,
    this.initialShopId,
    this.initialShopName,
    this.initialShowroomId,
    this.initialExternalCustomerId,
  });

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  /// Parallel arrays: tab label, status filter, due filter
  late final List<Tab> _tabs;

  static const _statusFilters = <String?>[
    null,
    'Pending',
    'Assigned',
    'InProgress',
    'Ready',
    null,
    null,
    null,
    'Cancelled',
  ];

  static const _dueFilters = <String?>[
    null,
    null,
    null,
    null,
    null,
    'today',
    'overdue',
    'next3',
    null,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = _buildTabs();
    final initialIndex = _resolveInitialTabIndex();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
    context.read<OrderListCubit>().loadOrders(
      status: _statusFilters[initialIndex],
      due: _dueFilters[initialIndex],
      source: widget.initialSource,
      shopId: widget.initialShopId,
      showroomId: widget.initialShowroomId,
      externalCustomerId: widget.initialExternalCustomerId,
    );
  }

  List<Tab> _buildTabs() {
    final auth = context.read<AuthBloc>().state;
    final businessType = auth is AuthAuthenticated
        ? auth.user.businessType
        : 'Shop';

    final statusTabs = switch (businessType) {
      'Showroom' => const ['All', 'New', 'With Shop', 'Making', 'Work Ready'],
      _ => const [
        'All',
        'New / To Give Work',
        'Work Given / Accepted',
        'Making',
        'Work Ready',
      ],
    };

    return [
      ...statusTabs.map((text) => Tab(text: text)),
      const Tab(text: 'Due Today'),
      const Tab(text: 'Overdue'),
      const Tab(text: 'Due 3 Days'),
      const Tab(text: 'Cancelled'),
    ];
  }

  String? get _filterBanner {
    final source = widget.initialSource;
    if (source != null && source.isNotEmpty) {
      return source.toLowerCase() == 'showroom'
          ? 'From Showrooms'
          : source.toLowerCase() == 'direct'
          ? 'Direct orders'
          : source;
    }
    final shopName = widget.initialShopName;
    if (shopName != null && shopName.isNotEmpty) return shopName;
    if (widget.initialShopId != null && widget.initialShopId!.isNotEmpty) {
      return 'Selected shop';
    }
    if (widget.initialShowroomId != null &&
        widget.initialShowroomId!.isNotEmpty) {
      return 'Selected showroom';
    }
    if (widget.initialExternalCustomerId != null &&
        widget.initialExternalCustomerId!.isNotEmpty) {
      return 'Selected customer';
    }
    return null;
  }

  int _resolveInitialTabIndex() {
    final due = widget.initialDue?.toLowerCase();
    if (due != null && due.isNotEmpty) {
      final dueIndex = _dueFilters.indexOf(due);
      if (dueIndex >= 0) return dueIndex;
    }

    final status = widget.initialStatus;
    if (status != null && status.isNotEmpty) {
      final statusIndex = _statusFilters.indexWhere(
        (s) => s != null && s.toLowerCase() == status.toLowerCase(),
      );
      if (statusIndex >= 0) return statusIndex;
    }

    return 0;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    context.read<OrderListCubit>().loadOrders(
      status: _statusFilters[index],
      due: _dueFilters[index],
      search: _searchController.text.isEmpty ? null : _searchController.text,
      source: widget.initialSource,
      shopId: widget.initialShopId,
      showroomId: widget.initialShowroomId,
      externalCustomerId: widget.initialExternalCustomerId,
    );
  }

  void _reloadCurrent() {
    final index = _tabController.index;
    context.read<OrderListCubit>().loadOrders(
      status: _statusFilters[index],
      due: _dueFilters[index],
      search: _searchController.text.isEmpty ? null : _searchController.text,
      source: widget.initialSource,
      shopId: widget.initialShopId,
      showroomId: widget.initialShowroomId,
      externalCustomerId: widget.initialExternalCustomerId,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Order List'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textLight,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/orders/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textOnGold,
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedPath: '/orders'),
      body: Column(
        children: [
          if (_filterBanner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: Text(_filterBanner!),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search order or business',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _reloadCurrent();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _reloadCurrent(),
            ),
          ),
          Expanded(
            child: BlocBuilder<OrderListCubit, OrderListState>(
              builder: (context, state) {
                if (state is OrderListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }
                if (state is OrderListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _reloadCurrent,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is OrderListLoaded) {
                  if (state.orders.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reloadCurrent(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) =>
                          _buildOrderCard(state.orders[index]),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderSummary order) {
    final auth = context.read<AuthBloc>().state;
    final businessType = auth is AuthAuthenticated
        ? auth.user.businessType
        : 'Shop';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/orders/${order.id}'),
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
                        _buildStatusChip(order),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.orderFromBusinessName,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${order.totalWeight.toStringAsFixed(3)} gm',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (order.source == 'Showroom') ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 12,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'From ${order.createdByBusinessName}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.orderDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (order.dueDate != null && order.dueDate!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.event_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${order.dueDate}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (businessType == 'Shop' &&
                            order.karigarName != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.engineering_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              order.karigarName!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (order.firstItemSize != null &&
                        order.firstItemSize!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Size ${order.firstItemSize}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
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

  Widget _buildStatusChip(OrderSummary order) {
    final color = _getStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _displayStatus(order),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _displayStatus(OrderSummary order) {
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
      case 'delivered':
        return AppColors.statusDelivered;
      default:
        return AppColors.textSecondary;
    }
  }
}
