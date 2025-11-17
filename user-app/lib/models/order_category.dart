class OrderCategory {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const OrderCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory OrderCategory.fromJson(Map<String, dynamic> json) {
    return OrderCategory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }
}
