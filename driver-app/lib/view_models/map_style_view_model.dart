import 'package:flutter/foundation.dart';

import '../models/map_style.dart';
import '../repositories/map_style_repository.dart';

class MapStyleViewModel with ChangeNotifier {
  MapStyleViewModel({MapStyleRepository? mapStyleRepository})
      : _mapStyleRepository = mapStyleRepository ?? MapStyleRepository() {
    _currentStyle = _mapStyleRepository.defaultStyle;
    _loadStyle();
  }

  final MapStyleRepository _mapStyleRepository;

  late MapStyle _currentStyle;
  bool _isLoading = true;

  MapStyle get currentStyle => _currentStyle;
  bool get isLoading => _isLoading;
  List<MapStyle> get availableStyles => MapStyleRepository.availableStyles;

  Future<void> _loadStyle() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentStyle = await _mapStyleRepository.loadSelectedStyle();
    } catch (e) {
      debugPrint('Error loading map style: $e');
      _currentStyle = _mapStyleRepository.defaultStyle;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setStyle(String styleId) async {
    final style = _mapStyleRepository.getStyleById(styleId);
    if (style == null) {
      debugPrint('Map style not found: $styleId');
      return;
    }

    if (_currentStyle.id == styleId) {
      return;
    }

    _currentStyle = style;
    notifyListeners();

    try {
      await _mapStyleRepository.saveSelectedStyle(styleId);
    } catch (e) {
      debugPrint('Error saving map style: $e');
    }
  }

  String getUrlTemplate() {
    var template = _currentStyle.urlTemplate;

    if (_currentStyle.apiKey != null && template.contains('{accessToken}')) {
      template = template.replaceAll('{accessToken}', _currentStyle.apiKey!);
    }

    return template;
  }

  String? getAttribution() => _currentStyle.attribution;

  int getMaxZoom() => _currentStyle.maxZoom;

  List<String>? getSubdomains() => _currentStyle.subdomains;

  bool useRetinaTiles() => _currentStyle.supportsRetina;
}

