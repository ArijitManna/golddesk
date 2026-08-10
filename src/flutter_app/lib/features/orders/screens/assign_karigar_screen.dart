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
  List<KarigarItem> _karigars = [];

  @override
  void initState() {
    super.initState();
    _assignDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadKarigars();
  }

  Future<void> _loadKarigars() async {
    try {
      final karigars = await getIt<OrderRepository>().getKarigars();
      setState(() => _karigars = karigars);
    } catch (_) {}
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  @override
  void dispose() {
    _assignDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
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
            context.go('/orders/${widget.orderId}');
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
            onPressed: () => context.go('/orders/${widget.orderId}'),
          ),
          title: const Text('Assign Karigar'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order number display
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
                      Text(widget.orderId.substring(0, 8) + '...',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Karigar selection
                Text('Karigar', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<KarigarItem>(
                  value: _selectedKarigar,
                  items: _karigars.map((k) => DropdownMenuItem(
                    value: k,
                    child: Text('${k.name}${k.specialization != null ? ' (${k.specialization})' : ''}'),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedKarigar = val),
                  decoration: const InputDecoration(hintText: 'Select Karigar'),
                  validator: (val) => val == null ? 'Karigar is required' : null,
                ),
                const SizedBox(height: 20),
                // Assign Date
                GoldDeskTextField(
                  label: 'Assign Date',
                  controller: _assignDateController,
                  readOnly: true,
                  onTap: () => _pickDate(_assignDateController),
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                // Due Date (Target)
                GoldDeskTextField(
                  label: 'Due Date (Target)',
                  hint: 'Select target completion date',
                  controller: _dueDateController,
                  readOnly: true,
                  onTap: () => _pickDate(_dueDateController),
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  validator: (v) => v == null || v.isEmpty ? 'Due date is required' : null,
                ),
                const SizedBox(height: 20),
                // Notes
                GoldDeskTextField(
                  label: 'Notes (Optional)',
                  hint: 'Any special instructions...',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                // Assign button
                BlocBuilder<OrderDetailCubit, OrderDetailState>(
                  builder: (context, state) {
                    return GoldDeskButton(
                      text: 'ASSIGN ORDER',
                      onPressed: _onAssign,
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
