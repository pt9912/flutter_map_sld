import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/parser/parsers/expression_parser.dart';
import 'package:flutter_map_sld/src/parser/parsers/filter_parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  // -----------------------------------------------------------------------
  // Expression parser edge cases
  // -----------------------------------------------------------------------
  group('Expression parser edge cases', () {
    test('unsupported expression emits info issue', () {
      final el = _el('<UnknownExpr>hello</UnknownExpr>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(issues.any((i) => i.code == 'unsupported-expression'), isTrue);
    });

    test('Concatenate with no children warns', () {
      final el = _el('<Concatenate></Concatenate>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(issues.any((i) => i.code == 'concatenate-empty'), isTrue);
    });

    test('FormatNumber missing expression warns', () {
      final el = _el('<FormatNumber><Pattern>#.##</Pattern></FormatNumber>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(
          issues.any((i) => i.code == 'format-number-missing-value'), isTrue);
    });

    test('FormatNumber missing pattern warns', () {
      final el = _el(
          '<FormatNumber><Literal>42</Literal></FormatNumber>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(
          issues.any((i) => i.code == 'format-number-missing-pattern'), isTrue);
    });

    test('Categorize with no values warns', () {
      final el = _el(
        '<Categorize>'
        '<LookupValue><PropertyName>x</PropertyName></LookupValue>'
        '</Categorize>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(issues.any((i) => i.code == 'categorize-no-values'), isTrue);
    });

    test('Interpolate missing LookupValue warns', () {
      final el = _el(
        '<Interpolate>'
        '<InterpolationPoint><Data>0</Data><Value>0</Value></InterpolationPoint>'
        '</Interpolate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(
          issues.any((i) => i.code == 'interpolate-missing-lookup'), isTrue);
    });

    test('Interpolate with no points warns', () {
      final el = _el(
        '<Interpolate>'
        '<LookupValue><PropertyName>x</PropertyName></LookupValue>'
        '</Interpolate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(issues.any((i) => i.code == 'interpolate-no-points'), isTrue);
    });

    test('InterpolationPoint with invalid Data warns', () {
      final el = _el(
        '<Interpolate>'
        '<LookupValue><PropertyName>x</PropertyName></LookupValue>'
        '<InterpolationPoint><Data>abc</Data><Value>1</Value></InterpolationPoint>'
        '<InterpolationPoint><Data>10</Data><Value>2</Value></InterpolationPoint>'
        '</Interpolate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      // Should still parse with the valid point.
      expect(expr, isA<Interpolate>());
      expect((expr! as Interpolate).dataPoints, hasLength(1));
      expect(issues.any((i) => i.code == 'interpolation-point-invalid-data'),
          isTrue);
    });

    test('InterpolationPoint with missing Value warns', () {
      final el = _el(
        '<Interpolate>'
        '<LookupValue><PropertyName>x</PropertyName></LookupValue>'
        '<InterpolationPoint><Data>0</Data></InterpolationPoint>'
        '<InterpolationPoint><Data>10</Data><Value>2</Value></InterpolationPoint>'
        '</Interpolate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isA<Interpolate>());
      expect((expr! as Interpolate).dataPoints, hasLength(1));
      expect(issues.any((i) => i.code == 'interpolation-point-missing-value'),
          isTrue);
    });

    test('Recode missing LookupValue warns', () {
      final el = _el(
        '<Recode>'
        '<MapItem><Data>A</Data><Value>Alpha</Value></MapItem>'
        '</Recode>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isNull);
      expect(issues.any((i) => i.code == 'recode-missing-lookup'), isTrue);
    });

    test('MapItem missing Data warns', () {
      final el = _el(
        '<Recode>'
        '<LookupValue><PropertyName>code</PropertyName></LookupValue>'
        '<MapItem><Value>Alpha</Value></MapItem>'
        '<MapItem><Data>B</Data><Value>Bravo</Value></MapItem>'
        '</Recode>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isA<Recode>());
      expect((expr! as Recode).mappings, hasLength(1));
      expect(issues.any((i) => i.code == 'map-item-missing-data'), isTrue);
    });

    test('MapItem missing Value warns', () {
      final el = _el(
        '<Recode>'
        '<LookupValue><PropertyName>code</PropertyName></LookupValue>'
        '<MapItem><Data>A</Data></MapItem>'
        '<MapItem><Data>B</Data><Value>Bravo</Value></MapItem>'
        '</Recode>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isA<Recode>());
      expect((expr! as Recode).mappings, hasLength(1));
      expect(issues.any((i) => i.code == 'map-item-missing-value'), isTrue);
    });

    test('Interpolate with method=cubic', () {
      final el = _el(
        '<Interpolate method="cubic">'
        '<LookupValue><PropertyName>x</PropertyName></LookupValue>'
        '<InterpolationPoint><Data>0</Data><Value>0</Value></InterpolationPoint>'
        '<InterpolationPoint><Data>10</Data><Value>100</Value></InterpolationPoint>'
        '</Interpolate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');
      expect(expr, isA<Interpolate>());
      expect((expr! as Interpolate).mode, InterpolateMode.cubic);
    });

    test('parseAllExpressions collects multiple expressions', () {
      final el = _el(
        '<Root>'
        '<PropertyName>a</PropertyName>'
        '<Literal>b</Literal>'
        '<OtherElement>ignore</OtherElement>'
        '<PropertyName>c</PropertyName>'
        '</Root>',
      );
      final issues = <SldParseIssue>[];
      final exprs = parseAllExpressions(el, issues, '/test');
      expect(exprs, hasLength(3));
    });

    test('parseTwoExpressions with too few operands', () {
      final el = _el(
        '<Filter><PropertyName>x</PropertyName></Filter>',
      );
      final issues = <SldParseIssue>[];
      final result = parseTwoExpressions(el, issues, '/test');
      expect(result, isNull);
      expect(issues.any((i) => i.code == 'missing-comparison-operand'), isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // Filter parser edge cases
  // -----------------------------------------------------------------------
  group('Filter parser edge cases', () {
    test('unsupported filter operator emits info', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<SomeUnknownFilter/>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');
      expect(f, isNull);
      expect(issues.any((i) => i.code == 'unsupported-filter'), isTrue);
    });

    test('PropertyIsBetween with missing boundaries warns', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<PropertyIsBetween>'
        '<PropertyName>x</PropertyName>'
        '</PropertyIsBetween>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');
      expect(f, isNull);
      expect(
          issues.any((i) => i.code == 'missing-between-boundary'), isTrue);
    });

    test('empty filter element warns', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');
      expect(f, isNull);
    });

    test('Not with missing child warns', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<Not></Not>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');
      expect(f, isNull);
    });

    test('And with single child still parses', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<And>'
        '<PropertyIsEqualTo>'
        '<PropertyName>a</PropertyName><Literal>1</Literal>'
        '</PropertyIsEqualTo>'
        '</And>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');
      expect(f, isA<And>());
    });

    test('PropertyIsLessThanOrEqualTo parsed', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<PropertyIsLessThanOrEqualTo>'
        '<PropertyName>x</PropertyName><Literal>10</Literal>'
        '</PropertyIsLessThanOrEqualTo>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');
      expect(f, isA<PropertyIsLessThanOrEqualTo>());
    });

    test('PropertyIsGreaterThanOrEqualTo parsed', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<PropertyIsGreaterThanOrEqualTo>'
        '<PropertyName>x</PropertyName><Literal>10</Literal>'
        '</PropertyIsGreaterThanOrEqualTo>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');
      expect(f, isA<PropertyIsGreaterThanOrEqualTo>());
    });
  });

  // -----------------------------------------------------------------------
  // Vector symbolizer parser — fill SvgParameter path
  // -----------------------------------------------------------------------
  group('SLD with SvgParameter-based styling', () {
    test('polygon with SvgParameter stroke attributes parses', () {
      final result = SldDocument.parseXmlString(
        '<StyledLayerDescriptor version="1.0.0"'
        ' xmlns="http://www.opengis.net/sld">'
        '<NamedLayer><Name>test</Name>'
        '<UserStyle><FeatureTypeStyle><Rule>'
        '<PolygonSymbolizer>'
        '<Stroke>'
        '<SvgParameter name="stroke">#FF0000</SvgParameter>'
        '<SvgParameter name="stroke-width">3</SvgParameter>'
        '<SvgParameter name="stroke-opacity">0.5</SvgParameter>'
        '<SvgParameter name="stroke-linecap">round</SvgParameter>'
        '<SvgParameter name="stroke-linejoin">bevel</SvgParameter>'
        '<SvgParameter name="stroke-dasharray">5 3 2</SvgParameter>'
        '</Stroke>'
        '</PolygonSymbolizer>'
        '</Rule></FeatureTypeStyle></UserStyle>'
        '</NamedLayer></StyledLayerDescriptor>',
      );
      expect(result.hasErrors, isFalse);
      final stroke =
          result.document!.layers.first.styles.first.featureTypeStyles.first
              .rules.first.polygonSymbolizer!.stroke!;
      expect(stroke.colorArgb, isNotNull);
      expect(stroke.width, 3.0);
      expect(stroke.opacity, 0.5);
      expect(stroke.lineCap, 'round');
      expect(stroke.lineJoin, 'bevel');
      expect(stroke.dashArray, [5.0, 3.0, 2.0]);
    });

    test('text with SvgParameter font attributes parses', () {
      final result = SldDocument.parseXmlString(
        '<StyledLayerDescriptor version="1.0.0"'
        ' xmlns="http://www.opengis.net/sld">'
        '<NamedLayer><Name>test</Name>'
        '<UserStyle><FeatureTypeStyle><Rule>'
        '<TextSymbolizer>'
        '<Label><PropertyName>name</PropertyName></Label>'
        '<Font>'
        '<SvgParameter name="font-family">Serif</SvgParameter>'
        '<SvgParameter name="font-style">italic</SvgParameter>'
        '<SvgParameter name="font-weight">bold</SvgParameter>'
        '<SvgParameter name="font-size">14</SvgParameter>'
        '</Font>'
        '</TextSymbolizer>'
        '</Rule></FeatureTypeStyle></UserStyle>'
        '</NamedLayer></StyledLayerDescriptor>',
      );
      expect(result.hasErrors, isFalse);
      final ts = result.document!.layers.first.styles.first
          .featureTypeStyles.first.rules.first.textSymbolizer!;
      expect(ts.font!.family, 'Serif');
      expect(ts.font!.style, 'italic');
      expect(ts.font!.weight, 'bold');
      expect(ts.font!.size, 14.0);
    });
  });
}
