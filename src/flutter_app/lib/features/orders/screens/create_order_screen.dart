import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../data/models/connection_models.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/connection_repository.dart';
import '../../../data/repositories/master_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/create_order_cubit.dart';

class CreateOrderScreen extends StatefulWidget {
  final String? orderId;
  const CreateOrderScreen({super.key, this.orderId});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderDateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_OrderItemForm> _items = [_OrderItemForm()];
  List<Map<String, dynamic>> _masterItems = [];
  List<BusinessConnection> _connectedShops = [];
  BusinessConnection? _selectedShop;
  List<ExternalBusiness> _externalBusinesses = [];
  ExternalBusiness? _selectedExternalBusiness;
  List<BusinessConnection> _connectedShowrooms = [];
  BusinessConnection? _selectedFromShowroom;
  _OrderFromOption? _selectedOrderFrom;
  bool _formReady = false;

  bool get _isEdit => widget.orderId != null;
  bool get _isShowroom =>
      context.read<AuthBloc>().state is AuthAuthenticated &&
      (context.read<AuthBloc>().state as AuthAuthenticated).user.businessType ==
          'Showroom';
  bool get _isShop =>
      context.read<AuthBloc>().state is AuthAuthenticated &&
      (context.read<AuthBloc>().state as AuthAuthenticated).user.businessType ==
          'Shop';

