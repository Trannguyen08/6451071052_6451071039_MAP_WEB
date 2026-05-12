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
      title: 'Quan ly danh muc',
      searchHint: 'Tim ten danh muc...',
      createLabel: 'Them danh muc',
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
                  child: Text('Chua co danh muc'),
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
          Expanded(flex: 1, child: Text('Icon', style: _headerStyle)),
          Expanded(flex: 4, child: Text('Ten danh muc', style: _headerStyle)),
          Expanded(flex: 4, child: Text('ID Firebase', style: _headerStyle)),
          Expanded(flex: 1, child: Text('Tac vu', style: _headerStyle)),
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
            flex: 1,
            child: Text(category.icon, style: const TextStyle(fontSize: 28)),
          ),
          Expanded(
            flex: 4,
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
                PopupMenuItem(value: 'edit', child: Text('Sua')),
                PopupMenuItem(value: 'delete', child: Text('Xoa')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '🍔');
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Text(category == null ? 'Them danh muc' : 'Sua danh muc'),
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
                    labelText: 'Ten danh muc',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Bat buoc' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
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
                      controller.saveCategory(
                        currentCategory: category,
                        name: nameController.text,
                        icon: iconController.text,
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
      iconController.dispose();
    });
  }

  void _confirmDelete(CategoryModel category) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xoa danh muc'),
        content: Text('Ban co chac muon xoa ${category.name}?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Huy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteCategory(category.id);
            },
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.grey);
