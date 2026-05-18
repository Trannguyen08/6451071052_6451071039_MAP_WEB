import 'package:get/get.dart';

import '../data/models/admin_user_model.dart';
import '../data/services/admin_service.dart';
import '../routes/app_routes.dart';

class AdminController extends GetxController {
  final AdminService _adminService = AdminService();

  final dashboardData = Rxn<AdminDashboardData>();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final searchQuery = ''.obs;
  final isAuthenticated = false.obs;
  final adminName = 'Admin'.obs;

  @override
  void onInit() {
    super.onInit();
    isAuthenticated.value = _adminService.isLoggedIn;
    adminName.value = _adminService.adminName;
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final session = await _adminService.login(email.trim(), password);
      isAuthenticated.value = true;
      adminName.value = session.name;
      Get.offAllNamed(AppRoutes.adminDashboard);
    } catch (e) {
      Get.snackbar('Lỗi đăng nhập', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _adminService.logout();
    isAuthenticated.value = false;
    dashboardData.value = null;
    Get.offAllNamed(AppRoutes.adminLogin);
  }

  void requireLogin() {
    if (!_adminService.isLoggedIn) {
      Get.offAllNamed(AppRoutes.adminLogin);
    }
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      dashboardData.value = await _adminService.getUsers(searchQuery.value);
    } catch (e) {
      if (e.toString().contains('Admin authentication required')) {
        isAuthenticated.value = false;
        Get.offAllNamed(AppRoutes.adminLogin);
        return;
      }
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveUser({
    AdminUser? currentUser,
    required String name,
    required String email,
    required String phone,
    required String avatar,
    required String status,
  }) async {
    final data = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'avatar': avatar.trim(),
      'status': status,
    };

    try {
      isSaving.value = true;
      final success = currentUser == null
          ? await _adminService.createUser(data)
          : await _adminService.updateUser(currentUser.id, data);

      if (success) {
        await fetchUsers();
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      isSaving.value = true;
      final success = await _adminService.deleteUser(userId);
      if (success) {
        await fetchUsers();
      }
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleUserStatus(String userId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'active' ? 'blocked' : 'active';
      final success = await _adminService.updateUserStatus(userId, newStatus);
      if (success) {
        fetchUsers();
      }
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    }
  }

  void onSearch(String query) {
    searchQuery.value = query;
    fetchUsers();
  }
}
