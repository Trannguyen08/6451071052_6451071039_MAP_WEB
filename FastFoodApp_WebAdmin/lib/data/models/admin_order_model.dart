class AdminOrder {
  final String id;
  final String orderCode;
  final String userId;
  final String customerName;
  final String customerPhone;
  final String payment;
  final int itemsCount;
  final double totalAmount;
  final DateTime createdAt;
  String status;

  AdminOrder({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.payment,
    required this.itemsCount,
    required this.totalAmount,
    required this.createdAt,
    required this.status,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return AdminOrder(
      id: json['id'] ?? '',
      orderCode: json['orderCode'] ?? '',
      userId: json['userId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      payment: json['payment'] ?? '',
      itemsCount: items.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1),
      ),
      totalAmount: ((json['totalAmount'] ?? 0) as num).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pending',
    );
  }
}

class AdminOrdersData {
  final int total;
  final int pending;
  final int processing;
  final int completed;
  final int cancelled;
  final double totalRevenue;
  final List<AdminOrder> orders;

  AdminOrdersData({
    required this.total,
    required this.pending,
    required this.processing,
    required this.completed,
    required this.cancelled,
    required this.totalRevenue,
    required this.orders,
  });

  factory AdminOrdersData.fromJson(Map<String, dynamic> json) {
    return AdminOrdersData(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      processing: json['processing'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      totalRevenue: ((json['totalRevenue'] ?? 0) as num).toDouble(),
      orders: (json['orders'] as List<dynamic>? ?? [])
          .map((order) => AdminOrder.fromJson(order))
          .toList(),
    );
  }
}
