import 'package:flutter/painting.dart';
import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld_flutter_map/flutter_map_sld_flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adapter = FlutterMapStyleAdapter();

  group('adaptRule', () {
    test('maps point symbolizer styles', () {
      const rule = Rule(
        pointSymbolizer: PointSymbolizer(
          graphic: Graphic(
            mark: Mark(
              wellKnownName: 'circle',
              fill: Fill(colorArgb: 0xFFFF0000, opacity: 0.8),
              stroke: Stroke(
                colorArgb: 0xFF000000,
                width: 1.5,
                opacity: 0.6,
              ),
            ),
            size: 12,
            rotation: 45,
            opacity: 0.5,
          ),
        ),
      );

      final style = adapter.adaptRule(rule);

      expect(style.point, isNotNull);
      expect(style.point!.markShape, FlutterMapMarkShape.circle);
      expect(style.point!.fill!.color, const Color(0xFFFF0000));
      expect(style.point!.fill!.opacity, 0.8);
      expect(style.point!.stroke!.color, const Color(0xFF000000));
      expect(style.point!.stroke!.width, 1.5);
      expect(style.point!.stroke!.opacity, 0.6);
      expect(style.point!.size, 12);
      expect(style.point!.rotation, 45);
      expect(style.point!.opacity, 0.5);
    });

    test('maps line and polygon styles', () {
      const rule = Rule(
        lineSymbolizer: LineSymbolizer(
          stroke: Stroke(
            colorArgb: 0xFF0000FF,
            width: 3,
            opacity: 0.7,
            dashArray: [5, 3],
            lineCap: 'round',
            lineJoin: 'bevel',
          ),
        ),
        polygonSymbolizer: PolygonSymbolizer(
          fill: Fill(colorArgb: 0xFF00FF00, opacity: 0.3),
          stroke: Stroke(colorArgb: 0xFF111111, width: 2),
        ),
      );

      final style = adapter.adaptRule(rule);

      expect(style.line!.stroke!.color, const Color(0xFF0000FF));
      expect(style.line!.stroke!.width, 3);
      expect(style.line!.stroke!.opacity, 0.7);
      expect(style.line!.stroke!.dashArray, [5, 3]);
      expect(style.line!.stroke!.cap, StrokeCap.round);
      expect(style.line!.stroke!.join, StrokeJoin.bevel);

      expect(style.polygon!.fill!.color, const Color(0xFF00FF00));
      expect(style.polygon!.fill!.opacity, 0.3);
      expect(style.polygon!.stroke!.color, const Color(0xFF111111));
      expect(style.polygon!.stroke!.width, 2);
    });

    test('maps text symbolizer and evaluates label', () {
      const rule = Rule(
        textSymbolizer: TextSymbolizer(
          label: PropertyName('name'),
          font: Font(
            family: 'Arial',
            style: 'italic',
            weight: 'bold',
            size: 14,
          ),
          fill: Fill(colorArgb: 0xFF222222, opacity: 0.9),
          halo: Halo(
            radius: 2,
            fill: Fill(colorArgb: 0xFFFFFFFF, opacity: 0.75),
          ),
          labelPlacement: LabelPlacement(
            pointPlacement: PointPlacement(
              anchorPointX: 0.5,
              anchorPointY: 1.0,
              displacementX: 8,
              displacementY: -4,
              rotation: 10,
            ),
          ),
        ),
      );

      final style = adapter.adaptRule(rule, properties: const {'name': 'Berlin'});

      expect(style.text, isNotNull);
      expect(style.text!.text, 'Berlin');
      expect(style.text!.fill!.color, const Color(0xFF222222));
      expect(style.text!.fill!.opacity, 0.9);
      expect(style.text!.textStyle!.fontFamily, 'Arial');
      expect(style.text!.textStyle!.fontSize, 14);
      expect(style.text!.textStyle!.fontStyle, FontStyle.italic);
      expect(style.text!.textStyle!.fontWeight, FontWeight.bold);
      expect(style.text!.haloFill!.color, const Color(0xFFFFFFFF));
      expect(style.text!.haloFill!.opacity, 0.75);
      expect(style.text!.haloRadius, 2);
      expect(style.text!.pointPlacement!.anchorPointX, 0.5);
      expect(style.text!.pointPlacement!.displacementY, -4);
    });
  });

  group('adaptDocument', () {
    test('uses filter and scale selection from the core model', () {
      final doc = SldDocument(
        layers: [
          SldLayer(
            name: 'places',
            styles: [
              UserStyle(
                featureTypeStyles: [
                  FeatureTypeStyle(
                    rules: const [
                      Rule(
                        name: 'cities',
                        filter: PropertyIsEqualTo(
                          expression1: PropertyName('type'),
                          expression2: Literal('city'),
                        ),
                        textSymbolizer: TextSymbolizer(
                          label: PropertyName('name'),
                        ),
                      ),
                      Rule(
                        name: 'towns',
                        filter: PropertyIsEqualTo(
                          expression1: PropertyName('type'),
                          expression2: Literal('town'),
                        ),
                        minScaleDenominator: 1000,
                        textSymbolizer: TextSymbolizer(
                          label: PropertyName('name'),
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

      final cityStyles = adapter.adaptDocument(
        doc,
        properties: const {'type': 'city', 'name': 'Berlin'},
      );
      expect(cityStyles, hasLength(1));
      expect(cityStyles.first.matchedRule.rule.name, 'cities');
      expect(cityStyles.first.style.text!.text, 'Berlin');

      final townStylesTooSmall = adapter.adaptDocument(
        doc,
        properties: const {'type': 'town', 'name': 'Freiburg'},
        scaleDenominator: 500,
      );
      expect(townStylesTooSmall, isEmpty);

      final townStyles = adapter.adaptDocument(
        doc,
        properties: const {'type': 'town', 'name': 'Freiburg'},
        scaleDenominator: 5000,
      );
      expect(townStyles, hasLength(1));
      expect(townStyles.first.matchedRule.rule.name, 'towns');
      expect(townStyles.first.matchedRule.layer.name, 'places');
      expect(townStyles.first.style.text!.text, 'Freiburg');
    });

    test('preserves external graphic metadata for point styles', () {
      const rule = Rule(
        pointSymbolizer: PointSymbolizer(
          graphic: Graphic(
            externalGraphic: ExternalGraphic(
              onlineResource: 'https://example.com/icon.png',
              format: 'image/png',
            ),
            size: 24,
          ),
        ),
      );

      final style = adapter.adaptRule(rule);

      expect(style.point!.externalGraphicUrl, 'https://example.com/icon.png');
      expect(style.point!.externalGraphicFormat, 'image/png');
      expect(style.point!.markShape, FlutterMapMarkShape.unknown);
      expect(style.point!.size, 24);
    });
  });
}
