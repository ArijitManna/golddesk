import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/models/connection_models.dart';
import '../../../data/repositories/master_repository.dart';

class ExternalBusinessListScreen extends StatefulWidget {
  const ExternalBusinessListScreen({super.key});

  @override
  State<ExternalBusinessListScreen> createState() =>
      _ExternalBusinessListScreenState();
}

class _ExternalBusinessListScreenState
    extends State<ExternalBusinessListScreen> {
  List<ExternalBusiness> _businesses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _businesses = await getIt<MasterRepository>().getExternalBusinesses();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCustomerForm({ExternalBusiness? existing}) async {
    final isEdit = existing != null;
    final code = TextEditingController(text: existing?.customerCode ?? '');
    final name = TextEditingController(text: existing?.name ?? '');
    final contact = TextEditingController(text: existing?.contactPerson ?? '');
    final mobile = TextEditingController(text: existing?.mobile ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final address = TextEditingController(text: existing?.address ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit External Customer' : 'Add External Customer',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              GoldDeskTextField(
                label: 'Customer Code *',
                hint: 'e.g. S00001',
                controller: code,
              ),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Customer Name *',
                hint: 'e.g. Shop X',
                controller: name,
              ),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Contact Person',
                hint: 'Optional',
                controller: contact,
              ),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Mobile',
                hint: 'Optional',
                controller: mobile,
              ),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Email',
                hint: 'Optional',
                controller: email,
              ),
              const SizedBox(height: 12),
              GoldDeskTextField(
                label: 'Address',
                hint: 'Optional',
                controller: address,
              ),
              const SizedBox(height: 20),
              GoldDeskButton(
                text: isEdit ? 'UPDATE CUSTOMER' : 'SAVE CUSTOMER',
                onPressed: () async {
                  final customerCode = code.text.trim();
                  final customerName = name.text.trim();
                  if (customerCode.isEmpty || customerName.isEmpty) return;

                  try {
                    if (isEdit) {
                      await getIt<MasterRepository>().updateExternalBusiness(
                        id: existing.id,
                        customerCode: customerCode,
                        name: customerName,
                        contactPerson: contact.text.trim(),
                        mobile: mobile.text.trim(),
                        email: email.text.trim(),
                        address: address.text.trim(),
                      );
                    } else {
                      await getIt<MasterRepository>().createExternalBusiness(
                        customerCode: customerCode,
                        name: customerName,
                        businessType: 'Shop',
                        contactPerson: contact.text.trim(),
                        mobile: mobile.text.trim(),
                        email: email.text.trim(),
                        address: address.text.trim(),
                      );
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                  } catch (error) {
                    if (sheetContext.mounted) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(
                          content: Text(error is ApiException ? error.message : '$error'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

    code.dispose();
    name.dispose();
    contact.dispose();
    mobile.dispose();
    email.dispose();
    address.dispose();

    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Customer updated' : 'Customer added',
            ),
          ),
        );
      }
    }
  }

  Future<void> _link(ExternalBusiness business) async {
    final goldDeskId = TextEditingController();
    final linked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Link ${business.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the customer’s GoldDesk ID to replace this external record with its GoldDesk profile.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            GoldDeskTextField(
              label: 'GoldDesk ID',
              hint: 'e.g. S00001 / P00001 / K00001',
              controller: goldDeskId,
            ),
            const SizedBox(height: 20),
            GoldDeskButton(
              text: 'LINK CUSTOMER',
              onPressed: () async {
                final id = goldDeskId.text.trim().toUpperCase();
                if (id.isEmpty) return;
                try {
                  await getIt<MasterRepository>().linkExternalBusiness(
                    externalBusinessId: business.id,
                    goldDeskId: id,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                } catch (error) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          error is ApiException ? error.message : '$error',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
    goldDeskId.dispose();
    if (linked == true && mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer linked to GoldDesk')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('External Customers'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCustomerForm(),
          backgroundColor: AppColors.gold,
          child: const Icon(Icons.add),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _businesses.isEmpty
                ? const Center(child: Text('No external customers. Tap + to add one.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: _businesses.length,
                      itemBuilder: (_, index) {
                        final business = _businesses[index];
                        final isLinked = business.linkedBusinessId != null;
                        return ListTile(
                          leading: Icon(
                            isLinked
                                ? Icons.verified_outlined
                                : Icons.business_outlined,
                            color: isLinked ? AppColors.success : null,
                          ),
                          title: Text(business.name),
                          subtitle: Text(
                            [
                              'External Customer',
                              business.customerCode,
                              if (business.contactPerson != null)
                                business.contactPerson!,
                              if (business.mobile != null) business.mobile!,
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: () => _showCustomerForm(existing: business),
                              ),
                              if (isLinked)
                                const Text(
                                  'Linked',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: () => _link(business),
                                  child: const Text('Link'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      );
}
