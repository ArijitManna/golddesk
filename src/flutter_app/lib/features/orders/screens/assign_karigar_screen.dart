import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/di/injection.dart';
import '../bloc/order_detail_cubit.dart';

class AssignKarigarScreen extends StatefulWidget {
  final String orderId;
  const AssignKarigarScreen({super.key, required this.orderId});

  @override
  State<AssignKarigarScreen> createState() => _AssignKarigarScreenState();
}

class _AssignKarigarScreenState extends State<AssignKarigarScreen> {
  final _formKey = GlobalKey<FormState>();
  KarigarItem? _selectedKarigar;
  final _assignDateController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _karigarSearchController = TextEditingController();
  List<KarigarItem> _karigars = [];
  OrderDetail? _order;
  bool _dueDateAuto = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _assignDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        getIt<OrderRepository>().getKarigars(),
        getIt<OrderRepository>().getOrderById(widget.orderId),
      ]);
      final karigars = results[0] as List<KarigarItem>;
      final order = results[1] as OrderDetail;
      final delivery = DateTime.tryParse(order.deliveryDate ?? '');
      String dueText = '';
      var auto = false;
      if (delivery != null) {
        final assignDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        var due = delivery.subtract(const Duration(days: 1));
        if (due.isBefore(assignDay)) due = assignDay;
        dueText = DateFormat('yyyy-MM-dd').format(due);
        auto = true;
      }
      if (!mounted) return;
      setState(() {
        _karigars = karigars;
        _order = order;
        _dueDateController.text = dueText;
        _dueDateAuto = auto;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(date);
      setState(() {});
    }
  }

  void _onAssign() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKarigar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Karigar'), backgroundColor: AppColors.error),
      );
      return;
    }

    final request = AssignKarigarRequest(
      karigarId: _selectedKarigar!.id,
      givenDate: _assignDateController.text,
      dueDate: _dueDateController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    context.read<OrderDetailCubit>().assignKarigar(widget.orderId, request);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders/${widget.orderId}');
    }
  }

  List<KarigarItem> get _filteredKarigars {
    final q = _karigarSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _karigars;
    return _karigars
        .where((k) =>
            k.name.toLowerCase().contains(q) ||
            (k.specialization?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Widget _buildKarigarPicker() {
    final filtered = _filteredKarigars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _karigarSearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search karigar by name or work',
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.gold),
            suffixIcon: _karigarSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _karigarSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No karigar matches your search',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final k = filtered[i];
                    final selected = _selectedKarigar?.id == k.id;
                    return ListTile(
                      dense: true,
                      selected: selected,
                      selectedTileColor: AppColors.gold.withValues(alpha: 0.1),
                      leading: Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? AppColors.gold : AppColors.textLight,
                        size: 20,
                      ),
                      title: Text(
                        k.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: k.specialization != null && k.specialization!.isNotEmpty
                          ? Text(k.specialization!)
                          : null,
                      onTap: () => setState(() => _selectedKarigar = k),
                    );
                  },
                ),
        ),
        if (_selectedKarigar != null) ...[
          const SizedBox(height: 6),
          Text(
            'Selected: ${_selectedKarigar!.name}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.goldBronze,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _assignDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _karigarSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderDetailCubit, OrderDetailState>(
      listener: (context, state) {
        if (state is AssignKarigarSuccess || state is OrderDetailLoaded) {
          if (state is OrderDetailLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Karigar assigned successfully!'), backgroundColor: AppColors.success),
            );
            _close();
          }
        } else if (state is OrderDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _close,
          ),
          title: const Text('Send to Karigar'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_outlined, color: AppColors.gold, size: 20),
                            const SizedBox(width: 8),
                            Text('Order: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            Text(_order?.orderNo ?? widget.orderId.substring(0, 8),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                      if (_order?.deliveryDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Order delivery date: ${_order!.deliveryDate}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text('Karigar', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      if (_karigars.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No connected Karigar yet. Connect a Karigar business first.',
                                style: TextStyle(fontSize: 13),
                              ),
                              TextButton(
                                onPressed: () => context.go('/connections'),
                                child: const Text('Open Connections'),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildKarigarPicker(),
                      const SizedBox(height: 20),
                      GoldDeskTextField(
                        label: 'Assign Date',
                        controller: _assignDateController,
                        readOnly: true,
                        onTap: () => _pickDate(_assignDateController),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      GoldDeskTextField(
                        label: 'Due Date (Target)',
                        hint: _dueDateAuto ? '1 day before order delivery' : 'Select target completion date',
                        controller: _dueDateController,
                        readOnly: true,
                        onTap: _dueDateAuto ? null : () => _pickDate(_dueDateController),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                        validator: (v) => v == null || v.isEmpty ? 'Due date is required' : null,
                      ),
                      if (_dueDateAuto) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Automatically set to 1 day before the order delivery date',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 20),
                      GoldDeskTextField(
                        label: 'Notes (Optional)',
                        hint: 'Any special instructions...',
                        controller: _notesController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<OrderDetailCubit, OrderDetailState>(
                        builder: (context, state) {
                          return GoldDeskButton(
                            text: 'ASSIGN ORDER',
                            onPressed: _karigars.isEmpty ? null : _onAssign,
                            isLoading: state is AssignKarigarLoading,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
