import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/models/order_models.dart';
import '../bloc/create_order_cubit.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? orderId;
  const CreateOrderScreen({super.key, this.orderId});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerItem? _selectedCustomer;
  final _orderDateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final List<_OrderItemForm> _items = [_OrderItemForm()];
  List<CustomerItem> _customers = [];
  List<Map<String, dynamic>> _masterItems = [];
  bool _formReady = false;

  bool get _isEdit => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    _orderDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    context.read<CreateOrderCubit>().loadFormData(editOrderId: widget.orderId);
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _totalWeight => _items.fold(0, (sum, item) {
        final weight = double.tryParse(item.weightController.text) ?? 0;
        final pieces = int.tryParse(item.quantityController.text) ?? 1;
        return sum + (weight * pieces);
      });

  void _populateFromOrder(OrderDetail order) {
    _selectedCustomer = CustomerItem(id: order.customerId, name: order.customerName);
    _orderDateController.text = order.orderDate;
    _deliveryDateController.text = order.deliveryDate ?? '';
    for (final item in _items) {
      item.dispose();
    }
    _items.clear();
    for (final i in order.items) {
      final form = _OrderItemForm();
      form.existingId = i.id;
      form.selectedItemId = i.itemMasterId;
      form.nameController.text = i.itemName;
      form.weightController.text = i.weight == 0 ? '' : i.weight.toString();
      form.quantityController.text = i.quantity.toString();
      form.sizeController.text = i.size ?? '';
      form.existingImagePath = i.imagePath;
      _items.add(form);
    }
    if (_items.isEmpty) _items.add(_OrderItemForm());
  }

  void _addItem() {
    setState(() => _items.add(_OrderItemForm()));
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
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

  Future<void> _pickItemImage(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 1200);
    if (photo != null) {
      setState(() => _items[index].localImagePath = photo.path);
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
        items: _items.map((item) {
          return OrderItemRequest(
            id: item.existingId,
            itemMasterId: item.selectedItemId,
            itemName: item.nameController.text,
            weight: double.tryParse(item.weightController.text) ?? 0,
            quantity: int.tryParse(item.quantityController.text) ?? 1,
            size: item.sizeController.text.trim().isEmpty ? null : item.sizeController.text.trim(),
          );
        }).toList(),
      );

      final images = _items.map((item) => item.localImagePath).toList();
      final cubit = context.read<CreateOrderCubit>();
      if (_isEdit) {
        cubit.updateOrder(widget.orderId!, request, itemImages: images);
      } else {
        cubit.createOrder(request, itemImages: images);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateOrderCubit, CreateOrderState>(
      listener: (context, state) {
        if (state is CreateOrderDataLoaded && !_formReady) {
          _customers = state.customers;
          _masterItems = state.items;
          if (state.existingOrder != null) {
            _populateFromOrder(state.existingOrder!);
          }
          setState(() => _formReady = true);
        } else if (state is CreateOrderDataLoaded) {
          _customers = state.customers;
          _masterItems = state.items;
        } else if (state is CreateOrderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEdit ? 'Order ${state.order.orderNo} updated!' : 'Order ${state.order.orderNo} created!'),
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
            onPressed: () => _isEdit ? context.go('/orders/${widget.orderId}') : context.go('/orders'),
          ),
          title: Text(_isEdit ? 'Edit Order' : 'New Order'),
          actions: [
            IconButton(icon: const Icon(Icons.save_outlined), onPressed: _onSave),
          ],
        ),
        body: !_formReady
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Name *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Autocomplete<CustomerItem>(
                        initialValue: TextEditingValue(text: _selectedCustomer?.name ?? ''),
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
                      ...List.generate(_items.length, (index) => _buildItemCard(index)),
                      const SizedBox(height: 16),
                      _buildSummary(),
                      const SizedBox(height: 24),
                      BlocBuilder<CreateOrderCubit, CreateOrderState>(
                        builder: (context, state) {
                          return GoldDeskButton(
                            text: _isEdit ? 'UPDATE ORDER' : 'SAVE ORDER',
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _pickItemImage(index),
                  child: _buildItemThumb(item),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Autocomplete<Map<String, dynamic>>(
                    initialValue: TextEditingValue(text: item.nameController.text),
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
                        onChanged: (v) {
                          if (item.selectedItemId == null) {
                            item.nameController.text = v;
                          }
                        },
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
                                final desc = (opt['category'] ?? '').toString();
                                return ListTile(
                                  dense: true,
                                  title: Text('${opt['itemCode']} - ${opt['name']}', style: const TextStyle(fontSize: 13)),
                                  subtitle: desc.isEmpty ? null : Text(desc, style: const TextStyle(fontSize: 10)),
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _pickItemImage(index),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: Text(item.localImagePath != null || item.existingImagePath != null ? 'Change Image' : 'Capture Image'),
                style: TextButton.styleFrom(foregroundColor: AppColors.gold, padding: EdgeInsets.zero),
              ),
            ),
            const SizedBox(height: 4),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.sizeController,
                    decoration: const InputDecoration(
                      labelText: 'Size',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Piece',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Item weight: ${((double.tryParse(item.weightController.text) ?? 0) * (int.tryParse(item.quantityController.text) ?? 1)).toStringAsFixed(3)} gm',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemThumb(_OrderItemForm item) {
    Widget child;
    if (item.localImagePath != null) {
      child = Image.file(File(item.localImagePath!), width: 56, height: 56, fit: BoxFit.cover);
    } else if (item.existingImagePath != null) {
      child = Image.network(
        '${AppConstants.serverUrl}${item.existingImagePath}',
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _itemPlaceholder(),
      );
    } else {
      child = _itemPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          child,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              color: Colors.black54,
              child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.divider)),
      child: const Icon(Icons.camera_alt_outlined, color: AppColors.gold, size: 22),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Weight', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text('${_totalWeight.toStringAsFixed(3)} gm', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OrderItemForm {
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final sizeController = TextEditingController();
  String? existingId;
  String? selectedItemId;
  String? localImagePath;
  String? existingImagePath;

  void dispose() {
    nameController.dispose();
    weightController.dispose();
    quantityController.dispose();
    sizeController.dispose();
  }
}
