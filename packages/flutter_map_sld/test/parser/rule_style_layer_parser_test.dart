import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/parser/parsers/layer_parser.dart';
import 'package:flutter_map_sld/src/parser/parsers/rule_parser.dart';
import 'package:flutter_map_sld/src/parser/parsers/style_parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  // -----------------------------------------------------------------------
  // RuleParser
  // -----------------------------------------------------------------------
  group('parseRule', () {
    test('parses rule with name and scale denominators', () {
      final el = _el(
        '<Rule>'
        '<Name>DEM</Name>'
        '<MinScaleDenominator>1000</MinScaleDenominator>'
        '<MaxScaleDenominator>50000</MaxScaleDenominator>'
        '</Rule>',
      );
      final issues = <SldParseIssue>[];
      final rule = parseRule(el, issues, '/test');

      expect(rule.name, 'DEM');
      expect(rule.minScaleDenominator, 1000.0);
      expect(rule.maxScaleDenominator, 50000.0);
      expect(rule.rasterSymbolizer, isNull);
      expect(issues, isEmpty);
    });

    test('parses rule with raster symbolizer', () {
      final el = _el(
        '<Rule>'
        '<RasterSymbolizer>'
        '<Opacity>0.5</Opacity>'
        '</RasterSymbolizer>'
        '</Rule>',
      );
      final issues = <SldParseIssue>[];
      final rule = parseRule(el, issues, '/test');

      expect(rule.rasterSymbolizer, isNotNull);
      expect(rule.rasterSymbolizer!.opacity, 0.5);
    });

    test('handles empty rule', () {
      final el = _el('<Rule/>');
      final issues = <SldParseIssue>[];
      final rule = parseRule(el, issues, '/test');

      expect(rule.name, isNull);
      expect(rule.rasterSymbolizer, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // StyleParser
  // -----------------------------------------------------------------------
  group('parseFeatureTypeStyle', () {
    test('parses rules', () {
      final el = _el(
        '<FeatureTypeStyle>'
        '<Rule><Name>R1</Name></Rule>'
        '<Rule><Name>R2</Name></Rule>'
        '</FeatureTypeStyle>',
      );
      final issues = <SldParseIssue>[];
      final fts = parseFeatureTypeStyle(el, issues, '/test');

      expect(fts.rules, hasLength(2));
      expect(fts.rules[0].name, 'R1');
      expect(fts.rules[1].name, 'R2');
    });
  });

  group('parseUserStyle', () {
    test('parses name and feature type styles', () {
      final el = _el(
        '<UserStyle>'
        '<Name>MyStyle</Name>'
        '<FeatureTypeStyle>'
        '<Rule><Name>R1</Name></Rule>'
        '</FeatureTypeStyle>'
        '</UserStyle>',
      );
      final issues = <SldParseIssue>[];
      final style = parseUserStyle(el, issues, '/test');

      expect(style.name, 'MyStyle');
      expect(style.featureTypeStyles, hasLength(1));
      expect(style.featureTypeStyles.first.rules.first.name, 'R1');
    });

    test('works with se: namespace', () {
      final el = _el(
        '<sld:UserStyle xmlns:sld="http://www.opengis.net/sld" '
        'xmlns:se="http://www.opengis.net/se">'
        '<se:Name>Styled</se:Name>'
        '<se:FeatureTypeStyle>'
        '<se:Rule>'
        '<se:RasterSymbolizer>'
        '<se:Opacity>1.0</se:Opacity>'
        '</se:RasterSymbolizer>'
        '</se:Rule>'
        '</se:FeatureTypeStyle>'
        '</sld:UserStyle>',
      );
      final issues = <SldParseIssue>[];
      final style = parseUserStyle(el, issues, '/test');

      expect(style.name, 'Styled');
      expect(
        style.featureTypeStyles.first.rules.first.rasterSymbolizer?.opacity,
        1.0,
      );
      expect(issues, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // LayerParser
  // -----------------------------------------------------------------------
  group('parseNamedLayer', () {
    test('parses name and user styles', () {
      final el = _el(
        '<NamedLayer>'
        '<Name>DEM</Name>'
        '<UserStyle>'
        '<Name>Elevation</Name>'
        '<FeatureTypeStyle>'
        '<Rule>'
        '<RasterSymbolizer>'
        '<Opacity>1.0</Opacity>'
        '</RasterSymbolizer>'
        '</Rule>'
        '</FeatureTypeStyle>'
        '</UserStyle>'
        '</NamedLayer>',
      );
      final issues = <SldParseIssue>[];
      final layer = parseNamedLayer(el, issues, '/test');

      expect(layer.name, 'DEM');
      expect(layer.styles, hasLength(1));
      expect(layer.styles.first.name, 'Elevation');
      expect(issues, isEmpty);
    });

    test('handles layer without styles', () {
      final el = _el('<NamedLayer><Name>Empty</Name></NamedLayer>');
      final issues = <SldParseIssue>[];
      final layer = parseNamedLayer(el, issues, '/test');

      expect(layer.name, 'Empty');
      expect(layer.styles, isEmpty);
    });
  });
}
