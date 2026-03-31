import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

void main() {
  group('SldDocument', () {
    test('can be constructed with layers', () {
      final doc = SldDocument(
        version: '1.0.0',
        layers: [],
      );

      expect(doc.version, '1.0.0');
      expect(doc.layers, isEmpty);
    });

    test('layers list is unmodifiable', () {
      final doc = SldDocument(layers: []);

      expect(
        () => doc.layers.add(SldLayer(name: 'x', styles: [])),
        throwsUnsupportedError,
      );
    });

    test('selectRasterSymbolizers returns empty for no layers', () {
      final doc = SldDocument(layers: []);

      expect(doc.selectRasterSymbolizers(), isEmpty);
    });

    test('selectRasterSymbolizers finds nested raster symbolizers', () {
      final doc = SldDocument(
        version: '1.0.0',
        layers: [
          SldLayer(
            name: 'DEM',
            styles: [
              UserStyle(
                name: 'elevation',
                featureTypeStyles: [
                  FeatureTypeStyle(
                    rules: [
                      Rule(
                        rasterSymbolizer: RasterSymbolizer(
                          opacity: 1.0,
                          colorMap: ColorMap(
                            type: ColorMapType.ramp,
                            entries: [
                              const ColorMapEntry(
                                colorArgb: 0xFF000000,
                                quantity: 0.0,
                                opacity: 1.0,
                              ),
                              const ColorMapEntry(
                                colorArgb: 0xFFFFFFFF,
                                quantity: 1000.0,
                                opacity: 1.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final rasterSymbolizers = doc.selectRasterSymbolizers();
      expect(rasterSymbolizers, hasLength(1));
      expect(rasterSymbolizers.first.opacity, 1.0);
      expect(rasterSymbolizers.first.colorMap?.entries, hasLength(2));
    });

    test('selectRasterSymbolizers skips rules without raster symbolizer', () {
      final doc = SldDocument(
        layers: [
          SldLayer(
            name: 'test',
            styles: [
              UserStyle(
                featureTypeStyles: [
                  FeatureTypeStyle(
                    rules: [
                      const Rule(name: 'no-symbolizer'),
                      Rule(
                        rasterSymbolizer: RasterSymbolizer(opacity: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(doc.selectRasterSymbolizers(), hasLength(1));
    });

    test('selectRasterSymbolizersAtScale filters by scale', () {
      final doc = SldDocument(
        layers: [
          SldLayer(
            name: 'dem',
            styles: [
              UserStyle(
                featureTypeStyles: [
                  FeatureTypeStyle(
                    rules: [
                      Rule(
                        name: 'overview',
                        maxScaleDenominator: 500000,
                        rasterSymbolizer: RasterSymbolizer(opacity: 1.0),
                      ),
                      Rule(
                        name: 'detail',
                        minScaleDenominator: 500000,
                        rasterSymbolizer: RasterSymbolizer(opacity: 0.8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      // Below 500000 — only overview matches
      final low = doc.selectRasterSymbolizersAtScale(100000);
      expect(low, hasLength(1));
      expect(low.first.opacity, 1.0);

      // At 500000 — only detail matches (max is exclusive, min is inclusive)
      final boundary = doc.selectRasterSymbolizersAtScale(500000);
      expect(boundary, hasLength(1));
      expect(boundary.first.opacity, 0.8);

      // Above 500000 — only detail matches
      final high = doc.selectRasterSymbolizersAtScale(1000000);
      expect(high, hasLength(1));
      expect(high.first.opacity, 0.8);
    });

    test('selectRasterSymbolizersAtScale returns empty for no layers', () {
      final doc = SldDocument(layers: []);
      expect(doc.selectRasterSymbolizersAtScale(50000), isEmpty);
    });

    test('equal documents are ==', () {
      final a = SldDocument(version: '1.0.0', layers: []);
      final b = SldDocument(version: '1.0.0', layers: []);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('SldParseResult', () {
    test('hasErrors is false when no issues', () {
      final result = SldParseResult(
        document: SldDocument(layers: []),
      );

      expect(result.hasErrors, isFalse);
      expect(result.document, isNotNull);
    });

    test('hasErrors is true when error issue present', () {
      final result = SldParseResult(
        issues: [
          const SldParseIssue(
            severity: SldIssueSeverity.error,
            code: 'invalid-xml',
            message: 'Not well-formed',
          ),
        ],
      );

      expect(result.hasErrors, isTrue);
      expect(result.document, isNull);
    });

    test('hasErrors is false when only warnings', () {
      final result = SldParseResult(
        document: SldDocument(layers: []),
        issues: [
          const SldParseIssue(
            severity: SldIssueSeverity.warning,
            code: 'missing-namespace',
            message: 'No namespace',
          ),
        ],
      );

      expect(result.hasErrors, isFalse);
    });

    test('issues list is unmodifiable', () {
      final result = SldParseResult(
        document: SldDocument(layers: []),
      );

      expect(
        () => result.issues.add(
          const SldParseIssue(
            severity: SldIssueSeverity.info,
            code: 'x',
            message: 'x',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
