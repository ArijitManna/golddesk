import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/models/order_models.dart';
import '../bloc/create_order_cubit.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerItem? _selectedCustomer;
  final _orderDateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _advanceController = TextEditingController(text: '0');
  final List<_OrderItemForm> _items = [_OrderItemForm()];
  List<CustomerItem> _customers = [];
  List<Map<String, dynamic>> _masterItems = [];

  @override
  void initState() {
    super.initState();
    _orderDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    context.read<CreateOrderCubit>().loadFormData();
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _notesController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  double get _totalWeight =>
      _items.fold(0, (sum, item) => sum + (double.tryParse(item.weightController.text) ?? 0));

  double get _totalMakingCharges =>
      _items.fold(0, (sum, item) => sum + (double.tryParse(item.makingChargeController.text) ?? 0));

  double get _totalAmount => _items.fold(0, (sum, item) {
        final weight = double.tryParse(item.weightController.text) ?? 0;
        final rate = double.tryParse(item.rateController.text) ?? 0;
        final making = double.tryParse(item.makingChargeController.text) ?? 0;
        return sum + (weight * rate) + making;
      });

  void _addItem() {
    setState(() => _items.add(_OrderItemForm()));
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    }
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

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer from the list'), backgroundColor: AppColors.error),
        );
        return;
      }

      final request = CreateOrderRequest(
        customerId: _selectedCustomer!.id,
        orderDate: _orderDateController.text,
        deliveryDate: _deliveryDateController.text.isEmpty ? null : _deliveryDateController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        advancePaid: double.tryParse(_advanceController.text) ?? 0,
        items: _items.map((item) {
          final weight = double.tryParse(item.weightController.text) ?? 0;
          final rate = double.tryParse(item.rateController.text) ?? 0;
          final making = double.tryParse(item.makingChargeController.text) ?? 0;
          final amount = (weight * rate) + making;
          return OrderItemRequest(
            itemMasterId: item.selectedItemId,
            itemName: item.nameController.text,
            weight: weight,
            quantity: int.tryParse(item.quantityController.text) ?? 1,
            purity: item.purityController.text.isEmpty ? null : item.purityController.text,
            rate: rate,
            makingCharge: making,
            amount: amount,
          );
        }).toList(),
      );

      context.read<CreateOrderCubit>().createOrder(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateOrderCubit, CreateOrderState>(
      listener: (context, state) {
        if (state is CreateOrderDataLoaded) {
          _customers = state.customers;
          _masterItems = state.items;
        } else if (state is CreateOrderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${state.order.orderNo} created!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/orders/${state.order.id}');
        } else if (state is CreateOrderError) {
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
            onPressed: () => context.go('/orders'),
          ),
          title: const Text('New Order'),
          actions: [
            IconButton(icon: const Icon(Icons.save_outlined), onPressed: _onSave),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer search field
                Text('Customer Name *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Autocomplete<CustomerItem>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _customers;
                    }
                    return _customers.where((c) =>
                        c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (CustomerItem c) => c.name,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type customer name to search...',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        suffixIcon: _selectedCustomer != null
                            ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                            : null,
                      ),
                      validator: (v) => _selectedCustomer == null ? 'Please select a customer' : null,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final c = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(c.name),
                                subtitle: c.mobile != null ? Text(c.mobile!, style: const TextStyle(fontSize: 11)) : null,
                                onTap: () {
                                  onSelected(c);
                                  setState(() => _selectedCustomer = c);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  onSelected: (CustomerItem selection) {
                    setState(() => _selectedCustomer = selection);
                  },
                ),
                const SizedBox(height: 16),
                // Dates row
                Row(
                  children: [
                    Expanded(
                      child: GoldDeskTextField(
                        label: 'Order Date',
                        controller: _orderDateController,
                        readOnly: true,
                        onTap: () => _pickDate(_orderDateController),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GoldDeskTextField(
                        label: 'Delivery Date',
                        hint: 'Optional',
                        controller: _deliveryDateController,
                        readOnly: true,
                        onTap: () => _pickDate(_deliveryDateController),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Items section
                Row(
                  children: [
                    Text('Items (${_items.length})',
                        style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 18, color: AppColors.gold),
                      label: const Text('Add Item', style: TextStyle(color: AppColors.gold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_items.length, (index) =>
                    _buildItemCard(index)),
                const SizedBox(height: 16),
                // Notes
                GoldDeskTextField(
                  label: 'Notes (Optional)',
                  hint: 'Special design for wedding...',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                // Summary
                _buildSummary(),
                const SizedBox(height: 24),
                // Save button
                BlocBuilder<CreateOrderCubit, CreateOrderState>(
                  builder: (context, state) {
                    return GoldDeskButton(
                      text: 'SAVE ORDER',
                      onPressed: _onSave,
                      isLoading: state is CreateOrderLoading,
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    final weight = double.tryParse(item.weightController.text) ?? 0;
    final rate = double.tryParse(item.rateController.text) ?? 0;
    final making = double.tryParse(item.makingChargeController.text) ?? 0;
    final itemTotal = (weight * rate) + making;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Item search by code/name
            Row(
              children: [
                // Image from master
                if (item.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${AppConstants.serverUrl}${item.imagePath}',
                      width: 44, height: 44, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _itemPlaceholder(),
                    ),
                  )
                else
                  _itemPlaceholder(),
                const SizedBox(width: 10),
                Expanded(
                  child: Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _masterItems;
                      final search = textEditingValue.text.toLowerCase();
                      return _masterItems.where((i) =>
                          (i['itemCode'] ?? '').toString().toLowerCase().contains(search) ||
                          (i['name'] ?? '').toString().toLowerCase().contains(search));
                    },
                    displayStringForOption: (i) => '${i['itemCode']} - ${i['name']}',
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (item.nameController.text.isNotEmpty && controller.text.isEmpty) {
                        controller.text = item.nameController.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search Item Code / Name *',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: Icon(Icons.search, size: 18),
                        ),
                        validator: (v) => item.nameController.text.isEmpty ? 'Select an item' : null,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, i) {
                                final opt = options.elementAt(i);
                                return ListTile(
                                  dense: true,
                                  title: Text('${opt['itemCode']} - ${opt['name']}', style: const TextStyle(fontSize: 13)),
                                  subtitle: Text('${opt['purity'] ?? ''} | Rate: ${opt['defaultRate'] ?? 0}', style: const TextStyle(fontSize: 10)),
                                  onTap: () => onSelected(opt),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    onSelected: (Map<String, dynamic> selection) {
                      setState(() {
                        item.nameController.text = '${selection['itemCode']} - ${selection['name']}';
                        item.selectedItemId = selection['id'];
                        item.purityController.text = selection['purity'] ?? '';
                        item.rateController.text = (selection['defaultRate'] ?? 0).toString();
                        item.makingChargeController.text = (selection['defaultMakingCharge'] ?? 0).toString();
                        item.imagePath = selection['imagePath'];
                      });
                    },
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                    onPressed: () => _removeItem(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (gm)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.purityController,
                    decoration: const InputDecoration(
                      labelText: 'Purity',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate/gm (\u20B9)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.makingChargeController,
                    decoration: const InputDecoration(
                      labelText: 'Making (\u20B9)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Item total
            Row(
              children: [
                const Spacer(),
                Text(
                  'Total: \u20B9${itemTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.gold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemPlaceholder() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.divider)),
      child: const Icon(Icons.diamond_outlined, color: AppColors.gold, size: 20),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _summaryRow('Total Weight', '${_totalWeight.toStringAsFixed(3)} gm'),
          _summaryRow('Making Charges', '\u20B9${_totalMakingCharges.toStringAsFixed(0)}'),
          Row(
            children: [
              const Expanded(child: Text('Advance Paid', style: TextStyle(fontSize: 13))),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _advanceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    prefixText: '\u20B9',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _summaryRow(
            'Estimated Amount',
            '\u20B9${_totalAmount.toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _OrderItemForm {
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final purityController = TextEditingController();
  final rateController = TextEditingController();
  final makingChargeController = TextEditingController();
  String? selectedItemId;
  String? imagePath;
}
