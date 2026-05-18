import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/admin_dashboard_controller.dart';
import '../../data/models/admin_order_model.dart';
import '../../routes/app_routes.dart';
import 'admin_layout.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AdminDashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminDashboardController>()
        ? Get.find<AdminDashboardController>()
        : Get.put(AdminDashboardController());
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      searchHint: 'Tổng quan hệ thống',
      createLabel: null,
      onSearch: null,
      content: Obx(() {
        if (controller.isLoading.value && controller.overview.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.overview.value;
        if (data == null) {
          return const Center(child: Text('Không có dữ liệu dashboard'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan vận hành của cửa hàng trong một màn hình.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'DOANH THU',
                    value: '${data.totalRevenue.toInt()}đ',
                    percentage: '${data.completedOrders} đơn hoàn tất',
                    icon: Icons.payments_outlined,
                    iconColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'ĐƠN HÀNG',
                    value: data.totalOrders.toString(),
                    percentage: '${data.pendingOrders} chờ xử lý',
                    icon: Icons.receipt_long_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'KHÁCH HÀNG',
                    value: data.totalUsers.toString(),
                    percentage: '${data.activeUsers} đang hoạt động',
                    icon: Icons.people_alt_outlined,
                    iconColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: StatCard(
                    title: 'SẢN PHẨM',
                    value: data.totalProducts.toString(),
                    percentage: '${data.totalCategories} danh mục',
                    icon: Icons.restaurant_menu_outlined,
                    iconColor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _RecentOrders(orders: data.recentOrders),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _StatusSummary(
                        pending: data.pendingOrders,
                        processing: data.processingOrders,
                        completed: data.completedOrders,
                        cancelled: data.cancelledOrders,
                      ),
                      const SizedBox(height: 20),
                      const _QuickActions(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  final List<AdminOrder> orders;

  const _RecentOrders({required this.orders});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Đơn hàng mới nhất',
      child: orders.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Chưa có đơn hàng'),
            )
          : Column(
              children: orders
                  .map(
                    (order) => ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFF0EB),
                        child: Icon(
                          Icons.receipt_long,
                          color: Color(0xFFE94E1B),
                        ),
                      ),
                      title: Text(order.orderCode),
                      subtitle: Text(
                        order.customerName.isEmpty
                            ? order.userId
                            : order.customerName,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${order.totalAmount.toInt()}đ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _statusLabel(order.status),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  final int pending;
  final int processing;
  final int completed;
  final int cancelled;

  const _StatusSummary({
    required this.pending,
    required this.processing,
    required this.completed,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Trạng thái đơn hàng',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _row('Chờ xử lý', pending, Colors.orange),
            _row('Đang xử lý', processing, Colors.blue),
            _row('Hoàn tất', completed, Colors.green),
            _row('Đã hủy', cancelled, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Đi nhanh',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _button(
              'Đơn hàng',
              Icons.shopping_bag_outlined,
              AppRoutes.adminOrders,
            ),
            _button(
              'Sản phẩm',
              Icons.restaurant_menu_outlined,
              AppRoutes.adminProducts,
            ),
            _button(
              'Danh mục',
              Icons.category_outlined,
              AppRoutes.adminCategories,
            ),
            _button('Khách hàng', Icons.people_outline, AppRoutes.adminUsers),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, IconData icon, String route) {
    return OutlinedButton.icon(
      onPressed: () => Get.offNamed(route),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Chờ xử lý';
    case 'pending_payment':
      return 'Chờ thanh toán';
    case 'processing':
      return 'Đang xử lý';
    case 'delivered':
      return 'Đã giao';
    case 'completed':
      return 'Hoàn tất';
    case 'cancelled':
      return 'Đã hủy';
    default:
      return status;
  }
}
