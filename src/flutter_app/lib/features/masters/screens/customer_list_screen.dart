import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/repositories/master_repository.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<CustomerData> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _customers = await getIt<MasterRepository>().getCustomers();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Customer', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            GoldDeskTextField(label: 'Name *', hint: 'Customer name', controller: nameCtrl),
            const SizedBox(height: 12),
            GoldDeskTextField(label: 'Mobile', hint: '10-digit number', controller: mobileCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            GoldDeskTextField(label: 'Email', hint: 'Email (optional)', controller: emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            GoldDeskTextField(label: 'Address', hint: 'Address (optional)', controller: addressCtrl),
            const SizedBox(height: 20),
            GoldDeskButton(
              text: 'SAVE CUSTOMER',
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await getIt<MasterRepository>().createCustomer(
                    name: nameCtrl.text.trim(),
                    mobile: mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer added!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/dashboard')),
        title: const Text('Customers'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _customers.isEmpty
              ? const Center(child: Text('No customers. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final c = _customers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                            child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(c.mobile ?? 'No mobile', style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
