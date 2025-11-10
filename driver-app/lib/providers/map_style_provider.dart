import 'package:flutter/foundation.dart';
import '../services/map_style_service.dart';

/// Provider for managing map style state
class MapStyleProvider with ChangeNotifier {
  MapStyle _currentStyle = MapStyleService.getDefaultStyle();
  bool _isLoading = true;

  MapStyle get currentStyle => _currentStyle;
  bool get isLoading => _isLoading;
  List<MapStyle> get availableStyles => MapStyleService.availableStyles;

  MapStyleProvider() {
    _loadStyle();
  }

  /// Load the saved map style
  Future<void> _loadStyle() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentStyle = await MapStyleService.loadSelectedStyle();
    } catch (e) {
      debugPrint('Error loading map style: $e');
      _currentStyle = MapStyleService.getDefaultStyle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change the map style
  Future<void> setStyle(String styleId) async {
    final style = MapStyleService.getStyleById(styleId);
    if (style == null) {
      debugPrint('Map style not found: $styleId');
      return;
    }

    if (_currentStyle.id == styleId) {
      return; // Already selected
    }

    _currentStyle = style;
    notifyListeners();

    try {
      await MapStyleService.saveSelectedStyle(styleId);
    } catch (e) {
      debugPrint('Error saving map style: $e');
    }
  }

  /// Get the URL template with API key if needed
  String getUrlTemplate() {
    String template = _currentStyle.urlTemplate;
    
    // Replace API key placeholder if needed
    if (_currentStyle.apiKey != null && template.contains('{accessToken}')) {
      template = template.replaceAll('{accessToken}', _currentStyle.apiKey!);
    }
    
    return template;
  }

  /// Get attribution text
  String? getAttribution() {
    return _currentStyle.attribution;
  }

  /// Get max zoom level
  int getMaxZoom() {
    return _currentStyle.maxZoom;
  }

  /// Get subdomains for tile providers that use {s} placeholder
  List<String>? getSubdomains() {
    return _currentStyle.subdomains;
  }

  /// Whether current style should request retina tiles
  bool useRetinaTiles() {
    return _currentStyle.supportsRetina;
  }
}

