import 'package:get/get.dart';

import '../data/models/admin_dashboard_model.dart';
import '../data/services/admin_service.dart';
import '../routes/app_routes.dart';

class AdminDashboardController extends GetxController {
  final AdminService _adminService = AdminService();

  final overview = Rxn<AdminDashboardOverview>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOverview();
  }

  Future<void> fetchOverview() async {
    if (!_adminService.isLoggedIn) {
      Get.offAllNamed(AppRoutes.adminLogin);
      return;
    }

    try {
      isLoading.value = true;
      overview.value = await _adminService.getDashboardOverview();
    } catch (e) {
      if (e.toString().contains('Admin authentication required')) {
        Get.offAllNamed(AppRoutes.adminLogin);
        return;
      }
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
