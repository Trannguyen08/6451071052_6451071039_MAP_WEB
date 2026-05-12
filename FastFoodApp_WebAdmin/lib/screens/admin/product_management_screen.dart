import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/admin_catalog_controller.dart';
import '../../data/models/product_model.dart';
import 'admin_layout.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  late final AdminCatalogController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminCatalogController>()
        ? Get.find<AdminCatalogController>()
        : Get.put(AdminCatalogController());
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Quan ly san pham',
      searchHint: 'Tim ten san pham...',
      createLabel: 'Them san pham',
      onSearch: controller.searchProducts,
      onCreate: () => _showProductDialog(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryFilter(),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.isLoading.value && controller.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  if (controller.products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Chua co san pham'),
                    )
                  else
                    ...controller.products.map(_buildRow),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Obx(
      () => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 260,
          child: DropdownButtonFormField<String>(
            initialValue: controller.selectedCategoryId.value,
            decoration: const InputDecoration(
              labelText: 'Loc danh muc',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tat ca danh muc'),
              ),
              ...controller.categories.map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) controller.filterProductsByCategory(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('San pham', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Mo ta', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Danh muc', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Gia', style: _headerStyle)),
          Expanded(flex: 1, child: Text('Tac vu', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildRow(ProductModel product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.imageUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 54,
                      height: 54,
                      color: const Color(0xFFFFF0EB),
                      child: const Icon(
                        Icons.fastfood,
                        color: Color(0xFFE94E1B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(controller.categoryName(product.categoryId)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${product.price.toInt()}d',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showProductDialog(product: product);
                if (value == 'delete') _confirmDelete(product);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Sua')),
                PopupMenuItem(value: 'delete', child: Text('Xoa')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({ProductModel? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );
    final imageController = TextEditingController(
      text: product?.imageUrl ?? '',
    );
    final selectedCategory =
        (product?.categoryId ??
                (controller.categories.isNotEmpty
                    ? controller.categories.first.id
                    : ''))
            .obs;
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Text(product == null ? 'Them san pham' : 'Sua san pham'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameController, 'Ten san pham'),
                const SizedBox(height: 12),
                _field(descriptionController, 'Mo ta', maxLines: 2),
                const SizedBox(height: 12),
                _field(
                  priceController,
                  'Gia',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _field(imageController, 'Image URL', required: false),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: selectedCategory.value.isEmpty
                        ? null
                        : selectedCategory.value,
                    decoration: const InputDecoration(
                      labelText: 'Danh muc',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Chon danh muc' : null,
                    onChanged: (value) {
                      if (value != null) selectedCategory.value = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Huy')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () {
                      if (!formKey.currentState!.validate()) return;
                      controller.saveProduct(
                        currentProduct: product,
                        name: nameController.text,
                        description: descriptionController.text,
                        price: priceController.text,
                        imageUrl: imageController.text,
                        categoryId: selectedCategory.value,
                      );
                    },
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Luu'),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      descriptionController.dispose();
      priceController.dispose();
      imageController.dispose();
    });
  }

  TextFormField _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Bat buoc' : null
          : null,
    );
  }

  void _confirmDelete(ProductModel product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xoa san pham'),
        content: Text('Ban co chac muon xoa ${product.name}?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Huy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(product.id);
            },
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.grey);
