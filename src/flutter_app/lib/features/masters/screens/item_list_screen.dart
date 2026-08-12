import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/golddesk_button.dart';
import '../../../core/widgets/golddesk_text_field.dart';
import '../../../core/widgets/order_image.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await getIt<ApiClient>().dio.get('/items', queryParameters: {'pageSize': 100});
      _items = List<Map<String, dynamic>>.from(response.data['items']);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showAddDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final purityCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final makingCtrl = TextEditingController();
    String? imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add Item', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                GoldDeskTextField(label: 'Item Code *', hint: 'e.g. GN-001, BR-22K', controller: codeCtrl),
                const SizedBox(height: 12),
                GoldDeskTextField(label: 'Item Name *', hint: 'Gold Necklace', controller: nameCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: GoldDeskTextField(label: 'Category', hint: 'Necklace', controller: categoryCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: GoldDeskTextField(label: 'Purity', hint: '22K', controller: purityCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: GoldDeskTextField(label: 'Rate/gm', hint: '0', controller: rateCtrl, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: GoldDeskTextField(label: 'Making Charge', hint: '0', controller: makingCtrl, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                // Image picker
                Row(
                  children: [
                    if (imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(imagePath!), width: 60, height: 60, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.divider)),
                        child: const Icon(Icons.image_outlined, color: AppColors.textLight),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 800);
                          if (photo != null) {
                            setModalState(() => imagePath = photo.path);
                          }
                        },
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: Text(imagePath != null ? 'Change Photo' : 'Add Photo from Gallery'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GoldDeskButton(
                  text: 'SAVE ITEM',
                  onPressed: () async {
                    if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item code and name are required'), backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    try {
                      // Create item
                      final response = await getIt<ApiClient>().dio.post('/items', data: {
                        'itemCode': codeCtrl.text.trim(),
                        'name': nameCtrl.text.trim(),
                        'category': categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                        'purity': purityCtrl.text.trim().isEmpty ? null : purityCtrl.text.trim(),
                        'defaultRate': double.tryParse(rateCtrl.text) ?? 0,
                        'defaultMakingCharge': double.tryParse(makingCtrl.text) ?? 0,
                      });

                      // Upload image if selected
                      if (imagePath != null && response.data['id'] != null) {
                        final itemId = response.data['id'];
                        final formData = FormData.fromMap({
                          'file': await MultipartFile.fromFile(imagePath!, filename: imagePath!.split('/').last),
                        });
                        await getIt<ApiClient>().dio.post('/files/upload/item/$itemId', data: formData);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item added!'), backgroundColor: AppColors.success),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/dashboard')),
        title: const Text('Item Master'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _items.isEmpty
              ? const Center(child: Text('No items. Tap + to add.', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              OrderImage(imagePath: item['imagePath'], size: 50, label: item['name']),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryDark.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(item['itemCode'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['purity'] ?? ''} | Rate: \u20B9${(item['defaultRate'] ?? 0).toStringAsFixed(0)} | Making: \u20B9${(item['defaultMakingCharge'] ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
