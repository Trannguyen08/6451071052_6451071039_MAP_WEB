import 'package:get/get.dart';

import '../data/models/admin_order_model.dart';
import '../data/services/admin_service.dart';
import '../routes/app_routes.dart';

class AdminOrderController extends GetxController {
  final AdminService _adminService = AdminService();

  final ordersData = Rxn<AdminOrdersData>();
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;

  final statusOptions = const [
    'all',
    'pending',
    'pending_payment',
    'processing',
    'delivered',
    'completed',
    'cancelled',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (!_adminService.isLoggedIn) {
      Get.offAllNamed(AppRoutes.adminLogin);
      return;
    }

    try {
      isLoading.value = true;
      ordersData.value = await _adminService.getOrders(
        search: searchQuery.value,
        status: selectedStatus.value,
      );
    } catch (e) {
      if (e.toString().contains('Admin authentication required')) {
        Get.offAllNamed(AppRoutes.adminLogin);
        return;
      }
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String query) {
    searchQuery.value = query;
    fetchOrders();
  }

  void onStatusFilterChanged(String status) {
    selectedStatus.value = status;
    fetchOrders();
  }

  Future<void> updateStatus(AdminOrder order, String status) async {
    final normalizedStatus = _normalizeStatus(status);
    if (order.status == normalizedStatus ||
        !statusOptions.contains(normalizedStatus) ||
        normalizedStatus == 'all') {
      return;
    }

    try {
      final success = await _adminService.updateOrderStatus(
        order.id,
        normalizedStatus,
      );
      if (success) {
        await fetchOrders();
      }
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    }
  }

  String _normalizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'delivere':
        return 'delivered';
      case 'complete':
        return 'completed';
      default:
        return status.trim().toLowerCase();
    }
  }
}
