import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_status_labels.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/order_image.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/side_drawer.dart';
import '../widgets/party_count_section.dart';

class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  PlatformShopsReport? _platformReport;
  bool _platformLoading = false;
  String? _platformError;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final isSuperAdmin =
        authState is AuthAuthenticated && authState.user.role == 'SuperAdmin';
    if (isSuperAdmin) {
      _loadPlatformReport();
    } else {
      context.read<DashboardCubit>().loadDashboard();
    }
  }

  Future<void> _loadPlatformReport() async {
    setState(() {
      _platformLoading = true;
      _platformError = null;
    });
    try {
      _platformReport = await getIt<AdminRepository>().getShopsReport();
    } catch (e) {
      _platformError = e.toString();
    }
    if (mounted) setState(() => _platformLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isSuperAdmin =
        authState is AuthAuthenticated && authState.user.role == 'SuperAdmin';

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go('/login');
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          title: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Gold',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'Desk',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [if (!isSuperAdmin) const NotificationBell()],
        ),
        drawer: const SideDrawer(),
        bottomNavigationBar: isSuperAdmin
            ? null
            : const AppBottomNavigation(selectedPath: '/dashboard'),
        body: isSuperAdmin
            ? _buildSuperAdminHome(context)
            : BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  }
                  if (state is DashboardError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<DashboardCubit>().loadDashboard(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is DashboardLoaded) {
                    return _buildDashboardContent(context, state.data);
                  }
                  return const SizedBox();
                },
              ),
      ),
    );
  }

  Widget _buildSuperAdminHome(BuildContext context) {
    if (_platformLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_platformError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _platformError!,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlatformReport,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final report = _platformReport;
    return RefreshIndicator(
      onRefresh: _loadPlatformReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Platform Admin', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Shops using GoldDesk and their Karigar counts.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.approval_outlined,
                color: AppColors.gold,
              ),
              title: const Text('Pending Approvals'),
              subtitle: Text(
                report == null
                    ? 'Review new shop registrations'
                    : '${report.pendingShops} pending registration(s)',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/admin/approvals'),
            ),
          ),
          const SizedBox(height: 16),
          if (report != null) ...[
            Row(
              children: [
                Expanded(
                  child: _platformStat(
                    'Total Shops',
                    report.totalShops,
                    AppColors.primaryDark,
                    onTap: () => context.go('/admin/reports'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _platformStat(
                    'Active',
                    report.activeShops,
                    AppColors.success,
                    onTap: () => context.go('/admin/reports'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _platformStat(
                    'Karigars',
                    report.totalKarigars,
                    AppColors.gold,
                    onTap: () => context.go('/admin/reports'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Shop List', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (report.shops.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No shops registered yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...report.shops.map(_buildPlatformShopCard),
          ],
        ],
      ),
    );
  }

  Widget _platformStat(String label, int count, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformShopCard(PlatformShopSummary shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryDark.withValues(alpha: 0.1),
          child: const Icon(
            Icons.storefront,
            color: AppColors.primaryDark,
            size: 20,
          ),
        ),
        title: Text(
          shop.shopName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${shop.ownerName}\nKarigars: ${shop.activeKarigarCount} active / ${shop.karigarCount} total',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Text(
          '${shop.karigarCount}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, ShopDashboardData data) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.businessType == 'Showroom'
                        ? 'Showroom Overview'
                        : 'Shop Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/orders/new'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Order'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.textOnGold,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats Grid
            _buildStatsGrid(data),
            const SizedBox(height: 24),
            // Overdue alert
            if (data.overdue > 0) ...[
              _buildOverdueAlert(data.overdue),
              const SizedBox(height: 16),
            ],
            if (data.businessType == 'Showroom') ...[
              PartyCountSection(
                title: 'My Shops',
                searchHint: 'Search shop name / code',
                emptyMessage:
                    'No shops connected yet. Connect a shop to start creating orders.',
                icon: Icons.store_outlined,
                parties: data.connectedShops,
                onTap: (shop) => context.go(
                  Uri(
                    path: '/orders',
                    queryParameters: {
                      'shopId': shop.businessId,
                      'shopName': shop.businessName,
                    },
                  ).toString(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (data.businessType == 'Shop') ...[
              PartyCountSection(
                title: 'Showrooms',
                searchHint: 'Search showroom name / code',
                emptyMessage: 'No showrooms connected yet.',
                icon: Icons.business_outlined,
                parties: data.connectedShowrooms,
                onTap: (showroom) => context.go(
                  Uri(
                    path: '/orders',
                    queryParameters: {
                      'showroomId': showroom.businessId,
                      'shopName': showroom.businessName,
                    },
                  ).toString(),
                ),
              ),
              const SizedBox(height: 16),
              PartyCountSection(
                title: 'External Customers',
                searchHint: 'Search customer name / code',
                emptyMessage: 'No external customers yet.',
                icon: Icons.people_outlined,
                parties: data.externalCustomers,
                onTap: (customer) => context.go(
                  Uri(
                    path: '/orders',
                    queryParameters: {
                      'externalCustomerId': customer.businessId,
                      'shopName': customer.businessName,
                    },
                  ).toString(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Recent Orders
            _buildSectionHeader(
              'Recent Orders',
              onViewAll: () => context.go('/orders'),
            ),
            const SizedBox(height: 8),
            ...data.recentOrders.map(
              (o) => _buildOrderCard(o, data.businessType),
            ),
            if (data.recentOrders.isEmpty)
              _buildEmptyState('No orders yet. Create your first order!'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ShopDashboardData data) {
    if (data.businessType == 'Showroom') {
      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
        children: [
          _buildStatCard(
            'Total Orders',
            data.totalOrders,
            AppColors.primaryDark,
            subtitle: 'All orders',
            onTap: () => context.go('/orders'),
          ),
          _buildStatCard(
            'New Orders',
            data.pending,
            AppColors.statusPending,
            subtitle: 'Yet to start',
            onTap: () => context.go('/orders?status=Pending'),
          ),
          _buildStatCard(
            'With Shop',
            data.assigned,
            AppColors.statusAssigned,
            subtitle: 'Assigned to shop',
            onTap: () => context.go('/orders?status=Assigned'),
          ),
          _buildStatCard(
            'In Making',
            data.inProgress,
            AppColors.statusInProgress,
            subtitle: 'In production',
            onTap: () => context.go('/orders?status=InProgress'),
          ),
          _buildStatCard(
            'Work Ready',
            data.ready,
            AppColors.statusReady,
            subtitle: 'Ready for pickup',
            onTap: () => context.go('/orders?status=Ready'),
          ),
          _buildStatCard(
            'Overdue',
            data.overdue,
            AppColors.statusOverdue,
            subtitle: 'Past due date',
            onTap: () => context.go('/orders?due=overdue'),
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _buildStatCard(
          'Total',
          data.totalOrders,
          AppColors.primaryDark,
          onTap: () => context.go('/orders'),
        ),
        _buildStatCard(
          'From Showrooms',
          data.fromShowrooms,
          AppColors.gold,
          onTap: () => context.go('/orders?source=Showroom'),
        ),
        _buildStatCard(
          'Direct',
          data.directOrders,
          AppColors.primaryDark,
          onTap: () => context.go('/orders?source=Direct'),
        ),
        _buildStatCard(
          'To Give Work',
          data.pending,
          AppColors.statusPending,
          onTap: () => context.go('/orders?status=Pending'),
        ),
        _buildStatCard(
          'Work Given',
          data.assigned,
          AppColors.statusAssigned,
          onTap: () => context.go('/orders?status=Assigned'),
        ),
        _buildStatCard(
          'Making',
          data.inProgress,
          AppColors.statusInProgress,
          onTap: () => context.go('/orders?status=InProgress'),
        ),
        _buildStatCard(
          'Due Today',
          data.dueToday,
          AppColors.due2Days,
          onTap: () => context.go('/orders?due=today'),
        ),
        _buildStatCard(
          'Overdue',
          data.overdue,
          AppColors.statusOverdue,
          onTap: () => context.go('/orders?due=overdue'),
        ),
        _buildStatCard(
          'Work Ready',
          data.ready,
          AppColors.statusReady,
          onTap: () => context.go('/orders?status=Ready'),
        ),
        _buildStatCard(
          'Due 3 Days',
          data.dueNext3Days,
          AppColors.due3Days,
          onTap: () => context.go('/orders?due=next3'),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statIcon(label), size: 16, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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

  IconData _statIcon(String label) {
    switch (label) {
      case 'Total':
      case 'Total Orders':
        return Icons.inventory_2_outlined;
      case 'New':
      case 'New Orders':
      case 'To Give Work':
        return Icons.note_add_outlined;
      case 'With Shop':
      case 'Work Given':
        return Icons.storefront_outlined;
      case 'Making':
      case 'In Making':
        return Icons.build_outlined;
      case 'Work Ready':
        return Icons.assignment_turned_in_outlined;
      case 'Due Today':
      case 'Due 3 Days':
        return Icons.event_outlined;
      case 'Overdue':
        return Icons.schedule_outlined;
      case 'From Showrooms':
        return Icons.business_outlined;
      case 'Direct':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.bar_chart_outlined;
    }
  }

  Widget _buildOverdueAlert(int count) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/orders?due=overdue'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count order(s) are overdue!',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/orders?due=overdue'),
                child: const Text(
                  'View',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(OrderSummary order, String businessType) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OrderImage(
                imagePath: order.firstItemImage,
                size: 44,
                label: order.orderNo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.orderNo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        _buildStatusChip(order, businessType),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.orderFromBusinessName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order.source == 'Showroom')
                      Text(
                        'From ${order.createdByBusinessName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gold,
                        ),
                      ),
                    if (businessType == 'Shop' && order.karigarName != null)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderSummary order, String businessType) {
    final color = _getStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayOrderStatus(
          businessType: businessType,
          status: order.status,
          acceptanceStatus: order.acceptanceStatus,
          assignmentStatus: order.assignmentStatus,
        ),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
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

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }
}
