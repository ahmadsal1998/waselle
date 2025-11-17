class City {
  City({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }

  final String id;
  final String name;
  final bool isActive;
}

