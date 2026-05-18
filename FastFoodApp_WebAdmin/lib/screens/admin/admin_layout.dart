import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/admin_controller.dart';
import 'widgets/admin_sidebar.dart';

class AdminLayout extends StatelessWidget {
  final Widget content;
  final String title;
  final String searchHint;
  final String? createLabel;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onCreate;
  final bool showExport;

  const AdminLayout({
    super.key,
    required this.content,
    this.title = 'Trang quản trị',
    this.searchHint = 'Tìm kiếm tên, email, SĐT...',
    this.createLabel = 'Thêm khách hàng',
    this.onSearch,
    this.onCreate,
    this.showExport = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          const AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const Spacer(),
          if (onSearch != null)
            Container(
              width: 300,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          if (createLabel != null) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 20),
              label: Text(createLabel!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94E1B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (onSearch != null || createLabel != null)
            const SizedBox(width: 12),
          if (showExport) ...[
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 20),
              label: const Text('Xuất file Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}
