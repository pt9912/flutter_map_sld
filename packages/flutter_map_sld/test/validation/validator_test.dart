import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:test/test.dart';

/// Builds a minimal [SldDocument] with a single raster symbolizer.
SldDocument _docWith(RasterSymbolizer rs) => SldDocument(
      layers: [
        SldLayer(
          name: 'test',
          styles: [
            UserStyle(
              featureTypeStyles: [
                FeatureTypeStyle(rules: [Rule(rasterSymbolizer: rs)]),
              ],
            ),
          ],
        ),
      ],
    );

void main() {
  const validator = SldValidator();

  // -----------------------------------------------------------------------
  // Valid document
  // -----------------------------------------------------------------------
  group('valid document', () {
    test('no issues for valid raster symbolizer', () {
      final doc = _docWith(RasterSymbolizer(
        opacity: 0.5,
        colorMap: ColorMap(
          type: ColorMapType.ramp,
          entries: [
            const ColorMapEntry(
                colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0),
            const ColorMapEntry(
                colorArgb: 0xFFFFFFFF, quantity: 100.0, opacity: 1.0),
          ],
        ),
      ));
      final result = validator.validate(doc);

      expect(result.hasErrors, isFalse);
      expect(result.hasWarnings, isFalse);
      expect(result.issues, isEmpty);
    });

    test('no issues for empty document', () {
      final doc = SldDocument(layers: []);
      final result = validator.validate(doc);

      expect(result.issues, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // Opacity validation
  // -----------------------------------------------------------------------
  group('opacity validation', () {
    test('opacity > 1.0 is an error', () {
      final doc = _docWith(RasterSymbolizer(opacity: 1.5));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      final issue = result.issues.first;
      expect(issue.code, 'opacity-out-of-range');
      expect(issue.severity, SldIssueSeverity.error);
      expect(issue.location, contains('opacity'));
    });

    test('opacity < 0.0 is an error', () {
      final doc = _docWith(RasterSymbolizer(opacity: -0.1));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'opacity-out-of-range');
    });

    test('opacity 0.0 is valid', () {
      final doc = _docWith(RasterSymbolizer(opacity: 0.0));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'opacity-out-of-range'),
        isEmpty,
      );
    });

    test('opacity 1.0 is valid', () {
      final doc = _docWith(RasterSymbolizer(opacity: 1.0));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'opacity-out-of-range'),
        isEmpty,
      );
    });

    test('null opacity is valid', () {
      final doc = _docWith(RasterSymbolizer());
      final result = validator.validate(doc);

      expect(result.issues, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // ColorMap validation
  // -----------------------------------------------------------------------
  group('ColorMap validation', () {
    test('empty ColorMap is an error', () {
      final doc = _docWith(RasterSymbolizer(
        colorMap: ColorMap(type: ColorMapType.ramp, entries: []),
      ));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'empty-color-map');
    });

    test('intervals type reports vendor extension info', () {
      final doc = _docWith(RasterSymbolizer(
        colorMap: ColorMap(
          type: ColorMapType.intervals,
          entries: [
            const ColorMapEntry(
                colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0),
          ],
        ),
      ));
      final result = validator.validate(doc);

      expect(result.hasErrors, isFalse);
      final info = result.issues
          .firstWhere((i) => i.code == 'vendor-extension-intervals');
      expect(info.severity, SldIssueSeverity.info);
    });

    test('non-ascending quantities warn', () {
      final doc = _docWith(RasterSymbolizer(
        colorMap: ColorMap(
          type: ColorMapType.ramp,
          entries: [
            const ColorMapEntry(
                colorArgb: 0xFF000000, quantity: 100.0, opacity: 1.0),
            const ColorMapEntry(
                colorArgb: 0xFFFFFFFF, quantity: 50.0, opacity: 1.0),
          ],
        ),
      ));
      final result = validator.validate(doc);

      expect(result.hasWarnings, isTrue);
      expect(
        result.issues.any((i) => i.code == 'quantity-not-ascending'),
        isTrue,
      );
    });

    test('ascending quantities produce no warning', () {
      final doc = _docWith(RasterSymbolizer(
        colorMap: ColorMap(
          type: ColorMapType.ramp,
          entries: [
            const ColorMapEntry(
                colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.0),
            const ColorMapEntry(
                colorArgb: 0xFFFFFFFF, quantity: 100.0, opacity: 1.0),
          ],
        ),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'quantity-not-ascending'),
        isEmpty,
      );
    });

    test('duplicate quantity values warn', () {
      final doc = _docWith(RasterSymbolizer(
        colorMap: ColorMap(
          type: ColorMapType.ramp,
          entries: [
            const ColorMapEntry(
                colorArgb: 0xFF000000, quantity: 50.0, opacity: 1.0),
            const ColorMapEntry(
                colorArgb: 0xFFFFFFFF, quantity: 50.0, opacity: 1.0),
          ],
        ),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.any((i) => i.code == 'duplicate-quantity'),
        isTrue,
      );
    });

    test('entry opacity out of range is an error', () {
      final doc = _docWith(RasterSymbolizer(
        colorMap: ColorMap(
          type: ColorMapType.ramp,
          entries: [
            const ColorMapEntry(
                colorArgb: 0xFF000000, quantity: 0.0, opacity: 1.5),
          ],
        ),
      ));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'entry-opacity-out-of-range');
    });
  });

  // -----------------------------------------------------------------------
  // ContrastEnhancement validation
  // -----------------------------------------------------------------------
  group('ContrastEnhancement validation', () {
    test('negative gamma warns', () {
      final doc = _docWith(RasterSymbolizer(
        contrastEnhancement: const ContrastEnhancement(gammaValue: -1.0),
      ));
      final result = validator.validate(doc);

      expect(result.hasWarnings, isTrue);
      expect(result.issues.first.code, 'gamma-not-positive');
    });

    test('zero gamma warns', () {
      final doc = _docWith(RasterSymbolizer(
        contrastEnhancement: const ContrastEnhancement(gammaValue: 0.0),
      ));
      final result = validator.validate(doc);

      expect(result.issues.any((i) => i.code == 'gamma-not-positive'), isTrue);
    });

    test('positive gamma is valid', () {
      final doc = _docWith(RasterSymbolizer(
        contrastEnhancement: const ContrastEnhancement(gammaValue: 1.5),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'gamma-not-positive'),
        isEmpty,
      );
    });
  });

  // -----------------------------------------------------------------------
  // Scale denominator validation
  // -----------------------------------------------------------------------
  group('scale denominator validation', () {
    SldDocument docWithScale({double? min, double? max}) => SldDocument(
          layers: [
            SldLayer(
              name: 'test',
              styles: [
                UserStyle(
                  featureTypeStyles: [
                    FeatureTypeStyle(rules: [
                      Rule(
                        minScaleDenominator: min,
                        maxScaleDenominator: max,
                        rasterSymbolizer: RasterSymbolizer(),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ],
        );

    test('min >= max is an error', () {
      final doc = docWithScale(min: 100000, max: 50000);
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      final issue =
          result.issues.firstWhere((i) => i.code == 'empty-scale-range');
      expect(issue.severity, SldIssueSeverity.error);
      expect(issue.location, contains('rules[0]'));
    });

    test('min == max is an error', () {
      final doc = docWithScale(min: 50000, max: 50000);
      final result = validator.validate(doc);

      expect(
        result.issues.any((i) => i.code == 'empty-scale-range'),
        isTrue,
      );
    });

    test('min < max is valid', () {
      final doc = docWithScale(min: 50000, max: 100000);
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'empty-scale-range'),
        isEmpty,
      );
    });

    test('only min is valid', () {
      final doc = docWithScale(min: 50000);
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'empty-scale-range'),
        isEmpty,
      );
    });

    test('only max is valid', () {
      final doc = docWithScale(max: 100000);
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'empty-scale-range'),
        isEmpty,
      );
    });

    test('no scale bounds is valid', () {
      final doc = docWithScale();
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'empty-scale-range'),
        isEmpty,
      );
    });
  });

  // -----------------------------------------------------------------------
  // ShadedRelief validation
  // -----------------------------------------------------------------------
  group('ShadedRelief validation', () {
    test('negative reliefFactor is an error', () {
      final doc = _docWith(RasterSymbolizer(
        shadedRelief: const ShadedRelief(reliefFactor: -1.0),
      ));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'relief-factor-negative');
    });

    test('zero reliefFactor is valid', () {
      final doc = _docWith(RasterSymbolizer(
        shadedRelief: const ShadedRelief(reliefFactor: 0.0),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'relief-factor-negative'),
        isEmpty,
      );
    });

    test('positive reliefFactor is valid', () {
      final doc = _docWith(RasterSymbolizer(
        shadedRelief: const ShadedRelief(reliefFactor: 55.0),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'relief-factor-negative'),
        isEmpty,
      );
    });

    test('null reliefFactor is valid', () {
      final doc = _docWith(RasterSymbolizer(
        shadedRelief: const ShadedRelief(),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'relief-factor-negative'),
        isEmpty,
      );
    });
  });

  // -----------------------------------------------------------------------
  // ChannelSelection validation
  // -----------------------------------------------------------------------
  group('ChannelSelection validation', () {
    test('complete RGB is valid', () {
      final doc = _docWith(RasterSymbolizer(
        channelSelection: const ChannelSelection(
          redChannel: SelectedChannel(channelName: '1'),
          greenChannel: SelectedChannel(channelName: '2'),
          blueChannel: SelectedChannel(channelName: '3'),
        ),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'incomplete-rgb-channels'),
        isEmpty,
      );
    });

    test('incomplete RGB is an error', () {
      final doc = _docWith(RasterSymbolizer(
        channelSelection: const ChannelSelection(
          redChannel: SelectedChannel(channelName: '1'),
        ),
      ));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      final issue = result.issues
          .firstWhere((i) => i.code == 'incomplete-rgb-channels');
      expect(issue.message, contains('green'));
      expect(issue.message, contains('blue'));
    });

    test('gray channel only is valid', () {
      final doc = _docWith(RasterSymbolizer(
        channelSelection: const ChannelSelection(
          grayChannel: SelectedChannel(channelName: '1'),
        ),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'incomplete-rgb-channels'),
        isEmpty,
      );
    });

    test('no channels is valid', () {
      final doc = _docWith(RasterSymbolizer(
        channelSelection: const ChannelSelection(),
      ));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'incomplete-rgb-channels'),
        isEmpty,
      );
    });
  });

  // -----------------------------------------------------------------------
  // Vector symbolizer validation
  // -----------------------------------------------------------------------
  group('vector symbolizer validation', () {
    SldDocument docWithPoint(PointSymbolizer ps) => SldDocument(
          layers: [
            SldLayer(
              name: 'test',
              styles: [
                UserStyle(
                  featureTypeStyles: [
                    FeatureTypeStyle(rules: [Rule(pointSymbolizer: ps)]),
                  ],
                ),
              ],
            ),
          ],
        );

    SldDocument docWithLine(LineSymbolizer ls) => SldDocument(
          layers: [
            SldLayer(
              name: 'test',
              styles: [
                UserStyle(
                  featureTypeStyles: [
                    FeatureTypeStyle(rules: [Rule(lineSymbolizer: ls)]),
                  ],
                ),
              ],
            ),
          ],
        );

    SldDocument docWithPolygon(PolygonSymbolizer ps) => SldDocument(
          layers: [
            SldLayer(
              name: 'test',
              styles: [
                UserStyle(
                  featureTypeStyles: [
                    FeatureTypeStyle(rules: [Rule(polygonSymbolizer: ps)]),
                  ],
                ),
              ],
            ),
          ],
        );

    test('negative stroke width is an error', () {
      final doc = docWithLine(
          const LineSymbolizer(stroke: Stroke(width: -1.0)));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'stroke-width-negative');
    });

    test('stroke opacity out of range is an error', () {
      final doc = docWithLine(
          const LineSymbolizer(stroke: Stroke(opacity: 1.5)));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'stroke-opacity-out-of-range');
    });

    test('fill opacity out of range is an error', () {
      final doc = docWithPolygon(
          const PolygonSymbolizer(fill: Fill(opacity: -0.1)));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'fill-opacity-out-of-range');
    });

    test('negative graphic size is an error', () {
      final doc = docWithPoint(const PointSymbolizer(
          graphic: Graphic(size: -5.0)));
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'graphic-size-negative');
    });

    test('unknown mark name is info', () {
      final doc = docWithPoint(const PointSymbolizer(
          graphic: Graphic(
              mark: Mark(wellKnownName: 'custom-shape'))));
      final result = validator.validate(doc);

      expect(result.hasErrors, isFalse);
      expect(
        result.issues.any((i) => i.code == 'unknown-mark-name'),
        isTrue,
      );
    });

    test('known mark name is valid', () {
      final doc = docWithPoint(const PointSymbolizer(
          graphic: Graphic(mark: Mark(wellKnownName: 'circle'))));
      final result = validator.validate(doc);

      expect(
        result.issues.where((i) => i.code == 'unknown-mark-name'),
        isEmpty,
      );
    });

    test('valid polygon passes', () {
      final doc = docWithPolygon(const PolygonSymbolizer(
        fill: Fill(colorArgb: 0xFFAAAAAA, opacity: 0.5),
        stroke: Stroke(colorArgb: 0xFF000000, width: 1.0),
      ));
      final result = validator.validate(doc);

      expect(result.hasErrors, isFalse);
    });

    test('negative font size is an error', () {
      final doc = SldDocument(
        layers: [
          SldLayer(
            name: 'test',
            styles: [
              UserStyle(
                featureTypeStyles: [
                  FeatureTypeStyle(rules: [
                    const Rule(
                      textSymbolizer: TextSymbolizer(
                        font: Font(size: -1.0),
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ],
      );
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'font-size-negative');
    });

    test('negative halo radius is an error', () {
      final doc = SldDocument(
        layers: [
          SldLayer(
            name: 'test',
            styles: [
              UserStyle(
                featureTypeStyles: [
                  FeatureTypeStyle(rules: [
                    const Rule(
                      textSymbolizer: TextSymbolizer(
                        halo: Halo(radius: -2.0),
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ],
      );
      final result = validator.validate(doc);

      expect(result.hasErrors, isTrue);
      expect(result.issues.first.code, 'halo-radius-negative');
    });
  });

  // -----------------------------------------------------------------------
  // Location paths
  // -----------------------------------------------------------------------
  group('location paths', () {
    test('issues have model-path locations', () {
      final doc = _docWith(RasterSymbolizer(opacity: 2.0));
      final result = validator.validate(doc);

      expect(
        result.issues.first.location,
        'layers[0].styles[0].featureTypeStyles[0].rules[0]'
            '.rasterSymbolizer.opacity',
      );
    });
  });

  // -----------------------------------------------------------------------
  // Multiple issues
  // -----------------------------------------------------------------------
  group('multiple issues', () {
    test('collects all issues from a single symbolizer', () {
      final doc = _docWith(RasterSymbolizer(
        opacity: 1.5,
        colorMap: ColorMap(
          type: ColorMapType.intervals,
          entries: [
            const ColorMapEntry(
                colorArgb: 0xFF000000, quantity: 100.0, opacity: 1.0),
            const ColorMapEntry(
                colorArgb: 0xFFFFFFFF, quantity: 50.0, opacity: 2.0),
          ],
        ),
        contrastEnhancement: const ContrastEnhancement(gammaValue: -1.0),
      ));
      final result = validator.validate(doc);
      final codes = result.issues.map((i) => i.code).toSet();

      expect(codes, contains('opacity-out-of-range'));
      expect(codes, contains('vendor-extension-intervals'));
      expect(codes, contains('quantity-not-ascending'));
      expect(codes, contains('entry-opacity-out-of-range'));
      expect(codes, contains('gamma-not-positive'));
    });
  });
}
