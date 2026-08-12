import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/order_image.dart';
import '../../../data/models/dashboard_models.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/side_drawer.dart';

class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final isSuperAdmin =
        authState is AuthAuthenticated && authState.user.role == 'SuperAdmin';
    if (!isSuperAdmin) {
      context.read<DashboardCubit>().loadDashboard();
    }
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
            text: const TextSpan(children: [
              TextSpan(
                text: 'Gold',
                style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Desk',
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ]),
          ),
          actions: [
            if (!isSuperAdmin) const NotificationBell(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
        ),
        drawer: const SideDrawer(),
        floatingActionButton: isSuperAdmin
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.go('/orders/new'),
                icon: const Icon(Icons.add),
                label: const Text('NEW ORDER'),
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.textOnGold,
              ),
        body: isSuperAdmin
            ? _buildSuperAdminHome(context)
            : BlocBuilder<DashboardCubit, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }
                  if (state is DashboardError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<DashboardCubit>().loadDashboard(),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Platform Admin', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Manage shop approvals and view platform reports.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.approval_outlined, color: AppColors.gold),
              title: const Text('Pending Approvals'),
              subtitle: const Text('Review and approve new shop registrations'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/admin/approvals'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart_outlined, color: AppColors.primaryDark),
              title: const Text('Platform Reports'),
              subtitle: const Text('Shop count with karigars per shop'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/reports'),
            ),
          ),
        ],
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
            // Stats Grid
            _buildStatsGrid(data),
            const SizedBox(height: 24),
            // Overdue alert
            if (data.overdue > 0) ...[
              _buildOverdueAlert(data.overdue),
              const SizedBox(height: 16),
            ],
            // Recent Orders
            _buildSectionHeader('Recent Orders', onViewAll: () => context.go('/orders')),
            const SizedBox(height: 8),
            ...data.recentOrders.map((o) => _buildOrderCard(o)),
            if (data.recentOrders.isEmpty)
              _buildEmptyState('No orders yet. Create your first order!'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ShopDashboardData data) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard('Total', data.totalOrders, AppColors.primaryDark,
            onTap: () => context.go('/orders')),
        _buildStatCard('Pending', data.pending, AppColors.statusPending,
            onTap: () => context.go('/orders?status=Pending')),
        _buildStatCard('Assigned', data.assigned, AppColors.statusAssigned,
            onTap: () => context.go('/orders?status=Assigned')),
        _buildStatCard('In Progress', data.inProgress, AppColors.statusInProgress,
            onTap: () => context.go('/orders?status=InProgress')),
        _buildStatCard('Due Today', data.dueToday, AppColors.due2Days,
            onTap: () => context.go('/orders?due=today')),
        _buildStatCard('Overdue', data.overdue, AppColors.statusOverdue,
            onTap: () => context.go('/orders?due=overdue')),
        _buildStatCard('Ready', data.ready, AppColors.statusReady,
            onTap: () => context.go('/orders?status=Ready')),
        _buildStatCard('Due 3 Days', data.dueNext3Days, AppColors.due3Days,
            onTap: () => context.go('/orders?due=next3')),
        _buildStatCard('Karigars', data.activeKarigars, AppColors.gold,
            onTap: () => context.go('/karigars')),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/orders?due=overdue'),
                child: const Text('View', style: TextStyle(color: AppColors.error)),
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
            child: const Text('View All', style: TextStyle(color: AppColors.gold)),
          ),
      ],
    );
  }

  Widget _buildOrderCard(OrderSummary order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OrderImage(imagePath: order.firstItemImage, size: 44, label: order.orderNo),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const Spacer(),
                        _buildStatusChip(order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(order.customerName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (order.karigarName != null)
                      Text('Karigar: ${order.karigarName}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.statusPending;
      case 'assigned': return AppColors.statusAssigned;
      case 'inprogress': return AppColors.statusInProgress;
      case 'ready': return AppColors.statusReady;
      case 'cancelled': return AppColors.statusCancelled;
      case 'delivered': return AppColors.statusDelivered;
      default: return AppColors.textSecondary;
    }
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.textLight)),
      ),
    );
  }
}
