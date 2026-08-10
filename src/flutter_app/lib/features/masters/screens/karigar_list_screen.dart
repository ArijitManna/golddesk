import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/repositories/master_repository.dart';

class KarigarListScreen extends StatefulWidget {
  const KarigarListScreen({super.key});

  @override
  State<KarigarListScreen> createState() => _KarigarListScreenState();
}

class _KarigarListScreenState extends State<KarigarListScreen> {
  List<KarigarData> _karigars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _karigars = await getIt<MasterRepository>().getKarigars();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool createLogin = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Karigar', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              GoldDeskTextField(label: 'Name *', hint: 'Karigar name', controller: nameCtrl),
              const SizedBox(height: 12),
              GoldDeskTextField(label: 'Mobile *', hint: '10-digit number', controller: mobileCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              GoldDeskTextField(label: 'Specialization', hint: 'e.g. Necklace, Ring...', controller: specCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: createLogin,
                    onChanged: (v) => setModalState(() => createLogin = v ?? false),
                    activeColor: AppColors.gold,
                  ),
                  const Text('Create login access for Karigar'),
                ],
              ),
              if (createLogin) ...[
                const SizedBox(height: 8),
                GoldDeskTextField(label: 'Password', hint: 'Min 6 characters', controller: passwordCtrl, obscureText: true),
              ],
              const SizedBox(height: 20),
              GoldDeskButton(
                text: 'SAVE KARIGAR',
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
                  if (createLogin && passwordCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: AppColors.error),
                    );
                    return;
                  }
                  try {
                    await getIt<MasterRepository>().createKarigar(
                      name: nameCtrl.text.trim(),
                      mobile: mobileCtrl.text.trim(),
                      specialization: specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(),
                      createLogin: createLogin,
                      password: createLogin ? passwordCtrl.text : null,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Karigar added!'), backgroundColor: AppColors.success),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/dashboard')),
        title: const Text('Karigars'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _karigars.isEmpty
              ? const Center(child: Text('No Karigars. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _karigars.length,
                    itemBuilder: (context, index) {
                      final k = _karigars[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryDark.withValues(alpha: 0.1),
                            child: const Icon(Icons.engineering, color: AppColors.primaryDark, size: 20),
                          ),
                          title: Text(k.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${k.mobile}${k.specialization != null ? ' | ${k.specialization}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: k.hasLoginAccess
                              ? const Icon(Icons.phone_android, color: AppColors.success, size: 18)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
