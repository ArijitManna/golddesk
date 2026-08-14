import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../data/repositories/karigar_portal_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class KarigarDashboardScreen extends StatefulWidget {
  const KarigarDashboardScreen({super.key});

  @override
  State<KarigarDashboardScreen> createState() => _KarigarDashboardScreenState();
}

class _KarigarDashboardScreenState extends State<KarigarDashboardScreen> {
  KarigarDashboardData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _data = await getIt<KarigarPortalRepository>().getDashboard();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) context.go('/login');
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          title: const Text('Karigar Dashboard'),
          actions: [
            const NotificationBell(),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _error != null
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ))
                : _buildContent(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.textSecondary,
          onTap: (i) {
            if (i == 1) context.go('/karigar/orders');
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Orders'),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _buildStatCard('Send to\nKarigar', data.totalAssigned, AppColors.primaryDark),
                const SizedBox(width: 10),
                _buildStatCard('In\nProgress', data.inProgress, AppColors.statusInProgress),
                const SizedBox(width: 10),
                _buildStatCard('Due\nSoon', data.dueSoon + data.dueToday, AppColors.statusPending),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('Overdue', data.overdue, AppColors.statusOverdue),
                const SizedBox(width: 10),
                _buildStatCard('Ready', data.ready, AppColors.statusReady),
                const SizedBox(width: 10),
                _buildStatCard('Due\nToday', data.dueToday, AppColors.due1Day),
              ],
            ),
            const SizedBox(height: 24),
            // Due Soon section
            if (data.dueSoonOrders.isNotEmpty) ...[
              _sectionTitle('Due Soon (Next 3 Days)'),
              const SizedBox(height: 8),
              ...data.dueSoonOrders.map((o) => _buildOrderCard(o)),
              const SizedBox(height: 16),
            ],
            // Recent
            if (data.recentOrders.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Recent Orders'),
                  TextButton(
                    onPressed: () => context.go('/karigar/orders'),
                    child: const Text('View All', style: TextStyle(color: AppColors.gold)),
                  ),
                ],
              ),
              ...data.recentOrders.map((o) => _buildOrderCard(o)),
            ],
            if (data.dueSoonOrders.isEmpty && data.recentOrders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No orders assigned yet.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _buildOrderCard(KarigarOrderItem order) {
    final dueColor = order.daysLeft <= 0 ? AppColors.due1Day
        : order.daysLeft <= 1 ? AppColors.due1Day
        : order.daysLeft <= 2 ? AppColors.due2Days
        : AppColors.due3Days;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/karigar/orders/${order.orderId}/update'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(order.customerName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('Due: ${order.dueDate}', style: TextStyle(fontSize: 11, color: dueColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: dueColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  order.daysLeft <= 0 ? 'Overdue' : '${order.daysLeft} Day${order.daysLeft > 1 ? 's' : ''} Left',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dueColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
