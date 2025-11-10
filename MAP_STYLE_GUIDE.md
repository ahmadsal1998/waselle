# 🗺️ Map Style Customization Guide

This guide explains how the map style system works and how to customize it.

## Overview

Both the User App and Driver App now support customizable map styles. Users can switch between different map tile providers and styles directly from the Profile screen.

## Available Map Styles

The following map styles are available by default:

1. **OpenStreetMap (Standard)** - Default OSM tiles
2. **Carto Dark Matter** - Dark themed map
3. **Carto Positron** - Light themed map
4. **Stamen Toner** - High contrast black and white
5. **Stamen Terrain** - Terrain visualization
6. **Stamen Watercolor** - Artistic watercolor style

## How to Change Map Style

1. Open the app
2. Navigate to the Profile screen
3. Expand the "Map Style" section
4. Select your preferred style
5. The map will update immediately across all screens

## Implementation Details

### Architecture

- **MapStyleService** (`lib/services/map_style_service.dart`): 
  - Defines available map styles
  - Handles persistence using SharedPreferences
  - Provides style configuration

- **MapStyleProvider** (`lib/providers/map_style_provider.dart`):
  - Manages map style state
  - Notifies listeners when style changes
  - Provides style information to map widgets

### Adding a New Map Style

To add a new map style, edit `lib/services/map_style_service.dart`:

```dart
MapStyle(
  id: 'your_style_id',
  name: 'Your Style Name',
  urlTemplate: 'https://your-tile-server.com/{z}/{x}/{y}.png',
  attribution: '© Your Attribution',
  maxZoom: 19,
),
```

### Adding Mapbox Support

To use Mapbox tiles, you'll need to:

1. Get a Mapbox API key from [mapbox.com](https://www.mapbox.com)
2. Uncomment and configure the Mapbox style in `map_style_service.dart`:

```dart
MapStyle(
  id: 'mapbox_streets',
  name: 'Mapbox Streets',
  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
  attribution: '© Mapbox © OpenStreetMap',
  apiKey: 'YOUR_MAPBOX_API_KEY_HERE',
  maxZoom: 22,
),
```

**Important**: Never commit API keys to version control. Consider using environment variables or a configuration file that's excluded from git.

### Tile Provider Requirements

When adding a new tile provider, ensure:

1. **URL Template Format**: Use `{z}` for zoom, `{x}` and `{y}` for tile coordinates
2. **Subdomain Support**: Use `{s}` for subdomain rotation (handled automatically by flutter_map)
3. **Attribution**: Always include proper attribution as required by the tile provider's terms of service
4. **Max Zoom**: Set appropriate max zoom level for the provider

### Attribution

All map styles include proper attribution that is displayed on the map. This is required by most tile providers' terms of service.

## Technical Notes

- Map styles are persisted using SharedPreferences
- Style changes are immediately reflected across all map screens
- The TileLayer automatically handles subdomain rotation (`{s}` placeholder)
- All existing map features (markers, routes, location tracking) work with all styles
- Map remains fully interactive (zoom, pan, markers) regardless of style

## Troubleshooting

### Map tiles not loading

1. Check your internet connection
2. Verify the tile provider URL is correct
3. Some tile providers may have rate limits
4. Check if the tile provider requires an API key

### Style not persisting

1. Ensure SharedPreferences is properly initialized
2. Check that the style ID exists in availableStyles
3. Verify the app has storage permissions

### Performance issues

1. Some styles may load slower than others
2. Consider caching tiles for offline use (future enhancement)
3. Reduce max zoom level if needed

## Future Enhancements

Potential improvements:

- [ ] Offline tile caching
- [ ] Custom style editor
- [ ] Style preview thumbnails
- [ ] More tile providers (Mapbox, Google Maps, etc.)
- [ ] Custom color schemes
- [ ] Style presets for different use cases

