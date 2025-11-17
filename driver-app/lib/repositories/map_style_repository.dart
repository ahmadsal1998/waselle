import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_style.dart';

class MapStyleRepository {
  MapStyleRepository({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future.value(preferences)
            : SharedPreferences.getInstance();

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
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
      attribution: '© OpenStreetMap contributors © CARTO',
      maxZoom: 20,
      subdomains: ['a', 'b', 'c', 'd'],
      supportsRetina: true,
    ),
    MapStyle(
      id: 'carto_light',
      name: 'Carto Positron',
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      attribution: '© OpenStreetMap contributors © CARTO',
      maxZoom: 20,
      subdomains: ['a', 'b', 'c', 'd'],
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
      subdomains: ['a', 'b', 'c', 'd'],
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
      subdomains: ['a', 'b', 'c', 'd'],
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
      subdomains: ['a', 'b', 'c', 'd'],
    ),
  ];

  final Future<SharedPreferences> _preferencesFuture;

  MapStyle get defaultStyle => availableStyles.first;

  MapStyle? getStyleById(String id) {
    try {
      return availableStyles.firstWhere((style) => style.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<MapStyle> loadSelectedStyle() async {
    final prefs = await _preferencesFuture;
    final styleId = prefs.getString(_prefsKey);

    if (styleId != null) {
      final style = getStyleById(styleId);
      if (style != null) {
        return style;
      }
    }

    return defaultStyle;
  }

  Future<void> saveSelectedStyle(String styleId) async {
    final prefs = await _preferencesFuture;
    await prefs.setString(_prefsKey, styleId);
  }

  static const String _prefsKey = 'selected_map_style';
}

