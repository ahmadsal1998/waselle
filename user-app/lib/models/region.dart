class City {
  final String id;
  final String name;
  final bool isActive;

  const City({
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
}

class Village {
  final String id;
  final String cityId;
  final String name;
  final bool isActive;

  const Village({
    required this.id,
    required this.cityId,
    required this.name,
    required this.isActive,
  });

  factory Village.fromJson(Map<String, dynamic> json) {
    return Village(
      id: json['_id']?.toString() ?? '',
      cityId: json['cityId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }
}
