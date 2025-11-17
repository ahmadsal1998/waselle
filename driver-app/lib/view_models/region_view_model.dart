import 'package:flutter/foundation.dart';

import '../models/city.dart';
import '../models/village.dart';
import '../repositories/region_repository.dart';

class RegionViewModel with ChangeNotifier {
  RegionViewModel({RegionRepository? regionRepository})
      : _regionRepository = regionRepository ?? RegionRepository();

  final RegionRepository _regionRepository;

  List<City> _cities = [];
  bool _citiesLoaded = false;
  bool _isLoadingCities = false;
  String? _citiesError;

  final Map<String, List<Village>> _villagesByCity = {};
  final Set<String> _loadingVillages = {};
  final Map<String, String?> _villagesErrors = {};

  List<City> get cities => _cities;
  List<City> get activeCities =>
      _cities.where((city) => city.isActive).toList(growable: false);

  bool get isLoadingCities => _isLoadingCities;
  String? get citiesError => _citiesError;

  Future<void> loadCities({bool forceRefresh = false}) async {
    if (_isLoadingCities) return;
    if (!forceRefresh && _citiesLoaded) return;

    _isLoadingCities = true;
    notifyListeners();

    try {
      final response = await _regionRepository.getCities(activeOnly: true);
      _cities = response.map(City.fromJson).toList()
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
      final response =
          await _regionRepository.getVillages(cityId, activeOnly: true);
      _villagesByCity[cityId] = response.map(Village.fromJson).toList()
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

  List<Village> villagesForCity(String cityId) =>
      _villagesByCity[cityId] ?? const [];

  List<Village> activeVillagesForCity(String cityId) => villagesForCity(cityId)
      .where((village) => village.isActive)
      .toList(growable: false);

  City? cityById(String id) {
    try {
      return _cities.firstWhere((city) => city.id == id);
    } catch (_) {
      return null;
    }
  }

  Village? villageById(String cityId, String villageId) {
    try {
      return villagesForCity(cityId)
          .firstWhere((village) => village.id == villageId);
    } catch (_) {
      return null;
    }
  }
}

