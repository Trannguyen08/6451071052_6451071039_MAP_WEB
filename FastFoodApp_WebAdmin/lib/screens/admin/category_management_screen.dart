import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/admin_catalog_controller.dart';
import '../../data/models/category_model.dart';
import 'admin_layout.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
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
      title: 'Quản lý danh mục',
      searchHint: 'Tìm tên danh mục...',
      createLabel: 'Thêm danh mục',
      onSearch: controller.searchCategories,
      onCreate: () => _showCategoryDialog(),
      content: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
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
              if (controller.categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Chưa có danh mục'),
                )
              else
                ...controller.categories.map(_buildRow),
            ],
          ),
        );
      }),
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
          Expanded(flex: 5, child: Text('Tên danh mục', style: _headerStyle)),
          Expanded(flex: 4, child: Text('ID Firebase', style: _headerStyle)),
          Expanded(flex: 1, child: Text('Tác vụ', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildRow(CategoryModel category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              category.id,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showCategoryDialog(category: category);
                if (value == 'delete') _confirmDelete(category);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () {
                      if (!formKey.currentState!.validate()) return;
                      controller.saveCategory(
                        currentCategory: category,
                        name: nameController.text,
                      );
                    },
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu'),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
    });
  }

  void _confirmDelete(CategoryModel category) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text('Bạn có chắc muốn xóa ${category.name}?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteCategory(category.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.grey);
