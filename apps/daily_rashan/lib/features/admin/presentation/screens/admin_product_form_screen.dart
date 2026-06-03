import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/multi_image_upload_widget.dart';
import '../../data/admin_repository.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  const AdminProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _stockController = TextEditingController(text: '0');

  String? _categoryId;
  List<dynamic> _categories = [];
  List<ProductImageItem> _images = [];
  bool _isFeatured = false;
  bool _loading = true;
  bool _saving = false;
  String? _savedProductId;

  bool get isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _categories = await ref.read(adminRepositoryProvider).getCategories();
    if (isEdit) {
      final product =
          await ref.read(adminRepositoryProvider).getProduct(widget.productId!);
      _nameController.text = product['name'] as String? ?? '';
      _descController.text = product['description'] as String? ?? '';
      _priceController.text = '${product['basePrice']}';
      _discountController.text = product['discountPrice'] != null
          ? '${product['discountPrice']}'
          : '';
      _stockController.text = '${product['stock']}';
      _categoryId = product['categoryId'] as String?;
      _isFeatured = product['isFeatured'] as bool? ?? false;
      _savedProductId = widget.productId;

      final productImages = product['productImages'] as List? ?? [];
      _images = productImages.map((img) {
        final m = img as Map<String, dynamic>;
        return ProductImageItem(
          id: m['id'] as String?,
          imageUrl: m['imageUrl'] as String?,
          thumbnailUrl: m['thumbnailUrl'] as String?,
          publicId: m['publicId'] as String?,
          isFeatured: m['isFeatured'] as bool? ?? false,
          sortOrder: m['sortOrder'] as int? ?? 0,
        );
      }).toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    setState(() => _saving = true);
    final data = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'categoryId': _categoryId,
      'basePrice': double.parse(_priceController.text),
      if (_discountController.text.isNotEmpty)
        'discountPrice': double.parse(_discountController.text),
      'stock': int.parse(_stockController.text),
      'isFeatured': _isFeatured,
      'images': _images.map((i) => i.imageUrl).whereType<String>().toList(),
    };

    try {
      if (isEdit) {
        await ref
            .read(adminRepositoryProvider)
            .updateProduct(widget.productId!, data);
        _savedProductId = widget.productId;
      } else {
        final created =
            await ref.read(adminRepositoryProvider).createProduct(data);
        _savedProductId = created['id'] as String?;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        setState(() {});
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit product' : 'New product')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final previewImages = _images
        .where((i) => i.imageUrl != null || i.thumbnailUrl != null)
        .map((i) => i.thumbnailUrl ?? i.imageUrl!)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit product' : 'New product'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (previewImages.isNotEmpty) ...[
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  viewportFraction: 0.85,
                  enlargeCenterPage: true,
                ),
                items: previewImages.map((url) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product name *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: _categories.map((c) {
                final cat = c as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: cat['id'] as String,
                  child: Text(cat['name'] as String? ?? ''),
                );
              }).toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (₹) *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount price (₹)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Featured product'),
              value: _isFeatured,
              activeThumbColor: AppColors.primaryGreen,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            const SizedBox(height: 24),
            MultiImageUploadWidget(
              productId: _savedProductId,
              images: _images,
              onImagesChanged: (imgs) => setState(() => _images = imgs),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(isEdit ? 'Update product' : 'Create product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
