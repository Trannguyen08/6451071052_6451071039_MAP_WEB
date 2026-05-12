class CategoryModel {
  final String id;
  final String name;
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory CategoryModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return CategoryModel(
      id: data['id'] ?? id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '🍔',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }
}