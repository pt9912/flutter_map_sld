/// WMS version identifier.
enum WmsVersion {
  /// WMS 1.1.1 — uses `SRS` parameter, lon/lat axis order for EPSG:4326.
  v1_1_1('1.1.1'),

  /// WMS 1.3.0 — uses `CRS` parameter, lat/lon axis order for EPSG:4326.
  v1_3_0('1.3.0');

  const WmsVersion(this.versionString);

  /// The version string for the WMS request (e.g. `"1.1.1"`).
  final String versionString;
}

/// Builds OGC WMS GetMap request URLs.
///
/// Handles version-dependent differences:
/// - WMS 1.1.1: `SRS` parameter, x/y = lon/lat for geographic CRS
/// - WMS 1.3.0: `CRS` parameter, axis order follows CRS definition
///   (lat/lon for EPSG:4326)
///
/// Example:
/// ```dart
/// final builder = WmsRequestBuilder(
///   baseUrl: Uri.parse('https://example.com/wms'),
///   version: WmsVersion.v1_1_1,
///   layers: ['dem'],
///   crs: 'EPSG:4326',
/// );
/// final url = builder.getMapUrl(
///   bbox: [5.0, 47.0, 15.0, 55.0], // minx, miny, maxx, maxy
///   width: 800,
///   height: 600,
/// );
/// ```
class WmsRequestBuilder {
  const WmsRequestBuilder({
    required this.baseUrl,
    required this.version,
    required this.layers,
    required this.crs,
    this.styles = const [],
    this.format = 'image/png',
    this.transparent = true,
  });

  /// The WMS base URL (without query parameters).
  final Uri baseUrl;

  /// WMS protocol version.
  final WmsVersion version;

  /// Layer names to request.
  final List<String> layers;

  /// Coordinate reference system (e.g. `"EPSG:4326"`).
  final String crs;

  /// Style names (one per layer, or empty for server defaults).
  final List<String> styles;

  /// Output image format. Defaults to `image/png`.
  final String format;

  /// Whether to request transparent background. Defaults to `true`.
  final bool transparent;

  /// Builds a GetMap request URL for the given bounding box and image size.
  ///
  /// [bbox] must contain 4 values: `[minx, miny, maxx, maxy]` in the axis
  /// order of the source data (typically lon/lat). The builder applies the
  /// correct axis order for the WMS version and CRS automatically.
  Uri getMapUrl({
    required List<double> bbox,
    required int width,
    required int height,
    String? sldBody,
  }) {
    assert(bbox.length == 4, 'bbox must have exactly 4 values');

    final bboxString = _formatBbox(bbox);

    final params = <String, String>{
      'SERVICE': 'WMS',
      'VERSION': version.versionString,
      'REQUEST': 'GetMap',
      'LAYERS': layers.join(','),
      'STYLES': styles.join(','),
      _crsParamName: crs,
      'BBOX': bboxString,
      'WIDTH': width.toString(),
      'HEIGHT': height.toString(),
      'FORMAT': format,
      'TRANSPARENT': transparent.toString().toUpperCase(),
    };

    if (sldBody != null) {
      params['SLD_BODY'] = sldBody;
    }

    return baseUrl.replace(
      queryParameters: {
        ...baseUrl.queryParameters,
        ...params,
      },
    );
  }

  /// Builds a GetCapabilities request URL.
  Uri getCapabilitiesUrl() => baseUrl.replace(
        queryParameters: {
          ...baseUrl.queryParameters,
          'SERVICE': 'WMS',
          'VERSION': version.versionString,
          'REQUEST': 'GetCapabilities',
        },
      );

  /// The CRS/SRS parameter name depends on WMS version.
  String get _crsParamName =>
      version == WmsVersion.v1_1_1 ? 'SRS' : 'CRS';

  /// Formats bbox with correct axis order.
  ///
  /// Input is always `[minx, miny, maxx, maxy]` (lon/lat order).
  /// For WMS 1.3.0 with geographic CRS (EPSG:4326), the axis order
  /// must be swapped to lat/lon per OGC spec.
  String _formatBbox(List<double> bbox) {
    if (version == WmsVersion.v1_3_0 && _isGeographicCrs(crs)) {
      // Swap to lat/lon: miny, minx, maxy, maxx
      return '${bbox[1]},${bbox[0]},${bbox[3]},${bbox[2]}';
    }
    return bbox.join(',');
  }

  /// Returns `true` for CRS identifiers that use lat/lon axis order
  /// in WMS 1.3.0.
  ///
  /// `EPSG:4326` uses lat/lon in WMS 1.3.0 (swap needed).
  /// `CRS:84` is explicitly lon/lat (no swap needed).
  static bool _isGeographicCrs(String crs) =>
      crs.toUpperCase() == 'EPSG:4326';
}
