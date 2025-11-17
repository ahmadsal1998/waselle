import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_style.dart';

/// Service for managing map styles
class MapStyleService {
  static const String _prefsKey = 'selected_map_style';

  /// Available map styles
  static const List<MapStyle> availableStyles = [
    MapStyle(
      id: 'osm',
      name: 'OpenStreetMap (Standard)',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19,
    ),
    MapStyle(
      id: 'carto_dark',
      name: 'Carto Dark Matter',
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      attribution: '© OpenStreetMap contributors © CARTO',
      maxZoom: 20,
      subdomains: const ['a', 'b', 'c', 'd'],
      supportsRetina: true,
    ),
    MapStyle(
      id: 'carto_light',
      name: 'Carto Positron',
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      attribution: '© OpenStreetMap contributors © CARTO',
      maxZoom: 20,
      subdomains: const ['a', 'b', 'c', 'd'],
      supportsRetina: true,
    ),
    MapStyle(
      id: 'stamen_toner',
      name: 'Stamen Toner',
      urlTemplate:
          'https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}{r}.png',
      attribution:
          'Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under ODbL.',
      maxZoom: 20,
      subdomains: const ['a', 'b', 'c', 'd'],
      supportsRetina: true,
    ),
    MapStyle(
      id: 'stamen_terrain',
      name: 'Stamen Terrain',
      urlTemplate:
          'https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}{r}.png',
      attribution:
          'Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under ODbL.',
      maxZoom: 18,
      subdomains: const ['a', 'b', 'c', 'd'],
      supportsRetina: true,
    ),
    MapStyle(
      id: 'stamen_watercolor',
      name: 'Stamen Watercolor',
      urlTemplate:
          'https://stamen-tiles-{s}.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.jpg',
      attribution:
          'Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under ODbL.',
      maxZoom: 18,
      subdomains: const ['a', 'b', 'c', 'd'],
    ),
    // Note: For Mapbox, you would need to add your API key
    // MapStyle(
    //   id: 'mapbox_streets',
    //   name: 'Mapbox Streets',
    //   urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
    //   attribution: '© Mapbox © OpenStreetMap',
    //   apiKey: 'YOUR_MAPBOX_API_KEY',
    //   maxZoom: 22,
    // ),
  ];

  /// Get default style (OSM)
  static MapStyle getDefaultStyle() {
    return availableStyles.first;
  }

  /// Get style by ID
  static MapStyle? getStyleById(String id) {
    try {
      return availableStyles.firstWhere((style) => style.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Load selected style from preferences
  static Future<MapStyle> loadSelectedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final styleId = prefs.getString(_prefsKey);

    if (styleId != null) {
      final style = getStyleById(styleId);
      if (style != null) {
        return style;
      }
    }

    return getDefaultStyle();
  }

  /// Save selected style to preferences
  static Future<void> saveSelectedStyle(String styleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, styleId);
  }
}
