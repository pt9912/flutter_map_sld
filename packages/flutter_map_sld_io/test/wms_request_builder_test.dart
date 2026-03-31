import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';
import 'package:test/test.dart';

void main() {
  group('WmsRequestBuilder', () {
    test('builds WMS 1.1.1 GetMap URL', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_1_1,
        layers: ['dem'],
        crs: 'EPSG:4326',
      );

      final url = builder.getMapUrl(
        bbox: [5.0, 47.0, 15.0, 55.0],
        width: 800,
        height: 600,
      );

      expect(url.queryParameters['SERVICE'], 'WMS');
      expect(url.queryParameters['VERSION'], '1.1.1');
      expect(url.queryParameters['REQUEST'], 'GetMap');
      expect(url.queryParameters['LAYERS'], 'dem');
      expect(url.queryParameters['SRS'], 'EPSG:4326');
      expect(url.queryParameters['BBOX'], '5.0,47.0,15.0,55.0');
      expect(url.queryParameters['WIDTH'], '800');
      expect(url.queryParameters['HEIGHT'], '600');
      expect(url.queryParameters['FORMAT'], 'image/png');
      expect(url.queryParameters['TRANSPARENT'], 'TRUE');
    });

    test('WMS 1.1.1 uses SRS parameter', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_1_1,
        layers: ['dem'],
        crs: 'EPSG:4326',
      );

      final url = builder.getMapUrl(
        bbox: [5.0, 47.0, 15.0, 55.0],
        width: 256,
        height: 256,
      );

      expect(url.queryParameters.containsKey('SRS'), isTrue);
      expect(url.queryParameters.containsKey('CRS'), isFalse);
    });

    test('WMS 1.3.0 uses CRS parameter', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_3_0,
        layers: ['dem'],
        crs: 'EPSG:3857',
      );

      final url = builder.getMapUrl(
        bbox: [0.0, 0.0, 100.0, 100.0],
        width: 256,
        height: 256,
      );

      expect(url.queryParameters.containsKey('CRS'), isTrue);
      expect(url.queryParameters.containsKey('SRS'), isFalse);
    });

    test('WMS 1.3.0 swaps axis order for EPSG:4326', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_3_0,
        layers: ['dem'],
        crs: 'EPSG:4326',
      );

      final url = builder.getMapUrl(
        bbox: [5.0, 47.0, 15.0, 55.0], // minx, miny, maxx, maxy (lon/lat)
        width: 256,
        height: 256,
      );

      // Should be swapped to miny, minx, maxy, maxx (lat/lon)
      expect(url.queryParameters['BBOX'], '47.0,5.0,55.0,15.0');
    });

    test('WMS 1.3.0 does not swap for EPSG:3857', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_3_0,
        layers: ['dem'],
        crs: 'EPSG:3857',
      );

      final url = builder.getMapUrl(
        bbox: [5.0, 47.0, 15.0, 55.0],
        width: 256,
        height: 256,
      );

      expect(url.queryParameters['BBOX'], '5.0,47.0,15.0,55.0');
    });

    test('includes SLD_BODY when provided', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_1_1,
        layers: ['dem'],
        crs: 'EPSG:4326',
      );

      final url = builder.getMapUrl(
        bbox: [0.0, 0.0, 10.0, 10.0],
        width: 256,
        height: 256,
        sldBody: '<StyledLayerDescriptor/>',
      );

      expect(url.queryParameters['SLD_BODY'],
          '<StyledLayerDescriptor/>');
    });

    test('builds multiple layers and styles', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_1_1,
        layers: ['dem', 'roads'],
        crs: 'EPSG:4326',
        styles: ['elevation', 'default'],
      );

      final url = builder.getMapUrl(
        bbox: [0.0, 0.0, 10.0, 10.0],
        width: 256,
        height: 256,
      );

      expect(url.queryParameters['LAYERS'], 'dem,roads');
      expect(url.queryParameters['STYLES'], 'elevation,default');
    });

    test('builds GetCapabilities URL', () {
      final builder = WmsRequestBuilder(
        baseUrl: Uri.parse('https://example.com/wms'),
        version: WmsVersion.v1_1_1,
        layers: ['dem'],
        crs: 'EPSG:4326',
      );

      final url = builder.getCapabilitiesUrl();

      expect(url.queryParameters['SERVICE'], 'WMS');
      expect(url.queryParameters['VERSION'], '1.1.1');
      expect(url.queryParameters['REQUEST'], 'GetCapabilities');
    });
  });
}
