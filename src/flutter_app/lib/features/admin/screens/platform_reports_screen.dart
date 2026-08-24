import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/admin_repository.dart';

class PlatformReportsScreen extends StatefulWidget {
  final String? businessType;

  const PlatformReportsScreen({super.key, this.businessType});

  @override
  State<PlatformReportsScreen> createState() => _PlatformReportsScreenState();
}

class _PlatformReportsScreenState extends State<PlatformReportsScreen> {
  PlatformShopsReport? _report;
  bool _loading = true;
  String? _error;

  String get _listTitle {
    switch (widget.businessType) {
      case 'Shop':
        return 'Shops';
      case 'Showroom':
        return 'Showrooms';
      case 'Karigar':
        return 'Karigars';
      default:
        return 'All Businesses';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _report = await getIt<AdminRepository>().getShopsReport(
        businessType: widget.businessType,
      );
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
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
        title: Text(_listTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (widget.businessType == null) ...[
                        _buildSummaryCards(_report!),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        '$_listTitle (${_report!.shops.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_report!.shops.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No ${_listTitle.toLowerCase()} registered yet',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ..._report!.shops.map(_buildShopCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards(PlatformShopsReport report) {
    return Row(
      children: [
        Expanded(
          child: _statCard('Shops', report.shopCount, AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('Showrooms', report.showroomCount, AppColors.gold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('Karigars', report.karigarCount, AppColors.statusInProgress),
        ),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(PlatformShopSummary shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _businessTypeColor(shop.businessType).withValues(alpha: 0.1),
          child: Icon(
            _businessTypeIcon(shop.businessType),
            color: _businessTypeColor(shop.businessType),
            size: 20,
          ),
        ),
        title: Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${shop.ownerName}\n${shop.mobile}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _businessTypeChip(shop.businessType),
            const SizedBox(height: 4),
            Text(
              shop.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _statusColor(shop.status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _businessTypeChip(String businessType) {
    final color = _businessTypeColor(businessType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        businessType,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  IconData _businessTypeIcon(String businessType) {
    switch (businessType) {
      case 'Showroom':
        return Icons.store_mall_directory_outlined;
      case 'Karigar':
        return Icons.handyman_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }

  Color _businessTypeColor(String businessType) {
    switch (businessType) {
      case 'Showroom':
        return AppColors.gold;
      case 'Karigar':
        return AppColors.statusInProgress;
      default:
        return AppColors.primaryDark;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'PendingApproval':
        return AppColors.statusPending;
      case 'Suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
