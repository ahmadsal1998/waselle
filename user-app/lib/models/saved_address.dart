class SavedAddress {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final String? address; // Formatted address string
  final String? cityId;
  final String? villageId;
  final String? streetDetails;

  SavedAddress({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.address,
    this.cityId,
    this.villageId,
    this.streetDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'cityId': cityId,
      'villageId': villageId,
      'streetDetails': streetDetails,
    };
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      cityId: json['cityId'] as String?,
      villageId: json['villageId'] as String?,
      streetDetails: json['streetDetails'] as String?,
    );
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    String? address,
    String? cityId,
    String? villageId,
    String? streetDetails,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      cityId: cityId ?? this.cityId,
      villageId: villageId ?? this.villageId,
      streetDetails: streetDetails ?? this.streetDetails,
    );
  }
}

