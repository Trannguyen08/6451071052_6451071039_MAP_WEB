import 'package:get/get.dart';

import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/category_management_screen.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/order_management_screen.dart';
import '../screens/admin/product_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.adminLogin, page: () => const AdminLoginScreen()),
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const DashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.adminOrders,
      page: () => const OrderManagementScreen(),
    ),
    GetPage(
      name: AppRoutes.adminCategories,
      page: () => const CategoryManagementScreen(),
    ),
    GetPage(
      name: AppRoutes.adminProducts,
      page: () => const ProductManagementScreen(),
    ),
    GetPage(
      name: AppRoutes.adminUsers,
      page: () => const UserManagementScreen(),
    ),
  ];
}
