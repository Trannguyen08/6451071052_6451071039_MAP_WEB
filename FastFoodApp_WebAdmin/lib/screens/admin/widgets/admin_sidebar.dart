import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/admin_controller.dart';
import '../../../routes/app_routes.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'FoodHero',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE94E1B),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildUserInfo(),
          const SizedBox(height: 32),
          _buildMenuItem(
            Icons.dashboard_outlined,
            'Dashboard',
            route: AppRoutes.adminDashboard,
          ),
          _buildMenuItem(
            Icons.shopping_bag_outlined,
            'Đơn hàng',
            route: AppRoutes.adminOrders,
          ),
          _buildMenuItem(
            Icons.category_outlined,
            'Danh mục',
            route: AppRoutes.adminCategories,
          ),
          _buildMenuItem(
            Icons.restaurant_menu_outlined,
            'Sản phẩm',
            route: AppRoutes.adminProducts,
          ),
          _buildMenuItem(
            Icons.people_outline,
            'Khách hàng',
            route: AppRoutes.adminUsers,
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final controller = Get.isRegistered<AdminController>()
        ? Get.find<AdminController>()
        : Get.put(AdminController());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFFFD6CC),
            child: Icon(Icons.admin_panel_settings, color: Color(0xFFE94E1B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    controller.adminName.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Quản lý cửa hàng',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String? route}) {
    final isActive = route != null && Get.currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE94E1B) : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[800],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: route == null || isActive ? null : () => Get.offNamed(route),
      ),
    );
  }
}
