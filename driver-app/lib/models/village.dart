class Village {
  Village({
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

  final String id;
  final String cityId;
  final String name;
  final bool isActive;
}