  @override
  void initState() {
    super.initState();
    _orderDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (!_isEdit && _isShowroom) {
      context.read<CreateOrderCubit>().loadFormData();
      _loadConnectedShops();
    } else {
      context.read<CreateOrderCubit>().loadFormData(
        editOrderId: widget.orderId,
      );
      if (!_isEdit && _isShop) {
        _loadExternalBusinesses();
        _loadConnectedShowrooms();
      }
    }
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _totalWeight => _items.fold(0, (sum, item) {
    return sum + (double.tryParse(item.totalWeightController.text) ?? 0);
  });

  void _populateFromOrder(OrderDetail order) {
    _orderDateController.text = order.orderDate;
    _deliveryDateController.text = order.deliveryDate ?? '';
    _notesController.text = order.notes ?? '';
    for (final item in _items) {
      item.dispose();
    }
    _items.clear();
    for (final i in order.items) {
      final form = _OrderItemForm();
      form.existingId = i.id;
      form.selectedItemId = i.itemMasterId;
      form.nameController.text = i.itemName;
      final qty = i.quantity < 1 ? 1 : i.quantity;
      final lineTotal = i.weight * qty;
      form.weightController.text = i.weight == 0 ? '' : i.weight.toString();
      form.quantityController.text = qty.toString();
      form.totalWeightController.text =
          lineTotal == 0 ? '' : lineTotal.toString();
      form.sizeController.text = i.size ?? '';
      form.existingImagePath = i.imagePath;
      _items.add(form);
    }
    if (_items.isEmpty) _items.add(_OrderItemForm());
  }

  void _addItem() {
    setState(() => _items.add(_OrderItemForm()));
  }

  Future<void> _loadConnectedShops() async {
    try {
      final connections = await getIt<ConnectionRepository>().getConnections(
        status: 'Accepted',
        connectionType: 'ShowroomShop',
      );
      if (mounted) {
        setState(
          () => _connectedShops = connections
              .where(
                (connection) => connection.counterpartyBusinessType == 'Shop',
              )
              .toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadExternalBusinesses() async {
    try {
      final businesses = await getIt<MasterRepository>()
          .getExternalBusinesses();
      if (mounted) setState(() => _externalBusinesses = businesses);
    } catch (_) {}
  }

  Future<void> _loadConnectedShowrooms() async {
    try {
      final connections = await getIt<ConnectionRepository>().getConnections(
        status: 'Accepted',
        connectionType: 'ShowroomShop',
      );
      if (mounted) {
        setState(
          () => _connectedShowrooms = connections
              .where(
                (connection) =>
                    connection.counterpartyBusinessType == 'Showroom',
              )
              .toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> _selectShop(BusinessConnection? shop) async {
    setState(() {
      _selectedShop = shop;
    });
  }

  Widget _buildOrderForPicker() {
    final selected = _selectedShop;
    return Autocomplete<BusinessConnection>(
      displayStringForOption: (option) =>
          '${option.counterpartyName} • ${option.counterpartyGoldDeskId}',
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return _connectedShops;
        return _connectedShops.where(
          (shop) =>
              shop.counterpartyName.toLowerCase().contains(query) ||
              shop.counterpartyGoldDeskId.toLowerCase().contains(query),
        );
      },
      onSelected: (shop) => _selectShop(shop),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (selected != null &&
            controller.text.isEmpty &&
            !focusNode.hasFocus) {
          controller.text =
              '${selected.counterpartyName} • ${selected.counterpartyGoldDeskId}';
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search shop name / code',
            prefixIcon: const Icon(
              Icons.storefront_outlined,
              size: 18,
              color: AppColors.goldBronze,
            ),
            suffixIcon: selected == null && controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      setState(() => _selectedShop = null);
                    },
                  ),
          ),
          onChanged: (value) {
            final selectedLabel = selected == null
                ? ''
                : '${selected.counterpartyName} • ${selected.counterpartyGoldDeskId}';
            if (selected != null && value.trim() != selectedLabel) {
              setState(() => _selectedShop = null);
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final maxWidth = MediaQuery.of(context).size.width - 32;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260, maxWidth: maxWidth),
              child: options.isEmpty
                  ? const ListTile(
                      dense: true,
                      title: Text('No matching connected Shop'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final shop = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.goldBronze,
                            size: 18,
                          ),
                          title: Text(
                            shop.counterpartyName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            shop.counterpartyGoldDeskId,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onSelected(shop),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  List<_OrderFromOption> get _orderFromOptions => [
        ..._connectedShowrooms.map(_OrderFromOption.showroom),
        ..._externalBusinesses.map(_OrderFromOption.external),
      ];

  Widget _buildOrderFromPicker() {
    final selected = _selectedOrderFrom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<_OrderFromOption>(
          displayStringForOption: (option) => option.label,
          optionsBuilder: (TextEditingValue value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return _orderFromOptions;
            return _orderFromOptions.where(
              (option) => option.matches(query),
            );
          },
          onSelected: (option) {
            setState(() {
              _selectedOrderFrom = option;
              _selectedFromShowroom = option.showroom;
              _selectedExternalBusiness = option.externalBusiness;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (selected != null &&
                controller.text.isEmpty &&
                !focusNode.hasFocus) {
              controller.text = selected.label;
            }
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Search Showroom ID / External Customer code or name',
                prefixIcon: const Icon(
                  Icons.apartment_outlined,
                  size: 18,
                  color: AppColors.goldBronze,
                ),
                suffixIcon: selected == null && controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clear();
                          setState(() {
                            _selectedOrderFrom = null;
                            _selectedFromShowroom = null;
                            _selectedExternalBusiness = null;
                          });
                        },
                      ),
              ),
              onChanged: (value) {
                if (selected != null && value.trim() != selected.label) {
                  setState(() {
                    _selectedOrderFrom = null;
                    _selectedFromShowroom = null;
                    _selectedExternalBusiness = null;
                  });
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final maxWidth = MediaQuery.of(context).size.width - 32;
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 260,
                    maxWidth: maxWidth,
                  ),
                  child: options.isEmpty
                      ? const ListTile(
                          dense: true,
                          title: Text('No matching Showroom or External Customer'),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                option.isShowroom
                                    ? Icons.apartment_outlined
                                    : Icons.person_outline,
                                color: AppColors.goldBronze,
                                size: 18,
                              ),
                              title: Text(
                                option.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                option.subtitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.goldBronze,
              ),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.goldBronze,
              ),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (photo != null) {
      setState(() => _items[index].localImagePath = photo.path);
    }
  }

  void _onSave() {
    if (_isShowroom && !_isEdit && _selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select the Shop that will fulfil this order'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
      final request = CreateOrderRequest(
        orderFromBusinessId: _selectedExternalBusiness == null
            ? _selectedFromShowroom?.counterpartyBusinessId ?? user.tenantId
            : null,
        orderFromExternalBusinessId: _selectedExternalBusiness?.id,
        orderToBusinessId:
            _selectedShop?.counterpartyBusinessId ?? user.tenantId,
        orderDate: _orderDateController.text,
        deliveryDate: _deliveryDateController.text.isEmpty
            ? null
            : _deliveryDateController.text,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: _items.map((item) {
          final quantity = int.tryParse(item.quantityController.text) ?? 1;
          final safeQty = quantity < 1 ? 1 : quantity;
          final lineTotal =
              double.tryParse(item.totalWeightController.text) ?? 0;
          // Keep existing API contract: Weight * Quantity = line total.
          final unitWeight = lineTotal / safeQty;
          return OrderItemRequest(
            id: item.existingId,
            itemMasterId: item.selectedItemId,
            itemName: item.nameController.text,
            weight: unitWeight,
            quantity: safeQty,
            size: item.sizeController.text.trim().isEmpty
                ? null
                : item.sizeController.text.trim(),
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
          _masterItems = state.items;
          if (state.existingOrder != null) {
            _populateFromOrder(state.existingOrder!);
          }
          setState(() => _formReady = true);
        } else if (state is CreateOrderDataLoaded) {
          _masterItems = state.items;
        } else if (state is CreateOrderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEdit
                    ? 'Order ${state.order.orderNo} updated!'
                    : 'Order ${state.order.orderNo} created!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/orders/${state.order.id}');
        } else if (state is CreateOrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navBar,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => _isEdit
                ? context.go('/orders/${widget.orderId}')
                : context.go('/orders'),
          ),
          title: Text(
            _isEdit ? 'Edit Order' : 'New Order',
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.task_alt_outlined),
              tooltip: _isEdit ? 'Update Order' : 'Save Order',
              onPressed: _onSave,
            ),
          ],
        ),
        body: !_formReady
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isShowroom && !_isEdit) ...[
                        _sectionCard(
                          title: 'Order For',
                          icon: Icons.storefront_outlined,
                          child: _buildOrderForPicker(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_isShop && !_isEdit) ...[
                        _sectionCard(
                          title: 'Order From',
                          icon: Icons.apartment_outlined,
                          child: _buildOrderFromPicker(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _sectionCard(
                        title: 'Order Info',
                        icon: Icons.info_outline,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GoldDeskTextField(
                                    label: 'Order Date',
                                    controller: _orderDateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _pickDate(_orderDateController),
                                    suffixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: AppColors.goldBronze,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GoldDeskTextField(
                                    label: 'Delivery Date',
                                    hint: 'Optional',
                                    controller: _deliveryDateController,
                                    readOnly: true,
                                    onTap: () =>
                                        _pickDate(_deliveryDateController),
                                    suffixIcon: const Icon(
                                      Icons.local_shipping_outlined,
                                      size: 16,
                                      color: AppColors.goldBronze,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GoldDeskTextField(
                              label: 'Short Note',
                              hint: 'Optional',
                              controller: _notesController,
                              maxLines: 2,
                              maxLength: 200,
                              prefixIcon: const Icon(
                                Icons.notes_outlined,
                                size: 18,
                                color: AppColors.goldBronze,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Items',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: AppColors.goldBronze,
                            ),
                            label: const Text(
                              'Add',
                              style: TextStyle(
                                color: AppColors.goldBronze,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(
                        _items.length,
                        (index) => _buildItemCard(index),
                      ),
                      const SizedBox(height: 8),
                      _buildSummary(),
                      const SizedBox(height: 16),
                      BlocBuilder<CreateOrderCubit, CreateOrderState>(
                        builder: (context, state) {
                          final loading = state is CreateOrderLoading;
                          if (loading) {
                            return const SizedBox(
                              height: 44,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gold,
                                ),
                              ),
                            );
                          }
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _onSave,
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.goldLight,
                                      AppColors.gold,
                                      AppColors.goldBronze,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEdit
                                          ? Icons.edit_outlined
                                          : Icons.task_alt,
                                      size: 18,
                                      color: AppColors.textOnGold,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEdit ? 'UPDATE ORDER' : 'SAVE ORDER',
                                      style: const TextStyle(
                                        color: AppColors.textOnGold,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.goldBronze),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _pickItemImage(index),
                child: _buildItemThumb(item),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Autocomplete<Map<String, dynamic>>(
                  initialValue: TextEditingValue(
                    text: item.nameController.text,
                  ),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _masterItems;
                    final search = textEditingValue.text.toLowerCase();
                    return _masterItems.where(
                      (i) =>
                          (i['itemCode'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(search) ||
                          (i['name'] ?? '').toString().toLowerCase().contains(
                                search,
                              ),
                    );
                  },
                  displayStringForOption: (i) =>
                      '${i['itemCode']} - ${i['name']}',
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    if (item.nameController.text.isNotEmpty &&
                        controller.text.isEmpty) {
                      controller.text = item.nameController.text;
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Item Code / Name *',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: AppColors.goldBronze,
                        ),
                      ),
                      validator: (v) => item.nameController.text.isEmpty
                          ? 'Select an item'
                          : null,
                      onChanged: (v) {
                        if (item.selectedItemId == null) {
                          item.nameController.text = v;
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final maxWidth = MediaQuery.of(context).size.width - 72;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 200,
                            maxWidth: maxWidth,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, i) {
                              final opt = options.elementAt(i);
                              final desc = (opt['category'] ?? '').toString();
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                title: Text(
                                  '${opt['itemCode']} - ${opt['name']}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: desc.isEmpty
                                    ? null
                                    : Text(
                                        desc,
                                        style: const TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                      item.nameController.text =
                          '${selection['itemCode']} - ${selection['name']}';
                      item.selectedItemId = selection['id'];
                    });
                  },
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.totalWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (gm)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                      size: 14,
                      color: AppColors.goldBronze,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v);
                    if (n == null || n < 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: item.sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(
                      Icons.straighten,
                      size: 14,
                      color: AppColors.goldBronze,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: item.quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Piece',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(
                      Icons.numbers,
                      size: 14,
                      color: AppColors.goldBronze,
                    ),
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
        ],
      ),
    );
  }

  Widget _buildItemThumb(_OrderItemForm item) {
    Widget child;
    if (item.localImagePath != null) {
      child = Image.file(
        File(item.localImagePath!),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      );
    } else if (item.existingImagePath != null) {
      child = Image.network(
        '${AppConstants.serverUrl}${item.existingImagePath}',
        width: 48,
        height: 48,
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
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                ),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.pastelGold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: const Icon(
        Icons.add_a_photo_outlined,
        color: AppColors.goldBronze,
        size: 20,
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.pastelGold.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monitor_weight_outlined,
            size: 14,
            color: AppColors.goldBronze,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Total Weight',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${_totalWeight.toStringAsFixed(3)} gm',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.goldBronze,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderFromOption {
  final BusinessConnection? showroom;
  final ExternalBusiness? externalBusiness;

  const _OrderFromOption._({this.showroom, this.externalBusiness});

  factory _OrderFromOption.showroom(BusinessConnection showroom) =>
      _OrderFromOption._(showroom: showroom);

  factory _OrderFromOption.external(ExternalBusiness externalBusiness) =>
      _OrderFromOption._(externalBusiness: externalBusiness);

  bool get isShowroom => showroom != null;

  String get title => isShowroom
      ? showroom!.counterpartyName
      : externalBusiness!.name;

  String get subtitle => isShowroom
      ? '${showroom!.counterpartyGoldDeskId} • Showroom'
      : '${externalBusiness!.customerCode} • External Customer';

  String get label => '$title • $subtitle';

  bool matches(String query) {
    if (isShowroom) {
      return showroom!.counterpartyName.toLowerCase().contains(query) ||
          showroom!.counterpartyGoldDeskId.toLowerCase().contains(query);
    }
    return externalBusiness!.customerCode.toLowerCase().contains(query) ||
        externalBusiness!.name.toLowerCase().contains(query) ||
        (externalBusiness!.mobile?.toLowerCase().contains(query) ?? false);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _OrderFromOption &&
        other.showroom?.counterpartyBusinessId ==
            showroom?.counterpartyBusinessId &&
        other.externalBusiness?.id == externalBusiness?.id;
  }

  @override
  int get hashCode =>
      Object.hash(showroom?.counterpartyBusinessId, externalBusiness?.id);
}

class _OrderItemForm {
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final totalWeightController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final sizeController = TextEditingController();
  String? existingId;
  String? selectedItemId;
  String? localImagePath;
  String? existingImagePath;

  void dispose() {
    nameController.dispose();
    weightController.dispose();
    totalWeightController.dispose();
    quantityController.dispose();
    sizeController.dispose();
  }
}
