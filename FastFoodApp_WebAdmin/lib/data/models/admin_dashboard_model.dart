import 'admin_order_model.dart';

class AdminDashboardOverview {
  final int totalUsers;
  final int activeUsers;
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int totalCategories;
  final int totalProducts;
  final double totalRevenue;
  final List<AdminOrder> recentOrders;

  const AdminDashboardOverview({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalCategories,
    required this.totalProducts,
    required this.totalRevenue,
    required this.recentOrders,
  });

  factory AdminDashboardOverview.fromJson(Map<String, dynamic> json) {
    return AdminDashboardOverview(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      processingOrders: json['processingOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      totalCategories: json['totalCategories'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalRevenue: ((json['totalRevenue'] ?? 0) as num).toDouble(),
      recentOrders: (json['recentOrders'] as List<dynamic>? ?? [])
          .map((order) => AdminOrder.fromJson(order))
          .toList(),
    );
  }
}
