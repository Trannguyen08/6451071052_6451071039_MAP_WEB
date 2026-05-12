import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/admin_controller.dart';
import '../../../data/models/admin_user_model.dart';

class UserDataTable extends StatelessWidget {
  final ValueChanged<AdminUser> onEdit;

  const UserDataTable({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Obx(() {
            final users = controller.dashboardData.value?.users ?? [];
            if (users.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Khong tim thay khach hang'),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (context, index) =>
                  _buildUserRow(users[index], controller),
            );
          }),
          _buildPagination(controller),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Khach hang',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Lien he',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Don',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Tong chi tieu',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Trang thai',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Tac vu',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(AdminUser user, AdminController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(user.avatar)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${user.id}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(user.phone, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.email, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(user.email, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${user.ordersCount} don')),
          Expanded(
            flex: 2,
            child: Text(
              '${user.totalSpending.toInt()}d',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: user.status == 'active'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: user.status == 'active'
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.status == 'active' ? 'Hoat dong' : 'Bi khoa',
                      style: TextStyle(
                        color: user.status == 'active'
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _showActionMenu(user, controller),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(AdminUser user, AdminController controller) {
    Get.dialog(
      AlertDialog(
        title: Text('Thao tac voi ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                user.status == 'active' ? Icons.block : Icons.check_circle,
                color: user.status == 'active' ? Colors.red : Colors.green,
              ),
              title: Text(
                user.status == 'active'
                    ? 'Khoa tai khoan'
                    : 'Mo khoa tai khoan',
              ),
              onTap: () {
                controller.toggleUserStatus(user.id, user.status);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Chinh sua thong tin'),
              onTap: () {
                Get.back();
                onEdit(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xoa khach hang'),
              onTap: () {
                Get.back();
                _confirmDelete(user, controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AdminUser user, AdminController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xoa khach hang'),
        content: Text('Ban co chac muon xoa ${user.name}?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Huy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.deleteUser(user.id);
            },
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(AdminController controller) {
    return Obx(() {
      final total = controller.dashboardData.value?.total ?? 0;
      final shown = controller.dashboardData.value?.users.length ?? 0;

      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hien thi $shown cua $total khach hang',
              style: const TextStyle(color: Colors.grey),
            ),
            Row(
              children: [
                _buildPageButton('<', isEnabled: false),
                _buildPageButton('1', isActive: true),
                _buildPageButton('>'),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPageButton(
    String text, {
    bool isActive = false,
    bool isEnabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE94E1B) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isEnabled ? Colors.black : Colors.grey),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
