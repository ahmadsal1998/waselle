import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class CityModel {
  final String id;
  final String name;
  final bool isActive;

  CityModel({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }
}

class VillageModel {
  final String id;
  final String cityId;
  final String name;
  final bool isActive;

  VillageModel({
    required this.id,
    required this.cityId,
    required this.name,
    required this.isActive,
  });

  factory VillageModel.fromJson(Map<String, dynamic> json) {
    return VillageModel(
      id: json['_id']?.toString() ?? '',
      cityId: json['cityId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }
}

class RegionProvider with ChangeNotifier {
  List<CityModel> _cities = [];
  bool _citiesLoaded = false;
  bool _isLoadingCities = false;
  String? _citiesError;

  final Map<String, List<VillageModel>> _villagesByCity = {};
  final Set<String> _loadingVillages = {};
  final Map<String, String?> _villagesErrors = {};

  List<CityModel> get cities => _cities;

  List<CityModel> get activeCities =>
      _cities.where((city) => city.isActive).toList(growable: false);

  bool get isLoadingCities => _isLoadingCities;
  String? get citiesError => _citiesError;

  Future<void> loadCities({bool forceRefresh = false}) async {
    if (_isLoadingCities) return;
    if (!forceRefresh && _citiesLoaded) return;

    _isLoadingCities = true;
    notifyListeners();

    try {
      final response = await ApiService.getCities(activeOnly: true);
      _cities = response.map((city) => CityModel.fromJson(city)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _citiesError = null;
      _citiesLoaded = true;
    } catch (e) {
      _citiesError = e.toString();
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  Future<void> loadVillages(String cityId, {bool forceRefresh = false}) async {
    if (_loadingVillages.contains(cityId)) return;
    if (!forceRefresh && _villagesByCity.containsKey(cityId)) return;

    _loadingVillages.add(cityId);
    notifyListeners();

    try {
      final response = await ApiService.getVillages(cityId, activeOnly: true);
      _villagesByCity[cityId] =
          response.map((item) => VillageModel.fromJson(item)).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      _villagesErrors[cityId] = null;
    } catch (e) {
      _villagesErrors[cityId] = e.toString();
    } finally {
      _loadingVillages.remove(cityId);
      notifyListeners();
    }
  }

  bool isLoadingVillages(String cityId) => _loadingVillages.contains(cityId);

  String? villagesError(String cityId) => _villagesErrors[cityId];

  List<VillageModel> villagesForCity(String cityId) =>
      _villagesByCity[cityId] ?? const [];

  List<VillageModel> activeVillagesForCity(String cityId) =>
      villagesForCity(cityId)
          .where((village) => village.isActive)
          .toList(growable: false);

  CityModel? cityById(String id) {
    try {
      return _cities.firstWhere((city) => city.id == id);
    } catch (_) {
      return null;
    }
  }

  VillageModel? villageById(String cityId, String villageId) {
    try {
      return villagesForCity(cityId).firstWhere((village) => village.id == villageId);
    } catch (_) {
      return null;
    }
  }
}

