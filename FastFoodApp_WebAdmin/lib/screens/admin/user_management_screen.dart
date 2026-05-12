import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/admin_controller.dart';
import '../../data/models/admin_user_model.dart';
import 'admin_layout.dart';
import 'widgets/stat_card.dart';
import 'widgets/user_data_table.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final AdminController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.requireLogin();
      if (controller.isAuthenticated.value) {
        controller.fetchUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Quan ly khach hang',
      onSearch: controller.onSearch,
      onCreate: () => _showCustomerDialog(context),
      content: Obx(() {
        if (!controller.isAuthenticated.value) {
          return const SizedBox.shrink();
        }

        if (controller.isLoading.value &&
            controller.dashboardData.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.dashboardData.value;
        if (data == null) {
          return const Center(child: Text('Khong co du lieu'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xem danh sach va quan ly tai khoan khach hang.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'TONG KHACH HANG',
                    value: data.total.toString(),
                    percentage: '+12%',
                    icon: Icons.people_alt_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: StatCard(
                    title: 'HOAT DONG',
                    value: data.active.toString(),
                    percentage:
                        '${data.total == 0 ? 0 : (data.active / data.total * 100).round()}%',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: StatCard(
                    title: 'BI KHOA',
                    value: data.blocked.toString(),
                    percentage:
                        '${data.total == 0 ? 0 : (data.blocked / data.total * 100).round()}%',
                    icon: Icons.block_outlined,
                    iconColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: StatCard(
                    title: 'CHI TIEU TB',
                    value: '${data.avgSpending.toInt()}d',
                    percentage: '+5.4%',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            UserDataTable(
              onEdit: (user) => _showCustomerDialog(context, user: user),
            ),
          ],
        );
      }),
    );
  }

  void _showCustomerDialog(BuildContext context, {AdminUser? user}) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final avatarController = TextEditingController(text: user?.avatar ?? '');
    final status = (user?.status ?? 'active').obs;
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Text(user == null ? 'Them khach hang' : 'Sua khach hang'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameController, 'Ho ten'),
                const SizedBox(height: 12),
                _dialogField(emailController, 'Email'),
                const SizedBox(height: 12),
                _dialogField(phoneController, 'So dien thoai'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: avatarController,
                  decoration: const InputDecoration(
                    labelText: 'Avatar URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: status.value,
                    decoration: const InputDecoration(
                      labelText: 'Trang thai',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Hoat dong'),
                      ),
                      DropdownMenuItem(
                        value: 'blocked',
                        child: Text('Bi khoa'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) status.value = value;
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
                      controller.saveUser(
                        currentUser: user,
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        avatar: avatarController.text,
                        status: status.value,
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
      emailController.dispose();
      phoneController.dispose();
      avatarController.dispose();
    });
  }

  TextFormField _dialogField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Bat buoc' : null,
    );
  }
}
