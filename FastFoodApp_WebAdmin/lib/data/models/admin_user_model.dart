class AdminUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final int ordersCount;
  final double totalSpending;
  String status;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.ordersCount,
    required this.totalSpending,
    required this.status,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      ordersCount: json['ordersCount'],
      totalSpending: json['totalSpending'].toDouble(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'ordersCount': ordersCount,
      'totalSpending': totalSpending,
      'status': status,
    };
  }
}

class AdminSession {
  final String token;
  final String id;
  final String name;
  final String email;

  const AdminSession({
    required this.token,
    required this.id,
    required this.name,
    required this.email,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>;
    return AdminSession(
      token: json['token'] as String,
      id: admin['id'] as String,
      name: admin['name'] as String,
      email: admin['email'] as String,
    );
  }
}

class AdminDashboardData {
  final int total;
  final int active;
  final int blocked;
  final double avgSpending;
  final List<AdminUser> users;

  AdminDashboardData({
    required this.total,
    required this.active,
    required this.blocked,
    required this.avgSpending,
    required this.users,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      total: json['total'],
      active: json['active'],
      blocked: json['blocked'],
      avgSpending: json['avgSpending'].toDouble(),
      users: (json['users'] as List).map((u) => AdminUser.fromJson(u)).toList(),
    );
  }
}
