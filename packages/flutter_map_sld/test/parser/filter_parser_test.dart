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

  // -----------------------------------------------------------------------
  // Composite expression parsing
  // -----------------------------------------------------------------------
  group('parseExpression — composite', () {
    test('parses Concatenate', () {
      final el = _el(
        '<Concatenate>'
        '<PropertyName>vorname</PropertyName>'
        '<Literal>-</Literal>'
        '<PropertyName>nachname</PropertyName>'
        '</Concatenate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<Concatenate>());
      final concat = expr! as Concatenate;
      expect(concat.expressions, hasLength(3));
      expect(
        concat.evaluate({'vorname': 'Max', 'nachname': 'Müller'}),
        'Max-Müller',
      );
      expect(issues, isEmpty);
    });

    test('parses FormatNumber', () {
      final el = _el(
        '<FormatNumber>'
        '<PropertyName>population</PropertyName>'
        '<Pattern>#.##</Pattern>'
        '</FormatNumber>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<FormatNumber>());
      final fmt = expr! as FormatNumber;
      expect(fmt.pattern, '#.##');
      expect(fmt.evaluate({'population': 12345.6789}), '12345.68');
      expect(issues, isEmpty);
    });

    test('parses Categorize', () {
      final el = _el(
        '<Categorize>'
        '<LookupValue><PropertyName>pop</PropertyName></LookupValue>'
        '<Value>small</Value>'
        '<Threshold>10000</Threshold>'
        '<Value>medium</Value>'
        '<Threshold>100000</Threshold>'
        '<Value>large</Value>'
        '</Categorize>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<Categorize>());
      final cat = expr! as Categorize;
      expect(cat.thresholds, hasLength(2));
      expect(cat.values, hasLength(3));
      expect(cat.evaluate({'pop': 500}), 'small');
      expect(cat.evaluate({'pop': 50000}), 'medium');
      expect(cat.evaluate({'pop': 200000}), 'large');
      expect(issues, isEmpty);
    });

    test('parses Interpolate', () {
      final el = _el(
        '<Interpolate method="linear">'
        '<LookupValue><PropertyName>elevation</PropertyName></LookupValue>'
        '<InterpolationPoint><Data>0</Data><Value>0</Value></InterpolationPoint>'
        '<InterpolationPoint><Data>1000</Data><Value>100</Value></InterpolationPoint>'
        '</Interpolate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<Interpolate>());
      final interp = expr! as Interpolate;
      expect(interp.dataPoints, hasLength(2));
      expect(interp.mode, InterpolateMode.linear);
      expect(interp.evaluate({'elevation': 500}), closeTo(50.0, 0.001));
      expect(issues, isEmpty);
    });

    test('parses Recode', () {
      final el = _el(
        '<Recode>'
        '<LookupValue><PropertyName>code</PropertyName></LookupValue>'
        '<MapItem><Data>A</Data><Value>Alpha</Value></MapItem>'
        '<MapItem><Data>B</Data><Value>Bravo</Value></MapItem>'
        '</Recode>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<Recode>());
      final recode = expr! as Recode;
      expect(recode.mappings, hasLength(2));
      expect(recode.evaluate({'code': 'A'}), 'Alpha');
      expect(recode.evaluate({'code': 'B'}), 'Bravo');
      expect(recode.evaluate({'code': 'C'}), isNull);
      expect(issues, isEmpty);
    });

    test('nested Concatenate with FormatNumber', () {
      final el = _el(
        '<Concatenate>'
        '<Literal>Population:</Literal>'
        '<FormatNumber>'
        '<PropertyName>pop</PropertyName>'
        '<Pattern>#.#</Pattern>'
        '</FormatNumber>'
        '</Concatenate>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isA<Concatenate>());
      final concat = expr! as Concatenate;
      expect(concat.expressions, hasLength(2));
      expect(concat.evaluate({'pop': 1234.56}), 'Population:1234.6');
      expect(issues, isEmpty);
    });

    test('Categorize missing LookupValue warns', () {
      final el = _el(
        '<Categorize>'
        '<Value>small</Value>'
        '<Threshold>10000</Threshold>'
        '<Value>large</Value>'
        '</Categorize>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isNull);
      expect(issues.any((i) => i.code == 'categorize-missing-lookup'), isTrue);
    });

    test('Recode without MapItems warns', () {
      final el = _el(
        '<Recode>'
        '<LookupValue><PropertyName>code</PropertyName></LookupValue>'
        '</Recode>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseExpression(el, issues, '/test');

      expect(expr, isNull);
      expect(issues.any((i) => i.code == 'recode-no-mappings'), isTrue);
    });

    test('parseFirstExpression finds Concatenate', () {
      final el = _el(
        '<Label>'
        '<Concatenate>'
        '<PropertyName>name</PropertyName>'
        '<Literal> city</Literal>'
        '</Concatenate>'
        '</Label>',
      );
      final issues = <SldParseIssue>[];
      final expr = parseFirstExpression(el, issues, '/test');

      expect(expr, isA<Concatenate>());
    });
  });
}
