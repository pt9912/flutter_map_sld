import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld_io/flutter_map_sld_io.dart';
import 'package:test/test.dart';

void main() {
  group('WmsStyleResolver', () {
    const capabilities = WmsCapabilities(
      version: '1.1.1',
      title: 'Test WMS',
      layers: [
        WmsLayerInfo(
          name: 'dem',
          title: 'DEM',
          styles: [
            WmsStyleInfo(name: 'elevation', title: 'Elevation'),
            WmsStyleInfo(name: 'contour', title: 'Contour'),
          ],
        ),
        WmsLayerInfo(
          name: 'roads',
          title: 'Roads',
          styles: [
            WmsStyleInfo(name: 'default', title: 'Default'),
          ],
        ),
      ],
    );

    final sldDocument = SldDocument(
      version: '1.0.0',
      layers: [
        SldLayer(
          name: 'dem',
          styles: [
            UserStyle(
              name: 'elevation',
              featureTypeStyles: [
                FeatureTypeStyle(rules: [
                  Rule(rasterSymbolizer: RasterSymbolizer(opacity: 1.0)),
                ]),
              ],
            ),
          ],
        ),
      ],
    );

    const resolver = WmsStyleResolver();

    test('resolves layer and matching UserStyle', () {
      final resolved = resolver.resolve(capabilities, sldDocument);

      expect(resolved, hasLength(2));

      // dem layer: matched SLD layer AND UserStyle 'elevation'
      expect(resolved[0].layerInfo.name, 'dem');
      expect(resolved[0].styleName, 'elevation');
      expect(resolved[0].sldLayer, isNotNull);
      expect(resolved[0].sldLayer!.name, 'dem');
      expect(resolved[0].userStyle, isNotNull);
      expect(resolved[0].userStyle!.name, 'elevation');

      // roads layer: no matching SLD layer
      expect(resolved[1].layerInfo.name, 'roads');
      expect(resolved[1].sldLayer, isNull);
      expect(resolved[1].userStyle, isNull);
    });

    test('filters by style name with no matching UserStyle', () {
      final resolved = resolver.resolve(
        capabilities,
        sldDocument,
        styleName: 'contour',
      );

      expect(resolved, hasLength(1));
      expect(resolved[0].layerInfo.name, 'dem');
      expect(resolved[0].styleName, 'contour');
      // SLD layer exists but has no UserStyle named 'contour'
      expect(resolved[0].sldLayer, isNotNull);
      expect(resolved[0].userStyle, isNull);
    });

    test('returns empty for non-matching style name', () {
      final resolved = resolver.resolve(
        capabilities,
        sldDocument,
        styleName: 'nonexistent',
      );

      expect(resolved, isEmpty);
    });
  });
}
