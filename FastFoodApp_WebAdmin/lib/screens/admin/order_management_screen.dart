import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/admin_order_controller.dart';
import '../../data/models/admin_order_model.dart';
import 'admin_layout.dart';
import 'widgets/stat_card.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  late final AdminOrderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminOrderController>()
        ? Get.find<AdminOrderController>()
        : Get.put(AdminOrderController());
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Quản lý đơn hàng',
      searchHint: 'Tìm mã đơn, khách hàng, SĐT...',
      createLabel: null,
      onSearch: controller.onSearch,
      content: Obx(() {
        if (controller.isLoading.value && controller.ordersData.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.ordersData.value;
        if (data == null) {
          return const Center(child: Text('Không có dữ liệu đơn hàng'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo dõi đơn hàng và cập nhật trạng thái từ dữ liệu Firebase.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'TỔNG ĐƠN',
                    value: data.total.toString(),
                    percentage: '${data.pending} chờ xử lý',
                    icon: Icons.receipt_long_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: StatCard(
                    title: 'ĐANG XỬ LÝ',
                    value: data.processing.toString(),
                    percentage: 'processing',
                    icon: Icons.local_shipping_outlined,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: StatCard(
                    title: 'HOÀN TẤT',
                    value: data.completed.toString(),
                    percentage: 'delivered',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: StatCard(
                    title: 'DOANH THU',
                    value: '${data.totalRevenue.toInt()}d',
                    percentage: '${data.cancelled} đã hủy',
                    icon: Icons.payments_outlined,
                    iconColor: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            _OrdersTable(controller: controller),
          ],
        );
      }),
    );
  }

  Widget _buildFilters() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 240,
        child: Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.selectedStatus.value,
            decoration: const InputDecoration(
              labelText: 'Lọc trạng thái',
              border: OutlineInputBorder(),
            ),
            items: controller.statusOptions
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_statusLabel(status)),
                  ),
                )
                .toList(),
            onChanged: (status) {
              if (status != null) controller.onStatusFilterChanged(status);
            },
          ),
        ),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final AdminOrderController controller;

  const _OrdersTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Obx(() {
            final orders = controller.ordersData.value?.orders ?? [];
            if (orders.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Không tìm thấy đơn hàng'),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildRow(orders[index]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Đơn hàng', style: _headerStyle)),
          Expanded(flex: 3, child: Text('Khách hàng', style: _headerStyle)),
          Expanded(flex: 1, child: Text('Món', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Tổng tiền', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Ngày tạo', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Trạng thái', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildRow(AdminOrder order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderCode,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  order.id,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName.isEmpty
                      ? order.userId
                      : order.customerName,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  order.customerPhone.isEmpty
                      ? order.payment
                      : order.customerPhone,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${order.itemsCount}')),
          Expanded(
            flex: 2,
            child: Text(
              '${order.totalAmount.toInt()}d',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
            ),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: order.status,
                items: controller.statusOptions
                    .where((status) => status != 'all')
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (status) {
                  if (status != null) {
                    controller.updateStatus(order, status);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'all':
      return 'Tất cả';
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

const _headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.grey);
