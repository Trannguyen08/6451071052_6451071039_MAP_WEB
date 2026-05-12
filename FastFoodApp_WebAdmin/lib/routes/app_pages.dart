import 'package:get/get.dart';

import '../bindings/home_binding.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/category_management_screen.dart';
import '../screens/admin/order_management_screen.dart';
import '../screens/admin/product_management_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/payment/payment_success_screen.dart';
import '../screens/product/product_detail_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainScreen(initialIndex: 0),
      binding: HomeBinding(),
    ),
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => RegisterScreen()),
    GetPage(name: AppRoutes.verifyOtp, page: () => VerifyOtpScreen()),
    GetPage(
      name: AppRoutes.orderHistory,
      page: () => const MainScreen(initialIndex: 3),
    ),
    GetPage(
      name: AppRoutes.cart,
      page: () => const MainScreen(initialIndex: 2),
    ),
    GetPage(name: AppRoutes.adminLogin, page: () => const AdminLoginScreen()),
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
    GetPage(
      name: AppRoutes.paymentSuccess,
      page: () => const PaymentSuccessScreen(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const MainScreen(initialIndex: 4),
    ),
    GetPage(
      name: AppRoutes.wishlist,
      page: () => const MainScreen(initialIndex: 1),
    ),
    GetPage(name: AppRoutes.productDetail, page: () => ProductDetailScreen()),
  ];
}
