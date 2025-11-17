class MapStyle {
  final String id;
  final String name;
  final String urlTemplate;
  final String? attribution;
  final String? apiKey;
  final int maxZoom;
  final List<String>? subdomains;
  final bool supportsRetina;

  const MapStyle({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.attribution,
    this.apiKey,
    this.maxZoom = 19,
    this.subdomains,
    this.supportsRetina = false,
  });
}
