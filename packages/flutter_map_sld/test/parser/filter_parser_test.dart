import 'package:flutter_map_sld/flutter_map_sld.dart';
import 'package:flutter_map_sld/src/parser/parsers/expression_parser.dart';
import 'package:flutter_map_sld/src/parser/parsers/filter_parser.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

XmlElement _el(String xml) => XmlDocument.parse(xml).rootElement;

void main() {
  // -----------------------------------------------------------------------
  // Expression parser
  // -----------------------------------------------------------------------
  group('parseExpression', () {
    test('parses PropertyName', () {
      final el = _el('<PropertyName>name</PropertyName>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<PropertyName>());
      expect((expr! as PropertyName).name, 'name');
    });

    test('parses string Literal', () {
      final el = _el('<Literal>hello</Literal>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<Literal>());
      expect((expr! as Literal).value, 'hello');
    });

    test('parses numeric Literal', () {
      final el = _el('<Literal>42</Literal>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<Literal>());
      expect((expr! as Literal).value, 42);
    });

    test('warns on empty PropertyName', () {
      final el = _el('<PropertyName></PropertyName>');
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isNull);
      expect(issues.first.code, 'empty-property-name');
    });
  });

  // -----------------------------------------------------------------------
  // Filter parser
  // -----------------------------------------------------------------------
  group('parseFilter', () {
    test('parses PropertyIsEqualTo', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<PropertyIsEqualTo>'
        '<PropertyName>type</PropertyName>'
        '<Literal>city</Literal>'
        '</PropertyIsEqualTo>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<PropertyIsEqualTo>());
    });

    test('parses And with two children', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<And>'
        '<PropertyIsEqualTo>'
        '<PropertyName>a</PropertyName><Literal>1</Literal>'
        '</PropertyIsEqualTo>'
        '<PropertyIsGreaterThan>'
        '<PropertyName>b</PropertyName><Literal>10</Literal>'
        '</PropertyIsGreaterThan>'
        '</And>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<And>());
      expect((f! as And).filters, hasLength(2));
    });

    test('parses Not', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<Not>'
        '<PropertyIsNull>'
        '<PropertyName>name</PropertyName>'
        '</PropertyIsNull>'
        '</Not>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<Not>());
      expect((f! as Not).filter, isA<PropertyIsNull>());
    });

    test('parses PropertyIsLike', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<PropertyIsLike wildCard="*" singleChar="?" escapeChar="\\"'
        ' literal="Ber*">'
        '<PropertyName>name</PropertyName>'
        '</PropertyIsLike>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<PropertyIsLike>());
      final like = f! as PropertyIsLike;
      expect(like.pattern, 'Ber*');
      expect(like.evaluate({'name': 'Berlin'}), isTrue);
    });

    test('parses PropertyIsBetween', () {
      final el = _el(
        '<Filter xmlns="http://www.opengis.net/ogc">'
        '<PropertyIsBetween>'
        '<PropertyName>temp</PropertyName>'
        '<LowerBoundary><Literal>10</Literal></LowerBoundary>'
        '<UpperBoundary><Literal>30</Literal></UpperBoundary>'
        '</PropertyIsBetween>'
        '</Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<PropertyIsBetween>());
      expect(f!.evaluate({'temp': 20}), isTrue);
      expect(f.evaluate({'temp': 5}), isFalse);
    });

    test('parses with ogc: prefix', () {
      final el = _el(
        '<ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">'
        '<ogc:PropertyIsEqualTo>'
        '<ogc:PropertyName>type</ogc:PropertyName>'
        '<ogc:Literal>city</ogc:Literal>'
        '</ogc:PropertyIsEqualTo>'
        '</ogc:Filter>',
      );
      final issues = <SldParseIssue>[];
      final f = parseFilter(el, issues, '/test');

      expect(f, isA<PropertyIsEqualTo>());
      expect(f!.evaluate({'type': 'city'}), isTrue);
    });
  });
}
